from dataclasses import dataclass
from typing import Dict, List, Tuple, Set


@dataclass(frozen=True)
class Gate:
    name: str
    op: str
    inputs: Tuple[str, str]
    rtl_ref: str


class GateDAG:
    OPS = {"AND", "OR", "XOR"}

    def __init__(self, name: str):
        self.name = name
        self.primary_inputs = {f"A[{i}]" for i in range(16)} | {f"B[{i}]" for i in range(16)}
        self.constants = {"CONST0", "CONST1"}
        self.gates: Dict[str, Gate] = {}
        self.outputs: Dict[str, str] = {}
        self._signature: Dict[Tuple[str, Tuple[str, str]], str] = {}
        self.metrics = {"black_cells": 0, "gray_cells": 0,
                        "prefix_cells": 0, "local_carry_cells": 0}
        self.mapping: List[Tuple[str, str]] = []

    def add_gate(self, name: str, op: str, left: str, right: str, rtl_ref: str) -> str:
        if op not in self.OPS:
            raise ValueError(f"unsupported gate type {op}")
        if name in self.gates or name in self.primary_inputs or name in self.constants:
            raise ValueError(f"duplicate node name {name}")
        missing = [x for x in (left, right) if x not in self.gates and
                   x not in self.primary_inputs and x not in self.constants]
        if missing:
            raise ValueError(f"{name} has undefined inputs {missing}")
        inputs = tuple(sorted((left, right)))
        signature = (op, inputs)
        if signature in self._signature:
            raise ValueError(f"duplicated logic {name}, already represented by {self._signature[signature]}")
        self.gates[name] = Gate(name, op, (left, right), rtl_ref)
        self._signature[signature] = name
        return name

    def set_output(self, index: int, node: str):
        if node not in self.gates and node not in self.primary_inputs and node not in self.constants:
            raise ValueError(f"output SUM[{index}] references undefined {node}")
        self.outputs[f"SUM[{index}]"] = node

    def reachable_gates(self) -> Set[str]:
        seen: Set[str] = set()
        stack = list(self.outputs.values())
        while stack:
            node = stack.pop()
            if node in self.gates and node not in seen:
                seen.add(node)
                stack.extend(self.gates[node].inputs)
        return seen

    def validate(self):
        if set(self.outputs) != {f"SUM[{i}]" for i in range(17)}:
            raise ValueError("model does not define exactly SUM[0] through SUM[16]")
        state: Dict[str, int] = {}

        def visit(node: str):
            if node not in self.gates:
                return
            if state.get(node) == 1:
                raise ValueError(f"combinational loop at {node}")
            if state.get(node) == 2:
                return
            state[node] = 1
            gate = self.gates[node]
            if gate.op not in self.OPS or len(gate.inputs) != 2:
                raise ValueError(f"invalid gate {node}")
            for source in gate.inputs:
                visit(source)
            state[node] = 2

        for output in self.outputs.values():
            visit(output)
        if any(not self._traces_to_source(node, set()) for node in self.outputs.values()):
            raise ValueError("an output cannot be traced to a primary input or constant")
        return {"all_outputs": True, "acyclic": True, "valid_gates": True,
                "traceable": True, "shared_nodes": True}

    def _traces_to_source(self, node: str, active: Set[str]) -> bool:
        if node in self.primary_inputs or node in self.constants:
            return True
        if node not in self.gates or node in active:
            return False
        next_active = active | {node}
        return all(self._traces_to_source(x, next_active) for x in self.gates[node].inputs)

    def evaluate(self, a: int, b: int) -> int:
        values = {"CONST0": 0, "CONST1": 1}
        values.update({f"A[{i}]": (a >> i) & 1 for i in range(16)})
        values.update({f"B[{i}]": (b >> i) & 1 for i in range(16)})
        for name, gate in self.gates.items():
            x, y = (values[s] for s in gate.inputs)
            values[name] = {"AND": x & y, "OR": x | y, "XOR": x ^ y}[gate.op]
        result = 0
        for i in range(17):
            result |= values[self.outputs[f"SUM[{i}]"]] << i
        return result

    def gate_counts(self, optimized: bool) -> Dict[str, int]:
        selected = self.reachable_gates() if optimized else set(self.gates)
        counts = {op: sum(self.gates[n].op == op for n in selected) for op in self.OPS}
        counts["TOTAL"] = sum(counts.values())
        return counts

    def timing(self, delays: Dict[str, float]):
        arrival = {x: 0.0 for x in self.primary_inputs | self.constants}
        predecessor: Dict[str, str] = {}
        for name, gate in self.gates.items():
            left, right = gate.inputs
            chosen = left if arrival[left] >= arrival[right] else right
            arrival[name] = max(arrival[left], arrival[right]) + delays[gate.op]
            predecessor[name] = chosen
        rows = []
        paths = {}
        for i in range(17):
            output = f"SUM[{i}]"
            node = self.outputs[output]
            path = []
            while node in self.gates:
                path.append(node)
                node = predecessor[node]
            path.reverse()
            composition = {op: sum(self.gates[n].op == op for n in path) for op in self.OPS}
            rows.append({"output": output, "delay": arrival[self.outputs[output]]})
            paths[output] = {"source": node, "nodes": path, "composition": composition}
        maximum = max(row["delay"] for row in rows)
        endpoint = next(row["output"] for row in rows if row["delay"] == maximum)
        return rows, maximum, endpoint, paths[endpoint]

    def constant_fold(self):
        """Return a constant-propagated DAG and original-to-folded node aliases.

        Only the explicitly requested Boolean identities are applied.  The
        returned DAG may still contain unreachable gates; callers use the
        normal reachable-gate view for the post-fold/pruned cost.
        """
        folded = GateDAG(self.name + " (constant-folded)")
        folded.metrics = dict(self.metrics)
        aliases = {x: x for x in self.primary_inputs | self.constants}

        def existing_or_add(name, op, left, right, rtl_ref):
            signature = (op, tuple(sorted((left, right))))
            if signature in folded._signature:
                return folded._signature[signature]
            return folded.add_gate(name, op, left, right, rtl_ref)

        for name, gate in self.gates.items():
            left, right = (aliases[x] for x in gate.inputs)
            replacement = None
            if gate.op == "AND":
                if "CONST0" in (left, right):
                    replacement = "CONST0"
                elif left == "CONST1":
                    replacement = right
                elif right == "CONST1":
                    replacement = left
            elif gate.op == "OR":
                if "CONST1" in (left, right):
                    replacement = "CONST1"
                elif left == "CONST0":
                    replacement = right
                elif right == "CONST0":
                    replacement = left
            elif gate.op == "XOR":
                if left == "CONST0":
                    replacement = right
                elif right == "CONST0":
                    replacement = left
            aliases[name] = replacement if replacement is not None else existing_or_add(
                name, gate.op, left, right, gate.rtl_ref)
        for output, node in self.outputs.items():
            folded.set_output(int(output[4:-1]), aliases[node])
        folded.validate()
        return folded, aliases
