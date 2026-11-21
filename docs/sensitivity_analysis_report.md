# 七种16位加法器理论延迟参数敏感性分析

## 1. 目的与模型假设

本分析复用实验2.1的七个常量传播后 `GateDAG`，对每组门延迟重新调用完整DAG时序传播和全局关键路径搜索。没有建立按Prefix级数或基准路径加权的简化公式。

所有门延迟严格大于0，输入到达时间为0，忽略布线、负载、寄生参数和工艺差异。结果是理论归一化门延迟，不是实际工艺下的静态时序结果。总基本门数仅作为逻辑复杂度代理，不等于芯片面积。

## 2. 基准复现

| 结构 | 常量传播后门数 | 基准最大延迟 |
|---|---:|---:|
| RCA | 77 | 32 |
| Kogge-Stone | 179 | 11 |
| Brent-Kung | 110 | 16 |
| Sparse-2 | 128 | 13 |
| Sparse-4 | 113 | 17 |
| Sparse-8 | 112 | 24 |
| Han-Carlson | 128 | 13 |

门数与延迟均精确匹配实验2.1，基准检查通过后才继续扫描。

## 3. 单参数分析

共3类扫描，每类6个参数点、每点7个结构，共126条记录。每条记录包含最大延迟、最慢输出、完整关键路径、路径门组成、相对基准差值和百分比。

| 扫描参数 | 结构 | 扫描内延迟范围 | 出现的关键终点 |
|---|---|---:|---|
| XOR | RCA | 31–36 | SUM[15], SUM[16] |
| XOR | Kogge-Stone | 9–15 | SUM[9] |
| XOR | Brent-Kung | 14–20 | SUM[15] |
| XOR | Sparse-2 / Han-Carlson | 11–17 | SUM[11] |
| XOR | Sparse-4 | 15–21 | SUM[15] |
| XOR | Sparse-8 | 22–28 | SUM[15] |
| AND | RCA | 25–47 | SUM[15], SUM[16] |
| AND | Kogge-Stone | 9.5–15 | SUM[9], SUM[15] |
| AND | Brent-Kung | 13–22 | SUM[15] |
| AND | Sparse-2 / Han-Carlson | 11–17 | SUM[11] |
| AND | Sparse-4 | 14–23 | SUM[15] |
| AND | Sparse-8 | 19–34 | SUM[15] |
| OR | RCA | 25–47 | SUM[15], SUM[16] |
| OR | Kogge-Stone | 9.5–15 | SUM[9], SUM[15] |
| OR | Brent-Kung | 13–22 | SUM[15] |
| OR | Sparse-2 / Han-Carlson | 10.5–18 | SUM[11] |
| OR | Sparse-4 | 13.5–24 | SUM[15] |
| OR | Sparse-8 | 19–34 | SUM[15] |

## 4. 80组联合网格与排名稳定性

AND取4值、OR取4值、XOR取5值，共80组；每组计算7种结构，共560条记录。并列采用竞争排名：相同延迟保持相同名次，后续名次保留跳位。

| 结构 | 延迟范围 | 排名第1次数 | 第1比例 | 平均名次 | 相对基准最大绝对变化 |
|---|---:|---:|---:|---:|---:|
| RCA | 23.5–48 | 0 | 0% | 7 | 16（50%） |
| Kogge-Stone | 7.25–16.5 | 80 | 100% | 1 | 5.5（50%） |
| Brent-Kung | 11–24 | 0 | 0% | 4 | 8（50%） |
| Sparse-2 | 8.75–19.5 | 0 | 0% | 2 | 6.5（50%） |
| Sparse-4 | 11.75–25.5 | 0 | 0% | 5 | 8.5（50%） |
| Sparse-8 | 17–36 | 0 | 0% | 6 | 12（50%） |
| Han-Carlson | 8.75–19.5 | 0 | 0% | 2 | 6.5（50%） |

Sparse-2与Han-Carlson在全部单参数点和80组联合参数下，17个输出的完整延迟曲线逐项相同，因此始终并列第2。

指定结构对在本参数范围内均未发生严格排序反转：Kogge-Stone始终快于Han-Carlson和Brent-Kung；Brent-Kung始终快于Sparse-4；Sparse-2与Han-Carlson始终相等；Sparse-4始终快于Sparse-8。这是本次有限参数网格的观察结果，不外推到其他参数范围或真实工艺。

## 5. 关键路径切换

| 结构 | 关键终点切换组数 | 内部选中路径切换组数 | 网格中关键终点 | 选中路径种类 |
|---|---:|---:|---|---:|
| RCA | 44 | 44 | SUM[15], SUM[16] | 3 |
| Kogge-Stone | 33 | 33 | SUM[9], SUM[15], SUM[16] | 3 |
| Brent-Kung | 0 | 8 | SUM[15] | 2 |
| Sparse-2 | 0 | 8 | SUM[11] | 2 |
| Sparse-4 | 0 | 8 | SUM[15] | 2 |
| Sparse-8 | 0 | 8 | SUM[15] | 2 |
| Han-Carlson | 0 | 8 | SUM[11] | 2 |

RCA与Kogge-Stone同时出现关键终点和内部节点序列变化。其余五种结构的8次变化只改变关键路径内部来源/节点序列，不改变最慢输出端点；这些变化集中在AND为1.25或1.5且XOR为1的组合。CSV逐条保留了切换条件和完整节点序列。

存在等长关键路径时，文件保留由 `GateDAG.timing()` 返回的一条实际有效路径，并记录全部等长关键输出。网格中多关键输出出现次数：RCA 8组、Kogge-Stone 48组、Sparse-2与Han-Carlson各80组；其他结构为0。关键终点并列与路径内部等到达分支分别标记，没有混为同一指标。

本网格中结构间延迟排名顺序没有因这些关键路径切换而反转。

## 6. 门数—延迟Pareto分析

基准Pareto前沿为：RCA、Brent-Kung、Sparse-2、Han-Carlson、Kogge-Stone。

- RCA以77门保留最低门数端点。
- Kogge-Stone以最低延迟保留速度端点。
- Brent-Kung以及Sparse-2/Han-Carlson构成中间折中点。
- 基准下Brent-Kung支配Sparse-4和Sparse-8。

80组网格的Pareto前沿未改变。进入前沿次数：RCA、Kogge-Stone、Brent-Kung、Sparse-2、Han-Carlson均为80；Sparse-4与Sparse-8均为0。Brent-Kung在全部80组中均支配Sparse-4和Sparse-8。两个完全等价的Sparse-2与Han-Carlson彼此不构成严格支配，因此都保留在前沿。

## 7. 验证与输出

所有模型保持17位输出完整、DAG无环、门延迟为正。每个联合参数点重复运行同一时序计算，最大延迟、端点和路径序列完全一致。全部80组成功完成。

输出文件：

- `analysis/results/sensitivity_single_parameter.csv`：126条
- `analysis/results/sensitivity_grid.csv`：560条
- `analysis/results/sensitivity_rankings.csv`：560条
- `analysis/results/sensitivity_critical_paths.csv`：686条
- `analysis/results/sensitivity_pareto.csv`：567条（7条基准加560条网格）
- `analysis/results/sensitivity_summary.json`

本阶段未进行绘图、综合、真实静态时序、功率或物理设计分析。
