param(
  [string]$StudentId = "2413575",
  [string]$StudentName = "柯云超"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$folderName = "$StudentId$StudentName"
$submissionRoot = Join-Path $projectRoot "deliverables\$folderName"
$sourceRoot = Join-Path $projectRoot "tmp\source-package"
$sourceZip = Join-Path $submissionRoot "源代码压缩包.zip"

function Copy-IfExists {
  param([string]$Source, [string]$Destination)
  if (-not (Test-Path -LiteralPath $Source)) {
    throw "Missing required file: $Source"
  }
  Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Copy-Tree {
  param([string]$Source, [string]$Destination)
  if (Test-Path -LiteralPath $Destination) {
    Remove-Item -LiteralPath $Destination -Recurse -Force
  }
  Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $submissionRoot | Out-Null
if (Test-Path -LiteralPath $sourceRoot) {
  Remove-Item -LiteralPath $sourceRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $sourceRoot | Out-Null

Copy-IfExists (Join-Path $projectRoot "report\nku-thesis-template-2020\main.pdf") `
  (Join-Path $submissionRoot "课程设计报告.pdf")
Copy-IfExists (Join-Path $projectRoot "report\defense-slides.pdf") `
  (Join-Path $submissionRoot "答辩PPT.pdf")

$videoPath = Join-Path $submissionRoot "程序运行录屏.avi"
if (-not (Test-Path -LiteralPath $videoPath)) {
  Write-Warning "Video is not found yet: $videoPath"
}

$items = @(
  ".env.example",
  ".gitattributes",
  ".gitignore",
  "AppScope",
  "README.md",
  "PROJECT_CONTEXT.md",
  "build-frontend.ps1",
  "build-profile.json5",
  "code-linter.json5",
  "entry",
  "focus-server",
  "hvigor",
  "hvigorfile.ts",
  "oh-package.json5",
  "oh-package-lock.json5",
  "record-demo.ps1",
  "scripts",
  "setup-backend-env.ps1",
  "start-backend.ps1"
)

foreach ($item in $items) {
  $source = Join-Path $projectRoot $item
  if (-not (Test-Path -LiteralPath $source)) {
    continue
  }
  Copy-Tree $source (Join-Path $sourceRoot $item)
}

$removePatterns = @(
  ".git",
  ".hvigor",
  ".idea",
  ".vscode",
  "build",
  "target",
  "data",
  "oh_modules",
  "node_modules",
  "ai-env.json",
  ".env"
)

foreach ($pattern in $removePatterns) {
  Get-ChildItem -LiteralPath $sourceRoot -Force -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq $pattern } |
    Sort-Object FullName -Descending |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
}

if (Test-Path -LiteralPath $sourceZip) {
  Remove-Item -LiteralPath $sourceZip -Force
}
Compress-Archive -Path (Join-Path $sourceRoot "*") -DestinationPath $sourceZip -Force

Write-Host "Submission folder prepared: $submissionRoot" -ForegroundColor Green
Get-ChildItem -LiteralPath $submissionRoot | Select-Object Name,Length,LastWriteTime
