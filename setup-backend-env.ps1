# 后端编译环境配置脚本(使用项目本地工具)
# 使用方法: . .\setup-backend-env.ps1

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$JAVA_HOME = Join-Path $projectRoot "tools\jdk-21"
$MAVEN_HOME = Join-Path $projectRoot "tools\maven"

$env:JAVA_HOME = $JAVA_HOME
$env:MAVEN_HOME = $MAVEN_HOME
$env:Path = "$JAVA_HOME\bin;$MAVEN_HOME\bin;$env:Path"

Write-Host "后端编译环境已配置(项目本地工具):" -ForegroundColor Green
Write-Host "  JAVA_HOME  = $JAVA_HOME"
Write-Host "  MAVEN_HOME = $MAVEN_HOME"
Write-Host ""

# 验证工具可用性
try {
    $javaVersion = & java -version 2>&1 | Select-Object -First 1
    Write-Host "Java: $javaVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Java 不可用" -ForegroundColor Red
}

try {
    $mvnVersion = & mvn -version 2>&1 | Select-Object -First 1
    Write-Host "Maven: $mvnVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Maven 不可用" -ForegroundColor Red
}

Write-Host ""
Write-Host "编译后端命令:" -ForegroundColor Yellow
Write-Host "  cd focus-server"
Write-Host "  mvn clean package -DskipTests"
Write-Host ""
Write-Host "运行后端命令:" -ForegroundColor Yellow
Write-Host "  java -jar focus-server\target\focus-server-0.0.1-SNAPSHOT.jar"

