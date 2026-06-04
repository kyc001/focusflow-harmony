# 知序项目人话版讲解

这份是给“看不进去技术文档”的你准备的。

我们先不背术语，也不急着看每个文件。你先把这个项目想象成一个“学习管家 App”：

```text
你把要做的事写进 App
App 帮你排任务
你开始一段番茄钟
完成后 App 记账
记多了以后 App 给你复盘
如果你登录后端，它还能把账本同步到服务器
```

这个项目真正做的事情，就这么简单。

后面所有代码，都只是围绕这句话展开。

## 1. 先用一个生活比喻理解项目

你可以把这个 App 看成一家小店。

```text
店面
  用户看到的页面：今日、任务、专注、复盘、我的

店长
  Index.ets：负责调度所有事情

账本
  FocusDatabase.ets：把任务、番茄、资料写进本地数据库

柜台记录员
  FocusStore.ets：把数据库里的东西整理成页面能直接用的数据

快递员
  FocusSyncService.ets：把本地数据送到后端，也从后端取数据

云端仓库
  Spring Boot 后端 + MySQL/H2
```

如果你能记住这张图，项目就已经懂了一半：

```text
页面
  -> Index.ets
  -> FocusStore.ets
  -> FocusDatabase.ets
  -> FocusSyncService.ets
  -> Spring Boot 后端
  -> 数据库
```

## 2. 用户点一下“添加任务”，代码到底发生了什么？

别先想代码，先想人做事。

你在今日页输入：

```text
整理答辩 PPT
```

然后点“添加任务”。

这时项目里发生了这条链：

```text
QuickAddTaskCard
  你看到的快速添加卡片

TodayView
  今日页组件，把“添加任务”这个动作告诉父页面

Index.ets
  主页面收到动作：哦，用户要加任务

FocusStore.addTask()
  构造一个任务对象：标题、项目、优先级、截止时间

FocusDatabase.addTask()
  真正写进本地 RDB 数据库 tasks 表

FocusStore.refresh()
  重新从数据库读最新数据

Index.syncFromStore()
  把新数据放进 @State

ArkUI 自动刷新
  页面上出现新任务
```

所以你答辩时不要说：

> 我这里写了一个按钮。

你要说：

> 这个按钮背后打通了组件回调、状态管理、本地 RDB 写入和 UI 自动刷新。

这就高级很多。

## 3. 为什么有这么多文件？它们其实是在分工

你现在觉得文件多，是因为还没给它们分角色。

### EntryAbility.ets：开门的人

位置：

```text
entry/src/main/ets/entryability/EntryAbility.ets
```

它做的事很少：

```text
系统启动 App
  -> 创建 EntryAbility
  -> 创建窗口 WindowStage
  -> 加载 pages/Splash
```

你可以记成：

> `EntryAbility` 是应用大门。它不管业务，只负责把第一个页面打开。

### Splash.ets：欢迎屏

位置：

```text
entry/src/main/ets/pages/Splash.ets
```

它就是启动动画。

2.5 秒后跳到：

```text
pages/Index
```

你可以记成：

> Splash 是开场动画，真正干活的是 Index。

### Index.ets：总导演

位置：

```text
entry/src/main/ets/pages/Index.ets
```

这是最重要的文件。

它像总导演，负责：

```text
初始化数据库
加载设置
读取登录状态
维护任务列表
维护番茄钟状态
处理用户点击
控制底部 Tab
控制 Navigation 跳转
调用 AI
调用云同步
```

你不要试图一口气读完 `Index.ets`。它很长，直接读会崩。

正确读法是看它里面几类函数：

```text
initNativeStore()
  启动时初始化所有服务

addQuickTask()
  添加任务

toggleTask() / deleteTask() / restoreTask()
  修改任务状态

startPomodoro() / pausePomodoro() / completePomodoro()
  番茄钟控制

addResource() / extractResource()
  学习资料和 AI 提炼

syncBidirectional()
  云同步

build()
  页面长什么样
```

一句话：

> `Index.ets` 是前端业务总入口，它把页面、数据、专注、同步、AI 串起来。

## 4. 这个项目最核心的两个文件

如果老师只让你讲技术核心，你先讲这两个：

```text
FocusStore.ets
FocusDatabase.ets
```

### FocusDatabase.ets：真正写数据库的人

位置：

```text
entry/src/main/ets/services/FocusDatabase.ets
```

它负责本地 RDB。

它创建了 4 张表：

```text
projects
  项目，比如“移动开发”“数据库”

tasks
  任务，比如“整理答辩 PPT”

pomodoros
  番茄记录，比如某天完成了 25 分钟

study_resources
  学习资料，比如课堂笔记、PDF 摘要、备忘录
```

它做的事情特别像数据库课：

```text
CREATE TABLE
INSERT
SELECT
UPDATE
ResultSet.close()
```

你可以这么讲：

> `FocusDatabase` 是本地数据层。我用 HarmonyOS RDB 保存结构化数据，让 App 离线也能使用。

### FocusStore.ets：把数据库变成页面能用的数据

位置：

```text
entry/src/main/ets/services/FocusStore.ets
```

如果 `FocusDatabase` 是原始账本，那 `FocusStore` 就是会整理账本的人。

比如数据库里有很多番茄记录，页面不想自己算：

```text
完成了几个番茄？
本周每天多少分钟？
哪个项目花时间最多？
连续学习几天？
解锁了哪些植物？
```

这些统计由 `FocusStore` 做。

而且它用了 TaskPool：

```text
@Concurrent buildReviewStatsSnapshot()
taskpool.execute(...)
```

意思是：

> 统计计算比较费劲，所以放到后台线程算，别卡住主界面。

这就是你课程里的并发知识点。

## 5. 番茄钟为什么不是简单倒计时？

很多人写倒计时会这样：

```text
每秒 remainingSeconds - 1
```

但这个项目没有只靠这种方式。

它做了更靠谱的设计：

```text
开始时记一个时间戳 lastStartedAt
每次刷新时用 Date.now() - lastStartedAt 计算真实经过时间
```

为什么？

因为手机切后台、锁屏、系统节流时，`setInterval` 可能不准。

所以项目里真正的时间来源是：

```text
系统当前时间 Date.now()
```

`setInterval` 只是提醒页面“该刷新了”。

答辩时可以这样说：

> 我的计时器不是单纯每秒减一，而是用时间戳校正真实经过时间，减少后台切换导致的计时漂移。

这句话很有含金量。

## 6. 为什么还要一个 FocusAbility？

主页面已经有专注功能，为什么还要 `FocusAbility`？

因为项目做了一个“独立沉浸专注窗口”。

流程是：

```text
用户在主页选择任务
  -> Index.ets 调 startAbility
  -> 启动 FocusAbility
  -> 通过 Want parameters 传 taskId 和 taskTitle
  -> FocusAbility 把参数写入 AppStorage
  -> FocusSolo 用 @StorageProp 读出来
```

最关键的是 `FocusAbility.ets` 里同时写了：

```text
onCreate()
onNewWant()
```

这不是多余。

因为 `FocusAbility` 是 singleton：

```text
第一次打开
  走 onCreate

已经打开后再次传新任务
  可能走 onNewWant
```

所以两个地方都解析 Want，才能保证热启动不丢参数。

答辩时就说：

> 这里对应 UIAbility 启动模式和 Want 传参。为了避免 singleton 热启动时参数不更新，我在 `onCreate` 和 `onNewWant` 中都解析 Want。

## 7. 云同步到底怎么同步？

这个部分一开始看很吓人，其实你按“拉下来、合进去、推上去”理解就行。

用户点“同步数据”后：

```text
第一步：pull
  从服务器拉取上次同步之后变化的数据

第二步：merge
  把服务器数据合并进本地 RDB

第三步：push
  把本地 dirty=1 的数据上传服务器

第四步：markSynced
  上传成功后，本地 dirty 改成 0
```

也就是：

```text
先下拉
再合并
再上推
最后标记已同步
```

### dirty 是什么？

`dirty` 可以理解成“这条数据弄脏了，还没同步”。

```text
dirty = 1
  本地改过，需要上传

dirty = 0
  已经同步，不用重复上传
```

### clientRequestId 是什么？

它是“防重复编号”。

比如网络不好，你点了一次同步，但请求重复发了两遍。

如果没有 `clientRequestId`，服务器可能插入两条一样的任务。

有了它：

```text
服务器先查有没有这个 clientRequestId
有：说明传过了，更新或返回原记录
没有：才新增
```

### updatedAt 是什么？

它是“谁更新得更晚”。

如果本地和服务器都有同一个任务，就比较：

```text
谁的 updatedAt 更新
谁就是最新版本
```

这叫 Last-Write-Wins。

答辩完整说法：

> 同步采用 dirty 增量上传、serverTime 增量拉取、clientRequestId 幂等去重、updatedAt 冲突处理。

这句话可以背。

## 8. 后端其实也不复杂

后端就是一个 Spring Boot 服务。

你可以按这条链理解：

```text
Controller
  接 HTTP 请求

Service
  做业务逻辑，比如 JWT

Mapper
  调数据库

XML
  写 SQL

Database
  H2 或 MySQL
```

### UserController

负责：

```text
注册
登录
ping 健康检查
```

登录成功会返回 JWT。

### AuthInterceptor

负责拦截接口。

除了登录、注册、ping，其他接口都必须带：

```text
Authorization: Bearer <token>
```

它验证 token 后，把用户 ID 放进 request。

### TaskController

负责任务 CRUD：

```text
查任务
加任务
改任务
删任务
```

### SyncController

负责同步：

```text
/api/sync/pull
/api/sync/push
```

这是后端最重要的 Controller。

## 9. 你答辩时可以这样讲一遍完整流程

假设老师问：

> 你这个项目怎么实现前后端联调？

你可以这样讲：

```text
用户先在鸿蒙前端添加任务。
任务不会直接发给服务器，而是先写入本地 RDB 的 tasks 表。
写入时会设置 dirty=1，表示这条任务还没有同步。

用户登录云同步后，前端 FocusSyncService 会先调用 /api/sync/pull，
根据上次同步时间 since 拉取服务器更新。
拉取后合并进本地数据库。

然后前端查询本地 dirty=1 的项目、任务、番茄记录，
调用 /api/sync/push 上传。

后端 SyncController 收到后，在事务中批量写入数据库。
任务和番茄记录通过 clientRequestId 去重，
项目和任务通过 updatedAt 判断新旧版本。

同步成功后，前端把这些数据 dirty 改成 0，
并保存服务器返回的 serverTime，作为下次增量同步游标。
```

这段你背熟，老师大概率会觉得你真的懂。

## 10. 最适合你先掌握的 5 个模块

不要一上来试图掌握全部。先吃下这 5 个。

### 第 1 个：启动

```text
EntryAbility
  -> Splash
  -> Index
```

你要会讲：

> App 怎么从 Ability 加载到主页。

### 第 2 个：任务

```text
TodayView / TasksView
  -> Index
  -> FocusStore
  -> FocusDatabase
```

你要会讲：

> 用户添加任务后，数据怎么写入 RDB，页面怎么刷新。

### 第 3 个：番茄钟

```text
Index 或 FocusSolo
  -> Date.now() 校正计时
  -> FocusStore.recordPomodoro
  -> pomodoros 表
```

你要会讲：

> 为什么计时不会只依赖 setInterval。

### 第 4 个：同步

```text
FocusSyncService
  -> SyncController
  -> Mapper XML
  -> 数据库
```

你要会讲：

> dirty、clientRequestId、updatedAt 分别解决什么问题。

### 第 5 个：复盘

```text
FocusStore TaskPool 统计
  -> ReviewView 展示
  -> ArkWeb H5 图表
```

你要会讲：

> 统计为什么放后台算，ArkWeb 怎么和 ArkTS 交互。

## 11. 你可以用这段作为开场白

老师好，我的项目叫“知序”，是一个 HarmonyOS 学习专注应用。

它的核心不是单纯展示页面，而是做了一个学习闭环：用户创建任务，选择任务开始番茄专注，完成或中断后写入本地 RDB，再通过复盘页面查看统计。如果用户登录后端，还可以把项目、任务和番茄记录同步到 Spring Boot 后端数据库。

前端使用 ArkTS 和 ArkUI，主入口是 `EntryAbility`，业务调度集中在 `Index.ets`。我把页面组件和业务数据分开：组件负责展示，`FocusStore` 负责状态和业务动作，`FocusDatabase` 负责本地 RDB。同步模块 `FocusSyncService` 通过 HTTP 调后端，使用 dirty 做增量上传，clientRequestId 防重复提交，updatedAt 做冲突处理。

后端使用 Spring Boot + MyBatis，Controller 提供 REST 接口，Mapper XML 写 SQL，JWT 拦截器保护业务接口，数据库支持 H2 演示和 MySQL 联调。

## 12. 你别这样学

不要从第一行读 `Index.ets`。

真的会很痛苦。

也不要试图记住所有 UI 样式。

答辩不是问你某个按钮 borderRadius 是多少，而是问：

```text
你的数据怎么流动？
你的模块怎么分工？
你用了哪些课程知识点？
你为什么这样设计？
```

所以正确顺序是：

```text
先理解整体数据流
再理解 5 个核心模块
最后再回头查具体文件
```

## 13. 一句话把每个核心文件记住

```text
EntryAbility.ets
  开门，加载 Splash。

Splash.ets
  启动画面，跳到 Index。

Index.ets
  总导演，管页面状态和用户动作。

FocusModels.ets
  数据字典，定义任务、项目、番茄等类型。

SeedData.ets
  第一次打开时的演示数据。

FocusDatabase.ets
  本地数据库，创建表、增删改查。

FocusStore.ets
  状态中心，把数据库数据整理给页面用。

FocusSyncService.ets
  同步服务，连接前端本地数据和后端。

FocusAbility.ets
  独立专注窗口入口。

FocusSolo.ets
  沉浸式番茄钟页面。

ReviewView.ets
  复盘统计和 ArkWeb 图表。

FocusAmbientService.ets
  白噪音播放。

FocusNetworkService.ets
  网络状态监听。

FocusAiCoachService.ets
  请求外部 AI，生成建议和资料摘要。

FocusServerApplication.java
  后端启动入口。

AuthInterceptor.java
  JWT 鉴权拦截器。

SyncController.java
  云同步核心接口。

mapper/*.xml
  MyBatis SQL。
```

## 14. 最后给你一个心理预期

你不需要把 2300 行详细文档全背下来。

你真正要掌握的是三层：

```text
第一层：整体架构
  前端页面 -> 本地数据库 -> 后端数据库

第二层：核心模块
  Index / FocusStore / FocusDatabase / FocusSyncService / SyncController

第三层：亮点话术
  RDB、Preferences、Navigation、TaskPool、ArkWeb、Want、JWT、MyBatis
```

你先把这份读顺，再去看 `PROJECT_STUDY_GUIDE.md`，那份就不会像天书了。

你甚至可以把这份当“上课听懂版”，把详细版当“考试查漏版”。
