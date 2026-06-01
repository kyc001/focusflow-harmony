# FocusFlow Harmony 项目上下文

本文档记录当前项目的本机路径、构建方式、HDC 调试方法、模拟器操作、后端环境、论文路径、Git/代理信息和已知问题。内容基于当前工作区状态和已完成调试过程整理。

## 1. 项目基本信息

- 项目根目录：`D:\Study\26sp\arkts\final`
- 当前 Shell：PowerShell
- 当前 Git 分支：`master`
- GitHub 远程仓库：`https://github.com/kyc001/focusflow-harmony.git`
- HarmonyOS bundleName：`com.example.myapplication`
- 主 module：`entry`
- 主 Ability：`EntryAbility`
- 主页面入口：`entry/src/main/ets/pages/Index.ets`
- 当前入口加载逻辑：`EntryAbility.ets` 直接 `loadContent('pages/Index')`
- 原 Splash 卡住问题：已绕过，不再从 `pages/Splash` 进入主界面

项目是一个 HarmonyOS ArkTS 专注效率应用，配套 Spring Boot + MyBatis 后端。主要功能包括：

- 本地账户进入
- 今日专注看板
- 任务管理
- 四象限/优先级任务视图
- 番茄钟记录
- 白噪音播放
- 数据统计
- TaskPool 复盘统计预计算
- 云同步
- AI 教练服务
- 后端 MySQL/H2 数据库支持
- 课程论文与运行截图

## 2. 关键目录结构

```text
D:\Study\26sp\arkts\final
├─ AppScope                         HarmonyOS 应用级配置
├─ entry                            HarmonyOS 前端 module
├─ focus-server                     Spring Boot 后端
├─ report\nku-thesis-template-2020  论文目录
├─ build-frontend.ps1               前端构建脚本
├─ setup-backend-env.ps1            后端环境初始化脚本
├─ start-backend.ps1                后端启动脚本
├─ README.md                        根 README
└─ PROJECT_CONTEXT.md               本文档
```

前端核心文件：

```text
entry/src/main/ets/entryability/EntryAbility.ets
entry/src/main/ets/pages/Index.ets
entry/src/main/ets/pages/FocusSolo.ets
entry/src/main/ets/pages/Splash.ets
entry/src/main/ets/components/TodayView.ets
entry/src/main/ets/components/TasksView.ets
entry/src/main/ets/components/ResourcesView.ets
entry/src/main/ets/components/FocusSessionView.ets
entry/src/main/ets/components/ReviewView.ets
entry/src/main/ets/components/ProfileView.ets
entry/src/main/ets/components/FocusVisuals.ets
entry/src/main/ets/services/FocusStore.ets
entry/src/main/ets/services/FocusDatabase.ets
entry/src/main/ets/services/FocusSyncService.ets
entry/src/main/ets/services/FocusAmbientService.ets
entry/src/main/ets/services/FocusAiCoachService.ets
entry/src/main/ets/services/FocusNativeServices.ets
entry/src/main/ets/services/FocusSettingsService.ets
entry/src/main/ets/repository/AuthRepository.ets
entry/src/main/ets/models/FocusModels.ets
entry/src/main/ets/data/SeedData.ets
entry/src/main/ets/utils/FocusDesignTokens.ets
entry/src/main/ets/utils/FocusFormatters.ets
entry/src/main/ets/utils/FocusRoutes.ets
```

后端核心文件：

```text
focus-server/src/main/java/com/focus/server/FocusServerApplication.java
focus-server/src/main/java/com/focus/server/controller/UserController.java
focus-server/src/main/java/com/focus/server/controller/ProjectController.java
focus-server/src/main/java/com/focus/server/controller/TaskController.java
focus-server/src/main/java/com/focus/server/controller/PomodoroController.java
focus-server/src/main/java/com/focus/server/controller/StatsController.java
focus-server/src/main/java/com/focus/server/controller/SyncController.java
focus-server/src/main/resources/application.yml
focus-server/src/main/resources/application-mysql.yml
focus-server/src/main/resources/init.sql
focus-server/src/main/resources/init-mysql.sql
focus-server/src/main/resources/mapper/*.xml
```

## 3. 本机工具路径

DevEco Studio：

```text
C:\Program Files\Huawei\DevEco Studio
```

DevEco JBR：

```text
C:\Program Files\Huawei\DevEco Studio\jbr
```

DevEco SDK：

```text
C:\Program Files\Huawei\DevEco Studio\sdk
```

Hvigor wrapper：

```text
C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat
```

HDC：

```text
C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe
```

项目本地 JDK，若存在：

```text
D:\Study\26sp\arkts\final\tools\jdk-21
```

项目本地 Maven，若存在：

```text
D:\Study\26sp\arkts\final\tools\maven
```

Git：

```text
D:\Git\cmd\git.exe
```

Git 自带代理连接工具：

```text
D:\Git\mingw64\bin\connect.exe
```

本地代理端口：

```text
127.0.0.1:7897
```

当前测试结果：`127.0.0.1:7897` 可连通。

## 4. 前端构建环境

前端构建脚本：

```powershell
.\build-frontend.ps1
```

默认执行：

```powershell
assembleApp --no-daemon
```

只构建 HAP：

```powershell
.\build-frontend.ps1 -HvigorArgs assembleHap,--no-daemon
```

脚本设置的环境变量：

```powershell
$env:JAVA_HOME = "C:\Program Files\Huawei\DevEco Studio\jbr"
$env:JRE_HOME = "C:\Program Files\Huawei\DevEco Studio\jbr"
$env:DEVECO_SDK_HOME = "C:\Program Files\Huawei\DevEco Studio\sdk"
```

脚本会把以下路径放到 PATH 前面：

```text
C:\Program Files\Huawei\DevEco Studio\jbr\bin
C:\Program Files\Huawei\DevEco Studio\tools\node
C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin
```

脚本会从 PATH 中移除 Oracle javapath：

```text
C:\Program Files (x86)\Common Files\Oracle\Java\javapath
```

原因：前端 ArkTS/PackageHap 能通过，但最终 `PackageApp` 曾被系统 Java 注册表问题卡住。使用 DevEco Studio 自带 JBR 后，`PackageApp / SignApp / assembleApp` 已验证通过。

常见输出：

```text
BUILD SUCCESSFUL
Finished ::PackageApp
Finished ::SignApp
Finished ::assembleApp
```

常见 warning：

- `getContext` deprecated
- `replaceUrl` deprecated
- 部分 ArkTS API 提示需要异常处理
- 未配置 `signingConfigs`，debug 构建可忽略
- `backgroundTaskManager` 不是所有设备都支持

这些 warning 当前不阻塞构建。

## 5. 后端构建和启动环境

初始化后端环境：

```powershell
. .\setup-backend-env.ps1
```

注意前面有一个点和空格，这是 dot-source 用法，会把环境变量写入当前 PowerShell 会话。

脚本设置：

```powershell
$env:JAVA_HOME  = "D:\Study\26sp\arkts\final\tools\jdk-21" # 若完整可用
$env:MAVEN_HOME = "D:\Study\26sp\arkts\final\tools\maven"
$env:Path       = "$env:JAVA_HOME\bin;$env:MAVEN_HOME\bin;$env:Path"
```

当前脚本会检查 JDK 是否包含 `bin\java.exe` 和 `lib\modules`。如果项目内 `tools\jdk-21` 不完整，会自动回退到：

```text
D:\jdk
C:\Program Files\Huawei\DevEco Studio\jbr
```

同时会从 PATH 中移除损坏的 Oracle `javapath`。

后端测试：

```powershell
. .\setup-backend-env.ps1
Set-Location .\focus-server
mvn test
```

已验证：`mvn test` 通过。

后端默认启动：

```powershell
.\start-backend.ps1
```

默认数据库 profile：`mysql`

等价于：

```text
--spring.profiles.active=mysql
```

H2 快速测试启动：

```powershell
.\start-backend.ps1 -DbProfile h2
```

启动脚本行为：

1. 自动选择可用 JDK，设置项目本地 Maven
2. 进入 `focus-server`
3. 执行 `mvn -q -DskipTests package`
4. 启动 `target\focus-server-0.0.1-SNAPSHOT.jar`

后端地址：

```text
http://localhost:8080
```

默认演示账号：

```text
username: demo
password: secret
```

## 6. 数据库配置

### MySQL

配置文件：

```text
focus-server/src/main/resources/application-mysql.yml
```

当前配置：

```yaml
server:
  port: 8080

spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: ${MYSQL_URL:jdbc:mysql://localhost:3306/focus_db?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: ${MYSQL_USERNAME:root}
    password: ${MYSQL_PASSWORD:}
```

本地 MySQL 密码放在根目录 `.env`：

```text
MYSQL_URL=jdbc:mysql://localhost:3306/focus_db?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai
MYSQL_USERNAME=root
MYSQL_PASSWORD=...
```

`setup-backend-env.ps1` 和 `start-backend.ps1` 会读取 `.env` 注入进程环境变量。

初始化 SQL：

```text
focus-server/src/main/resources/init-mysql.sql
```

首次使用 MySQL 前需要执行该 SQL，创建：

- `focus_db`
- 用户表
- 项目表
- 任务表
- 番茄钟记录表
- 默认 demo 账号和示例数据

### H2

配置文件：

```text
focus-server/src/main/resources/application.yml
```

H2 JDBC URL：

```text
jdbc:h2:file:./data/focus_db;MODE=MySQL;DATABASE_TO_UPPER=false;CASE_INSENSITIVE_IDENTIFIERS=TRUE;AUTO_SERVER=FALSE
```

H2 控制台：

```text
http://localhost:8080/h2-console
```

H2 登录参数：

```text
JDBC URL: jdbc:h2:file:./data/focus_db
User: sa
Password: 留空
```

H2 数据目录：

```text
focus-server/data/
```

该目录已加入 `.gitignore`。

## 7. 后端 API

基础地址：

```text
http://localhost:8080
```

主要接口：

```text
POST /api/user/login
POST /api/user/register
GET  /api/projects
POST /api/projects
PUT  /api/projects/{id}
DELETE /api/projects/{id}
GET  /api/tasks
POST /api/tasks
PUT  /api/tasks/{id}
DELETE /api/tasks/{id}
GET  /api/pomodoros
POST /api/pomodoros
GET  /api/stats/summary
POST /api/sync/pull
POST /api/sync/push
```

多数接口通过请求头识别用户：

```text
X-User-Id: 1
```

后端 Jackson 配置：

```yaml
property-naming-strategy: SNAKE_CASE
default-property-inclusion: non_null
```

前端同步服务已经兼容 camelCase 和 snake_case 字段，例如：

- `userId` / `user_id`
- `projectId` / `project_id`
- `updatedAt` / `updated_at`
- `clientRequestId` / `client_request_id`

## 8. 前端模块和关键状态

应用配置：

```text
AppScope/app.json5
```

关键字段：

```json
{
  "bundleName": "com.example.myapplication",
  "versionCode": 1000000,
  "versionName": "1.0.0"
}
```

module 配置：

```text
entry/src/main/module.json5
```

关键内容：

- module name：`entry`
- mainElement：`EntryAbility`
- deviceTypes：`phone`、`tablet`、`2in1`
- permissions：
  - `ohos.permission.NOTIFICATION_CONTROLLER`
  - `ohos.permission.KEEP_BACKGROUND_RUNNING`
  - `ohos.permission.VIBRATE`
  - `ohos.permission.INTERNET`
- abilities：
  - `EntryAbility`
  - `FocusAbility`
- extensionAbilities：
  - `EntryFormAbility`
  - `EntryBackupAbility`

白噪音资源：

```text
entry/src/main/resources/rawfile/outdoor.mp3
entry/src/main/resources/rawfile/ocean.mp3
entry/src/main/resources/rawfile/cricket.mp3
```

旧中文文件名资源已替换为 ASCII 文件名，避免 rawfile 加载问题。

白噪音服务：

```text
entry/src/main/ets/services/FocusAmbientService.ets
```

当前逻辑：

- `none` 不播放
- `outdoor` 对应 `outdoor.mp3`
- `ocean` 对应 `ocean.mp3`
- `cricket` 对应 `cricket.mp3`
- 使用 `resourceManager.getRawFdSync`
- 给 `AVPlayer.fdSrc` 设置 `fd / offset / length`
- 等待 `initialized` 后 `prepare`
- 等待 `prepared` 后 `play`
- 停止时释放 player，并关闭 raw fd

云同步服务：

```text
entry/src/main/ets/services/FocusSyncService.ets
```

默认前端同步地址：

```text
http://10.0.2.2:8080
```

说明：

- 模拟器访问宿主机后端使用 `10.0.2.2`
- 真机访问后端需要填写电脑局域网 IP，例如 `http://电脑IP:8080`
- 不要在代码里硬编码临时局域网 IP

AI 教练服务：

```text
entry/src/main/ets/services/FocusAiCoachService.ets
```

注意：

- 源码默认不保存真实 API key
- 本地可通过根目录 `.env` 配置 `AI_ENDPOINT`、`AI_MODEL`、`AI_API_KEY`
- `build-frontend.ps1` 会读取 `.env` 并生成被忽略的 `entry/src/main/resources/rawfile/ai-env.json`
- 推送 GitHub 前必须确认 `.env` 和 `ai-env.json` 没有被跟踪

## 9. HDC 调试方法

HDC 路径：

```powershell
$hdc = 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
```

查看设备：

```powershell
& $hdc list targets
```

当前已见目标：

```text
127.0.0.1:5555
```

安装 HAP：

```powershell
& $hdc install -r .\entry\build\default\outputs\default\app\entry-default.hap
```

如果需要干净安装：

```powershell
& $hdc uninstall com.example.myapplication
& $hdc install -r .\entry\build\default\outputs\default\app\entry-default.hap
```

启动应用：

```powershell
& $hdc shell aa start -a EntryAbility -b com.example.myapplication -m entry
```

必须带 `-m entry`。不带 module 参数时可能报：

```text
specified ability does not exist
```

查看屏幕截图并拉回本地：

```powershell
& $hdc shell snapshot_display -f /data/local/tmp/current.jpeg
& $hdc file recv /data/local/tmp/current.jpeg .\current.jpeg
```

模拟点击：

```powershell
& $hdc shell uitest uiInput click 650 2020
```

模拟滑动：

```powershell
& $hdc shell uitest uiInput swipe 500 1800 500 800
```

模拟返回键：

```powershell
& $hdc shell uitest uiInput keyEvent Back
```

获取 UI 布局：

```powershell
& $hdc shell uitest dumpLayout
```

如果 dumpLayout 输出到设备文件，可以再用：

```powershell
& $hdc file recv /data/local/tmp/layout.json .\layout.json
```

常用调试流程：

```powershell
.\build-frontend.ps1 -HvigorArgs assembleHap,--no-daemon
$hdc = 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
& $hdc list targets
& $hdc uninstall com.example.myapplication
& $hdc install -r .\entry\build\default\outputs\default\app\entry-default.hap
& $hdc shell aa start -a EntryAbility -b com.example.myapplication -m entry
Start-Sleep -Seconds 8
& $hdc shell snapshot_display -f /data/local/tmp/app.jpeg
& $hdc file recv /data/local/tmp/app.jpeg .\app.jpeg
```

## 10. 已验证过的模拟操作

模拟器启动后：

1. 应用打开后能进入登录页，不再卡在 Splash 的“加载中”。
2. 点击“进入本地账户”后进入 Today 工作台。
3. Today 页面可见专注、任务、统计等内容。
4. Tasks 页面可见快速添加任务卡片。
5. Profile 页面可见“我的”和云同步入口。
6. 云同步页显示：
   - 标题：云同步
   - 默认服务器地址：`http://10.0.2.2:8080`
   - 模拟器提示：`10.0.2.2`
   - 真机提示：填写电脑局域网 IP
   - 后端启动提示：运行 `.\start-backend.ps1`
   - 演示账号：`demo / secret`
7. 白噪音已能听到声音。

曾用点击点位：

```text
进入本地账户：约 x=650, y=2020
```

不同模拟器分辨率下点位可能变化，应优先用截图和 layout dump 判断。

## 11. 论文路径和构建

论文目录：

```text
D:\Study\26sp\arkts\final\report\nku-thesis-template-2020
```

论文主文件：

```text
report/nku-thesis-template-2020/main.tex
```

摘要：

```text
report/nku-thesis-template-2020/abstract.tex
```

正文：

```text
report/nku-thesis-template-2020/course-report.tex
```

生成 PDF：

```text
report/nku-thesis-template-2020/main.pdf
```

论文引用截图：

```text
report/nku-thesis-template-2020/figures/app-today.jpeg
report/nku-thesis-template-2020/figures/app-tasks.jpeg
report/nku-thesis-template-2020/figures/app-profile.jpeg
```

论文结构已按要求写入：

1. 第一章 序论
2. 第二章 工具选型
3. 第三章 系统设计
4. 第四章 系统实现
5. 第五章 总结与展望

要求已覆盖：

- 摘要先写背景和问题，再写解决方法和效果
- 关键词 3 到 5 个
- 目录由 LaTeX 自动生成，非手工输入
- 第三章不贴代码
- 第四章不贴代码，展示运行效果和关键问题解决
- 第五章总结与展望分开

编译命令：

```powershell
Set-Location .\report\nku-thesis-template-2020
xelatex -interaction=nonstopmode main.tex
biber main
xelatex -interaction=nonstopmode main.tex
xelatex -interaction=nonstopmode main.tex
```

已验证：

- `main.pdf` 生成成功
- 未检出 undefined references / undefined citations / rerun cross-references 警告
- `biber` 可能出现 MiKTeX log4cxx 用户日志权限 warning，但不影响 `main.bbl` 生成

## 12. Git、GitHub 和代理

当前远程：

```text
origin  https://github.com/kyc001/focusflow-harmony.git
```

当前分支：

```text
master
```

查看状态：

```powershell
git status -sb
```

推送：

```powershell
git push -u origin master
```

如果使用 HTTPS 远程并需要 7897 代理：

```powershell
git -c http.proxy=http://127.0.0.1:7897 -c https.proxy=http://127.0.0.1:7897 push -u origin master
```

如果使用 SSH 远程并需要 7897 代理，可以使用 Git 自带 `connect.exe`：

```powershell
$env:GIT_SSH_COMMAND = 'ssh -o ProxyCommand="D:/Git/mingw64/bin/connect.exe -H 127.0.0.1:7897 %h %p"'
git push -u origin master
```

如果出现 SSH known_hosts 权限问题：

```text
hostkeys_find_by_key_hostfile: hostkeys_foreach failed for /c/Users/kyc/.ssh/known_hosts: Permission denied
Host key verification failed.
```

处理方式：

- 用授权方式运行 git push
- 或改用 HTTPS 远程和 HTTPS 代理
- 或修复 `C:\Users\kyc\.ssh\known_hosts` 的访问权限

## 13. `.gitignore` 当前策略

已忽略：

```text
/node_modules
/oh_modules
/local.properties
/.idea
**/build
/.hvigor
.cxx
.clangd
.clang-format
.clang-tidy
**/.test
/.appanalyzer
focus-server/data/
focus-server/target/
focus-server/backend-smoke.*.log
/backend-*-smoke.*.log
/eval_*.*
/layout_*.json
/report/nku-thesis-template-2020/*.aux
/report/nku-thesis-template-2020/*.bbl
/report/nku-thesis-template-2020/*.bcf
/report/nku-thesis-template-2020/*.blg
/report/nku-thesis-template-2020/*.log
/report/nku-thesis-template-2020/*.out
/report/nku-thesis-template-2020/*.run.xml
/report/nku-thesis-template-2020/*.toc
/report/nku-thesis-template-2020/pdf-check-*.png
```

已清理过的无用文件：

- `eval_*`
- `layout_*.json`
- `backend-*-smoke.*.log`
- `report/nku-thesis-template-2020/pdf-check-*.png`
- LaTeX 中间文件
- `.hvigor`
- 根 `build`
- `entry/build`
- `entry/.preview`
- `focus-server/target`
- 旧根目录 `白噪音/*.mp3`

保留文件：

- `report/nku-thesis-template-2020/main.pdf`
- 论文正文和摘要
- 论文引用截图
- `entry/src/main/resources/rawfile/*.mp3`
- 源码、脚本、README

## 14. 已修复问题记录

### 14.1 后端环境脚本语法损坏

问题：

```text
setup-backend-env.ps1 语法坏了，导致后端测试被脚本拦住。
```

处理：

- 重写为有效 PowerShell
- 自动选择可用 JDK，优先项目本地 JDK，回退到 `D:\jdk` 或 DevEco Studio JBR
- 使用项目本地 Maven
- 从 PATH 移除损坏的 Oracle `javapath`
- dot-source 后可直接运行 `mvn test`

验证：

```powershell
. .\setup-backend-env.ps1
Set-Location .\focus-server
mvn test
```

结果：通过。

### 14.7 Navigation 路由评分点

问题：

```text
早期个人页详情使用 Tabs + Stack 条件渲染浮层，不满足“最新 Navigation 方式跳转”的评分点。
```

处理：

- `Index.ets` 外层使用 `Navigation(this.navStack)`
- 资料库、复盘统计、云同步和设置入口调用 `pushPathByName`
- 目标页面通过 `NavDestination` 承载
- 返回按钮调用 `navStack.pop()`

验证：

```powershell
.\build-frontend.ps1 -HvigorArgs assembleHap,--no-daemon
```

结果：通过。

### 14.8 TaskPool 复盘统计优化

问题：

```text
复盘页会反复计算本周统计、项目占比、连续学习天数和植物解锁状态；当番茄记录增多时，主线程重复扫描数组会影响页面响应。
```

处理：

- `FocusStore.ets` 新增 `@Concurrent` 统计函数
- 数据刷新后使用 `taskpool.execute` 后台生成 `ReviewStats` 快照
- 页面读取预计算快照，避免构建 UI 时重复聚合
- TaskPool 执行失败时回退到同步计算，保证统计页面可用

验证：

```powershell
.\build-frontend.ps1
```

结果：`PackageApp / SignApp / assembleApp` 全部通过。

### 14.9 双向同步重复番茄记录

问题：

```text
拉取服务端番茄记录时如果直接 insert，多次同步可能产生重复专注记录，影响复盘统计。
```

处理：

- 客户端 `pomodoros` 表增加 `client_request_id`
- 本地创建番茄记录时生成稳定 `clientRequestId`
- 服务端拉取番茄记录时按 `clientRequestId` 查询并 upsert
- 同步推送保留本地 `clientRequestId`，让前后端幂等标识一致

验证：

```powershell
.\build-frontend.ps1 -HvigorArgs assembleHap,--no-daemon
```

结果：通过。

### 14.2 前端 PackageApp 被系统 Java 注册表卡住

问题：

```text
ArkTS/PackageHap 通过，最终 PackageApp 被系统 Java 注册表卡住。
```

处理：

- 新增 `build-frontend.ps1`
- 强制使用 DevEco Studio JBR
- 从 PATH 移除 Oracle javapath

验证：

```powershell
.\build-frontend.ps1
```

结果：`PackageApp / SignApp / assembleApp` 全部通过。

### 14.3 应用启动卡在 Splash

问题：

```text
应用启动后停在 Splash 的“加载中...”
```

处理：

- `EntryAbility.ets` 从 `windowStage.loadContent('pages/Splash')`
- 改为 `windowStage.loadContent('pages/Index')`

结果：

- 模拟器启动后进入登录页
- 不再卡 Splash

### 14.4 白噪音无法正常加载

问题：

- 中文 rawfile 文件名存在加载兼容风险
- AVPlayer 状态切换未等待充分
- raw fd 释放不完整

处理：

- 资源改为：
  - `outdoor.mp3`
  - `ocean.mp3`
  - `cricket.mp3`
- 播放时等待 `initialized` 和 `prepared`
- 停止时释放 player 并关闭 raw fd

结果：

- 已听到声音

### 14.5 默认项目硬编码

问题：

- 快速添加任务和资源默认项目曾硬编码某个项目 id

处理：

- 优先选择名为 `移动开发` 的项目
- 找不到则取第一个项目作为 fallback
- UI 高亮实际 fallback 项目

### 14.6 云同步地址提示

问题：

- 旧版本提示里有固定局域网 IP
- 模拟器和真机使用方式不清楚

处理：

- 默认模拟器地址改为 `http://10.0.2.2:8080`
- 真机提示改为填写电脑局域网 IP
- 页面提示运行 `.\start-backend.ps1`
- 保留 demo/secret 提示

### 14.7 调试 GET 登录接口

曾短暂添加过 `GET /api/user/login` 用于设备调试，后续已移除。最终保留正式接口：

```text
POST /api/user/login
```

原因：

- GET URL 会暴露用户名和密码
- 不适合作为最终版本

## 15. 常用完整流程

### 15.1 从零启动后端并让模拟器同步

```powershell
Set-Location D:\Study\26sp\arkts\final
.\start-backend.ps1
```

模拟器前端同步地址填：

```text
http://10.0.2.2:8080
```

账号：

```text
demo / secret
```

### 15.2 快速验证后端

```powershell
Set-Location D:\Study\26sp\arkts\final
. .\setup-backend-env.ps1
Set-Location .\focus-server
mvn test
```

### 15.3 构建前端并安装到模拟器

```powershell
Set-Location D:\Study\26sp\arkts\final
.\build-frontend.ps1 -HvigorArgs assembleHap,--no-daemon

$hdc = 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
& $hdc list targets
& $hdc uninstall com.example.myapplication
& $hdc install -r .\entry\build\default\outputs\default\app\entry-default.hap
& $hdc shell aa start -a EntryAbility -b com.example.myapplication -m entry
```

### 15.4 完整前端打包

```powershell
Set-Location D:\Study\26sp\arkts\final
.\build-frontend.ps1
```

### 15.5 生成论文 PDF

```powershell
Set-Location D:\Study\26sp\arkts\final\report\nku-thesis-template-2020
xelatex -interaction=nonstopmode main.tex
biber main
xelatex -interaction=nonstopmode main.tex
xelatex -interaction=nonstopmode main.tex
```

## 16. 安全注意事项

不要提交：

- `C:\Users\kyc\.codex\auth.json`
- `C:\Users\kyc\.codex\config.toml`
- OpenAI key
- 自定义 AI 服务 key
- GitHub token
- SSH 私钥
- 数据库真实生产密码
- `.env`
- `entry/src/main/resources/rawfile/ai-env.json`
- 任何 `sk-*`、`tp-*`、`ghp_*`、`github_pat_*` 格式密钥

当前文档不记录任何外部 API key 明文。

推送 GitHub 前建议扫描：

```powershell
rg -n "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]+|api[_-]?key|token|secret|password" -S --glob '!oh_modules/**' --glob '!node_modules/**' --glob '!**/build/**' --glob '!focus-server/target/**'
```

如果扫描命中 `.env` 或 `ai-env.json`，说明扫描命令没有排除本地配置文件。真实密钥不能进入 Git 索引。

## 17. 当前仍需关注的点

1. ArkTS deprecated warning 不阻塞，但后续可逐步替换。
2. `signingConfigs` 未配置，发布正式包前需要配置签名。
3. `focus-server/target` 以前被 Git 跟踪过，现在已加入 `.gitignore` 并清理，后续提交会从仓库删除。
4. 旧根目录 `白噪音/*.mp3` 已清理，实际运行资源在 `entry/src/main/resources/rawfile/`。
5. 如果重新构建后生成 `eval_*`、`layout_*.json`、LaTeX 中间文件，它们已被 `.gitignore` 忽略。
