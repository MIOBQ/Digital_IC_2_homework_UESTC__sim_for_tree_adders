# 实验 1 阶段 2.1：16 位 Radix-2 Kogge-Stone Tree 测试报告

## RTL 结构

- 语言：Verilog-2001
- 输入：`A[15:0]`、`B[15:0]`
- `Cin`：固定为 0
- 输出：`SUM[16:0]`
- 单比特预处理：`G0 = A & B`、`P0 = A ^ B`
- 前缀合并：`G_out = G_high | (P_high & G_low)`、`P_out = P_high & P_low`
- 四级 Radix-2 递归倍增距离：1、2、4、8
- DUT 未使用 `A+B`；普通二进制加法只用于 Testbench 参考值

## Prefix Cell 实例统计

统计由 ModelSim elaboration 后的实际设计层次产生，仿真脚本通过 `find instances -recursive` 枚举 `ks_prefix_cell` 实例，并按 stage 分类。

```text
KOGGE_STONE_STAGE_COUNTS=15,14,12,8
KOGGE_STONE_PREFIX_CELL_COUNT=49
KOGGE_STONE_STRUCTURE_PASS expected=49 actual=49
```

## 测试配置

- 与 RCA 相同的 12 组定向测试
- 与 RCA 相同的随机种子：`32'h13579bdf`
- 随机测试：10,000 组
- 参考结果：`{1'b0, A} + {1'b0, B}`
- 比较完整的 17 位输出

## 仿真环境

- ModelSim-Altera Starter Edition 10.3c
- 完整路径：`D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem`
- Verilog 编译选项：`-vlog01compat`
- 从工程目录外启动，确认脚本不依赖当前工作目录
- 未调用 Active-HDL

## 实际结果

```text
DIRECTED_TESTS_COMPLETE count=12 errors=0
RANDOM_TESTS_COMPLETE count=10000
KOGGE_STONE16_TEST_SUMMARY total=10012 errors=0
KOGGE_STONE16_TEST_PASS
MODELSIM_ERROR_COUNT=0
MODELSIM_EXIT_CODE=0
POWERSHELL_OBSERVED_EXIT_CODE=0
```

- 编译：0 errors，0 warnings
- 仿真：0 errors，0 warnings
- Prefix Cell：49，符合理论值
- 结论：通过

完整 ModelSim 控制台日志：`docs/kogge_stone_console.log`

ModelSim transcript：`docs/kogge_stone_simulation.log`
