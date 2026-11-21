# 16 位 Tree Adder 仿真与理论建模

本仓库实现并验证七种 16 位无符号加法器，并基于与 RTL 拓扑一致的 Python 基本门 DAG 开展理论成本、延迟、敏感性和 Pareto 分析。

## 研究对象与统一规格

所有被测设计均采用 Verilog-2001，接口为 `A[15:0]`、`B[15:0]` 和 `SUM[16:0]`：

- `Cin` 固定为 `0`。
- `SUM[16]` 是最高位进位。
- DUT 不直接使用 `A + B`；测试平台使用普通 17 位加法作为参考模型。

| 结构 | RTL 顶层 | 主要进位组织 |
| --- | --- | --- |
| Ripple-Carry Adder | `rca16` | 逐位进位递推 |
| Kogge-Stone | `kogge_stone16` | 距离 1、2、4、8 的全前缀网络 |
| Brent-Kung | `brent_kung16` | Up-Sweep / Down-Sweep 前缀网络 |
| Sparse-2 | `sparse2_16` | 二位分组、组间 KS、局部进位 |
| Sparse-4 | `sparse4_16` | 四位平衡分组、组间 KS、局部 Ripple |
| Sparse-8 | `sparse8_16` | 八位平衡分组、组间前缀、局部 Ripple |
| Han-Carlson | `han_carlson16` | 成对合并、组级前缀、末级 Gray Cell 补齐 |

## 目录结构

```text
.
├── rtl/                    # 七种加法器 RTL
├── tb/                     # 单结构测试平台和七结构统一测试平台
├── sim/                    # ModelSim .do / PowerShell 运行脚本及生成库
├── analysis/               # Python 门级 DAG、常量传播与敏感性分析
│   └── results/            # CSV / JSON 分析结果
├── figures/                # 由 analysis/visualization.py 生成的图表
├── docs/                   # 仿真日志、测试报告、理论分析与可视化报告
└── README.md
```

`sim/work*`、`sim/regression_build/`、`sim/transcript` 和 `sim/modelsim.ini` 是 ModelSim 运行产生或使用的构建文件；不应将它们解释为 RTL 源码。

## 环境

已验证的仿真环境：

- ModelSim-Altera Starter Edition 10.3c
- ModelSim 可执行目录：`D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem`
- Python 3.13.2

PowerShell 脚本显式调用上面的 `vsim.exe`，不依赖 `PATH`，因此不会误调用 Active-HDL。Python 分析依赖标准库以及已安装的 `matplotlib`；可视化脚本也使用 `pandas`。

## ModelSim 功能仿真

每种单结构测试平台均执行 12 组定向测试和 10,000 组确定性随机测试。统一回归由 `tb/tb_all_adders16.v` 同时例化七个 DUT，使用种子 `32'h13579bdf`，逐个比较完整 17 位输出并检查 DUT 间一致性。

在仓库根目录运行：

```powershell
& .\sim\run_all.ps1
```

脚本会：

1. 为七种 RTL 建立独立逻辑库，避免辅助模块同名覆盖；
2. 编译统一 Testbench 至 `regression_work`；
3. 用 `-L` 选项装载各结构库并检查顶层绑定；
4. 检查 `directed_count=12`、`random_count=10000`、`total_vectors=10012`、`total_dut_checks=70084`；
5. 仅在 `$finish` 正常结束且所有错误计数为零时返回退出码 `0`。

可执行自动化负向验证，确认失败会原样传递非零退出码：

```powershell
& .\sim\run_all.ps1 -NegativeTest
```

单结构仿真同样通过相应脚本启动，例如：

```powershell
& .\sim\run_rca.ps1
& .\sim\run_kogge_stone.ps1
& .\sim\run_brent_kung.ps1
& .\sim\run_sparse2.ps1
& .\sim\run_sparse4.ps1
& .\sim\run_sparse8.ps1
& .\sim\run_han_carlson.ps1
```

正式统一回归的结果与日志见 `docs/all_adders_test_report.md`、`docs/all_adders_regression.log` 和 `docs/all_adders_console.log`。

## Python 理论门级模型

Python 模型不是 Verilog 自动综合网表。它根据已验证的 RTL 拓扑，在 `analysis/adder_models.py` 中显式重建 G/P 预处理、Black/Gray Prefix Cell、Local Carry 和最终 SUM XOR 的基本门 DAG。

- `analysis/gate_model.py`：DAG、布尔求值、时序传播和常量折叠。
- `analysis/validate_models.py`：12 组定向与 10,000 组随机向量的模型功能检查。
- `analysis/run_analysis.py`：基线门数、延迟与关键路径。
- `analysis/run_constant_fold.py`：`Cin=0` 下常量传播、不可达逻辑删除和正式门数/延迟结果。
- `analysis/sensitivity_analysis.py`：单参数及联合参数扫描、排名、关键路径和 Pareto 分析。
- `analysis/visualization.py`：从结果 CSV/JSON 生成图表。

在 `analysis/` 目录运行：

```powershell
python .\run_analysis.py
python .\run_constant_fold.py
python .\sensitivity_analysis.py
python .\visualization.py
```

基准门延迟为 `AND=1`、`OR=1`、`XOR=2`。正式比较采用常量传播后的模型；它将 `C1=G0`、`SUM0=P0` 等常量条件化简，并从所有 `SUM[0:16]` 输出反向删除不可达逻辑。

### 基准结果

| 结构 | AND | OR | XOR | 总门数 | 最大理论延迟 |
| --- | ---: | ---: | ---: | ---: | ---: |
| RCA | 31 | 15 | 31 | 77 | 32 |
| Kogge-Stone | 99 | 49 | 31 | 179 | 11 |
| Brent-Kung | 53 | 26 | 31 | 110 | 16 |
| Sparse-2 | 65 | 32 | 31 | 128 | 13 |
| Sparse-4 | 55 | 27 | 31 | 113 | 17 |
| Sparse-8 | 54 | 27 | 31 | 112 | 24 |
| Han-Carlson | 65 | 32 | 31 | 128 | 13 |

这些是统一基本门模型下的逻辑复杂度和归一化延迟，并非逻辑综合、标准单元映射、STA、布局布线或功耗分析得到的真实 PPA。

## 参数敏感性与可视化

`analysis/sensitivity_config.json` 定义两类扫描：

- 单参数扫描：分别扫描 XOR、AND、OR 的 6 个取值，共 18 种条件和 126 条结构记录；
- 联合扫描：AND 4 个取值 × OR 4 个取值 × XOR 5 个取值，共 80 种条件和 560 条结构记录。

敏感性分析对每组参数重新执行 DAG 时序传播并重新寻找关键路径。排名采用允许并列的竞争排名；Pareto 支配要求一个结构的门数和延迟都不劣，且至少一项更优。

主要数据和图表位于 `analysis/results/` 与 `figures/`；包括常量传播门数、延迟、关键路径、敏感性、排名和 Pareto CSV/JSON，以及 `fig3_1` 至 `fig3_6` 的 PNG/SVG 图。

在当前参数网格中，Kogge-Stone 的理论延迟始终最小；Sparse-2 与 Han-Carlson 的完整输出延迟曲线相同。该结论仅适用于本仓库指定的 16 位 RTL 拓扑和门延迟模型。

## 报告与复现边界

详细的仿真、建模、参数敏感性和可视化说明位于 `docs/` 下的测试报告、`theoretical_model_report.md`、`constant_fold_comparison_report.md`、`sensitivity_analysis_report.md` 与 `experiment3_visualization_report.md`。

本仓库已经完成功能验证和理论门级分析；尚未进行逻辑综合、标准单元映射、静态时序分析、布局布线、寄生参数提取或实际功耗测量。因此，不应将这里的门数、归一化延迟或 Pareto 前沿解释为真实芯片面积、时序或功耗结论。

