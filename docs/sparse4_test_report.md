# 实验 1 阶段 3.2：16 位 Sparse-4 Tree Adder 测试报告

## 实现定义

- Verilog-2001，16位输入，`Cin=0`，17位输出
- 单比特G/P预处理
- 指定结构：平衡4位分组 + 4组Kogge-Stone + 组内局部Ripple-Carry
- 组边界进位`C[4]、C[8]、C[12]、C[16]`来自完整组间前缀
- DUT未使用`A+B`；普通加法仅用于Testbench参考结果

## ModelSim实际结构统计

```text
SPARSE4_GROUP_LEVEL_COUNTS=8,4
SPARSE4_GROUP_PREFIX_COUNT=12
SPARSE4_INTERGROUP_STAGE_COUNTS=3,2
SPARSE4_INTERGROUP_PREFIX_COUNT=5
SPARSE4_PREFIX_CELL_COUNT=17
SPARSE4_INTERGROUP_DISTANCE_SETS=1,2
SPARSE4_LONGEST_PREFIX_CELL_CHAIN=4
SPARSE4_LOCAL_CARRY_CELL_COUNT=12
SPARSE4_LONGEST_LOCAL_RIPPLE_CHAIN=3
SPARSE4_STRUCTURE_PASS expected_group=12 expected_intergroup=5 expected_total=17
```

实际连接关系：

```text
分组第1级：1:0,3:2,5:4,7:6,9:8,11:10,13:12,15:14
分组第2级：3:1,7:5,11:9,15:13
组间Stage 1：1:0,2:1,3:2
组间Stage 2：2:0,3:1
```

最长Prefix Cell链为4：分组平衡树2级加组间Kogge-Stone 2级。最长局部Ripple-Carry链为每组3级。Prefix Cell数量不包含12个局部carry实例、单比特G/P和最终XOR。

## 实际测试结果

```text
DIRECTED_TESTS_COMPLETE count=12 errors=0
RANDOM_TESTS_COMPLETE count=10000
SPARSE4_16_TEST_SUMMARY total=10012 errors=0
SPARSE4_16_TEST_PASS
MODELSIM_RUN_STATUS=break
MODELSIM_RUN_STATUS_FULL=break simulation_stop {$finish}
MODELSIM_TEST_COUNT=10012
MODELSIM_ERROR_COUNT=0
MODELSIM_EXIT_CODE=0
POWERSHELL_OBSERVED_EXIT_CODE=0
```

- ModelSim-Altera Starter Edition 10.3c
- 完整路径：`D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem`
- 编译：0 errors，0 warnings
- 仿真：0 errors，0 warnings
- 从`C:\Windows\Temp`启动成功
- 未调用Active-HDL

完整控制台日志：`docs/sparse4_console.log`

ModelSim transcript：`docs/sparse4_simulation.log`
