param(
  [string]$OutputPath = "deliverables\2413575柯云超\程序运行录屏.avi"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$devecoRoot = if ($env:DEVECO_STUDIO_HOME) { $env:DEVECO_STUDIO_HOME } else { "C:\Program Files\Huawei\DevEco Studio" }
$hdc = Join-Path $devecoRoot "sdk\default\openharmony\toolchains\hdc.exe"
$framesDir = Join-Path $projectRoot "tmp\demo-frames"

if (-not (Test-Path $hdc)) {
  throw "HDC not found: $hdc"
}

function Invoke-Hdc {
  & $hdc @args
  if ($LASTEXITCODE -ne 0) {
    throw "hdc failed: $($args -join ' ')"
  }
}

function Sleep-Short {
  Start-Sleep -Milliseconds 850
}

function Tap {
  param([int]$X, [int]$Y)
  Invoke-Hdc shell uitest uiInput click $X $Y
  Sleep-Short
}

function Back {
  Invoke-Hdc shell uitest uiInput keyEvent Back
  Sleep-Short
}

function Return-Top {
  # Detail pages use an in-app top-left "返回" button. Repeated taps are harmless
  # on the main tab pages and make the recording start from a non-sensitive view.
  for ($n = 0; $n -lt 4; $n++) {
    Tap 130 270
  }
}

function Snapshot {
  param([int]$Index)
  $remote = "/data/local/tmp/focus-demo-$Index.jpeg"
  $local = Join-Path $framesDir ("{0:D2}.jpeg" -f $Index)
  Invoke-Hdc shell snapshot_display -f $remote
  Invoke-Hdc file recv $remote $local
}

$resolvedOutput = Join-Path $projectRoot $OutputPath
New-Item -ItemType Directory -Force -Path $framesDir | Out-Null
Get-ChildItem -LiteralPath $framesDir -File -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host "Starting 知序 app..." -ForegroundColor Cyan
Invoke-Hdc shell aa start -a EntryAbility -b com.nankai.zhixu -m entry
Start-Sleep -Seconds 2

# Make sure the recording does not start inside an input field or a settings detail page.
Back
Return-Top

$i = 1
Write-Host "Capturing profile page..." -ForegroundColor Cyan
Tap 1090 2680
Snapshot $i; $i++

Write-Host "Capturing task page..." -ForegroundColor Cyan
Tap 654 2680
Snapshot $i; $i++

Write-Host "Capturing today page..." -ForegroundColor Cyan
Tap 210 2680
Snapshot $i; $i++

Write-Host "Opening focus timer..." -ForegroundColor Cyan
Tap 654 910
Snapshot $i; $i++

Write-Host "Starting timer..." -ForegroundColor Cyan
Tap 370 1985
Snapshot $i; $i++

Write-Host "Returning from timer..." -ForegroundColor Cyan
Tap 130 270
Snapshot $i; $i++

Write-Host "Opening review page through Navigation..." -ForegroundColor Cyan
Tap 1090 2680
Tap 530 1420
Snapshot $i; $i++
Tap 130 270

Write-Host "Opening cloud sync page through Navigation..." -ForegroundColor Cyan
Tap 550 1970
Snapshot $i; $i++
Tap 130 270

Write-Host "Encoding demo video..." -ForegroundColor Cyan
$encoderArgs = @(
  (Join-Path $projectRoot "scripts\make_demo_video.py"),
  "--frames-dir", $framesDir,
  "--output", $resolvedOutput,
  "--fps", "1",
  "--hold", "8",
  "--caption", "Profile: local account, total focus, review entry",
  "--caption", "Tasks: filters, Eisenhower quadrants, pomodoro entry",
  "--caption", "Today: dashboard and start focus",
  "--caption", "Focus: pomodoro timer and local record",
  "--caption", "Focus: timer running state",
  "--caption", "Back to Today: data remains local-first",
  "--caption", "Review: Navigation page-stack destination",
  "--caption", "Sync: Spring Boot backend entry"
)
python @encoderArgs
if ($LASTEXITCODE -ne 0) {
  throw "video encoding failed"
}

Write-Host "Demo video generated: $resolvedOutput" -ForegroundColor Green
