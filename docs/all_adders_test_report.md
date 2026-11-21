# Seven-Adder Unified Regression Report

## Tool and invocation

- Simulator: ModelSim-Altera Starter Edition 10.3c
- Executable directory: `D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem`
- Invocation: full path to `vsim.exe`; Active-HDL was not used.
- Compilation mode: Verilog-2001 compatibility (`vlog -vlog01compat`).
- Working-directory check: regression launched successfully from `C:\Windows\Temp`.

## Design audit and library isolation

No duplicate auxiliary-module names were found in the current source set. Each RTL file is nevertheless compiled into its own logical library so its dependencies cannot be replaced by later compilation:

| Design | Top module | Auxiliary modules | Logical library |
|---|---|---|---|
| RCA | `rca16` | none | `rca_lib` |
| Kogge-Stone | `kogge_stone16` | `ks_prefix_cell` | `ks_lib` |
| Brent-Kung | `brent_kung16` | `bk_black_cell`, `bk_gray_cell` | `bk_lib` |
| Sparse-2 | `sparse2_16` | `sparse2_prefix_cell` | `sparse2_lib` |
| Sparse-4 | `sparse4_16` | `sparse4_prefix_cell`, `sparse4_local_carry_cell` | `sparse4_lib` |
| Sparse-8 | `sparse8_16` | `sparse8_prefix_cell`, `sparse8_local_carry_cell` | `sparse8_lib` |
| Han-Carlson | `han_carlson16` | `hc_black_cell`, `hc_gray_cell` | `hc_lib` |

The unified testbench is compiled into `regression_work`. ModelSim elaboration reported all seven top instances with the expected module type, and every explicit binding check returned `matched=1`. The generated libraries reside under `sim/regression_build/` and do not alter source RTL.

## Vector equivalence

The unified testbench copies the same 12 directed calls from `tb_rca16.v`. Random generation also retains the original algorithm and ordering: seed `32'h13579bdf`, followed by `A = $random(seed)` and `B = $random(seed)` once per iteration for exactly 10,000 iterations.

## Final formal regression

| Metric | Result |
|---|---:|
| Directed vectors | 12 |
| Random vectors | 10000 |
| Total vectors | 10012 |
| DUT checks | 70084 |
| Total reference mismatches | 0 |
| Cross-DUT consistency errors | 0 |

| DUT | Error count |
|---|---:|
| RCA | 0 |
| Kogge-Stone | 0 |
| Brent-Kung | 0 |
| Sparse-2 | 0 |
| Sparse-4 | 0 |
| Sparse-8 | 0 |
| Han-Carlson | 0 |

All seven outputs matched the 17-bit reference result for every vector and were mutually identical. No isolated DUT failure occurred. Compilation and simulation completed with 0 errors and 0 warnings. Termination was `simulation_stop {$finish}`. ModelSim returned 0 and PowerShell observed/returned 0.

## Negative-path verification

The `-NegativeTest` switch enables a controlled plusarg mode that flips bit 0 of the reference only for the first vector. It does not modify any RTL and is disabled in the formal test.

- Testbench detected the deliberately incorrect reference.
- The one affected vector produced seven reference mismatches, one for each DUT.
- DUT-to-DUT consistency remained valid (`consistency_errors=0`), demonstrating that agreement alone is not accepted as correctness.
- ModelSim returned 1.
- PowerShell observed and returned 1.
- A subsequent normal regression was run and passed, restoring the formal logs to the passing result.

Negative-path console evidence is retained in `docs/all_adders_negative_console.log`.

## Source protection

SHA256 hashes were captured before the work and checked again after the final regression for all pre-existing RTL, individual testbenches, and individual simulation scripts. The comparison passed: no protected file changed.

No delay model, synthesis, timing, power, or physical-design work was performed.
