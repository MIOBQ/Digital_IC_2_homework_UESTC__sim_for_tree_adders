import csv
import json
import re
from pathlib import Path

from adder_models import build_all
from validate_models import validate_models


ROOT = Path(__file__).resolve().parent
RESULTS = ROOT / "results"


def write_csv(path, fieldnames, rows):
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader(); writer.writerows(rows)


def corrected_reference(adder, python_node, old_reference):
    """Return (kind, reference); never present a descriptive label as a path."""
    m = re.fullmatch(r"ks\.s([1-4])\.n(\d+)", python_node)
    if m:
        return "rtl_instance_path", f"kogge_stone16.stage{m.group(1)}[{m.group(2)}].prefix.u_prefix"
    if adder == "Brent-Kung":
        return "rtl_instance_path", "brent_kung16." + old_reference
    if adder == "Han-Carlson":
        return "rtl_instance_path", "han_carlson16." + old_reference
    m = re.fullmatch(r"rca\.stage(\d+)", python_node)
    if m:
        return "rtl_generate_scope", f"rca16.gen_rca_stage[{m.group(1)}] carry assignment"
    m = re.fullmatch(r"sparse2\.group(\d+)\.l1\.n0", python_node)
    if m:
        return "rtl_instance_path", f"sparse2_16.group_preprocess[{m.group(1)}].u_group_prefix"
    m = re.fullmatch(r"sparse2\.ks(\d+)\.n(\d+)", python_node)
    if m:
        return "rtl_instance_path", f"sparse2_16.intergroup_stage{m.group(1)}[{m.group(2)}].prefix.u_prefix"
    m = re.fullmatch(r"sparse2\.local\.g(\d+)\.c1", python_node)
    if m:
        return "rtl_logic_label", f"sparse2_16.local_carry[{m.group(1)}] C[2*k+1] assignment (no module instance)"
    m = re.fullmatch(r"sparse4\.group(\d+)\.l([12])\.n(\d+)", python_node)
    if m:
        inst = {("1","0"):"u_low_pair", ("1","1"):"u_high_pair", ("2","0"):"u_group"}[(m.group(2),m.group(3))]
        return "rtl_instance_path", f"sparse4_16.group_tree[{m.group(1)}].{inst}"
    m = re.fullmatch(r"sparse4\.ks(\d+)\.n(\d+)", python_node)
    if m:
        return "rtl_instance_path", f"sparse4_16.intergroup_stage{m.group(1)}[{m.group(2)}].prefix.u_prefix"
    m = re.fullmatch(r"sparse4\.local\.g(\d+)\.c(\d+)", python_node)
    if m:
        return "rtl_instance_path", f"sparse4_16.local_ripple[{m.group(1)}].u_carry{m.group(2)}"
    m = re.fullmatch(r"sparse8\.group(\d+)\.l([123])\.n(\d+)", python_node)
    if m:
        group, level, node = m.groups()
        if level == "1": ref=f"sparse8_16.group_tree[{group}].level1[{node}].u_prefix"
        elif level == "2": ref=f"sparse8_16.group_level2[{group}].node[{node}].u_prefix"
        else: ref=f"sparse8_16.group_level3[{group}].u_prefix"
        return "rtl_instance_path", ref
    if python_node == "sparse8.ks1.n1":
        return "rtl_instance_path", "sparse8_16.intergroup_stage1.u_prefix"
    m = re.fullmatch(r"sparse8\.local\.g(\d+)\.c(\d+)", python_node)
    if m:
        return "rtl_instance_path", f"sparse8_16.local_ripple[{m.group(1)}].step[{int(m.group(2))-1}].u_carry"
    return "descriptive_logic_label", old_reference


def main():
    config=json.loads((ROOT/"config.json").read_text(encoding="utf-8"))
    baselines=build_all(); folded=[]; aliases_by_name={}
    for baseline in baselines:
        model, aliases=baseline.constant_fold(); model.name=baseline.name
        folded.append(model); aliases_by_name[baseline.name]=aliases
    validation=validate_models(folded,config["random_seed"],config["random_tests"])
    count_rows=[];delay_rows=[];critical_rows=[];mapping_rows=[]
    for baseline,model in zip(baselines,folded):
        counts=model.gate_counts(True)
        rows,maximum,endpoint,path=model.timing(config["gate_delays"])
        count_rows.append({"adder":baseline.name,"and_gates":counts["AND"],"or_gates":counts["OR"],
                           "xor_gates":counts["XOR"],"total_gates":counts["TOTAL"],
                           "prefix_cells_rtl":baseline.metrics["prefix_cells"],
                           "local_carry_cells_rtl":baseline.metrics["local_carry_cells"]})
        for row in rows: delay_rows.append({"adder":baseline.name,**row})
        critical_rows.append({"adder":baseline.name,"max_delay":maximum,"endpoint":endpoint,
            "source":path["source"],"and_gates":path["composition"]["AND"],
            "or_gates":path["composition"]["OR"],"xor_gates":path["composition"]["XOR"],
            "gate_count":len(path["nodes"]),"node_sequence":" -> ".join(path["nodes"])})
        for node,old_ref in baseline.mapping:
            kind,ref=corrected_reference(baseline.name,node,old_ref)
            mapping_rows.append({"adder":baseline.name,"python_logic_node":node,
                                 "reference_kind":kind,"rtl_reference":ref})
    write_csv(RESULTS/"constant_fold_gate_counts.csv",list(count_rows[0]),count_rows)
    write_csv(RESULTS/"constant_fold_delay.csv",list(delay_rows[0]),delay_rows)
    write_csv(RESULTS/"constant_fold_critical_paths.csv",list(critical_rows[0]),critical_rows)
    write_csv(RESULTS/"rtl_node_mapping_corrected.csv",list(mapping_rows[0]),mapping_rows)
    checks={
      "RCA_C1_alias":aliases_by_name["RCA"]["rca.stage0.C"],
      "RCA_SUM0_alias":folded[0].outputs["SUM[0]"],
      "Sparse2_HanCarlson_counts_equal":count_rows[3]["total_gates"]==count_rows[6]["total_gates"],
      "Sparse2_HanCarlson_delay_equal":critical_rows[3]["max_delay"]==critical_rows[6]["max_delay"]}
    summary={"checks":checks,"validation":validation,"gate_counts":count_rows,"critical_paths":critical_rows}
    (RESULTS/"constant_fold_summary.json").write_text(json.dumps(summary,indent=2),encoding="utf-8")
    for row in count_rows:
        v=validation[row["adder"]]; cp=next(x for x in critical_rows if x["adder"]==row["adder"])
        print(f"{row['adder']}: executed={v['executed_count']} errors={v['error_count']} "
              f"gates={row['total_gates']} max_delay={cp['max_delay']}")
    print("CHECKS",json.dumps(checks,sort_keys=True))
    if any(v["executed_count"] != 10012 or v["error_count"] for v in validation.values()): raise SystemExit(1)
    if checks != {"RCA_C1_alias":"G0[0]","RCA_SUM0_alias":"P0[0]",
                  "Sparse2_HanCarlson_counts_equal":True,"Sparse2_HanCarlson_delay_equal":True}: raise SystemExit(2)


if __name__=="__main__": main()
