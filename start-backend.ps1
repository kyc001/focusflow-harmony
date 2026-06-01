param(
  [ValidateSet("mysql", "h2")]
  [string]$DbProfile = "mysql"
)

$activeProfile = if ($DbProfile -eq "h2") { "" } else { $DbProfile }

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mavenHome = Join-Path $projectRoot "tools\maven"
$serverDir = Join-Path $projectRoot "focus-server"

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
  (Join-Path $projectRoot "tools\jdk-21"),
  "D:\jdk",
  "C:\Program Files\Huawei\DevEco Studio\jbr"
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

Write-Host "Using configured JDK and project-local Maven" -ForegroundColor Green
Write-Host "JAVA_HOME=$javaHome"
Write-Host "MAVEN_HOME=$mavenHome"

Push-Location $serverDir
try {
  & mvn -q -DskipTests package
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
  $profileText = if ($activeProfile.Length -gt 0) { $activeProfile } else { "h2" }
  Write-Host "Starting Focus Server at http://localhost:8080" -ForegroundColor Cyan
  Write-Host "Spring profile: $profileText" -ForegroundColor Cyan
  Write-Host "Demo account: demo / secret" -ForegroundColor Cyan
  if ($activeProfile.Length -gt 0) {
    & java -jar "target\focus-server-0.0.1-SNAPSHOT.jar" "--spring.profiles.active=$activeProfile"
  } else {
    & java -jar "target\focus-server-0.0.1-SNAPSHOT.jar"
  }
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
