import csv
import json
import math
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image, ImageStat


ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "analysis" / "results"
FIGURES = ROOT / "figures"
ORDER = ["RCA", "Kogge-Stone", "Brent-Kung", "Sparse-2",
         "Sparse-4", "Sparse-8", "Han-Carlson"]
SHORT = {"RCA": "RCA", "Kogge-Stone": "Kogge-\nStone", "Brent-Kung": "Brent-\nKung",
         "Sparse-2": "Sparse-2", "Sparse-4": "Sparse-4", "Sparse-8": "Sparse-8",
         "Han-Carlson": "Han-\nCarlson"}
COLORS = {
    "blue": "#3268a8", "orange": "#d9792b", "green": "#3b8c6e",
    "red": "#bc4b51", "purple": "#7868a6", "gold": "#c49a2c",
    "gray": "#77808a", "light": "#d9dee5", "dark": "#25313c"
}
SERIES = dict(zip(ORDER, [COLORS["gray"], COLORS["blue"], COLORS["green"],
                          COLORS["orange"], COLORS["purple"], COLORS["gold"], COLORS["red"]]))
EXPECTED_GATES = {"RCA":77,"Kogge-Stone":179,"Brent-Kung":110,"Sparse-2":128,
                  "Sparse-4":113,"Sparse-8":112,"Han-Carlson":128}
EXPECTED_DELAYS = {"RCA":32,"Kogge-Stone":11,"Brent-Kung":16,"Sparse-2":13,
                   "Sparse-4":17,"Sparse-8":24,"Han-Carlson":13}


def read_csv(name):
    with (RESULTS / name).open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def configure_style():
    mpl.rcParams.update({
        "font.family": "DejaVu Sans", "font.size": 10, "axes.titlesize": 14,
        "axes.labelsize": 11, "axes.titleweight": "bold", "axes.edgecolor": "#52606d",
        "axes.linewidth": 0.8, "axes.grid": True, "axes.axisbelow": True,
        "grid.color": "#d9dee5", "grid.linewidth": 0.6, "grid.alpha": 0.75,
        "legend.frameon": False, "figure.facecolor": "white", "axes.facecolor": "white",
        "savefig.facecolor": "white", "savefig.bbox": "tight", "savefig.pad_inches": 0.12,
        "svg.hashsalt": "tree-adder-experiment-3"
    })


def save_pair(fig, stem):
    FIGURES.mkdir(exist_ok=True)
    fig.savefig(FIGURES / f"{stem}.png", dpi=300, metadata={"Software": "matplotlib"})
    fig.savefig(FIGURES / f"{stem}.svg", metadata={"Date": None, "Creator": "matplotlib"})
    plt.close(fig)


def strict_pareto(gates, delays):
    front = []
    dominated_by = {}
    for name in ORDER:
        dominators = [other for other in ORDER if other != name and
                      gates[other] <= gates[name] and delays[other] <= delays[name] and
                      (gates[other] < gates[name] or delays[other] < delays[name])]
        dominated_by[name] = dominators
        if not dominators:
            front.append(name)
    return front, dominated_by


def load_and_validate():
    counts = {r["adder"]: r for r in read_csv("constant_fold_gate_counts.csv")}
    critical = {r["adder"]: r for r in read_csv("constant_fold_critical_paths.csv")}
    structure = {r["adder"]: r for r in read_csv("gate_counts.csv")}
    single = read_csv("sensitivity_single_parameter.csv")
    grid = read_csv("sensitivity_grid.csv")
    rankings = read_csv("sensitivity_rankings.csv")
    pareto = read_csv("sensitivity_pareto.csv")
    summary = json.loads((RESULTS / "sensitivity_summary.json").read_text(encoding="utf-8"))
    gates = {n: int(counts[n]["total_gates"]) for n in ORDER}
    delays = {n: float(critical[n]["max_delay"]) for n in ORDER}
    if gates != EXPECTED_GATES or delays != {k: float(v) for k,v in EXPECTED_DELAYS.items()}:
        raise SystemExit(f"BASELINE_DATA_MISMATCH gates={gates} delays={delays}")
    if (len(single), len(grid), len(pareto)) != (126, 560, 567):
        raise SystemExit(f"SENSITIVITY_RECORD_MISMATCH {(len(single),len(grid),len(pareto))}")
    if len(rankings) != 560 or summary["grid_combinations"] != 80:
        raise SystemExit("RANKING_RECORD_MISMATCH")
    return counts, critical, structure, single, grid, rankings, pareto, summary, gates, delays


def figure_gate_counts(counts):
    x=np.arange(7); ands=np.array([int(counts[n]["and_gates"]) for n in ORDER])
    ors=np.array([int(counts[n]["or_gates"]) for n in ORDER]); xors=np.array([int(counts[n]["xor_gates"]) for n in ORDER])
    fig,ax=plt.subplots(figsize=(10.5,6.2)); width=.66
    ax.bar(x,ands,width,label="AND",color=COLORS["blue"])
    ax.bar(x,ors,width,bottom=ands,label="OR",color=COLORS["orange"])
    ax.bar(x,xors,width,bottom=ands+ors,label="XOR",color=COLORS["green"])
    for i,total in enumerate(ands+ors+xors): ax.text(i,total+3,str(total),ha="center",va="bottom",fontweight="bold")
    ax.set_xticks(x,[SHORT[n] for n in ORDER]);ax.set_ylabel("Basic logic gate count")
    ax.set_title("Constant-Folded Basic Gate Counts");ax.legend(ncols=3,loc="upper left")
    ax.set_ylim(0,max(ands+ors+xors)*1.16);ax.spines[["top","right"]].set_visible(False)
    fig.text(.5,.01,"Gate count is a theoretical logic-complexity proxy, not chip area.",ha="center",color="#52606d")
    fig.tight_layout(rect=(0,.04,1,1));save_pair(fig,"fig3_1_gate_counts")


def figure_delays(delays):
    x=np.arange(7); values=np.array([delays[n] for n in ORDER]);colors=[COLORS["blue"] if n=="Kogge-Stone" else COLORS["gray"] for n in ORDER]
    fig,ax=plt.subplots(figsize=(10.5,6.2));bars=ax.bar(x,values,.66,color=colors)
    ax.bar_label(bars,labels=[f"{v:g}" for v in values],padding=4,fontweight="bold")
    ax.set_xticks(x,[SHORT[n] for n in ORDER]);ax.set_ylabel("Normalized Delay")
    ax.set_title("Maximum Theoretical Delay at AND=1, OR=1, XOR=2")
    ax.set_ylim(0,max(values)*1.18);ax.spines[["top","right"]].set_visible(False)
    ax.annotate("Minimum in this model",xy=(1,values[1]),xytext=(1.7,values[1]+8),
                arrowprops={"arrowstyle":"->","color":COLORS["blue"]},color=COLORS["blue"],ha="center")
    fig.text(.5,.01,"Normalized gate-delay model; wiring and load effects are excluded.",ha="center",color="#52606d")
    fig.tight_layout(rect=(0,.04,1,1));save_pair(fig,"fig3_2_delay_comparison")


def figure_structure(structure):
    x=np.arange(7); black=np.array([int(structure[n]["black_cells"]) for n in ORDER])
    gray=np.array([int(structure[n]["gray_cells"]) for n in ORDER]);local=np.array([int(structure[n]["local_carry_cells"]) for n in ORDER])
    width=.34;fig,ax=plt.subplots(figsize=(10.8,6.4))
    ax.bar(x-width/2,black,width,label="Black cells",color=COLORS["blue"])
    ax.bar(x-width/2,gray,width,bottom=black,label="Gray cells",color=COLORS["orange"])
    ax.bar(x+width/2,local,width,label="Local carry cells",color=COLORS["green"])
    for i,total in enumerate(black+gray):
        if total: ax.text(i-width/2,total+1,f"P={total}",ha="center",fontsize=9)
    for i,v in enumerate(local):
        if v: ax.text(i+width/2,v+1,str(v),ha="center",fontsize=9)
    ax.set_xticks(x,[SHORT[n] for n in ORDER]);ax.set_ylabel("RTL structural cell count")
    ax.set_title("Prefix Composition and Local-Carry Structures")
    ax.legend(ncols=3,loc="upper left");ax.set_ylim(0,max(black+gray)*1.2);ax.spines[["top","right"]].set_visible(False)
    fig.text(.5,.01,"Prefix total is the stacked Black+Gray bar; it is not added again. Naming alone does not imply area.",ha="center",color="#52606d")
    fig.tight_layout(rect=(0,.04,1,1));save_pair(fig,"fig3_3_structure_counts")


def figure_pareto(gates, delays, front):
    fig,ax=plt.subplots(figsize=(9.4,6.6));dominated=[n for n in ORDER if n not in front]
    ax.scatter([gates[n] for n in dominated],[delays[n] for n in dominated],s=90,c=COLORS["light"],edgecolors=COLORS["gray"],label="Dominated")
    ax.scatter([gates[n] for n in front],[delays[n] for n in front],s=110,c=COLORS["blue"],edgecolors="white",linewidths=.8,label="Pareto optimal",zorder=3)
    coords=sorted(set((gates[n],delays[n]) for n in front));ax.plot([x for x,y in coords],[y for x,y in coords],color=COLORS["blue"],linestyle="--",linewidth=1.2,zorder=1)
    offsets={"RCA":(5,7),"Kogge-Stone":(-54,-14),"Brent-Kung":(-55,8),"Sparse-2":(-65,-17),"Han-Carlson":(8,8),"Sparse-4":(8,8),"Sparse-8":(8,8)}
    for n in ORDER: ax.annotate(n,(gates[n],delays[n]),xytext=offsets[n],textcoords="offset points",fontsize=9,arrowprops={"arrowstyle":"-","color":"#9aa3ad","lw":.6})
    ax.set_xlabel("Total basic gate count (constant-folded)");ax.set_ylabel("Normalized maximum delay")
    ax.set_title("Gate Count–Delay Pareto Trade-off");ax.legend(loc="upper right")
    ax.spines[["top","right"]].set_visible(False)
    fig.text(.5,.01,"Lower-left is preferable under this theoretical model; gate count is not physical area.",ha="center",color="#52606d")
    fig.tight_layout(rect=(0,.04,1,1));save_pair(fig,"fig3_4_pareto")


def figure_sensitivity(single, parameter, stem, label):
    selected=[r for r in single if r["varied_parameter"]==parameter]
    by=defaultdict(list)
    for r in selected: by[r["adder"]].append((float(r["varied_value"]),float(r["max_delay"])))
    fig,ax=plt.subplots(figsize=(10.2,6.6));styles={"Han-Carlson":"--","Sparse-2":"-"}
    for name in ORDER:
        points=sorted(by[name]);ax.plot([x for x,y in points],[y for x,y in points],marker="o",markersize=4,
            linewidth=2,linestyle=styles.get(name,"-"),color=SERIES[name],label=name)
    ax.set_xlabel(f"{label} gate delay");ax.set_ylabel("Normalized maximum delay")
    ax.set_title(f"Sensitivity to {label} Gate Delay");ax.legend(ncols=2,loc="upper left")
    ax.spines[["top","right"]].set_visible(False)
    fig.text(.5,.01,"Sparse-2 and Han-Carlson overlap exactly; delays are normalized, not measured time.",ha="center",color="#52606d")
    fig.tight_layout(rect=(0,.04,1,1));save_pair(fig,stem)


def figure_rankings(rankings):
    values={n:np.mean([float(r["rank"]) for r in rankings if r["adder"]==n]) for n in ORDER}
    sorted_names=sorted(ORDER,key=lambda n:values[n]);y=np.arange(7)
    fig,ax=plt.subplots(figsize=(9.5,6.2));bars=ax.barh(y,[values[n] for n in sorted_names],color=[SERIES[n] for n in sorted_names],height=.62)
    ax.bar_label(bars,labels=[f"{values[n]:g}" for n in sorted_names],padding=5,fontweight="bold")
    ax.set_yticks(y,[SHORT[n].replace("\n"," ") for n in sorted_names]);ax.invert_yaxis();ax.set_xlim(0,7.6)
    ax.set_xlabel("Average competition rank (lower is better)");ax.set_title("Ranking Stability Across 80 Delay Combinations")
    ax.spines[["top","right"]].set_visible(False)
    fig.text(.5,.01,"Kogge-Stone ranks 1st in all 80 cases; Sparse-2 and Han-Carlson tie for 2nd.",ha="center",color="#52606d")
    fig.tight_layout(rect=(0,.04,1,1));save_pair(fig,"fig3_6_ranking_stability")
    return values


def verify_images(stems):
    checks=[]
    for stem in stems:
        png=FIGURES/f"{stem}.png";svg=FIGURES/f"{stem}.svg"
        with Image.open(png) as image:
            stat=ImageStat.Stat(image.convert("L")); width,height=image.size
            if width<1500 or height<900 or stat.var[0]<5: raise SystemExit(f"PNG_QA_FAIL {png}")
        root=ET.parse(svg).getroot()
        if root.tag.split("}")[-1]!="svg" or svg.stat().st_size<5000: raise SystemExit(f"SVG_QA_FAIL {svg}")
        checks.append({"figure":stem,"png_width":width,"png_height":height,
                       "png_variance":stat.var[0],"png_bytes":png.stat().st_size,"svg_bytes":svg.stat().st_size})
    return checks


def write_summaries(counts, structure, gates, delays, rankings, front, dominated_by, qa):
    avg={n:np.mean([float(r["rank"]) for r in rankings if r["adder"]==n]) for n in ORDER}
    rank1={n:sum(float(r["rank"])==1 for r in rankings if r["adder"]==n) for n in ORDER}
    rows=[]
    for n in ORDER:
        rows.append({"adder":n,"and_gates":counts[n]["and_gates"],"or_gates":counts[n]["or_gates"],
          "xor_gates":counts[n]["xor_gates"],"total_gates":gates[n],"baseline_max_delay":delays[n],
          "black_cells":structure[n]["black_cells"],"gray_cells":structure[n]["gray_cells"],
          "prefix_cells":structure[n]["prefix_cells"],"local_carry_cells":structure[n]["local_carry_cells"],
          "average_rank":avg[n],"rank1_count":rank1[n],"pareto_optimal":n in front,
          "dominated_by":";".join(dominated_by[n])})
    with (RESULTS/"visualization_summary.csv").open("w",newline="",encoding="utf-8") as handle:
        w=csv.DictWriter(handle,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
    payload={"source_files":["constant_fold_gate_counts.csv","constant_fold_critical_paths.csv","gate_counts.csv",
              "sensitivity_single_parameter.csv","sensitivity_grid.csv","sensitivity_rankings.csv","sensitivity_pareto.csv","sensitivity_summary.json"],
             "validation":{"baseline_match":True,"single_records":126,"grid_records":560,"pareto_records":567},
             "baseline_pareto_front":front,"figure_qa":qa,"structures":rows}
    (RESULTS/"visualization_summary.json").write_text(json.dumps(payload,indent=2),encoding="utf-8")


def main():
    configure_style()
    counts,critical,structure,single,grid,rankings,pareto,sens_summary,gates,delays=load_and_validate()
    front,dominated_by=strict_pareto(gates,delays)
    expected={"RCA","Brent-Kung","Sparse-2","Han-Carlson","Kogge-Stone"}
    if set(front)!=expected: raise SystemExit(f"PARETO_MISMATCH {front}")
    baseline_csv_front={r["adder"] for r in pareto if r["scenario"]=="BASELINE" and r["on_pareto_front"]=="True"}
    if baseline_csv_front!=expected: raise SystemExit("PARETO_SOURCE_CROSSCHECK_FAIL")
    figure_gate_counts(counts);figure_delays(delays);figure_structure(structure);figure_pareto(gates,delays,front)
    figure_sensitivity(single,"XOR","fig3_5a_xor_sensitivity","XOR")
    figure_sensitivity(single,"AND","fig3_5b_and_sensitivity","AND")
    figure_sensitivity(single,"OR","fig3_5c_or_sensitivity","OR")
    rank_values=figure_rankings(rankings)
    if rank_values!={"RCA":7.0,"Kogge-Stone":1.0,"Brent-Kung":4.0,"Sparse-2":2.0,
                    "Sparse-4":5.0,"Sparse-8":6.0,"Han-Carlson":2.0}: raise SystemExit("RANKING_MISMATCH")
    stems=["fig3_1_gate_counts","fig3_2_delay_comparison","fig3_3_structure_counts","fig3_4_pareto",
           "fig3_5a_xor_sensitivity","fig3_5b_and_sensitivity","fig3_5c_or_sensitivity","fig3_6_ranking_stability"]
    qa=verify_images(stems);write_summaries(counts,structure,gates,delays,rankings,front,dominated_by,qa)
    print("VISUALIZATION_DATA_VALIDATION_PASS")
    print(f"FIGURES_CREATED={len(stems)*2} PNG={len(stems)} SVG={len(stems)}")
    print("PARETO_FRONT="+",".join(front))
    for check in qa: print(f"QA {check['figure']} {check['png_width']}x{check['png_height']} var={check['png_variance']:.2f}")


if __name__=="__main__": main()
