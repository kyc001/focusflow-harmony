# 知序项目从零学习与答辩文档

这份文档的目标不是简单介绍项目，而是帮助你把它讲成“我理解它是怎么一步步写出来的”。我会先用比较直观的方式解释整体，再把每个目录、每个核心文件、每条数据流和课程知识点对应起来。

项目名称是“知序”，本质上是一个面向学习和深度工作的 HarmonyOS 专注效率应用。它不是只有前端页面的展示 Demo，而是包含：

- HarmonyOS ArkTS 前端应用
- 本地 RDB 数据库
- Preferences 轻量配置存储
- UIAbility、独立 FocusAbility、服务卡片 FormExtensionAbility
- ArkWeb H5 图表
- AVPlayer 白噪音播放
- 网络状态监听
- Spring Boot + MyBatis 后端
- H2 / MySQL 数据库
- 前后端登录、CRUD、同步闭环

一句话概括：

> 用户在鸿蒙 App 里管理任务、开始番茄钟、记录专注结果、查看复盘统计；数据优先保存到本地 RDB，登录后可以通过 Spring Boot 后端同步到数据库。

## 1. 先建立整体直觉

你可以把这个项目想成一个学习助手，它有三层：

```text
第一层：用户看到的界面
  今日、任务、资料、专注、复盘、我的

第二层：前端业务和本地数据
  FocusStore 管状态
  FocusDatabase 读写本地 RDB
  FocusSettingsService / AuthRepository 存轻量配置

第三层：远程后端
  Spring Boot 接收 HTTP 请求
  MyBatis 执行 SQL
  H2 或 MySQL 保存云端数据
```

用户点击“添加任务”的真实过程大致是：

```text
TodayView / QuickAddTaskCard
  -> 回调给 Index.ets
  -> Index 调 focusStore.addTask()
  -> FocusStore 构造 FocusTask 对象
  -> FocusDatabase 写入 tasks 表
  -> FocusStore.refresh() 重新读取本地数据
  -> Index.syncFromStore() 更新 @State
  -> ArkUI 页面自动刷新
```

用户点击“云同步”的过程大致是：

```text
SyncDetailOverlay
  -> focusSyncService.syncBidirectional()
  -> pullFromServer(lastServerTime)
  -> mergeServerData()
  -> getProjectsForSync / getTasksForSync / getPomodorosForSync
  -> pushToServer()
  -> 后端 SyncController
  -> MyBatis Mapper
  -> H2 / MySQL
```

这就是项目最核心的闭环：页面操作 -> 本地数据库 -> 后端接口 -> 远程数据库。

## 2. 项目目录总览

根目录主要内容如下：

```text
AppScope/
  应用级配置，例如 bundleName、图标、版本号。

entry/
  HarmonyOS 前端主 module，ArkTS 代码、资源、Ability 配置都在这里。

focus-server/
  Spring Boot 后端，包含 Controller、Mapper、Entity、DTO、SQL 配置。

report/
  论文、答辩材料、截图等交付材料。

build-frontend.ps1
  前端构建脚本，调用 Hvigor 构建 HAP / APP。

start-backend.ps1
  后端启动脚本，负责选择 JDK/Maven，打包并运行 Spring Boot。

setup-backend-env.ps1
  后端环境初始化脚本。

README.md / PROJECT_CONTEXT.md
  项目说明和调试上下文。
```

## 3. HarmonyOS 应用配置

### 3.1 AppScope/app.json5

位置：

```text
AppScope/app.json5
```

作用：应用级配置。

关键字段：

```json5
{
  "bundleName": "com.nankai.zhixu",
  "vendor": "nankai",
  "versionCode": 1000000,
  "versionName": "1.0.0",
  "icon": "$media:app_icon",
  "label": "$string:app_name"
}
```

答辩可以这样讲：

> `app.json5` 决定整个应用是谁，比如包名、版本号、应用图标和应用名称。这里的 `bundleName` 是 `com.nankai.zhixu`，后面通过 hdc 启动 Ability 时也会用到它。

### 3.2 entry/src/main/module.json5

位置：

```text
entry/src/main/module.json5
```

作用：entry 模块配置。它告诉系统这个模块有哪些 Ability、页面、权限和设备类型。

核心内容：

- module 名称：`entry`
- 主 Ability：`EntryAbility`
- 支持设备：phone、tablet、2in1
- 权限：
  - `INTERNET`：访问后端和 AI 接口
  - `GET_NETWORK_INFO`：监听网络状态
  - `VIBRATE`：震动提醒
  - `KEEP_BACKGROUND_RUNNING`：专注计时后台保持
  - `NOTIFICATION_CONTROLLER`：通知提醒
- Ability：
  - `EntryAbility`：主应用入口
  - `FocusAbility`：独立专注窗口
- ExtensionAbility：
  - `EntryFormAbility`：服务卡片
  - `EntryBackupAbility`：备份扩展

答辩可以这样讲：

> `module.json5` 是鸿蒙应用层的模块说明书。它把课程里的 Application -> AbilityStage -> UIAbility -> WindowStage -> Page 这条运行链条落到了具体配置里。系统先找到 entry 模块，再找到 mainElement，也就是 `EntryAbility`，然后由它加载页面。

### 3.3 main_pages.json

位置：

```text
entry/src/main/resources/base/profile/main_pages.json
```

内容：

```json
{
  "src": [
    "pages/Splash",
    "pages/Index",
    "pages/FocusSolo"
  ]
}
```

作用：声明系统路由页面。`EntryAbility` 加载 `pages/Splash`，Splash 再跳到 `pages/Index`。`FocusAbility` 加载 `pages/FocusSolo`。

## 4. 前端代码结构

前端代码都在：

```text
entry/src/main/ets
```

按职责分层：

```text
entryability/
  主 UIAbility。

focusability/
  独立专注 UIAbility。

entryformability/
  服务卡片 ExtensionAbility。

pages/
  页面入口，包含 Splash、Index、FocusSolo。

components/
  可复用页面组件，例如 TodayView、TasksView、ReviewView。

services/
  业务服务，例如数据库、同步、设置、白噪音、AI、网络状态。

models/
  前端数据模型。

data/
  初始化种子数据。

repository/
  登录状态仓库。

utils/
  格式化工具、设计 token、路由名。
```

这个结构接近 MVVM：

```text
View:
  pages/*.ets
  components/*.ets

ViewModel / Store:
  services/FocusStore.ets

Model:
  models/FocusModels.ets

Local Data:
  services/FocusDatabase.ets

Remote Data:
  services/FocusSyncService.ets
```

## 5. 应用启动流程

### 5.1 EntryAbility.ets

位置：

```text
entry/src/main/ets/entryability/EntryAbility.ets
```

它继承 `UIAbility`，实现生命周期方法：

- `onCreate`
- `onDestroy`
- `onWindowStageCreate`
- `onWindowStageDestroy`
- `onForeground`
- `onBackground`

最关键的是：

```ts
windowStage.loadContent('pages/Splash')
```

说明主 Ability 创建窗口后先加载 Splash 页面。

答辩可以这样讲：

> `EntryAbility` 是主入口。系统创建 UIAbility 后，会创建 WindowStage，然后我在 `onWindowStageCreate` 中加载 `pages/Splash`。这对应课程里的 UIAbility 生命周期和 WindowStage 页面加载流程。

### 5.2 Splash.ets

位置：

```text
entry/src/main/ets/pages/Splash.ets
```

它是启动页，主要做两件事：

1. 用 `@State showContent` 控制启动动画显示。
2. 2.5 秒后调用：

```ts
this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' })
```

跳转到主页面。

这里的 Splash 不是业务核心，但答辩时可以说：

> 我把启动页和主页拆开，`EntryAbility` 只负责加载首屏，真正业务初始化放在 `Index.ets`，这样入口职责更清晰。

### 5.3 Index.ets

位置：

```text
entry/src/main/ets/pages/Index.ets
```

这是前端最核心的页面，也是整个 App 的“总调度中心”。

它负责：

- 登录态显示
- 初始化数据库、设置、AI、同步服务
- 维护页面 `@State`
- 底部 Tabs
- Navigation 详情页
- 添加任务
- 切换任务状态
- 删除 / 恢复任务
- 添加资料
- AI 提炼资料
- 开始 / 暂停 / 完成 / 中断番茄钟
- 云同步登录和同步

重要状态包括：

```ts
@State isAuthed
@State activeTab
@State tasks
@State records
@State resources
@State settings
@State selectedTaskId
@State timerStatus
@State remainingSeconds
@Provide('pathStack') navStack
```

解释：

- `@State`：组件内部状态，变了会触发 UI 刷新。
- `@Provide('pathStack')`：把 `NavPathStack` 提供给子组件，比如 `ProfileView` 可以用 `@Consume` 拿到它。
- `navStack`：Navigation 页面栈，用来跳转“复盘统计”“学习资源库”“云同步”“设置”等详情页。

初始化入口：

```ts
aboutToAppear() {
  this.remainingSeconds = this.settings.focusMinutes * 60;
  this.initNativeStore();
}
```

`initNativeStore()` 做了这些事：

```text
初始化 RDB 数据库
初始化设置服务
刷新 FocusStore
加载 Preferences 设置
初始化 AuthRepository
初始化 AI 服务
初始化同步服务
初始化网络状态监听
读取当前登录资料
```

这就是 App 从“空壳页面”变成“带数据的应用”的关键。

## 6. 独立专注窗口 FocusAbility

### 6.1 FocusAbility.ets

位置：

```text
entry/src/main/ets/focusability/FocusAbility.ets
```

它也是一个 `UIAbility`，但不是主入口，而是专门用于沉浸式专注页面。

核心点：

```ts
onCreate(want, launchParam) {
  this.parseWant(want);
}

onNewWant(want, launchParam) {
  this.parseWant(want);
}
```

为什么 `onCreate` 和 `onNewWant` 都要解析 Want？

- 第一次启动 Ability 时走 `onCreate`
- 如果 Ability 是 singleton，已经存在时再次启动可能走 `onNewWant`
- 如果只在 `onCreate` 解析参数，热启动时任务标题可能不更新

这正好对应课程知识点：

> 冷启动和热启动都要解析 Want 参数，防止热启动跳转失效。

`parseWant` 把参数写到 `AppStorage`：

```ts
AppStorage.setOrCreate<string>('focus.taskTitle', ...)
AppStorage.setOrCreate<number>('focus.taskId', ...)
```

然后 `FocusSolo.ets` 用 `@StorageProp` 读取：

```ts
@StorageProp('focus.taskId') taskId
@StorageProp('focus.taskTitle') taskTitle
```

这就是跨 Ability 共享简单状态。

### 6.2 FocusSolo.ets

位置：

```text
entry/src/main/ets/pages/FocusSolo.ets
```

它是独立专注页面，负责：

- 显示当前任务
- 计时
- 播放白噪音
- 申请后台延迟任务
- 完成后写入番茄记录
- 发布通知

关键设计：

```ts
private updateTimerFromClock(): void {
  const runningSeconds = Math.floor((Date.now() - this.lastStartedAt) / 1000);
  const elapsed = this.accumulatedSeconds + runningSeconds;
  this.remainingSeconds = this.focusSeconds - elapsed;
}
```

它不是单纯每秒 `remainingSeconds--`，而是用真实时间戳 `Date.now()` 计算经过时间。这样即使系统切后台、定时器不准，回来后也能校正时间。

答辩可以这样讲：

> 计时器的 setInterval 只负责触发刷新，真正时间来源是系统时间戳。这样可以减少后台节流造成的计时漂移。

## 7. 前端数据模型

位置：

```text
entry/src/main/ets/models/FocusModels.ets
```

主要枚举：

- `TaskStatus`
  - `TODO = 0`
  - `DONE = 1`
  - `DELETED = 2`
- `PomodoroStatus`
  - `IDLE`
  - `RUNNING`
  - `PAUSED`
  - `BREAK`
  - `FINISHED`
- `StudyResourceStatus`
  - `ACTIVE`
  - `ARCHIVED`
- `ResourceSummaryStatus`
  - `PENDING`
  - `EXTRACTED`
  - `FAILED`

主要接口：

- `FocusProject`：项目
- `FocusTask`：任务
- `StudyResource`：学习资料
- `PomodoroRecord`：番茄记录
- `FocusSettings`：专注设置
- `ReviewStats`：复盘统计快照
- `AiCoachSettings`：AI 配置
- `AiCoachAdvice`：AI 建议
- `ResourceInsight`：资料提炼结果

答辩可以这样讲：

> `FocusModels.ets` 相当于前端的数据字典。所有页面和服务都引用这里的类型，避免每个文件自己猜字段。

## 8. 种子数据

位置：

```text
entry/src/main/ets/data/SeedData.ets
```

作用：第一次启动时，如果本地数据库为空，就插入演示数据。

包含：

- 默认项目：数据库、科研、协程演讲、移动开发
- 默认任务：实验报告复盘、数据库总结、论文阅读等
- 默认番茄记录
- 默认学习资料
- 默认专注设置
- 学习森林植物解锁规则

这能保证 App 第一次打开时不是空白页面，方便演示和答辩。

## 9. 本地数据库 FocusDatabase

位置：

```text
entry/src/main/ets/services/FocusDatabase.ets
```

这是前端本地持久化的核心文件，使用 HarmonyOS RDB，也就是关系型数据库，本质上可以理解为鸿蒙侧的 SQLite。

数据库名：

```ts
const DB_NAME = 'focus.db';
const DB_VERSION = 6;
```

### 9.1 表结构

它创建四张表：

```text
projects
  项目表

tasks
  任务表

pomodoros
  番茄记录表

study_resources
  学习资料表
```

其中同步相关字段很重要：

```text
updated_at
  记录最后修改时间，用于冲突判断。

is_deleted
  删除墓碑。删除后不立即物理删除，而是标记删除，用于同步给另一端。

client_request_id
  客户端生成的稳定请求 ID，用于避免重复提交导致重复插入。

dirty
  本地是否有未同步修改。1 表示需要 push，0 表示已经同步。
```

### 9.2 为什么要加 dirty？

如果没有 `dirty`，每次同步都要把本地所有项目、任务、番茄记录全量上传，数据多了就很浪费。

现在的策略是：

```text
用户本地新增或修改
  -> dirty = 1

同步 push 成功
  -> markTasksSynced()
  -> dirty = 0

下一次同步
  -> 只上传 dirty = 1 的数据
```

### 9.3 为什么要加 is_deleted？

如果用户删除一个任务，本地直接删掉，那么同步时服务器不知道“这个任务被删了”。下一次 pull 服务器旧数据时，它可能又回来了。

所以项目采用软删除：

```text
删除任务
  -> status = DELETED
  -> is_deleted = 1
  -> dirty = 1

同步到服务器
  -> 服务器也标记 is_deleted = 1
```

答辩可以这样讲：

> 删除不是直接删数据库行，而是保留一条删除墓碑。这样云同步时能把删除动作同步出去，避免旧数据复活。

### 9.4 为什么要 client_request_id？

POST 请求可能因为网络重试重复提交。如果每次都插入一条新记录，就会出现重复任务或重复番茄。

项目做法：

- 本地任务插入后生成 `client-task-${id}`
- 番茄记录生成稳定的 `local-pomo-...`
- 同步和后端插入时先按 `client_request_id` 查重
- 查到就更新，不查到才新增

这对应课程里的：

> 解决 POST 非幂等重复提交问题。

### 9.5 RDB ResultSet 释放

`FocusDatabase` 每次查询后都用：

```ts
try {
  while (resultSet.goToNextRow()) {
    ...
  }
} finally {
  resultSet.close();
}
```

这是 RDB 的好习惯。`ResultSet` 用完要释放，否则会占用资源。

## 10. 状态中心 FocusStore

位置：

```text
entry/src/main/ets/services/FocusStore.ets
```

它是前端业务状态中心。

主要字段：

```ts
projects
tasks
pomodoros
resources
settings
plants
reviewStats
```

主要方法：

- `refresh()`：从 RDB 重新读取全部数据
- `addTask()`：新增任务
- `toggleTask()`：切换任务完成状态
- `softDeleteTask()`：软删除任务
- `restoreTask()`：恢复任务
- `recordPomodoro()`：写入番茄记录
- `addStudyResource()`：新增资料
- `updateResourceInsight()`：保存 AI 提炼结果
- `createTaskFromResource()`：根据资料生成任务
- `completedPomodoros()` 等：读取统计快照

### 10.1 Store 为什么存在？

如果页面直接操作数据库，页面会很乱：

```text
页面既要显示 UI
又要拼数据对象
又要写 SQL
又要刷新统计
```

`FocusStore` 把业务动作封装起来。页面只说“我要添加任务”，具体怎么写数据库、怎么刷新统计由 Store 处理。

### 10.2 TaskPool 统计优化

`FocusStore` 有一个 `@Concurrent` 函数：

```ts
@Concurrent
function buildReviewStatsSnapshot(...)
```

然后在 `refreshReviewStats()` 中：

```ts
taskpool.execute(buildReviewStatsSnapshot, ...)
```

作用：把复盘统计计算放到后台任务池，减少主线程压力。

如果 TaskPool 失败，它会回退到同步计算：

```ts
catch {
  this.reviewStats = buildReviewStatsSnapshot(...)
}
```

答辩可以这样讲：

> 复盘页需要统计本周时长、项目占比、连续天数和植物解锁。如果每次 UI 构建都重新扫描番茄记录，会增加主线程压力。所以我在数据刷新后用 TaskPool 预计算统计快照，页面只读快照。

这对应课程里的：

> 主线程和后台线程隔离，使用 TaskPool 做后台计算。

## 11. Preferences 轻量存储

项目里多个服务使用 Preferences：

### 11.1 AuthRepository.ets

位置：

```text
entry/src/main/ets/repository/AuthRepository.ets
```

存储本地登录状态：

- token
- username
- nickname
- guest

它支持：

- `loginLocal()`
- `guest()`
- `currentProfile()`
- `logout()`

这里的本地登录不是后端登录，只是让 App 有一个本地账户/游客模式。

### 11.2 FocusSettingsService.ets

位置：

```text
entry/src/main/ets/services/FocusSettingsService.ets
```

存储专注设置：

- 专注时长
- 短休时长
- 长休时长
- 主题色
- 白噪音类型
- 通知开关

它有 `normalize()`，会限制时长范围，例如专注时间 10 到 60 分钟。

### 11.3 FocusSyncService.ets

存储同步配置：

- 后端地址
- userId
- token
- username
- nickname
- lastServerTime

### 11.4 FocusAiCoachService.ets

存储 AI 配置：

- endpoint
- model
- apiKey
- enabled

注意：Preferences 不是加密保险箱，`rawfile/ai-env.json` 也会打进 HAP。答辩时不要说“已经加密保存”，应该说：

> 当前项目使用本地配置注入，敏感配置不进入 Git；正式生产环境还需要更安全的密钥管理方案。

## 12. 白噪音播放

位置：

```text
entry/src/main/ets/services/FocusAmbientService.ets
```

资源位置：

```text
entry/src/main/resources/rawfile/outdoor.mp3
entry/src/main/resources/rawfile/ocean.mp3
entry/src/main/resources/rawfile/cricket.mp3
```

流程：

```text
用户选择白噪音
  -> settings.noise 保存到 Preferences

开始专注
  -> focusAmbientService.play()
  -> resourceManager.getRawFdSync()
  -> AVPlayer.fdSrc
  -> 等 initialized
  -> prepare()
  -> 等 prepared
  -> play()
  -> loop = true

停止专注
  -> stop()
  -> release()
  -> closeRawFdSync()
```

关键点：

- rawfile 文件名使用 ASCII，避免资源加载兼容问题
- 等待 AVPlayer 状态再播放
- 停止时释放 player 和 raw fd

答辩可以这样讲：

> 白噪音使用 AVPlayer 播放 rawfile 本地音频。为了避免资源泄漏，停止时会 release player，并关闭 raw fd。

## 13. 网络状态监听

位置：

```text
entry/src/main/ets/services/FocusNetworkService.ets
```

使用：

```ts
connection.createNetConnection()
connection.hasDefaultNet()
```

监听：

- `netAvailable`
- `netLost`
- `netUnavailable`

作用：

- 云同步页显示网络状态
- 离线时禁用登录/同步按钮
- 网络监听不可用时仍允许手动同步

对应课程知识点：

> connection 模块、NetConnection 监听器注册、网络状态订阅。

## 14. 通知和后台任务

位置：

```text
entry/src/main/ets/services/FocusNativeServices.ets
```

包含两个类：

```text
FocusNotificationService
  申请通知权限
  发布基础通知

FocusBackgroundService
  申请后台延迟任务
  取消后台延迟任务
```

专注开始时：

```text
FocusBackgroundService.startPomodoroGuard()
```

番茄完成时：

```text
FocusNotificationService.publishBasic()
```

答辩可以这样讲：

> 计时主逻辑仍在页面中，但开始专注时会申请后台延迟任务，完成后发布通知提醒。

## 15. ArkWeb 混合开发

前端复盘页：

```text
entry/src/main/ets/components/ReviewView.ets
```

H5 页面：

```text
entry/src/main/resources/rawfile/charts/index.html
```

`ReviewView` 里使用：

```ts
Web({ src: $rawfile('charts/index.html'), controller: this.webController })
  .javaScriptAccess(true)
  .domStorageAccess(true)
  .javaScriptProxy({
    object: this.reviewBridge,
    name: 'nativeBridge',
    methodList: ['getStats', 'exportPng', 'shareReport']
  })
```

`ReviewBridge` 提供：

- `getStats()`
- `exportPng()`
- `shareReport()`

H5 通过 `nativeBridge.getStats()` 读取 ArkTS 统计数据。

答辩可以这样讲：

> 复盘页展示了 ArkWeb 混合开发：H5 资源放在 rawfile，ArkTS 通过 `javaScriptProxy` 注入对象，网页端调用 `nativeBridge.getStats()` 获取本地统计数据。

注意：

> ArkWeb 在预览器里通常不生效，需要模拟器或真机调试。

## 16. Navigation 页面栈

路由名：

```text
entry/src/main/ets/utils/FocusRoutes.ets
```

包含：

- `review-detail`
- `resource-detail`
- `sync-detail`
- `settings-detail`

在 `Index.ets`：

```ts
@Provide('pathStack') navStack: NavPathStack = new NavPathStack();

Navigation(this.navStack) {
  ...
}
.navDestination(this.buildDestination)
```

在 `ProfileView.ets`：

```ts
@Consume('pathStack') navStack
this.navStack.pushPathByName(routeName, null)
```

含义：

- `Index` 提供页面栈
- `ProfileView` 消费页面栈
- 点击“复盘统计 / 学习资源库 / 云同步 / 设置”时 push 目标页面
- 返回时 `navStack.pop()`

这对应课程知识点：

> API 10+ 推荐 Navigation 组件，使用 NavPathStack 动态管理页面栈。

## 17. 主要页面组件

### 17.1 TodayView.ets

位置：

```text
entry/src/main/ets/components/TodayView.ets
```

功能：

- 今日首页
- 展示“先做这一件”
- 展示今日任务
- 快速添加任务
- 开启通知
- 开始专注

数据来自 props：

- `tasks`
- `selectedTask`
- `totalFocusMinutes`
- `notificationReady`

动作通过回调给 `Index`：

- `onStartFocus`
- `onToggleTask`
- `onDeleteTask`
- `onRestoreTask`
- `onAddTask`
- `onRequestNotification`

### 17.2 TasksView.ets

位置：

```text
entry/src/main/ets/components/TasksView.ets
```

功能：

- 任务管理
- 搜索
- 按项目筛选
- 按优先级/四象限筛选
- 回收站
- 开始番茄
- 删除/恢复任务

内部状态：

- `searchText`
- `filterProjectId`
- `filterPriority`
- `showRecycle`

### 17.3 FocusSessionView.ets

位置：

```text
entry/src/main/ets/components/FocusSessionView.ets
```

功能：

- 专注计时卡片
- 开始/暂停/完成/中断/重置
- AI 学习助手卡片
- AI 设置卡片
- 专注时长设置
- 白噪音设置
- 最近番茄历史

它本身不直接写数据库，而是把动作回调给 `Index.ets`。

### 17.4 ResourcesView.ets

位置：

```text
entry/src/main/ets/components/ResourcesView.ets
```

功能：

- 学习资料库
- 备忘录
- 文件导入
- AI 提炼
- 资料归档/恢复
- 从资料生成任务

资料只存本地 RDB，暂未同步到后端数据库。

### 17.5 ReviewView.ets

位置：

```text
entry/src/main/ets/components/ReviewView.ets
```

功能：

- 总专注分钟
- 完成率
- 最长连续天数
- 本周学习时长柱状图
- 项目时间占比
- 完成 vs 中断
- 热力图
- 学习森林
- ArkWeb H5 图表

数据主要来自 `focusStore` 的统计快照。

### 17.6 ProfileView.ets

位置：

```text
entry/src/main/ets/components/ProfileView.ets
```

功能：

- 我的页面
- 展示昵称和模式
- 展示统计摘要
- 菜单入口：
  - 复盘统计
  - 学习资源库
  - 云同步
  - 设置
- 退出登录

它通过 `@Consume('pathStack')` 使用 Navigation 页面栈。

## 18. AI 学习助手

位置：

```text
entry/src/main/ets/services/FocusAiCoachService.ets
```

它做两类请求：

```text
requestAdvice()
  根据任务、项目、番茄记录和设置生成学习建议。

requestResourceInsight()
  根据学习资料生成摘要、要点和下一步任务。
```

请求方式：

```text
HTTP POST
  -> /v1/chat/completions
  -> Authorization: Bearer API_KEY
```

它会构造 prompt，要求 AI 严格返回固定格式，例如：

```text
标题: ...
下一步: ...
安排: ...
风险: ...
```

然后用 `pickLine()` 解析对应字段。

注意：

> 这个 AI 服务不是后端 focus-server 的一部分，而是前端直接请求外部兼容 Chat Completions 的接口。

## 19. 服务卡片

### 19.1 EntryFormAbility.ets

位置：

```text
entry/src/main/ets/entryformability/EntryFormAbility.ets
```

它继承 `FormExtensionAbility`。

主要方法：

- `onAddForm()`：添加卡片时返回绑定数据
- `onUpdateForm()`：更新卡片
- `onFormEvent()`：处理卡片事件
- `onAcquireFormState()`：返回卡片状态

它读取：

```text
FocusFormSnapshotService
```

### 19.2 FocusFormSnapshotService.ets

位置：

```text
entry/src/main/ets/services/FocusFormSnapshotService.ets
```

它把主页当前数据做成一份快照，存入 Preferences：

- 标题
- 副标题
- 今日番茄进度
- 前 3 个待办任务

为什么服务卡片要快照？

> 服务卡片和普通页面不是同一个显示环境，不能随便直接拿页面状态。所以主页每次刷新数据时保存一份轻量快照，卡片读取这份快照。

## 20. 后端整体结构

后端在：

```text
focus-server/
```

结构：

```text
src/main/java/com/focus/server
  FocusServerApplication.java

  controller/
    REST API 控制器

  mapper/
    MyBatis Mapper 接口

  entity/
    数据库实体类

  dto/
    请求和响应对象

  common/
    Result、PageResult、HashUtil、AuthUser

  config/
    CORS 配置、JWT 拦截器

  service/
    JwtService

src/main/resources
  application.yml
  application-mysql.yml
  init.sql
  init-mysql.sql
  mapper/*.xml
```

## 21. 后端依赖和配置

### 21.1 pom.xml

位置：

```text
focus-server/pom.xml
```

主要依赖：

- `spring-boot-starter-web`：提供 REST API
- `mybatis-spring-boot-starter`：集成 MyBatis
- `springdoc-openapi`：Swagger UI
- `mysql-connector-j`：MySQL 连接
- `h2`：H2 演示数据库
- `lombok`：自动生成 getter/setter/构造函数
- `spring-boot-starter-test`：测试

Java 版本：

```xml
<java.version>17</java.version>
```

### 21.2 application.yml

位置：

```text
focus-server/src/main/resources/application.yml
```

默认使用 H2：

```yaml
spring:
  datasource:
    driver-class-name: org.h2.Driver
    url: jdbc:h2:file:./data/focus_db
```

适合快速演示，不依赖本机 MySQL。

### 21.3 application-mysql.yml

位置：

```text
focus-server/src/main/resources/application-mysql.yml
```

使用 MySQL：

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: ${MYSQL_URL:...}
    username: ${MYSQL_USERNAME:root}
    password: ${MYSQL_PASSWORD:}
```

适合正式前后端数据库联调。

### 21.4 Jackson 字段命名

配置里有：

```yaml
jackson:
  property-naming-strategy: SNAKE_CASE
```

后端输出 JSON 时字段会变成下划线形式，例如：

```text
userId -> user_id
updatedAt -> updated_at
```

前端 `FocusSyncService` 同时兼容 camelCase 和 snake_case，所以比较稳。

## 22. 后端启动入口

位置：

```text
focus-server/src/main/java/com/focus/server/FocusServerApplication.java
```

核心注解：

```java
@SpringBootApplication
@MapperScan("com.focus.server.mapper")
```

说明：

- `@SpringBootApplication` 启动 Spring Boot
- `@MapperScan` 扫描 MyBatis Mapper 接口

答辩可以这样讲：

> 后端启动后，Spring 扫描 Controller、Service、Config 等组件，MyBatis 扫描 Mapper 接口，再根据 resources/mapper 下的 XML 找到 SQL。

## 23. 后端鉴权

### 23.1 JwtService.java

位置：

```text
focus-server/src/main/java/com/focus/server/service/JwtService.java
```

功能：

- 创建 JWT
- 验证 JWT 签名
- 检查过期时间
- 从 token 里取 userId

签名算法：

```text
HS256 / HmacSHA256
```

### 23.2 AuthInterceptor.java

位置：

```text
focus-server/src/main/java/com/focus/server/config/AuthInterceptor.java
```

它拦截请求：

```text
Authorization: Bearer <token>
```

验证成功后：

```java
request.setAttribute("authenticatedUserId", userId)
```

业务 Controller 再通过：

```java
AuthUser.id(servletRequest)
```

拿到当前用户 ID。

### 23.3 CorsConfig.java

位置：

```text
focus-server/src/main/java/com/focus/server/config/CorsConfig.java
```

作用：

- 配置 CORS
- 注册 AuthInterceptor
- 放行：
  - `/api/user/login`
  - `/api/user/register`
  - `/api/user/ping`

答辩可以这样讲：

> 登录、注册、ping 不需要 token；其他 `/api/**` 都需要 JWT。这样后端不会信任前端随意传来的 userId，而是从 token 中解析用户身份。

## 24. 后端统一响应

位置：

```text
focus-server/src/main/java/com/focus/server/common/Result.java
```

统一格式：

```json
{
  "code": 200,
  "msg": "ok",
  "data": ...
}
```

好处：

- 前端不用猜响应结构
- 成功、失败、未授权统一处理

## 25. 后端 Controller

### 25.1 UserController.java

位置：

```text
focus-server/src/main/java/com/focus/server/controller/UserController.java
```

接口：

```text
GET  /api/user/ping
POST /api/user/register
POST /api/user/login
```

注册流程：

```text
校验用户名和密码
检查用户名是否存在
SHA-256 哈希密码
插入 users 表
返回 AuthResponse + JWT
```

登录流程：

```text
根据 username 查用户
比较 sha256(password)
生成 JWT
返回 userId、username、nickname、token
```

### 25.2 ProjectController.java

位置：

```text
focus-server/src/main/java/com/focus/server/controller/ProjectController.java
```

接口：

```text
GET    /api/projects
POST   /api/projects
PUT    /api/projects/{id}
DELETE /api/projects/{id}
```

删除是软删除：

```text
is_deleted = 1
updated_at = now
```

### 25.3 TaskController.java

位置：

```text
focus-server/src/main/java/com/focus/server/controller/TaskController.java
```

接口：

```text
GET    /api/tasks
GET    /api/tasks/{id}
POST   /api/tasks
PUT    /api/tasks/{id}
DELETE /api/tasks/{id}
```

支持分页和筛选：

- keyword
- status
- projectId
- page
- pageSize

创建任务时，如果有 `clientRequestId`，会先查重：

```java
taskMapper.findByClientRequestId(userId, request.getClientRequestId())
```

这就是防重复提交。

### 25.4 PomodoroController.java

位置：

```text
focus-server/src/main/java/com/focus/server/controller/PomodoroController.java
```

接口：

```text
GET  /api/pomodoros
POST /api/pomodoros
```

创建番茄记录时：

- 按 `clientRequestId` 查重
- 插入 `pomodoros`
- 如果 completed = 1，则任务的 `pomodoro_count + 1`

### 25.5 StatsController.java

位置：

```text
focus-server/src/main/java/com/focus/server/controller/StatsController.java
```

接口：

```text
GET /api/stats/summary
```

返回：

- 总专注分钟
- 完成番茄数
- 中断番茄数
- streak
- 任务总数

### 25.6 SyncController.java

位置：

```text
focus-server/src/main/java/com/focus/server/controller/SyncController.java
```

接口：

```text
POST /api/sync/pull
POST /api/sync/push
```

这是云同步核心。

#### pull

```text
前端传 since
后端查询 updated_at > since 的 projects/tasks/pomodoros
返回 SyncBundle
```

#### push

```text
前端上传 dirty 数据
后端在事务中批量处理
按 id 或 clientRequestId 查是否存在
不存在就 insert
存在且本次数据更旧就丢弃
存在且本次数据更新就 update
返回 serverTime
```

`push` 加了：

```java
@Transactional
```

说明批量同步要么整体成功，要么失败回滚，避免只写一半。

答辩可以这样讲：

> 同步不是简单覆盖，而是增量同步。客户端用 dirty 标记待上传数据，服务端用 updatedAt 做 Last-Write-Wins 冲突处理，用 clientRequestId 做幂等去重。

## 26. MyBatis 和 SQL

Mapper 接口在：

```text
focus-server/src/main/java/com/focus/server/mapper
```

SQL XML 在：

```text
focus-server/src/main/resources/mapper
```

主要 XML：

- `UserMapper.xml`
- `ProjectMapper.xml`
- `TaskMapper.xml`
- `PomodoroMapper.xml`

举例：`TaskMapper.xml`

- `findPage`：分页查询任务
- `count`：统计数量
- `findUpdatedSince`：增量同步查询
- `findByClientRequestId`：幂等查重
- `insert`：新增任务
- `update`：更新任务
- `softDelete`：软删除
- `increasePomodoro`：番茄计数加一

答辩可以这样讲：

> Controller 不直接写 SQL，而是调用 Mapper。Mapper 接口和 XML 对应，XML 里写具体 SQL。MyBatis 负责把查询结果映射成 Java entity。

## 27. 数据库表设计

后端建表 SQL：

```text
focus-server/src/main/resources/init.sql
focus-server/src/main/resources/init-mysql.sql
```

主要表：

### users

保存用户：

- id
- username
- password_hash
- nickname
- created_at

### projects

保存项目：

- id
- user_id
- name
- color
- icon
- updated_at
- is_deleted

### tasks

保存任务：

- id
- user_id
- title
- note
- project_id
- priority
- due_at
- status
- pomodoro_count
- created_at
- updated_at
- completed_at
- is_deleted
- client_request_id
- tags_json
- subtasks_json

### pomodoros

保存番茄记录：

- id
- user_id
- task_id
- start_at
- duration
- completed
- interrupt_reason
- updated_at
- client_request_id

注意：

> 后端目前同步项目、任务、番茄记录；前端的学习资料 `study_resources` 是本地 RDB 功能，没有进入后端 SQL 表。

## 28. 前后端接口闭环

### 28.1 登录闭环

```text
用户在云同步页输入账号密码
  -> Index.SyncDetailOverlay
  -> focusSyncService.login()
  -> GET /api/user/ping
  -> POST /api/user/login
  -> UserController.login()
  -> UserMapper.findByUsername()
  -> HashUtil.sha256 对比密码
  -> JwtService.createToken()
  -> 返回 token
  -> 前端 Preferences 保存 token
```

### 28.2 同步闭环

```text
用户点击同步数据
  -> focusSyncService.syncBidirectional()
  -> pullFromServer(lastServerTime)
  -> POST /api/sync/pull?since=...
  -> SyncController.pull()
  -> MyBatis 查 updated_at > since
  -> 前端 mergeServerData()
  -> 前端查 dirty = 1 的本地数据
  -> pushToServer()
  -> POST /api/sync/push
  -> SyncController.push()
  -> 后端事务写入
  -> 前端 markSynced()
  -> 保存 serverTime
```

### 28.3 番茄记录闭环

```text
用户开始专注
  -> Index.startPomodoro() 或 FocusSolo.start()
  -> 计时运行

用户完成
  -> completePomodoro() / finish()
  -> focusStore.recordPomodoro()
  -> FocusDatabase.recordPomodoro()
  -> pomodoros 表新增记录
  -> incrementTaskPomodoro()
  -> 复盘统计刷新

用户同步
  -> dirty 番茄记录上传到后端 pomodoros 表
```

## 29. 和课程知识点的对应关系

### ArkTS 语法、声明式 UI

对应文件：

- `pages/Splash.ets`
- `pages/Index.ets`
- `components/*.ets`

体现：

- `@Entry`
- `@Component`
- `@State`
- `@Prop`
- `@Builder`
- `ForEach`
- `if` 条件渲染
- `Column` / `Row` / `Stack` / `GridRow` / `GridCol`

### 组件与状态管理

对应文件：

- `Index.ets`
- `TodayView.ets`
- `TasksView.ets`
- `FocusSessionView.ets`
- `ResourcesView.ets`
- `ProfileView.ets`

体现：

- 父组件 `Index` 保存核心状态
- 子组件用 `@Prop` 接收数据
- 子组件通过回调把事件交给父组件
- `@Provide` / `@Consume` 共享 Navigation 栈
- `@StorageProp` 读取 AppStorage

### APP 编译与组成原理

对应文件：

- `AppScope/app.json5`
- `entry/src/main/module.json5`
- `build-profile.json5`
- `entry/build-profile.json5`
- `build-frontend.ps1`

体现：

- entry module
- HAP 构建
- Ability 配置
- 资源打包

### UIAbility 生命周期与窗口

对应文件：

- `EntryAbility.ets`
- `FocusAbility.ets`

体现：

- `onCreate`
- `onWindowStageCreate`
- `loadContent`
- `onForeground`
- `onBackground`

### 启动模式和 Want 参数

对应文件：

- `module.json5`
- `FocusAbility.ets`
- `Index.ets`
- `FocusSolo.ets`

体现：

- `FocusAbility` 配置 `launchType: singleton`
- `Index` 用 `context.startAbility()` 启动
- Want parameters 传 `taskId`、`taskTitle`
- `onCreate` 和 `onNewWant` 都解析参数
- `AppStorage` 传递到 `FocusSolo`

### 数据同步：AppStorage / LocalStorage / EventHub

项目主要用：

- `AppStorage`
- `Preferences`
- `@Provide` / `@Consume`

没有重点使用 EventHub。答辩时可以说：

> 本项目跨 Ability 简单数据使用 AppStorage；持久配置使用 Preferences；组件树内部共享 Navigation 栈使用 Provide/Consume。

### 线程并发 TaskPool

对应文件：

- `FocusStore.ets`

体现：

- `@Concurrent`
- `taskpool.execute`
- 后台计算复盘统计快照
- 失败时同步计算兜底

### 网络通信与状态订阅

对应文件：

- `FocusNetworkService.ets`
- `FocusSyncService.ets`
- `FocusAiCoachService.ets`

体现：

- `connection.hasDefaultNet`
- `connection.createNetConnection`
- `http.createHttp`
- GET / POST 请求
- Authorization 请求头
- 超时配置

### 页面路由 Navigation

对应文件：

- `Index.ets`
- `ProfileView.ets`
- `FocusRoutes.ets`

体现：

- `Navigation(this.navStack)`
- `NavPathStack`
- `pushPathByName`
- `NavDestination`
- `pop`

### Preferences

对应文件：

- `AuthRepository.ets`
- `FocusSettingsService.ets`
- `FocusSyncService.ets`
- `FocusAiCoachService.ets`
- `FocusFormSnapshotService.ets`

体现：

- 轻量 KV 存储
- 保存登录态、设置、同步 token、AI 配置、服务卡片快照
- 修改后 `flush()`

### RDB

对应文件：

- `FocusDatabase.ets`

体现：

- `relationalStore.getRdbStore`
- `executeSql`
- `querySql`
- `RdbPredicates`
- `ResultSet.close()`
- 表结构和数据迁移

### ArkWeb

对应文件：

- `ReviewView.ets`
- `resources/rawfile/charts/index.html`

体现：

- rawfile H5 资源
- `Web` 组件
- `javaScriptProxy`
- H5 调 ArkTS 方法

### 后端 Maven 依赖

对应文件：

- `focus-server/pom.xml`

体现：

- Spring Boot
- MyBatis
- Lombok
- H2
- MySQL
- Swagger

### Java 面向对象与 Lombok

对应文件：

- `entity/*.java`
- `dto/*.java`
- `common/Result.java`

体现：

- Entity / DTO 类
- Lombok 自动生成 getter/setter
- `@NoArgsConstructor`
- `@AllArgsConstructor`
- `@Data`

### 数据库与 CRUD 联调

对应文件：

- `controller/*.java`
- `mapper/*.java`
- `resources/mapper/*.xml`
- `init.sql`
- `init-mysql.sql`

体现：

- 用户登录
- 项目 CRUD
- 任务 CRUD
- 番茄记录新增和查询
- 统计接口
- 同步接口

## 30. 答辩时建议画的架构图

可以在白板或 PPT 画：

```text
用户
 |
 v
ArkUI 页面
 TodayView / TasksView / FocusSessionView / ReviewView
 |
 v
Index.ets 状态调度
 |
 v
FocusStore
 |
 +------------------> FocusSettingsService / AuthRepository
 |                    Preferences
 |
 +------------------> FocusDatabase
 |                    HarmonyOS RDB
 |
 +------------------> FocusSyncService
                      HTTP + JWT
                      |
                      v
                Spring Boot Controller
                      |
                      v
                MyBatis Mapper XML
                      |
                      v
                H2 / MySQL
```

再补充两个旁路：

```text
FocusAbility / FocusSolo
  独立专注窗口
  Want 参数 + AppStorage

ReviewView + ArkWeb
  rawfile H5
  javaScriptProxy
```

## 31. 你需要特别会讲的 8 个亮点

### 亮点 1：本地优先

> 用户操作先写入 HarmonyOS RDB，本地离线也能使用。同步只是增强能力，不影响基础使用。

对应：

- `FocusDatabase.ets`
- `FocusStore.ets`

### 亮点 2：增量同步

> 本地数据用 dirty 标记待上传，服务器用 since 拉取增量，减少全量同步开销。

对应：

- `FocusSyncService.ets`
- `SyncController.java`

### 亮点 3：幂等去重

> 任务和番茄记录使用 clientRequestId，避免网络重试导致重复插入。

对应：

- `FocusDatabase.ets`
- `FocusSyncService.ets`
- `TaskController.java`
- `PomodoroController.java`
- `SyncController.java`

### 亮点 4：删除墓碑

> 删除任务/项目时保留 isDeleted，用同步把删除动作传给另一端。

对应：

- `FocusDatabase.ets`
- `ProjectMapper.xml`
- `TaskMapper.xml`

### 亮点 5：TaskPool 复盘统计

> 番茄统计在数据刷新后后台预计算，页面只读取快照。

对应：

- `FocusStore.ets`

### 亮点 6：独立 FocusAbility

> 主页面之外还有一个独立专注 Ability，通过 Want 参数和 AppStorage 传递任务信息。

对应：

- `FocusAbility.ets`
- `FocusSolo.ets`

### 亮点 7：ArkWeb 混合图表

> H5 图表放在 rawfile，ArkTS 通过 javaScriptProxy 提供 nativeBridge。

对应：

- `ReviewView.ets`
- `charts/index.html`

### 亮点 8：Spring Boot + MyBatis + JWT

> 后端用 JWT 做鉴权，Controller 处理 API，MyBatis XML 写 SQL，支持 H2 和 MySQL。

对应：

- `JwtService.java`
- `AuthInterceptor.java`
- `controller/*.java`
- `mapper/*.xml`

## 32. 常见答辩问题和回答

### 问：这个项目的核心功能是什么？

答：

> 核心是学习任务和番茄专注闭环。用户可以添加任务、开始专注、完成或中断番茄记录，然后在复盘页查看统计。数据先保存到鸿蒙本地 RDB，登录后可以同步到 Spring Boot 后端数据库。

### 问：前端怎么组织代码？

答：

> 我把前端拆成页面、组件、服务、模型几层。`Index.ets` 是页面调度中心，`components` 负责展示，`FocusStore` 负责业务状态，`FocusDatabase` 负责 RDB，`FocusSyncService` 负责后端同步。

### 问：为什么不用页面直接写数据库？

答：

> 页面直接写数据库会让 UI 和业务混在一起。现在页面只触发动作，例如添加任务；真正构造数据、写 RDB、刷新统计都由 `FocusStore` 和 `FocusDatabase` 完成，更清晰。

### 问：本地数据库有哪些表？

答：

> 前端本地 RDB 有 projects、tasks、pomodoros、study_resources 四张表。前三张参与云同步，study_resources 是本地学习资料库。

### 问：同步怎么避免重复数据？

答：

> 任务和番茄记录都有 `clientRequestId`。本地创建后生成稳定 ID，后端插入前先按这个 ID 查重。如果已经存在就返回或更新，不会重复插入。

### 问：同步冲突怎么处理？

答：

> 项目采用 Last-Write-Wins。前端和后端都比较 `updatedAt`，保留更新时间较新的版本。虽然不是最复杂的冲突合并，但适合这个课程项目。

### 问：删除为什么不直接 delete？

答：

> 因为要同步删除动作。如果本地直接物理删除，服务器不知道它被删了，下次 pull 可能把旧数据拉回来。所以使用 `isDeleted` 删除墓碑。

### 问：TaskPool 用在哪里？

答：

> 用在复盘统计。`FocusStore` 里有 `@Concurrent buildReviewStatsSnapshot`，刷新数据后用 `taskpool.execute` 在后台计算总专注、本周时长、项目占比、连续天数和植物解锁。

### 问：ArkWeb 怎么体现？

答：

> 复盘页使用 `Web` 组件加载 rawfile 下的 H5 图表页面，并通过 `javaScriptProxy` 注入 `nativeBridge`。H5 可以调用 `getStats()` 获取 ArkTS 统计数据。

### 问：FocusAbility 为什么要有 onNewWant？

答：

> 因为 `FocusAbility` 是 singleton。第一次启动走 `onCreate`，如果已经存在时再次启动可能走 `onNewWant`。两边都解析 Want，才能保证热启动时新任务参数也能更新。

### 问：Preferences 和 RDB 怎么分工？

答：

> Preferences 存轻量 KV，例如登录态、设置、同步 token、AI 配置。RDB 存结构化业务数据，例如项目、任务、番茄记录和学习资料。

### 问：后端有哪些接口？

答：

> 用户接口有登录、注册、ping；业务接口有 projects、tasks、pomodoros、stats；同步接口有 `/api/sync/pull` 和 `/api/sync/push`。

### 问：后端怎么鉴权？

答：

> 登录成功后后端返回 JWT。除登录、注册、ping 外，其他 `/api/**` 都经过 `AuthInterceptor`，它校验 `Authorization: Bearer token`，解析 userId，再交给 Controller。

## 33. 如果你要按顺序复习代码

建议顺序：

```text
1. AppScope/app.json5
2. entry/src/main/module.json5
3. EntryAbility.ets
4. Splash.ets
5. Index.ets 的状态和 initNativeStore()
6. FocusModels.ets
7. SeedData.ets
8. FocusDatabase.ets
9. FocusStore.ets
10. TodayView.ets / TasksView.ets
11. FocusSessionView.ets / FocusSolo.ets
12. ReviewView.ets / charts/index.html
13. FocusSyncService.ets
14. focus-server/pom.xml
15. FocusServerApplication.java
16. AuthInterceptor.java / JwtService.java
17. UserController.java
18. TaskController.java / ProjectController.java / PomodoroController.java
19. SyncController.java
20. mapper/*.xml
21. init.sql / init-mysql.sql
```

这样学，会从“应用怎么启动”一路看到“数据怎么落库”。

## 34. 一句话背诵版

如果老师让你 1 分钟介绍项目，可以这样说：

> 我的项目是一个 HarmonyOS 学习专注应用“知序”。前端用 ArkTS 和 ArkUI 实现今日、任务、专注、资料、复盘、我的等页面；主页面 `Index.ets` 负责状态调度，组件负责展示，`FocusStore` 管业务状态，`FocusDatabase` 用 RDB 保存项目、任务、番茄和资料。专注模块支持独立 `FocusAbility`，通过 Want 和 AppStorage 传任务信息，并用时间戳校正计时。复盘统计使用 TaskPool 后台预计算，还集成 ArkWeb H5 图表。后端使用 Spring Boot + MyBatis，提供登录、项目、任务、番茄、统计和同步接口，用 JWT 鉴权，支持 H2 和 MySQL。同步采用 dirty 增量上传、serverTime 增量拉取、clientRequestId 幂等去重和 updatedAt 冲突处理，实现了前端、本地数据库、后端数据库的完整闭环。

## 35. 最后要注意的边界

答辩时建议实事求是：

- 学习资料库目前主要是本地 RDB 功能，没有同步到后端。
- AI 配置不是安全加密存储，当前适合本地演示，不适合直接当生产密钥管理。
- 同步冲突策略是 Last-Write-Wins，不是复杂多人协作合并。
- `HeatMapCard` 有一部分是演示型可视化，不是严格按真实日期逐格计算。
- 后端密码使用 SHA-256 哈希，课程项目可解释原理；生产环境应使用更强的密码哈希算法和盐。

这些边界讲清楚，反而显得你真的理解项目，而不是只背功能。
