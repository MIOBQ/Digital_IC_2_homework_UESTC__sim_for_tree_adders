# 实验 1 阶段 3.1：16 位 Sparse-2 Tree Adder 测试报告

## 实现定义

- Verilog-2001
- 16位无符号输入，`Cin=0`，17位输出
- 单比特预处理：`G=A&B`、`P=A^B`
- Sparse-2结构：2位分组 + 8组Kogge-Stone前缀网络 + 组内局部进位
- DUT未使用`A+B`；普通加法仅用于Testbench参考结果

## 实际结构统计

以下数据来自ModelSim elaboration后的真实实例和实例参数：

```text
SPARSE2_GROUP_PREFIX_COUNT=8
SPARSE2_INTERGROUP_STAGE_COUNTS=7,6,4
SPARSE2_PREFIX_CELL_COUNT=25
SPARSE2_INTERGROUP_DISTANCE_SETS=1,2,4
SPARSE2_LONGEST_PREFIX_CELL_CHAIN=4
SPARSE2_STRUCTURE_PASS expected_groups=8 expected_intergroup=7,6,4 expected_total=25
```

最长Prefix Cell链为4：首先经过1个二位分组预处理节点，再经过距离1、2、4的3个组间前缀节点。普通单比特G/P、组内奇数位进位逻辑和求和XOR不计入25个Prefix Cell。

## 测试配置

- 与RCA、Kogge-Stone和Brent-Kung相同的12组定向测试
- 随机种子：`32'h13579bdf`
- 随机测试：10,000组
- 参考值：`{1'b0,A}+{1'b0,B}`
- 使用`!==`比较完整17位输出

## 实际仿真结果

```text
DIRECTED_TESTS_COMPLETE count=12 errors=0
RANDOM_TESTS_COMPLETE count=10000
SPARSE2_16_TEST_SUMMARY total=10012 errors=0
SPARSE2_16_TEST_PASS
MODELSIM_RUN_STATUS=break
MODELSIM_RUN_STATUS_FULL=break simulation_stop {$finish}
MODELSIM_TEST_COUNT=10012
MODELSIM_ERROR_COUNT=0
MODELSIM_EXIT_CODE=0
POWERSHELL_OBSERVED_EXIT_CODE=0
```

- ModelSim-Altera Starter Edition 10.3c
- 完整工具路径：`D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem`
- 编译：0 errors，0 warnings
- 仿真：0 errors，0 warnings
- 从`C:\Windows\Temp`启动成功
- 未调用Active-HDL

完整控制台日志：`docs/sparse2_console.log`

ModelSim transcript：`docs/sparse2_simulation.log`
