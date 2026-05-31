# FocusFlow Harmony

FocusFlow Harmony 是一个面向学习和深度工作的 HarmonyOS 专注效率应用。项目使用 ArkTS/ArkUI 构建移动端体验，使用 Spring Boot + MyBatis 提供后端同步服务，并支持 MySQL 与 H2 两种数据库运行模式。

这个项目不是一个静态展示 Demo，而是一个包含前端、本地数据、后端接口、数据库持久化、云同步和课程论文材料的完整闭环系统。用户可以在移动端完成任务规划、番茄钟专注、白噪音播放、复盘统计和后端同步。

## 项目特性

- HarmonyOS 原生前端：基于 ArkTS、ArkUI、RDB、Preferences、AVPlayer、ArkWeb。
- 专注工作流闭环：任务规划、今日看板、番茄钟、专注记录、复盘统计。
- 本地优先：核心数据先写入 HarmonyOS RDB，本地账户可离线使用。
- 后端同步：Spring Boot + MyBatis 提供登录、项目、任务、番茄钟、统计、同步接口。
- 数据库可切换：默认 MySQL，支持 H2 文件数据库快速演示和测试。
- 白噪音播放：支持室外、海边、虫鸣三类本地 rawfile 音频。
- 移动端体验优化：快速添加任务、默认项目兜底、云同步地址提示、模拟器/真机连接指引。
- 课程论文材料完整：包含 LaTeX 论文正文、摘要、运行截图和最终 PDF。

## 功能概览

### 今日看板

今日页是应用的主工作台，用于快速查看当天任务、专注状态和关键统计。页面将任务、番茄钟和复盘数据集中呈现，减少用户在多个页面之间切换的成本。

主要能力：

- 今日任务聚合
- 快速添加任务
- 默认项目自动归类
- 专注入口
- 当天完成情况展示
- 轻量统计反馈

### 任务管理

任务模块面向学习和课程项目管理，支持任务的创建、编辑、完成、删除和恢复。任务支持优先级、截止时间、标签、子任务、项目归属等字段，便于用户把课程作业、实验、论文、复习计划拆解为可执行事项。

主要能力：

- 快速添加任务
- 项目归类
- 优先级管理
- 截止时间
- 标签和子任务
- 软删除和恢复
- 与番茄钟记录关联

### 番茄钟专注

专注模块用于把任务转化为实际执行时间。用户可以选择任务开始专注，完成后写入番茄钟记录，并累计到任务和统计数据中。

主要能力：

- 内嵌专注页
- 独立 FocusAbility 专注窗口
- 完成/中断记录
- 专注时长统计
- 与任务 pomodoroCount 联动
- 本地记录和后端同步

### 白噪音

应用内置三类本地白噪音资源：

- `outdoor.mp3`
- `ocean.mp3`
- `cricket.mp3`

白噪音服务位于：

```text
entry/src/main/ets/services/FocusAmbientService.ets
```

当前实现使用 `resourceManager.getRawFdSync` 读取 rawfile，并通过 `AVPlayer` 播放。播放流程会等待播放器进入 `initialized` 和 `prepared` 状态，停止时释放 player 并关闭 raw fd，避免资源泄漏和加载失败。

### 复盘统计

复盘统计用于让用户看到专注行为的结果，而不是只记录任务清单。统计数据来自本地番茄钟记录和任务完成情况，也可以同步到后端数据库。

主要能力：

- 本周专注时长
- 项目占比
- 任务完成率
- 专注中断情况
- 连续打卡反馈
- 图表化展示

### 云同步

云同步模块把本地 RDB 数据与后端数据库进行双向同步。移动端登录后会保存用户标识，并通过同步接口拉取和推送项目、任务、番茄钟记录。

模拟器默认后端地址：

```text
http://10.0.2.2:8080
```

说明：

- HarmonyOS 模拟器访问宿主机后端使用 `10.0.2.2`。
- 真机调试时需要填写电脑局域网 IP，例如 `http://192.168.x.x:8080`。
- 后端默认运行在 `http://localhost:8080`。

## 技术栈

### 前端

- HarmonyOS
- ArkTS
- ArkUI
- RDB
- Preferences
- AVPlayer
- ArkWeb
- UIAbility / ExtensionAbility

### 后端

- Java 17
- Spring Boot 3.2
- MyBatis
- MySQL
- H2
- Maven

### 工程工具

- DevEco Studio
- Hvigor
- JDK 21
- Maven 3.9.10
- HDC
- LaTeX / XeLaTeX / Biber

## 架构设计

项目整体采用“移动端本地优先 + 后端同步”的架构。

```text
HarmonyOS ArkTS App
        |
        | 本地读写
        v
HarmonyOS RDB / Preferences
        |
        | 登录与同步 HTTP API
        v
Spring Boot Backend
        |
        | MyBatis Mapper
        v
MySQL / H2 Database
```

### 前端分层

前端按照接近 MVVM 的方式组织：

```text
entry/src/main/ets
├─ pages/         页面和交互入口
├─ services/      数据库、同步、设置、白噪音、原生能力封装
├─ models/        前端数据模型
├─ repository/    认证和本地持久化入口
├─ data/          种子数据
└─ utils/         设计 token 和格式化工具
```

核心职责：

- View：`pages/Index.ets`、`pages/FocusSolo.ets`
- ViewModel/Store：`services/FocusStore.ets`
- Model：`models/FocusModels.ets`
- Local Data：`services/FocusDatabase.ets`
- Remote Sync：`services/FocusSyncService.ets`
- Native Ability：`services/FocusNativeServices.ets`
- Ambient Audio：`services/FocusAmbientService.ets`

### 后端分层

后端使用 Spring Boot 常规分层：

```text
focus-server/src/main/java/com/focus/server
├─ controller/    REST API
├─ mapper/        MyBatis Mapper 接口
├─ entity/        数据库实体
├─ dto/           请求和响应对象
├─ common/        Result、HashUtil 等通用类
└─ config/        CORS 等配置
```

资源文件：

```text
focus-server/src/main/resources
├─ application.yml          H2 默认配置
├─ application-mysql.yml    MySQL profile 配置
├─ init.sql                 H2 初始化 SQL
├─ init-mysql.sql           MySQL 初始化 SQL
└─ mapper/*.xml             MyBatis SQL 映射
```

## 项目结构

```text
.
├─ AppScope/
├─ entry/
│  └─ src/main/
│     ├─ ets/
│     │  ├─ data/
│     │  ├─ entryability/
│     │  ├─ focusability/
│     │  ├─ formpages/
│     │  ├─ models/
│     │  ├─ pages/
│     │  ├─ repository/
│     │  ├─ services/
│     │  └─ utils/
│     └─ resources/
│        └─ rawfile/
├─ focus-server/
│  └─ src/main/
│     ├─ java/com/focus/server/
│     └─ resources/
├─ report/
│  └─ nku-thesis-template-2020/
├─ tools/
│  ├─ jdk-21/
│  └─ maven/
├─ build-frontend.ps1
├─ setup-backend-env.ps1
├─ start-backend.ps1
└─ PROJECT_CONTEXT.md
```

## 环境要求

### 前端

- Windows
- DevEco Studio
- HarmonyOS SDK
- 可用模拟器或真机

项目脚本默认 DevEco Studio 路径：

```text
C:\Program Files\Huawei\DevEco Studio
```

HDC 路径：

```text
C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe
```

### 后端

项目自带后端构建工具：

```text
tools/jdk-21
tools/maven
```

因此后端不依赖系统 Java 和系统 Maven。推荐使用项目脚本设置环境，避免版本不一致。

## 快速开始

### 1. 克隆项目

```powershell
git clone https://github.com/kyc001/focusflow-harmony.git
cd focusflow-harmony
```

### 2. 启动后端

默认使用 MySQL：

```powershell
.\start-backend.ps1
```

首次使用 MySQL 前，需要在本机 MySQL 中执行：

```text
focus-server/src/main/resources/init-mysql.sql
```

该 SQL 会创建 `focus_db`、基础表结构和演示账号。

如果只是快速演示或接口测试，可以使用 H2：

```powershell
.\start-backend.ps1 -DbProfile h2
```

后端地址：

```text
http://localhost:8080
```

演示账号：

```text
username: demo
password: secret
```

### 3. 构建前端

推荐使用项目脚本：

```powershell
.\build-frontend.ps1
```

该脚本会强制使用 DevEco Studio 自带 JBR，并从 PATH 中移除 Oracle `javapath`，用于规避 `PackageApp` 阶段被系统 Java 注册表问题卡住的情况。

只构建 HAP：

```powershell
.\build-frontend.ps1 -HvigorArgs assembleHap,--no-daemon
```

完整构建成功后会看到：

```text
BUILD SUCCESSFUL
Finished ::PackageApp
Finished ::SignApp
Finished ::assembleApp
```

### 4. 安装到模拟器

```powershell
$hdc = 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
& $hdc list targets
& $hdc install -r .\entry\build\default\outputs\default\app\entry-default.hap
```

如需干净安装：

```powershell
& $hdc uninstall com.example.myapplication
& $hdc install -r .\entry\build\default\outputs\default\app\entry-default.hap
```

启动应用：

```powershell
& $hdc shell aa start -a EntryAbility -b com.example.myapplication -m entry
```

注意必须带 `-m entry`，否则可能出现 `specified ability does not exist`。

## 后端开发

初始化环境：

```powershell
. .\setup-backend-env.ps1
```

运行测试：

```powershell
cd focus-server
mvn test
```

打包：

```powershell
mvn clean package -DskipTests
```

直接运行 H2：

```powershell
java -jar target\focus-server-0.0.1-SNAPSHOT.jar
```

直接运行 MySQL profile：

```powershell
java -jar target\focus-server-0.0.1-SNAPSHOT.jar --spring.profiles.active=mysql
```

## API 概览

基础地址：

```text
http://localhost:8080
```

主要接口：

```text
POST   /api/user/login
POST   /api/user/register

GET    /api/projects
POST   /api/projects
PUT    /api/projects/{id}
DELETE /api/projects/{id}

GET    /api/tasks
POST   /api/tasks
PUT    /api/tasks/{id}
DELETE /api/tasks/{id}

GET    /api/pomodoros
POST   /api/pomodoros

GET    /api/stats/summary

POST   /api/sync/pull
POST   /api/sync/push
```

多数业务接口通过请求头识别用户：

```text
X-User-Id: 1
```

后端响应统一使用 `Result<T>` 包装。Jackson 使用 `SNAKE_CASE` 输出字段，前端同步服务已兼容 snake_case 和 camelCase。

## 数据库说明

### MySQL

MySQL profile 配置：

```text
focus-server/src/main/resources/application-mysql.yml
```

初始化脚本：

```text
focus-server/src/main/resources/init-mysql.sql
```

默认数据库名：

```text
focus_db
```

公开部署时建议将数据库用户名和密码改为环境变量或外部配置，不要把真实生产密码提交到仓库。

### H2

H2 配置：

```text
focus-server/src/main/resources/application.yml
```

H2 控制台：

```text
http://localhost:8080/h2-console
```

连接参数：

```text
JDBC URL: jdbc:h2:file:./data/focus_db
User: sa
Password: 留空
```

H2 数据文件位于：

```text
focus-server/data/
```

该目录已被 `.gitignore` 忽略。

## 模拟器调试

查看设备：

```powershell
$hdc = 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
& $hdc list targets
```

截图：

```powershell
& $hdc shell snapshot_display -f /data/local/tmp/current.jpeg
& $hdc file recv /data/local/tmp/current.jpeg .\current.jpeg
```

点击：

```powershell
& $hdc shell uitest uiInput click 650 2020
```

滑动：

```powershell
& $hdc shell uitest uiInput swipe 500 1800 500 800
```

返回：

```powershell
& $hdc shell uitest uiInput keyEvent Back
```

Dump UI：

```powershell
& $hdc shell uitest dumpLayout
```

## 运行截图

论文目录中保留了部分运行截图，可用于查看当前界面效果：

```text
report/nku-thesis-template-2020/figures/app-today.jpeg
report/nku-thesis-template-2020/figures/app-tasks.jpeg
report/nku-thesis-template-2020/figures/app-profile.jpeg
```

## 论文材料

论文目录：

```text
report/nku-thesis-template-2020
```

关键文件：

```text
abstract.tex
course-report.tex
main.tex
main.pdf
```

论文结构：

1. 序论
2. 工具选型
3. 系统设计
4. 系统实现
5. 总结与展望

编译命令：

```powershell
cd report\nku-thesis-template-2020
xelatex -interaction=nonstopmode main.tex
biber main
xelatex -interaction=nonstopmode main.tex
xelatex -interaction=nonstopmode main.tex
```

## 已解决的关键问题

### PackageApp Java 注册表问题

现象：

```text
ArkTS / PackageHap 通过，但 PackageApp 被系统 Java 注册表卡住。
```

处理：

- 新增 `build-frontend.ps1`
- 强制使用 DevEco Studio 自带 JBR
- 清理 PATH 中的 Oracle `javapath`

### 启动卡 Splash

现象：

```text
应用启动停在 Splash 的“加载中...”
```

处理：

- `EntryAbility.ets` 直接加载 `pages/Index`
- 避免 deprecated router 跳转导致入口失败

### 白噪音加载失败

处理：

- rawfile 使用 ASCII 文件名
- AVPlayer 播放前等待状态
- 停止时释放 player 和 raw fd

### 云同步地址不清晰

处理：

- 模拟器默认 `http://10.0.2.2:8080`
- 真机提示填写电脑局域网 IP
- 页面提示启动后端和演示账号

## 安全注意事项

公开推送前不要提交：

- OpenAI key
- 自定义 AI 服务 key
- GitHub token
- SSH 私钥
- `C:\Users\kyc\.codex\auth.json`
- `C:\Users\kyc\.codex\config.toml`
- 真实生产数据库密码

建议推送前扫描：

```powershell
rg -n "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]+|api[_-]?key|token|secret|password" -S --glob '!oh_modules/**' --glob '!node_modules/**' --glob '!**/build/**' --glob '!focus-server/target/**'
```

## 更多上下文

本机调试细节、HDC 命令、代理上传方式、论文编译记录和历史问题见：

```text
PROJECT_CONTEXT.md
```
