param(
  [string[]]$HvigorArgs = @("assembleApp", "--no-daemon")
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$devecoRoot = "C:\Program Files\Huawei\DevEco Studio"
$hvigor = Join-Path $devecoRoot "tools\hvigor\bin\hvigorw.bat"
$jbrHome = Join-Path $devecoRoot "jbr"
$sdkHome = Join-Path $devecoRoot "sdk"

if (-not (Test-Path $hvigor)) {
  throw "DevEco Hvigor wrapper not found: $hvigor"
}

if (-not (Test-Path (Join-Path $jbrHome "bin\java.exe"))) {
  throw "DevEco JBR not found: $jbrHome"
}

$pathEntries = @(
  (Join-Path $jbrHome "bin"),
  (Join-Path $devecoRoot "tools\node"),
  (Join-Path $devecoRoot "tools\ohpm\bin")
)

$pathEntries += ($env:Path -split ';' | Where-Object {
  $_ -and ($_ -notmatch [regex]::Escape("C:\Program Files (x86)\Common Files\Oracle\Java\javapath"))
})

$env:JAVA_HOME = $jbrHome
$env:JRE_HOME = $jbrHome
$env:DEVECO_SDK_HOME = $sdkHome
$env:Path = ($pathEntries | Select-Object -Unique) -join ';'

$dotEnvPath = Join-Path $projectRoot ".env"
$aiEnvPath = Join-Path $projectRoot "entry\src\main\resources\rawfile\ai-env.json"
if (Test-Path $dotEnvPath) {
  $dotEnv = @{}
  Get-Content $dotEnvPath | ForEach-Object {
    $line = $_.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith("#") -or -not $line.Contains("=")) {
      return
    }
    $name, $value = $line.Split("=", 2)
    $dotEnv[$name.Trim()] = $value.Trim().Trim('"').Trim("'")
  }
  $aiConfig = [ordered]@{
    endpoint = $dotEnv["AI_ENDPOINT"]
    model = $dotEnv["AI_MODEL"]
    apiKey = $dotEnv["AI_API_KEY"]
  }
  if (($aiConfig.endpoint -or $aiConfig.model -or $aiConfig.apiKey) -and (Test-Path (Split-Path -Parent $aiEnvPath))) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($aiEnvPath, (($aiConfig | ConvertTo-Json -Compress) + "`n"), $utf8NoBom)
    Write-Host "AI env config generated from local .env." -ForegroundColor Cyan
  }
} elseif (Test-Path $aiEnvPath) {
  Remove-Item -LiteralPath $aiEnvPath -Force
}

Write-Host "Frontend build environment configured." -ForegroundColor Green
Write-Host "  JAVA_HOME = $env:JAVA_HOME"
Write-Host "  java     = $((Get-Command java).Source)"
Write-Host "  hvigor   = $hvigor"
Write-Host ""

Push-Location $projectRoot
try {
  & $hvigor @HvigorArgs
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
