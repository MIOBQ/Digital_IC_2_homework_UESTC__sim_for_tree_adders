# 实验 1 阶段 1：16 位 Ripple-Carry Adder 测试报告

## 实现说明

- 语言标准：Verilog-2001
- 输入：`A[15:0]`、`B[15:0]`
- 固定输入进位：`Cin = 0`（实现为 `C[0] = 1'b0`）
- 输出：`SUM[16:0]`，其中 `SUM[16]` 为最高位进位
- 生成信号：`G = A & B`
- 传播信号：`P = A ^ B`
- 逐级进位：`C[i+1] = G[i] | (P[i] & C[i])`
- 和位：`SUM[i] = P[i] ^ C[i]`
- 被测电路未使用 `A+B`；`A+B` 仅在 Testbench 中生成参考结果

## 仿真环境

- 工具：ModelSim-Altera Starter Edition 10.3c
- 完整工具目录：`D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem`
- 编译兼容选项：`vlog -vlog01compat`
- 启动方式：使用上述目录内 `vsim.exe` 的完整路径
- 未调用 Active-HDL，未修改系统 PATH

## 测试内容

- 定向测试：12 组
- 伪随机测试：10,000 组（固定种子 `32'h13579bdf`，可重复）
- 参考模型：`{1'b0, A} + {1'b0, B}`
- 总测试数：10,012 组

定向测试覆盖零值、全 1、最高位进位、长进位链、交替位型及典型数值组合。

## 实际结果

```text
DIRECTED_TESTS_COMPLETE count=12 errors=0
RANDOM_TESTS_COMPLETE count=10000
RCA16_TEST_SUMMARY total=10012 errors=0
RCA16_TEST_PASS
```

- 编译：0 errors，0 warnings
- 仿真：0 errors，0 warnings
- 最终结论：通过

完整 transcript 见 `docs/rca_simulation.log`。
