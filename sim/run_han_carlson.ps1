$ErrorActionPreference='Stop'
$bin='D:\CourseTools\MicroEmbedded_Toolchain\ModelSim\modelsim_ase\win32aloem'
$vsim=Join-Path $bin 'vsim.exe'
$simDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir=Split-Path -Parent $simDir
$doFile=Join-Path $simDir 'run_han_carlson.do'
$log=Join-Path $projectDir 'docs\han_carlson_console.log'
if(-not(Test-Path -LiteralPath $vsim)){throw "ModelSim executable not found: $vsim"}
$old=$env:HC_PROJECT_DIR
try{$env:HC_PROJECT_DIR=$projectDir;& $vsim -c -do "do {$doFile}" 2>&1|Tee-Object -FilePath $log;$code=$LASTEXITCODE}finally{$env:HC_PROJECT_DIR=$old}
if($null-eq$code){throw 'ModelSim did not return an exit code.'}
Write-Host "ModelSim process exit code: $code"
exit $code
