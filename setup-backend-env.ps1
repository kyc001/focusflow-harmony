# Backend build environment for this project.
# Usage: . .\setup-backend-env.ps1

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mavenHome = Join-Path $projectRoot "tools\maven"

function Test-UsableJavaHome {
  param([string]$Path)
  return $Path `
    -and (Test-Path (Join-Path $Path "bin\java.exe")) `
    -and (Test-Path (Join-Path $Path "lib\modules"))
}

function Import-DotEnv {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    return
  }
  Get-Content $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith("#") -or -not $line.Contains("=")) {
      return
    }
    $name, $value = $line.Split("=", 2)
    $cleanName = $name.Trim()
    if ($cleanName.Length -eq 0) {
      return
    }
    [Environment]::SetEnvironmentVariable($cleanName, $value.Trim().Trim('"').Trim("'"), "Process")
  }
}

$javaCandidates = @(
  $env:JAVA_HOME,
  $env:JDK_HOME,
  (Join-Path $projectRoot "tools\jdk-21"),
  "C:\Program Files\Java\jdk-21",
  $(if ($env:DEVECO_STUDIO_HOME) { Join-Path $env:DEVECO_STUDIO_HOME "jbr" })
)

$javaHome = $javaCandidates | Where-Object { Test-UsableJavaHome $_ } | Select-Object -First 1
if (-not $javaHome) {
  throw "No usable JDK found. Install JDK 21 or DevEco Studio JBR."
}

if (-not (Test-Path (Join-Path $mavenHome "bin\mvn.cmd"))) {
  throw "Project Maven not found: $mavenHome"
}

$pathEntries = @(
  (Join-Path $javaHome "bin"),
  (Join-Path $mavenHome "bin")
)
$pathEntries += ($env:Path -split ';' | Where-Object {
  $_ -and ($_ -notmatch [regex]::Escape("C:\Program Files (x86)\Common Files\Oracle\Java\javapath"))
})

$env:JAVA_HOME = $javaHome
$env:MAVEN_HOME = $mavenHome
$env:Path = ($pathEntries | Select-Object -Unique) -join ';'
Import-DotEnv (Join-Path $projectRoot ".env")

Write-Host "Backend environment configured with usable JDK and project-local Maven." -ForegroundColor Green
Write-Host "  JAVA_HOME  = $javaHome"
Write-Host "  MAVEN_HOME = $mavenHome"
Write-Host ""

try {
  $javaVersion = & java -version 2>&1 | Select-Object -First 1
  Write-Host "Java: $javaVersion" -ForegroundColor Cyan
} catch {
  Write-Host "Java is not available." -ForegroundColor Red
}

try {
  $mvnVersion = & mvn -version 2>&1 | Select-Object -First 1
  Write-Host "Maven: $mvnVersion" -ForegroundColor Cyan
} catch {
  Write-Host "Maven is not available." -ForegroundColor Red
}

Write-Host ""
Write-Host "Build backend:" -ForegroundColor Yellow
Write-Host "  cd focus-server"
Write-Host "  mvn clean package -DskipTests"
Write-Host ""
Write-Host "Run backend:" -ForegroundColor Yellow
Write-Host "  java -jar focus-server\target\focus-server-0.0.1-SNAPSHOT.jar"
