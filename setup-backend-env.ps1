# Backend build environment for this project.
# Usage: . .\setup-backend-env.ps1

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$javaHome = Join-Path $projectRoot "tools\jdk-21"
$mavenHome = Join-Path $projectRoot "tools\maven"

if (-not (Test-Path (Join-Path $javaHome "bin\java.exe"))) {
  throw "Project JDK not found: $javaHome"
}

if (-not (Test-Path (Join-Path $mavenHome "bin\mvn.cmd"))) {
  throw "Project Maven not found: $mavenHome"
}

$env:JAVA_HOME = $javaHome
$env:MAVEN_HOME = $mavenHome
$env:Path = "$javaHome\bin;$mavenHome\bin;$env:Path"

Write-Host "Backend environment configured with project-local tools." -ForegroundColor Green
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
