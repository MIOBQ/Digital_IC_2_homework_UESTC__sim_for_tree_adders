# 实验1阶段4：16位Han-Carlson Tree Adder测试报告

## 实际结构统计

ModelSim elaboration后的真实实例结果：

```text
HAN_CARLSON_STAGE_COUNTS=8,7,6,4,7
HAN_CARLSON_BLACK_CELL_COUNT=17
HAN_CARLSON_GRAY_CELL_COUNT=15
HAN_CARLSON_PREFIX_CELL_COUNT=32
HAN_CARLSON_LONGEST_PREFIX_CHAIN=5
HAN_CARLSON_STRUCTURE_PASS expected_total=32
```

Black/Gray选择依据实际P依赖：Stage1为7 Black+1 Gray，Stage2为6 Black+1 Gray，Stage3为4 Black+2 Gray，Stage4为4 Gray，Stage5为7 Gray。未被下游使用P输出的节点不采用Black Cell。

## 五级实际连接

```text
Stage1：1:0,3:2,5:4,7:6,9:8,11:10,13:12,15:14
Stage2：1:0,2:1,3:2,4:3,5:4,6:5,7:6
Stage3：2:0,3:1,4:2,5:3,6:4,7:5
Stage4：4:0,5:1,6:2,7:3
Stage5：2:1,4:3,6:5,8:7,10:9,12:11,14:13
```

脚本根据elaboration后每个节点的唯一ID和高/低来源ID递归重建依赖图，得到最长真实前缀链5。

## 功能测试

```text
DIRECTED_TESTS_COMPLETE count=12 errors=0
RANDOM_TESTS_COMPLETE count=10000
HAN_CARLSON16_TEST_SUMMARY total=10012 errors=0
HAN_CARLSON16_TEST_PASS
MODELSIM_RUN_STATUS=break
MODELSIM_RUN_STATUS_FULL=break simulation_stop {$finish}
MODELSIM_TEST_COUNT=10012
MODELSIM_ERROR_COUNT=0
MODELSIM_EXIT_CODE=0
POWERSHELL_OBSERVED_EXIT_CODE=0
```

- 编译：0 errors，0 warnings
- 仿真：0 errors，0 warnings
- ModelSim 10.3c完整路径调用，未使用Active-HDL
- 从`C:\Windows\Temp`启动成功

## 与Sparse-2的关系

两者共享相同的前四级骨架：8个相邻二位分组节点，以及距离1、2、4的8组Kogge-Stone网络（7、6、4个节点），因此都形成偶数位置的组边界进位。

区别在最后一级：Sparse-2使用7个普通局部Carry逻辑生成`C[3]、C[5]...C[15]`；本Han-Carlson实现把相同逻辑显式实例化为7个Gray Cell并纳入前缀节点统计。因此两者在本实验的`Cin=0`条件下逻辑功能等价，但统计口径分别为25个Prefix Cell和32个Prefix Cell。仅凭命名和节点计数不能断言实际面积或延迟差异，需综合和物理分析后才能判断，本阶段未开展这些工作。

完整日志：`docs/han_carlson_console.log`和`docs/han_carlson_simulation.log`。
