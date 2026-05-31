$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$javaHome = Join-Path $projectRoot "tools\jdk-21"
$mavenHome = Join-Path $projectRoot "tools\maven"
$serverDir = Join-Path $projectRoot "focus-server"

$env:JAVA_HOME = $javaHome
$env:MAVEN_HOME = $mavenHome
$env:Path = "$javaHome\bin;$mavenHome\bin;$env:Path"

Write-Host "Using project-local JDK and Maven" -ForegroundColor Green
Write-Host "JAVA_HOME=$javaHome"
Write-Host "MAVEN_HOME=$mavenHome"

Push-Location $serverDir
try {
  & mvn -q -DskipTests package
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
  Write-Host "Starting Focus Server at http://localhost:8080" -ForegroundColor Cyan
  Write-Host "Demo account: demo / secret" -ForegroundColor Cyan
  & java -jar "target\focus-server-0.0.1-SNAPSHOT.jar"
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
