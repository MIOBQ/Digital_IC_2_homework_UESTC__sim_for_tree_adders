import csv
import itertools
import json
import math
from collections import defaultdict
from pathlib import Path

from adder_models import build_all


ROOT = Path(__file__).resolve().parent
RESULTS = ROOT / "results"
TOL = 1e-12


def write_csv(name, rows):
    path = RESULTS / name
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)


def analyze(model, delays):
    if set(delays) != {"AND", "OR", "XOR"} or any(v <= 0 for v in delays.values()):
        raise ValueError(f"all three gate delays must be positive: {delays}")
    output_rows, maximum, endpoint, path = model.timing(delays)
    critical_endpoints = [r["output"] for r in output_rows if math.isclose(r["delay"], maximum, abs_tol=TOL)]

    # GateDAG.timing supplies the selected real path.  This second traversal is
    # only used to flag equal-arrival alternatives on that selected path.
    arrival = {x: 0.0 for x in model.primary_inputs | model.constants}
    for name, gate in model.gates.items():
        arrival[name] = max(arrival[gate.inputs[0]], arrival[gate.inputs[1]]) + delays[gate.op]
    internal_tie = any(math.isclose(arrival[model.gates[n].inputs[0]],
                                    arrival[model.gates[n].inputs[1]], abs_tol=TOL)
                       for n in path["nodes"])
    return {
        "max_delay": maximum, "endpoint": endpoint,
        "critical_endpoints": critical_endpoints,
        "critical_endpoint_count": len(critical_endpoints),
        "multiple_critical_paths_possible": internal_tie or len(critical_endpoints) > 1,
        "source": path["source"], "and_gates": path["composition"]["AND"],
        "or_gates": path["composition"]["OR"], "xor_gates": path["composition"]["XOR"],
        "gate_count": len(path["nodes"]), "node_sequence": " -> ".join(path["nodes"]),
        "output_delays": tuple(r["delay"] for r in output_rows)
    }


def common_record(kind, scenario, delays, adder, result, baseline):
    delta = result["max_delay"] - baseline["max_delay"]
    return {
        "analysis_kind": kind, "scenario": scenario,
        "and_delay": delays["AND"], "or_delay": delays["OR"], "xor_delay": delays["XOR"],
        "adder": adder, "max_delay": result["max_delay"], "endpoint": result["endpoint"],
        "critical_endpoints": ";".join(result["critical_endpoints"]),
        "critical_endpoint_count": result["critical_endpoint_count"],
        "multiple_critical_paths_possible": result["multiple_critical_paths_possible"],
        "source": result["source"], "and_gates": result["and_gates"],
        "or_gates": result["or_gates"], "xor_gates": result["xor_gates"],
        "path_gate_count": result["gate_count"], "node_sequence": result["node_sequence"],
        "baseline_delay": baseline["max_delay"], "delay_delta": delta,
        "delay_change_percent": 100.0 * delta / baseline["max_delay"],
        "endpoint_changed_from_baseline": result["endpoint"] != baseline["endpoint"],
        "path_changed_from_baseline": result["node_sequence"] != baseline["node_sequence"]
    }


def competition_ranks(delay_by_adder):
    return {name: 1 + sum(other < delay - TOL for other in delay_by_adder.values())
            for name, delay in delay_by_adder.items()}


def pareto_rows(scenario, delays, delay_by_adder, gates):
    rows = []
    for name, delay in delay_by_adder.items():
        dominated_by = []
        for other, other_delay in delay_by_adder.items():
            if other == name:
                continue
            if (gates[other] <= gates[name] and other_delay <= delay + TOL and
                    (gates[other] < gates[name] or other_delay < delay - TOL)):
                dominated_by.append(other)
        rows.append({"scenario": scenario, "and_delay": delays["AND"],
                     "or_delay": delays["OR"], "xor_delay": delays["XOR"],
                     "adder": name, "total_gates": gates[name], "max_delay": delay,
                     "on_pareto_front": not dominated_by,
                     "dominated_by": ";".join(sorted(dominated_by))})
    return rows


def main():
    cfg = json.loads((ROOT / "sensitivity_config.json").read_text(encoding="utf-8"))
    baseline_models = build_all()
    models = []
    for original in baseline_models:
        folded, _ = original.constant_fold(); folded.name = original.name
        folded.validate(); models.append(folded)
    names = [m.name for m in models]
    gates = {m.name: m.gate_counts(True)["TOTAL"] for m in models}
    if gates != cfg["expected_gate_counts"]:
        raise SystemExit(f"BASELINE_GATE_COUNT_MISMATCH actual={gates}")

    baseline = {m.name: analyze(m, cfg["baseline_delays"]) for m in models}
    actual_delays = {name: value["max_delay"] for name, value in baseline.items()}
    if actual_delays != cfg["expected_baseline_delays"]:
        raise SystemExit(f"BASELINE_DELAY_MISMATCH actual={actual_delays}")
    print("BASELINE_REPRODUCTION_PASS")

    single_rows, all_path_rows = [], []
    sweeps = [("XOR", cfg["xor_values"]), ("AND", cfg["and_values"]), ("OR", cfg["or_values"])]
    single_curves = defaultdict(dict)
    for parameter, values in sweeps:
        for value in values:
            delays = dict(cfg["baseline_delays"]); delays[parameter] = value
            scenario = f"{parameter}_{value:g}"
            for model in models:
                result = analyze(model, delays)
                record = common_record("single", scenario, delays, model.name, result, baseline[model.name])
                record = {"varied_parameter": parameter, "varied_value": value, **record}
                single_rows.append(record); all_path_rows.append(dict(record))
                single_curves[(parameter, value)][model.name] = result["output_delays"]

    grid_rows, ranking_rows, pareto = [], [], []
    grid_results = {}
    combinations = list(itertools.product(cfg["grid"]["AND"], cfg["grid"]["OR"], cfg["grid"]["XOR"]))
    for index, (and_delay, or_delay, xor_delay) in enumerate(combinations):
        delays = {"AND": and_delay, "OR": or_delay, "XOR": xor_delay}
        scenario = f"GRID_{index:03d}"
        per_adder = {m.name: analyze(m, delays) for m in models}
        # Repeatability check uses the same GateDAG timing method again.
        repeated = {m.name: analyze(m, delays) for m in models}
        for name in names:
            keys = ("max_delay", "endpoint", "node_sequence")
            if any(per_adder[name][k] != repeated[name][k] for k in keys):
                raise SystemExit(f"NONDETERMINISTIC_RESULT {scenario} {name}")
        delay_by_adder = {name: per_adder[name]["max_delay"] for name in names}
        ranks = competition_ranks(delay_by_adder)
        winners = sorted(name for name in names if ranks[name] == 1)
        for name in names:
            rec = common_record("grid", scenario, delays, name, per_adder[name], baseline[name])
            grid_rows.append(rec); all_path_rows.append(dict(rec))
            ranking_rows.append({"scenario": scenario, "and_delay": and_delay,
                "or_delay": or_delay, "xor_delay": xor_delay, "adder": name,
                "max_delay": delay_by_adder[name], "rank": ranks[name],
                "rank_tie_count": sum(math.isclose(delay_by_adder[x], delay_by_adder[name], abs_tol=TOL) for x in names),
                "minimum_delay": min(delay_by_adder.values()), "fastest_structures": ";".join(winners)})
        pareto.extend(pareto_rows(scenario, delays, delay_by_adder, gates))
        grid_results[scenario] = per_adder

    if len(single_rows) != 126 or len(combinations) != 80 or len(grid_rows) != 560:
        raise SystemExit("RECORD_COUNT_MISMATCH")

    # Full 17-output curve equivalence, not merely maximum-delay equality.
    sparse_equivalent_single = all(v["Sparse-2"] == v["Han-Carlson"] for v in single_curves.values())
    sparse_equivalent_grid = all(v["Sparse-2"]["output_delays"] == v["Han-Carlson"]["output_delays"]
                                 for v in grid_results.values())
    if not (sparse_equivalent_single and sparse_equivalent_grid):
        raise SystemExit("SPARSE2_HC_CURVE_MISMATCH")

    stats = {}
    for name in names:
        rr = [r for r in ranking_rows if r["adder"] == name]
        gr = [r for r in grid_rows if r["adder"] == name]
        wins = sum(r["rank"] == 1 for r in rr)
        stats[name] = {
            "rank1_count": wins, "rank1_proportion": wins / 80.0,
            "average_rank": sum(r["rank"] for r in rr) / 80.0,
            "min_delay": min(r["max_delay"] for r in gr),
            "max_delay": max(r["max_delay"] for r in gr),
            "max_absolute_change": max(abs(r["delay_delta"]) for r in gr),
            "max_absolute_change_percent": max(abs(r["delay_change_percent"]) for r in gr),
            "endpoint_switch_count": sum(r["endpoint_changed_from_baseline"] for r in gr),
            "path_switch_count": sum(r["path_changed_from_baseline"] for r in gr),
            "critical_endpoints_seen": sorted(set(r["endpoint"] for r in gr)),
            "unique_selected_paths": len(set(r["node_sequence"] for r in gr))
        }

    pairs = [("Kogge-Stone","Han-Carlson"),("Kogge-Stone","Brent-Kung"),
             ("Brent-Kung","Sparse-4"),("Sparse-2","Han-Carlson"),("Sparse-4","Sparse-8")]
    reversals = {}
    for left, right in pairs:
        signs = set()
        for values in grid_results.values():
            diff = values[left]["max_delay"] - values[right]["max_delay"]
            signs.add(0 if abs(diff) <= TOL else (1 if diff > 0 else -1))
        reversals[f"{left} vs {right}"] = {"relations_seen": sorted(signs),
            "strict_order_reversal": -1 in signs and 1 in signs}

    baseline_delay_map = {n: baseline[n]["max_delay"] for n in names}
    baseline_pareto = pareto_rows("BASELINE", cfg["baseline_delays"], baseline_delay_map, gates)
    baseline_front = sorted(r["adder"] for r in baseline_pareto if r["on_pareto_front"])
    pareto_counts = {name: sum(r["adder"] == name and r["on_pareto_front"] for r in pareto) for name in names}
    front_sets = sorted(set(tuple(sorted(r["adder"] for r in pareto if r["scenario"] == scenario and r["on_pareto_front"]))
                            for scenario in grid_results))

    write_csv("sensitivity_single_parameter.csv", single_rows)
    write_csv("sensitivity_grid.csv", grid_rows)
    write_csv("sensitivity_rankings.csv", ranking_rows)
    write_csv("sensitivity_critical_paths.csv", all_path_rows)
    write_csv("sensitivity_pareto.csv", baseline_pareto + pareto)
    summary = {
        "baseline_reproduced": True, "baseline_gate_counts": gates,
        "baseline_delays": actual_delays, "single_parameter_records": len(single_rows),
        "grid_combinations": len(combinations), "grid_records": len(grid_rows),
        "repeatability_check": "pass", "ranking_statistics": stats,
        "pairwise_order_reversals": reversals,
        "sparse2_han_carlson_full_curves_equal_single": sparse_equivalent_single,
        "sparse2_han_carlson_full_curves_equal_grid": sparse_equivalent_grid,
        "baseline_pareto_front": baseline_front, "pareto_front_counts": pareto_counts,
        "distinct_grid_pareto_fronts": [list(x) for x in front_sets]
    }
    (RESULTS / "sensitivity_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"SINGLE_RECORDS={len(single_rows)} GRID_COMBINATIONS={len(combinations)} GRID_RECORDS={len(grid_rows)}")
    print("BASELINE_PARETO=" + ",".join(baseline_front))
    for name in names:
        s=stats[name]
        print(f"STATS {name} range={s['min_delay']}..{s['max_delay']} rank1={s['rank1_count']} "
              f"avg_rank={s['average_rank']} endpoint_switch={s['endpoint_switch_count']} path_switch={s['path_switch_count']} pareto={pareto_counts[name]}")


if __name__ == "__main__":
    main()
