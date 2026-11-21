# Tree Adder 第四章精简重组修改说明

## 修改范围

本次以“Tree_Adder_实验融合修订稿.docx”为基础另存修订稿，未覆盖输入报告或其他原始报告。摘要、第五章和第六章沿用现有融合稿的已验证结论；本轮实质性重组对象为第四章及目录。

## 第四章新旧小节对应关系

| 原融合稿内容 | 新位置 | 处理方式 |
|---|---|---|
| 4.1逻辑深度与理论延迟、4.2统一案例 | 4.1.1、4.2.1、4.2.2 | 将结构深度、RTL连接和结构统计融入实验实施与结果分析，避免将Prefix级数误写为完整关键路径。 |
| 4.3 RTL实现与功能验证 | 4.1.1、4.1.2、4.2.1 | 方法与结果分离：前者说明RTL、库隔离和Testbench，后者集中展示验证结果。 |
| 4.4基本门DAG | 4.1.3 | 保留显式DAG、常量传播、功能检查和时序传播方法。 |
| 4.5门数与理论延迟 | 4.2.2 | 保留常量传播后的门数、延迟及结构解释。 |
| 4.6敏感性与Pareto | 4.2.3 | 保留单参数、80组联合参数、竞争排名和Pareto定义。 |
| 4.7节点/扇出/连线，4.8互连，4.9功耗，4.10选型 | 4.2.4 | 合并为工程边界与结构选择讨论，保留互连寄生、负载、动态功耗和物理实现限制。 |

第四章现仅有两个二级小节：4.1“实验设计与实施”、4.2“实验结果与性能权衡分析”；仅有七个规定的三级小节：4.1.1至4.1.3、4.2.1至4.2.4。

## 补充的实验方法

- 4.1.1说明Verilog-2001、ModelSim-Altera Starter Edition 10.3c、Python 3.13.2和matplotlib的分工，并根据七个RTL文件说明RCA、Kogge-Stone、Brent-Kung、Sparse-2/4/8、Han-Carlson的实际连接方式。
- 4.1.2根据`tb/tb_all_adders16.v`、`sim/run_all.do`、`sim/run_all.ps1`说明独立逻辑库、统一Testbench、17位参考结果、`!==`比较、DUT一致性检查和退出码判定；正文摘录的两行参考值/比较代码均来自实际Testbench。
- 4.1.3根据`analysis/gate_model.py`、`adder_models.py`、`validate_models.py`、`run_constant_fold.py`和`sensitivity_analysis.py`说明DAG、常量传播、门数、时序传播、10012组模型验证、126条单参数记录、80组联合参数和560条结构记录。

## 保留的理论与工程分析

第三章及其公式、图片、表格、图题和引用均未改动。第四章保留了原有的Sparse稀疏度推导含义、节点/扇出/连线讨论、互连寄生、动态功耗公式、工程约束和结构选择逻辑，只是迁移至4.2.1与4.2.4的论证链中。

## 插入和重编号图表

- 图4-1：七种加法器实验的技术路线（本次新增）。
- 表4-1：实验环境与七种加法器RTL实现概览。
- 表4-2：七种16位加法器的统一功能验证结果。
- 表4-3：七种结构的RTL Prefix/Carry组成统计。
- 表4-4：常量传播后七种加法器的基本门成本与理论最大延迟。
- 图4-2至图4-5：依次使用已有基本门数量图、理论延迟图、XOR敏感性图和Pareto图；源图像未修改。
- 表4-5：面向应用约束的结构选择建议。

## 数据核对

- 统一回归：每种10012组输入，七种共70084次DUT—参考结果检查，DUT错误和一致性错误均为0。
- 常量传播后门数/延迟：RCA为77/32，Kogge-Stone为179/11，Brent-Kung为110/16，Sparse-2为128/13，Sparse-4为113/17，Sparse-8为112/24，Han-Carlson为128/13。
- 联合参数：80组参数、560条结构记录；Kogge-Stone均排名第1，Sparse-2与Han-Carlson均并列第2。Sparse-2与Han-Carlson坐标均为(128,13)，Sparse-4和Sparse-8被Brent-Kung支配。

数据分别核对自`docs/all_adders_test_report.md`、`analysis/results/constant_fold_gate_counts.csv`、`constant_fold_delay.csv`、`sensitivity_grid.csv`、`sensitivity_rankings.csv`、`sensitivity_pareto.csv`和`sensitivity_summary.json`。

## 保护和验收

- 输入融合稿未覆盖；第一至第三章锁定区共225个正文XML元素逐项比对为0处差异。
- 锁定区包含222个段落、3个表格、96个公式对象和8幅图片；均保持不变。
- 原有RTL、Testbench、ModelSim脚本、Python模型、CSV/JSON和已有图像均未写入；本轮仅生成新的DOCX、说明文件及内部渲染检查文件。
- 目录已改为静态目录并显示当前33页排版的页码，以消除继承文档中的失效书签提示。
- 使用Microsoft Word导出PDF，渲染33页并逐页检查；未发现图片裁切、正文重叠、公式损坏或明显表格溢出。
