$ErrorActionPreference = 'Stop'

$modelSimBin = 'D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem'
$vsim = Join-Path $modelSimBin 'vsim.exe'
$simDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $simDir
$doFile = Join-Path $simDir 'run_brent_kung.do'
$consoleLog = Join-Path $projectDir 'docs\brent_kung_console.log'

if (-not (Test-Path -LiteralPath $vsim)) {
    throw "ModelSim executable not found: $vsim"
}
if (-not (Test-Path -LiteralPath $doFile)) {
    throw "ModelSim do file not found: $doFile"
}

$previousProjectDir = $env:BK_PROJECT_DIR
try {
    $env:BK_PROJECT_DIR = $projectDir
    & $vsim -c -do "do {$doFile}" 2>&1 |
        Tee-Object -FilePath $consoleLog
    $modelSimExitCode = $LASTEXITCODE
}
finally {
    $env:BK_PROJECT_DIR = $previousProjectDir
}

if ($null -eq $modelSimExitCode) {
    throw 'ModelSim did not return an exit code.'
}

Write-Host "ModelSim process exit code: $modelSimExitCode"
exit $modelSimExitCode
