# 基线模型与常量传播模型对比

本增强保留原有三份基线CSV不变，新增独立常量传播结果。使用规则为 `AND(X,0)=0`、`AND(X,1)=X`、`OR(X,0)=X`、`OR(X,1)=1`、`XOR(X,0)=X`；传播别名后共享相同门节点，最后从17个输出反向删除不可达逻辑。不进行其他布尔代数化简。

| 加法器 | 基线优化后门数 | 常量传播后门数 | 减少 | 基线最大延迟 | 折叠后最大延迟 | 关键终点 |
|---|---:|---:|---:|---:|---:|---|
| RCA | 80 | 77 | 3 | 34 | 32 | SUM[15] |
| Kogge-Stone | 180 | 179 | 1 | 11 | 11 | SUM[9] |
| Brent-Kung | 111 | 110 | 1 | 16 | 16 | SUM[15] |
| Sparse-2 | 131 | 128 | 3 | 13 | 13 | SUM[11] |
| Sparse-4 | 118 | 113 | 5 | 17 | 17 | SUM[15] |
| Sparse-8 | 117 | 112 | 5 | 24 | 24 | SUM[15] |
| Han-Carlson | 129 | 128 | 1 | 13 | 13 | SUM[11] |

常量传播后的基本门数：

| 加法器 | AND | OR | XOR | 总计 |
|---|---:|---:|---:|---:|
| RCA | 31 | 15 | 31 | 77 |
| Kogge-Stone | 99 | 49 | 31 | 179 |
| Brent-Kung | 53 | 26 | 31 | 110 |
| Sparse-2 | 65 | 32 | 31 | 128 |
| Sparse-4 | 55 | 27 | 31 | 113 |
| Sparse-8 | 54 | 27 | 31 | 112 |
| Han-Carlson | 65 | 32 | 31 | 128 |

专项检查：

- 七种结构的 `SUM[0]` 均由 `P0[0] XOR CONST0` 折叠为 `P0[0]`，到达时间为2，不再含最终求和XOR门。
- RCA第0级的 `P0[0] AND CONST0` 折叠为0，随后 `G0[0] OR 0` 折叠为 `G0[0]`，因此 `C1` 的别名为 `G0[0]`。新的RCA代表性关键路径从 `P0[1]` 开始，不再经过虚假的 `P0[0]&CONST0` 路径，最大延迟由34降为32。
- Sparse-2和Han-Carlson传播后均为65 AND、32 OR、31 XOR，共128门；最大延迟均为13，关键终点均为SUM[11]。在本模型规则下两者成本及延迟一致。
- Sparse-4/Sparse-8除SUM0及首个常量进位化简外，传播后的节点别名使已有分组生成逻辑与局部进位逻辑共享，避免重复门计数。

功能验证使用原12组定向输入及10000组新的确定性Python随机输入。程序不再因记录到若干错误而提前停止；每种模型的实际执行计数均为10012，错误数均为0。

修正映射输出为 `analysis/results/rtl_node_mapping_corrected.csv`。其中 `rtl_instance_path` 表示真实的RTL相对实例路径，`rtl_generate_scope` 表示没有模块实例的generate赋值范围，`rtl_logic_label`/`descriptive_logic_label` 明确表示逻辑描述而非实例路径。

详细数据位于：

- `analysis/results/constant_fold_gate_counts.csv`
- `analysis/results/constant_fold_delay.csv`
- `analysis/results/constant_fold_critical_paths.csv`
- `analysis/results/constant_fold_summary.json`

归一化延迟仍使用AND=1、OR=1、XOR=2，不代表综合后真实时序。
