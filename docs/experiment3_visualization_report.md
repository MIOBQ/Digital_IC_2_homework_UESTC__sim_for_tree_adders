# 实验3：七种16位加法器性能可视化与综合权衡分析

## 1. 研究方法与数据口径

实验1使用ModelSim验证七种RTL的逻辑功能；实验2根据已验证RTL拓扑显式重建Python基本门DAG，并完成常量传播与门延迟敏感性分析；实验3只读取实验2已经生成并审查的数据进行可视化，没有重新仿真、修改RTL或改变理论模型。

基准门数来自 `constant_fold_gate_counts.csv`，理论延迟来自 `constant_fold_critical_paths.csv`，结构单元来自 `gate_counts.csv` 中已核对的RTL结构统计，敏感性和排名来自实验2.2 CSV/JSON。绘图前自动验证了七组门数、七组基准延迟和126/560/567条敏感性记录。

所有延迟均为AND=1、OR=1、XOR=2或指定参数下的归一化理论延迟。基本门数量是逻辑复杂度代理，不是芯片面积。

## 2. 图3-1：理论基本门数量

常量传播后，RCA为77门，是七种结构中门数最少的；Kogge-Stone为179门，是门数最多的。Brent-Kung为110门；Sparse-4与Sparse-8分别为113门和112门；Sparse-2与Han-Carlson均为128门。

堆叠柱分别显示AND、OR和XOR，柱顶总数直接来自CSV。该图仅比较理论基本门数量，不能据此断言RCA具有最小真实芯片面积。

## 3. 图3-2：基准理论最大延迟

Kogge-Stone的归一化最大延迟为11，在当前理论模型中最小；Sparse-2和Han-Carlson均为13；Brent-Kung为16；Sparse-4为17；Sparse-8为24；RCA为32，是当前模型中最大值。

该结论忽略布线、负载、缓冲和工艺差异，因此不能解释为Kogge-Stone在真实芯片上必然最快。

## 4. 图3-3：结构单元数量

图中Prefix结构由Black Cell与Gray Cell堆叠构成，未把Prefix总数再次相加。Local Carry使用相邻独立柱显示：RCA为16，Sparse-2为8，Sparse-4为12，Sparse-8为14。

Kogge-Stone具有49个Prefix Cell；Brent-Kung为26；Sparse-2、Sparse-4和Sparse-8分别为25、17和15；Han-Carlson为32。Sparse-2与Han-Carlson共享两位分组和组间前缀骨架，但末级分别以局部Carry逻辑与显式Gray Cell表达。命名和实例统计口径不同，不能直接理解为实际面积差异。

## 5. 图3-4：门数—延迟Pareto权衡

严格支配关系由代码根据真实坐标重新计算，并与 `sensitivity_pareto.csv` 的基准记录交叉验证。基准Pareto前沿包括：RCA、Brent-Kung、Sparse-2、Han-Carlson和Kogge-Stone。

RCA代表低门数但高延迟端点；Kogge-Stone代表高门数但低延迟端点；Brent-Kung在当前模型中体现中间成本—延迟折中。Sparse-2和Han-Carlson真实坐标均为(128,13)，图中数据坐标完全重合，仅将文字标注错开。Sparse-4和Sparse-8均受到Brent-Kung支配：其门数更高且理论延迟也更高。

## 6. 图3-5：门延迟敏感性

XOR、AND、OR三张曲线图均直接使用 `sensitivity_single_parameter.csv` 的全部参数点。不同门延迟下，RCA的最大理论延迟增长最明显；Kogge-Stone在扫描范围内保持最低延迟。Sparse-2与Han-Carlson的完整曲线完全重合，图中以不同颜色和线型绘制，并在图注中明确说明。

这些是控制变量条件下的理论参数敏感性，不是实测延迟曲线。

## 7. 图3-6：排名稳定性

80组联合参数使用竞争排名并保留并列：Kogge-Stone在80组中均排名第1；Sparse-2与Han-Carlson始终并列第2；Brent-Kung为第4；Sparse-4为第5；Sparse-8为第6；RCA为第7。

该排序在当前参数网格内稳定，但不能外推到未分析的门延迟范围或真实工艺条件。

## 8. 综合研究结论

- Kogge-Stone：当前模型中理论延迟最小，但基本门数量最多。
- RCA：当前模型中基本门数量最少，但理论延迟最大。
- Brent-Kung：在当前门数—延迟模型中提供明显的中间折中，并支配Sparse-4和Sparse-8。
- Sparse-2与Han-Carlson：常量传播后均为128门、基准延迟13，单参数及联合参数下的完整延迟曲线相同。
- Sparse-4与Sparse-8：前缀节点较少，但较长局部进位链提高了完整输出延迟，当前门数—延迟坐标均被Brent-Kung支配。
- 参数敏感性：Kogge-Stone在本次80组网格中始终具有最小理论延迟。

## 9. 产物与验收

共生成8张300 dpi PNG和8张SVG。程序自动检查PNG尺寸、像素方差和SVG XML结构，并实际打开全部PNG检查排版。图表无明显空白、裁切或标签重叠，Pareto重合标注和敏感性重合曲线均正确。

同时生成：

- `analysis/results/visualization_summary.csv`
- `analysis/results/visualization_summary.json`

## 10. 局限性

本研究尚未开展逻辑综合、标准单元映射、静态时序分析、布线与寄生参数提取、功率分析或物理设计。因此图表只描述当前理论基本门DAG及其归一化延迟假设，不能用于声称真实速度、面积、功耗或完整PPA已经得到验证。
