# 实验 1 阶段 2.2：16 位 Radix-2 Brent-Kung Tree 测试报告

## RTL 结构

- Verilog-2001
- 输入：`A[15:0]`、`B[15:0]`
- `Cin = 0`
- 输出：`SUM[16:0]`
- 单比特预处理：`G0 = A & B`、`P0 = A ^ B`
- 前缀公式：`G_out = G_high | (P_high & G_low)`
- Black Cell传播公式：`P_out = P_high & P_low`
- DUT未使用`A+B`；普通加法仅用于Testbench参考结果

## Brent-Kung拓扑

ModelSim elaboration后实际层次统计结果：

```text
BRENT_KUNG_STAGE_COUNTS=8,4,2,1,1,3,7
BRENT_KUNG_UP_SWEEP_COUNT=15
BRENT_KUNG_DOWN_SWEEP_COUNT=11
BRENT_KUNG_BLACK_CELL_COUNT=11
BRENT_KUNG_GRAY_CELL_COUNT=15
BRENT_KUNG_PREFIX_CELL_COUNT=26
BRENT_KUNG_STRUCTURE_PASS expected_up=15 expected_down=11 expected_total=26
```

Up-Sweep使用4级完成归约；Down-Sweep使用3级补齐中间前缀，最大前缀逻辑深度为7级。只有P输出继续参与后续合并的节点使用Black Cell，其余节点使用Gray Cell。

## 测试配置

- 与RCA相同的12组定向测试
- 随机种子：`32'h13579bdf`
- 随机测试：10,000组
- 参考结果：`{1'b0, A} + {1'b0, B}`
- 比较完整17位输出，包含最高位进位

## 仿真环境

- ModelSim-Altera Starter Edition 10.3c
- 完整路径：`D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem`
- 编译模式：`vlog -vlog01compat`
- 从`C:\Windows\Temp`启动，确认不依赖当前工作目录
- 未调用Active-HDL

## 实际结果

```text
DIRECTED_TESTS_COMPLETE count=12 errors=0
RANDOM_TESTS_COMPLETE count=10000
BRENT_KUNG16_TEST_SUMMARY total=10012 errors=0
BRENT_KUNG16_TEST_PASS
MODELSIM_RUN_STATUS=break
MODELSIM_RUN_STATUS_FULL=break simulation_stop {$finish}
MODELSIM_ERROR_COUNT=0
MODELSIM_EXIT_CODE=0
POWERSHELL_OBSERVED_EXIT_CODE=0
```

- 编译：0 errors，0 warnings
- 仿真：0 errors，0 warnings
- 结论：通过

完整控制台日志：`docs/brent_kung_console.log`

ModelSim transcript：`docs/brent_kung_simulation.log`
