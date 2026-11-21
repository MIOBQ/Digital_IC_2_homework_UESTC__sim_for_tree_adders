# Tree Adder 功能仿真实验

## 实验目标

使用 Verilog 设计并验证一个 16 位无符号 Tree Adder。

## 实验要求

- 硬件描述语言：Verilog
- 仿真工具：ModelSim-Altera Starter Edition 10.3c
- 输入位宽：16 位无符号数
- 输入进位：`Cin = 0`
- 输出位宽：17 位，保留最高位进位
- 当前阶段：实验 1 阶段 1，16 位 Ripple-Carry Adder（RCA）

## 工程结构

```text
Tree_Adder/
├── rtl/       # RCA 源代码（rca16.v）
├── tb/        # 独立测试平台（tb_rca16.v）
├── sim/       # ModelSim 批处理脚本
├── docs/      # 仿真日志和测试报告
└── README.md  # 工程说明与实验要求
```

## 环境检查

- ModelSim `vlog.exe`：可调用，版本 10.3c
- ModelSim `vsim.exe`：可调用，版本 10.3c
- ModelSim 路径：`D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem`
- `vlib.exe`、`vmap.exe`、`vlog.exe`、`vsim.exe` 均已确认存在
- PATH 中 `D:\active_hdl_9_2\software_location\bin` 排在 ModelSim 前面，因此直接执行 `vlog` 或 `vsim` 会优先启动 Active-HDL；仿真脚本需要显式使用 ModelSim 路径，或调整 PATH 顺序

## RCA 仿真

在 PowerShell 中执行：

```powershell
& .\sim\run_rca.ps1
```

启动脚本使用 ModelSim `vsim.exe` 的完整路径，不依赖 PATH。测试包含 12 组定向用例和 10,000 组随机用例。

