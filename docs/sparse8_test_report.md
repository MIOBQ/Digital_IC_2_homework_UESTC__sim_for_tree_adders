# 实验 1 阶段 3.3：16 位 Sparse-8 Tree Adder 测试报告

## 结构定义

- Verilog-2001，16位输入，`Cin=0`，17位输出
- 平衡8位分组 + 两组Radix-2 Kogge-Stone + 每组7级局部Ripple-Carry
- `C[8]`来自Group0完整生成量，`C[16]`来自两组合并生成量
- DUT未使用`A+B`；普通加法仅用于Testbench参考

## ModelSim真实实例统计

```text
SPARSE8_GROUP_LEVEL_COUNTS=8,4,2
SPARSE8_GROUP_PREFIX_COUNT=14
SPARSE8_INTERGROUP_PREFIX_COUNT=1
SPARSE8_PREFIX_CELL_COUNT=15
SPARSE8_LOCAL_CARRY_CELL_COUNT=14
SPARSE8_STRUCTURE_PASS expected_group=14 expected_intergroup=1 expected_total=15
```

真实连接集合：

```text
Level 1：1:0,3:2,5:4,7:6,9:8,11:10,13:12,15:14
Level 2：3:1,7:5,11:9,15:13
Level 3：7:3,15:11
组间：15:7
```

## 实际依赖链分析

脚本从elaboration后的节点ID及高/低来源ID递归重建Prefix依赖图，并从局部Carry前驱ID及边界Prefix来源重建局部与混合路径：

```text
SPARSE8_LONGEST_PREFIX_CELL_CHAIN=4
SPARSE8_LONGEST_LOCAL_RIPPLE_CHAIN=7
SPARSE8_C8_PREFIX_DEPTH=3
SPARSE8_C16_PREFIX_DEPTH=4
SPARSE8_LONGEST_SUM_DEPENDENCY_CELL_CHAIN=10
```

纯Prefix最长链为3级分组加1级组间合并，共4。纯局部Ripple最长为7。到`SUM[15]`的最长混合链从Group0的3级前缀形成`C[8]`，再经过Group1的7级局部Carry，共10个单元；不是简单的4+7。

## 实际测试结果

```text
DIRECTED_TESTS_COMPLETE count=12 errors=0
RANDOM_TESTS_COMPLETE count=10000
SPARSE8_16_TEST_SUMMARY total=10012 errors=0
SPARSE8_16_TEST_PASS
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

完整控制台日志：`docs/sparse8_console.log`

ModelSim transcript：`docs/sparse8_simulation.log`
