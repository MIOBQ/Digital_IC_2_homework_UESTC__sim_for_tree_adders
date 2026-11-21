param([switch]$NegativeTest)
$ErrorActionPreference = 'Stop'
$modelSimBin = 'D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem'
$vsim = Join-Path $modelSimBin 'vsim.exe'
$simDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $simDir
$doFile = Join-Path $simDir 'run_all.do'
$logName = if ($NegativeTest) { 'all_adders_negative_console.log' } else { 'all_adders_console.log' }
$consoleLog = Join-Path $projectDir "docs\$logName"
if (-not (Test-Path -LiteralPath $vsim)) { throw "ModelSim executable not found: $vsim" }

$oldProject = $env:ALL_PROJECT_DIR
$oldNegative = $env:ALL_NEGATIVE_TEST
try {
    $env:ALL_PROJECT_DIR = $projectDir
    $env:ALL_NEGATIVE_TEST = if ($NegativeTest) { '1' } else { '0' }
    & $vsim -c -do "do {$doFile}" 2>&1 | Tee-Object -FilePath $consoleLog
    $modelSimExitCode = $LASTEXITCODE
} finally {
    $env:ALL_PROJECT_DIR = $oldProject
    $env:ALL_NEGATIVE_TEST = $oldNegative
}
if ($null -eq $modelSimExitCode) { throw 'ModelSim did not return an exit code.' }
Write-Host "ModelSim process exit code: $modelSimExitCode"
exit $modelSimExitCode
