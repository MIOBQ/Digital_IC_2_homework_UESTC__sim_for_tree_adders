import csv
import json
from pathlib import Path

from adder_models import build_all
from validate_models import validate_models


ROOT = Path(__file__).resolve().parent
RESULTS = ROOT / "results"


def write_csv(path, fieldnames, rows):
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader(); writer.writerows(rows)


def main():
    config = json.loads((ROOT / "config.json").read_text(encoding="utf-8"))
    models = build_all()
    validation = validate_models(models, config["random_seed"], config["random_tests"])
    RESULTS.mkdir(exist_ok=True)
    count_rows=[];delay_rows=[];critical_rows=[];mapping_rows=[]
    for model in models:
        raw=model.gate_counts(False);opt=model.gate_counts(True)
        rows,maximum,endpoint,path=model.timing(config["gate_delays"])
        raw_area=sum(raw[op]*config["gate_areas"][op] for op in ("AND","OR","XOR"))
        opt_area=sum(opt[op]*config["gate_areas"][op] for op in ("AND","OR","XOR"))
        count_rows.append({"adder":model.name,
            "and_before":raw["AND"],"or_before":raw["OR"],"xor_before":raw["XOR"],"total_before":raw["TOTAL"],
            "and_optimized":opt["AND"],"or_optimized":opt["OR"],"xor_optimized":opt["XOR"],"total_optimized":opt["TOTAL"],
            "assumed_area_before":raw_area,"assumed_area_optimized":opt_area,
            **model.metrics})
        for row in rows: delay_rows.append({"adder":model.name,**row})
        critical_rows.append({"adder":model.name,"max_delay":maximum,"endpoint":endpoint,
            "source":path["source"],"and_gates":path["composition"]["AND"],
            "or_gates":path["composition"]["OR"],"xor_gates":path["composition"]["XOR"],
            "gate_count":len(path["nodes"]),"node_sequence":" -> ".join(path["nodes"])})
        for node,rtl in model.mapping: mapping_rows.append({"adder":model.name,"python_node":node,"rtl_reference":rtl})
    write_csv(RESULTS/"gate_counts.csv",list(count_rows[0]),count_rows)
    write_csv(RESULTS/"theoretical_delay.csv",list(delay_rows[0]),delay_rows)
    write_csv(RESULTS/"critical_paths.csv",list(critical_rows[0]),critical_rows)
    write_csv(RESULTS/"rtl_node_mapping.csv",list(mapping_rows[0]),mapping_rows)
    summary={"configuration":config,"random_sequence":"Python random.Random; not Verilog $random",
             "validation":validation,"gate_counts":count_rows,"critical_paths":critical_rows}
    (RESULTS/"summary.json").write_text(json.dumps(summary,indent=2),encoding="utf-8")
    for model in models:
        v=validation[model.name]
        print(f"{model.name}: vectors={v['executed_count']} errors={v['error_count']} max_delay="
              f"{next(x['max_delay'] for x in critical_rows if x['adder']==model.name)}")
    if any(validation[name]["error_count"] for name in validation):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
