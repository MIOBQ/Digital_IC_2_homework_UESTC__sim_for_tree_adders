# Tree Adder 数据证据对应表

| 主要研究结论 | 数据证据 | 图表 | 报告位置 |
|---|---|---|---|
| 七种DUT均完成10012组向量，合计70084次17位输出检查，错误数为0 | `docs/all_adders_regression.log`、`docs/all_adders_console.log`、`docs/all_adders_test_report.md` | 表4-2 | 摘要；4.3；第六章 |
| 常量传播后的七种结构基本门数量 | `analysis/results/constant_fold_gate_counts.csv` | 表4-3；图4-1 | 4.4；4.5；第六章 |
| 基准参数AND=1、OR=1、XOR=2下的最大理论延迟 | `analysis/results/constant_fold_delay.csv` | 表4-3；图4-2 | 摘要；4.4；4.5；第六章 |
| 完整关键路径及其AND/OR/XOR组成 | `analysis/results/constant_fold_critical_paths.csv` | 表4-3的延迟列引用该分析口径 | 4.4；4.5 |
| RCA为77门/延迟32，Kogge-Stone为179门/延迟11，Brent-Kung为110门/延迟16 | `analysis/results/constant_fold_gate_counts.csv`；`analysis/results/constant_fold_delay.csv` | 表4-3；图4-1；图4-2 | 摘要；4.5；第六章 |
| Sparse-2与Han-Carlson均为128门/延迟13 | 同上 | 表4-3；图4-1；图4-2；图4-3 | 摘要；4.5；4.6；第六章 |
| Sparse-2与Han-Carlson在全部参数组合下17位输出延迟曲线一致 | `analysis/results/sensitivity_single_parameter.csv`；`analysis/results/sensitivity_grid.csv`；`analysis/results/sensitivity_critical_paths.csv`；`analysis/results/sensitivity_summary.json` | 图4-3；图4-4 | 4.5；4.6.2；4.6.3 |
| 80组联合参数、560条结构时序记录中，Kogge-Stone始终排名第1，Sparse-2与Han-Carlson始终并列第2 | `analysis/results/sensitivity_grid.csv`；`analysis/results/sensitivity_rankings.csv`；`analysis/results/sensitivity_summary.json` | 图4-4 | 摘要；4.6.2；4.6.3；第六章 |
| 基准Pareto前沿包含RCA、Brent-Kung、Sparse-2、Han-Carlson和Kogge-Stone | `analysis/results/sensitivity_pareto.csv`；`analysis/results/sensitivity_summary.json` | 图4-3 | 4.6.1；4.10；第六章 |
| Sparse-4和Sparse-8在当前门数—延迟模型中受到Brent-Kung支配 | 同上 | 图4-3 | 4.6.1；4.10；5.1；第六章 |
| 七种结构的RTL Prefix/Black/Gray/Local Carry统计 | 实验1各结构测试报告与ModelSim elaboration日志；统一回归报告 | 表4-1 | 4.2；4.7 |
| 模型属于显式重建的基本门DAG而非自动综合网表，不代表真实PPA | `docs/theoretical_model_report.md`；`docs/sensitivity_analysis_report.md`；`docs/experiment3_visualization_report.md` | 图4-1至图4-4的口径说明 | 摘要；4.4；4.7至4.10；第六章 |

## 图像源文件

- 图4-1：`figures/fig3_1_gate_counts.png`
- 图4-2：`figures/fig3_2_delay_comparison.png`
- 图4-3：`figures/fig3_4_pareto.png`
- 图4-4：`figures/fig3_6_ranking_stability.png`

以上图像仅重新编号后插入Word正文，数据坐标和图中数值未修改。
