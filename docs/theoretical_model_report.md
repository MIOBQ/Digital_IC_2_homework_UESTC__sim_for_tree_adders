# 七种16位加法器统一理论门级模型报告

## 1. 建模范围与方法

本阶段使用Python显式重建当前工程中七份RTL已经验证的拓扑，不是自动Verilog门级提取。关键Python节点与RTL实例/信号的对应表保存在 `analysis/results/rtl_node_mapping.csv`。

统一假设：A、B到达时间为0；AND=1、OR=1、XOR=2；忽略布线、扇出负载、寄生参数、毛刺和工艺差异。配置位于 `analysis/config.json`。报告中的归一化面积只是可配置假设（AND=1、OR=1、XOR=1.5），不是实际面积。

每个模型均显式包含：16组G/P预处理、RTL对应的Prefix/Carry内部AND与OR、16个求和XOR以及SUM[16]进位输出。共享信号只建立一次，扇出不产生新门。

“优化前”统计按RTL布尔赋值建立全部门。“优化后”只移除不能反向到达任何SUM输出的逻辑，不进行常量传播、代数化简或综合优化。因此Sparse-2中的 `P0[0] & CONST0` 仍保留，只要其输出路径可到达SUM。

## 2. RTL拓扑对应

| 模型 | 按当前RTL重建的结构 | Prefix构成 | Local Carry |
|---|---|---:|---:|
| RCA | 16级逐位进位 | 0 | 16 |
| Kogge-Stone | 距离1/2/4/8的15/14/12/8节点 | 49 Black | 0 |
| Brent-Kung | Up-Sweep 8/4/2/1，Down-Sweep 1/3/7 | 11 Black + 15 Gray = 26 | 0 |
| Sparse-2 | 8个2位分组 + 7/6/4组间KS | 25 Black | 8 |
| Sparse-4 | 每组3节点，共12；组间3/2 | 17 Black | 12 |
| Sparse-8 | 每组7节点，共14；组间1 | 15 Black | 14 |
| Han-Carlson | 8/7/6/4/7五级结构 | 17 Black + 15 Gray = 32 | 0 |

这些Prefix Cell数量与实验1的结构统计完全一致。

## 3. 理论门数量

| 加法器 | AND前 | OR前 | XOR前 | 总门前 | AND优化后 | OR优化后 | XOR优化后 | 总门优化后 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| RCA | 32 | 16 | 32 | 80 | 32 | 16 | 32 | 80 |
| Kogge-Stone | 114 | 49 | 32 | 195 | 99 | 49 | 32 | 180 |
| Brent-Kung | 53 | 26 | 32 | 111 | 53 | 26 | 32 | 111 |
| Sparse-2 | 74 | 33 | 32 | 139 | 66 | 33 | 32 | 131 |
| Sparse-4 | 62 | 29 | 32 | 123 | 57 | 29 | 32 | 118 |
| Sparse-8 | 60 | 29 | 32 | 121 | 56 | 29 | 32 | 117 |
| Han-Carlson | 65 | 32 | 32 | 129 | 65 | 32 | 32 | 129 |

无效逻辑主要是Black Cell中没有任何最终输出使用的P输出。完整数据（包括假设面积）见 `analysis/results/gate_counts.csv`。

## 4. 理论延迟与关键路径

到达时间严格使用 `max(input arrivals) + gate delay` 在门级DAG上传播，而不是用Prefix级数估计。

| 加法器 | 最大延迟 | 关键终点 | 路径起点 | AND | OR | XOR | 路径基本门数 |
|---|---:|---|---|---:|---:|---:|---:|
| RCA | 34 | SUM[15] | A[0] | 15 | 15 | 2 | 32 |
| Kogge-Stone | 11 | SUM[9] | A[2] | 3 | 4 | 2 | 9 |
| Brent-Kung | 16 | SUM[15] | A[1] | 6 | 6 | 2 | 14 |
| Sparse-2 | 13 | SUM[11] | A[3] | 4 | 5 | 2 | 11 |
| Sparse-4 | 17 | SUM[15] | A[5] | 6 | 7 | 2 | 15 |
| Sparse-8 | 24 | SUM[15] | A[1] | 10 | 10 | 2 | 22 |
| Han-Carlson | 13 | SUM[11] | A[3] | 4 | 5 | 2 | 11 |

若多个输入或输出具有相同最大到达时间，程序使用固定遍历顺序报告其中一条代表性关键路径。每个SUM[0:16]的到达时间见 `analysis/results/theoretical_delay.csv`；完整门节点序列见 `analysis/results/critical_paths.csv`。

## 5. Sparse-2与Han-Carlson

两者的8个两位分组和17个组间KS节点在功能依赖上相同。C[3]、C[5]……C[15]的7段末级逻辑也都是同一布尔式 `G | (P & Cboundary)`，所以实例名称“local carry”或“gray cell”本身不造成基本门成本差异，其关键路径和最大延迟均为13。

实际差异来自当前RTL：

- Sparse-2的全部25个Prefix实例均输出G和P；部分P输出不影响任何SUM，反向剪枝后移除8个AND门。
- Han-Carlson根据下游需求使用17个Black和15个Gray，所有已实例化门均输出可达。
- Sparse-2还用完整Carry公式计算C[1]，包含 `P0[0] & C[0]` 和OR；Han-Carlson因Cin=0直接令C[1]=G0[0]。
- 在本报告限定的“仅删除输出不可达逻辑、不做常量传播”规则下，Sparse-2优化后为131门，Han-Carlson为129门。若进一步进行常量传播，Sparse-2的C[1]可再化简，但这不属于当前剪枝口径。

不能据此声称真实综合面积或时序必然不同。

## 6. 自动正确性检查

每种模型均通过以下结构检查：17个输出完整；所有输出可追溯至输入或常量；无组合环；门类型和二输入数量正确；无相同操作及相同输入的重复逻辑节点；共享节点扇出不重复计门；关键路径可回溯至完整节点序列。

功能验证对每种模型执行12组与实验1相同的定向输入和10000组随机输入，共10012组。七种模型错误数均为0。随机输入使用Python `random.Random(324508639)`，不是Verilog `$random`，因此明确属于新的随机序列，不声称与实验1随机向量相同。

## 7. 输出文件

- `analysis/results/gate_counts.csv`
- `analysis/results/theoretical_delay.csv`
- `analysis/results/critical_paths.csv`
- `analysis/results/rtl_node_mapping.csv`
- `analysis/results/summary.json`

## 8. 局限性

本模型是基于当前RTL显式重建的零布线理论DAG。它不包含标准单元映射、综合优化、门输入斜率、负载、扇出缓冲、布线延迟、PVT、电气毛刺或物理布局，因此归一化延迟与面积只能用于当前统一假设下的结构比较，不能作为静态时序、真实面积或功耗结论。
