# Focus App 交接文档

更新时间：2026-05-27
工作目录：`D:\Study\26sp\arkts\final`  
课程项目：鸿蒙应用开发期末大作业  
产品定位：本地优先的学习任务 + 番茄专注 App，后端为可选同步 / 全栈展示层。

## 1. 当前结论

Focus 不再按“必须联网、端云强绑定”的大而全方向推进。当前产品主线已经调整为：

- 鸿蒙端本地完整可用。
- 任务、项目、番茄记录以 RDB 为主要数据源。
- 登录态 / 游客模式使用 Preferences。
- Spring Boot + MyBatis + MySQL 后端保留为 optional，用于课程后端联调、备份和同步接口展示。
- 后端不可用不影响新增任务、番茄计时、完成/中断记录和复盘统计。

这个取舍更符合番茄钟产品本身，也更利于答辩：核心功能稳定，架构边界清楚，课程知识点能串成闭环。

## 2. 最新重构内容

### 2.0 详细设计文档

- 已新增 `设计文档.md`。
- 该文档详细记录了 Focus 的产品定位、总体架构、前端模块、RDB 数据层、Preferences 登录态、`FocusAbility`、ArkWeb、服务卡片、可选后端、课程知识点映射、构建验证、已知限制和答辩讲解建议。
- 后续答辩或继续开发时，建议先读 `需求文档.md` 理解产品范围，再读 `设计文档.md` 理解模块实现，最后读本 `HANDOVER.md` 查看最新状态和操作提示。

### 2.1 需求与产品范围

- 已重写 `需求文档.md`。
- 新文档明确：
  - 本地优先是主线。
  - RDB 是任务 / 项目 / 番茄记录的真实来源。
  - 后端是可选同步层，不是核心依赖。
  - RCP、JWT、分布式、AI、AVPlayer 白噪音、签名 HAP 均列为后续加分项。

### 2.2 本地 RDB 数据层

核心文件：`entry/src/main/ets/services/FocusDatabase.ets`

当前已实现：

- 打开 `focus.db`，数据库版本为 `2`。
- 创建 / 迁移三张表：
  - `projects`
  - `tasks`
  - `pomodoros`
- 通过 `PRAGMA table_info` 补充缺失字段。
- 首次空库时写入默认项目、任务和番茄记录。
- 提供 DAO 风格方法：
  - `getProjects`
  - `getTasks`
  - `getPomodoros`
  - `addTask`
  - `upsertProject`
  - `upsertTask`
  - `updateTask`
  - `recordPomodoro`
  - `incrementTaskPomodoro`
- 所有 `ResultSet` 查询路径都在 `finally` 中 `close()`。
- 时间戳统一使用 Unix milliseconds。
- `tags` / `subtasks` 用 JSON 字符串保存到 RDB。

### 2.3 Store / UI 数据流

核心文件：

- `entry/src/main/ets/services/FocusStore.ets`
- `entry/src/main/ets/pages/Index.ets`

当前已实现：

- `FocusStore.refresh()` 从 RDB 读取项目、任务、番茄记录。
- 新增任务、完成切换、软删除、恢复、完成番茄、中断番茄均先写 RDB，再刷新 store。
- `Index.ets` 启动时执行：
  - `focusDatabase.init(context)`
  - `focusStore.refresh()`
  - `syncFromStore()`
  - `authRepository.init(context)`
- Today / Tasks / Focus / Review 使用同一份 `FocusStore` 快照。
- ArkWeb bridge 的统计数据来自 `FocusStore`，不再只是固定种子数据。

### 2.4 独立 FocusAbility

核心文件：

- `entry/src/main/ets/focusability/FocusAbility.ets`
- `entry/src/main/ets/pages/FocusSolo.ets`

当前已实现：

- `FocusAbility` 为 singleton。
- `onCreate` 和 `onNewWant` 都解析 Want，避免热启动时参数不刷新。
- Want 参数包括：
  - `taskTitle`
  - `taskId`
- `FocusSolo` 通过 `@StorageProp` 读取当前任务。
- 独立专注窗口完成番茄时会尝试初始化同一套本地 RDB，并调用 `focusStore.recordPomodoro()` 写入本地记录。
- 如果 RDB 初始化失败，计时和通知仍可继续，页面显示降级提示。

### 2.5 已有产品能力

已实现或保留：

- 本地账户 / 游客模式。
- 四个 Tab：今日、任务、专注、复盘。
- 快速添加任务。
- 搜索、项目筛选、四象限筛选。
- 回收站软删除和恢复。
- 番茄开始、暂停、完成、中断、重置。
- 中断原因记录。
- 原生统计图表风格视图。
- ArkWeb H5 复盘页：`entry/src/main/resources/rawfile/charts/index.html`。
- 服务卡片：
  - `entry/src/main/ets/entryformability/EntryFormAbility.ets`
  - `entry/src/main/ets/formpages/FocusCard.ets`
  - `entry/src/main/resources/base/profile/form_config.json`
- 通知和后台任务 best-effort 封装：
  - `entry/src/main/ets/services/FocusNativeServices.ets`
- 可选后端：
  - `focus-server/`

### 2.6 最新前端展示美化（2026-05-25）

核心文件：

- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/pages/FocusSolo.ets`
- `entry/src/main/ets/formpages/FocusCard.ets`

本轮改动：

- 全局视觉常量微调：页面背景更干净，主色从高饱和蓝压到更稳的靛蓝，卡片边框和阴影统一。
- 登录页强化第一印象：标题改为更明确的产品承诺，增加 `RDB 持久化` / `番茄闭环` 标签，输入框与主按钮更有层级。
- 今日页 Hero 增加“本地优先 / 已保存到本地”状态条，主卡片圆角、阴影、间距统一。
- 快速添加卡增加“本地写入”标签，输入框改为浅底 + 边框，主按钮增加轻阴影。
- 任务行从硬分割线列表升级为轻卡片条目：标题更清晰，截止时间改为状态标签，完成态/优先级色条更稳定。
- 专注计时器加强主视觉：计时环更大，按钮层级更明确，并增加“完成和中断都会写入本地记录”的说明。
- 复盘页 KPI、柱状图、完成/中断卡片统一边框与阴影；完成/中断区块使用低饱和状态底色提升可读性。
- 独立 `FocusSolo` 页面同步为更成熟的沉浸专注视觉，并提示完成后写入本地记录。
- 服务卡片同步调整深色背景、进度条颜色和任务文本透明度，和主 App 视觉保持一致。

本轮没有改 RDB schema、FocusStore 数据流或后端代码。

### 2.7 AI Focus Coach 与素材系统（2026-05-27）

核心文件：

- `entry/src/main/ets/services/FocusAiCoachService.ets`
- `entry/src/main/ets/services/FocusSettingsService.ets`
- `entry/src/main/ets/utils/FocusFormatters.ets`
- `entry/src/main/ets/models/FocusModels.ets`
- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/resources/base/media/`

本轮新增：

- AI Focus Coach 卡片已接入 Today / Focus 体验：
  - 默认使用本地规则，不依赖网络。
  - 读取当前任务、项目、番茄完成/中断记录和专注设置。
  - 给出推荐任务、下一步、专注安排、风险提示和置信度。
- 可选远程 AI 接入：
  - 设置存储在 Preferences 的 `focus_ai` 中。
  - 运行时填写 endpoint / model / API key 后可请求 OpenAI-compatible `/v1/chat/completions`。
  - 远程失败、未配置 key、空响应都会降级到本地建议。
  - API key 输入框不会回显已保存密钥；留空保存表示保留旧 key。
- 新增 `ohos.permission.INTERNET`，仅用于可选远程 AI。
- 成熟度补强：
  - 番茄时长、短休、长休、白噪音、主题色和通知偏好已通过 Preferences 的 `focus_settings` 本地保存。
  - 设置保存失败时会保留本次会话内的可用状态，不阻断任务和番茄主流程。
  - 计时文本、截止时间、优先级、专注状态等展示逻辑已提取到 `FocusFormatters.ets`，后续可继续拆分 `Index.ets`。
- 新增视觉资源：
  - `focus_ai_hero.png`：Today hero 中的 AI + 番茄桌面视觉。
  - `focus_coach_orbit.png`：AI Coach 卡片视觉。
  - `focus_forest_spritesheet.png`：4x3 森林奖励素材表，用于整体检查和后续切图参考。
  - `focus_plant_seed.png` / `focus_plant_ginkgo.png` / `focus_plant_pine.png` / `focus_plant_bloom.png` / `focus_plant_maple.png` / `focus_plant_forest.png`：复盘森林植物阶段素材。
  - `focus_reward_timer_token.png` / `focus_reward_water.png` / `focus_reward_stone_path.png` / `focus_reward_compost.png` / `focus_reward_locked_seed.png`：复盘奖励与中断复盘素材。
- 继续新增一套可复用 UI micro-assets：
  - `focus_ui_spritesheet.png`：通过 `https://sin.ioll.pp.ua` 生成的 4x4 素材表。
  - `focus_ui_empty_inbox.png` / `focus_ui_quick_add.png` / `focus_ui_next_marker.png` / `focus_ui_priority_flag.png`
  - `focus_ui_ai_orb.png` / `focus_ui_local_cube.png` / `focus_ui_remote_cloud.png` / `focus_ui_timer_token.png`
  - `focus_ui_pause_resume.png` / `focus_ui_notification_bell.png` / `focus_ui_completion_medal.png` / `focus_ui_risk_shield.png`
  - `focus_ui_review_bars.png` / `focus_ui_heatmap_grid.png` / `focus_ui_settings_sliders.png` / `focus_ui_sync_bridge.png`
- UI 深度接入：
  - Today hero 增加“本地数据 / AI 建议”视觉芯片。
  - 快速添加、下一段专注、AI Coach、空状态、任务行、专注计时器、AI 接入设置、Review KPI / 图表卡片都接入了语义化小素材。
  - 任务行增加优先级浅色标签与状态图标，完成态和待办态更容易扫读。
  - 专注页增加 timer / pause / risk 状态小组件，能更清楚表达运行状态和中断记录。

素材经验：

- hero / coach 可以使用概念型生成图。
- 复盘森林这类重复 UI 元素应使用 spritesheet 或独立透明 PNG 素材，避免把大概念图裁进 tile。
- 用户提供的生图 API 每次请求成本固定；批量素材优先一次生成 spritesheet，再本地裁剪或本地重绘。
- UI micro-assets 也应遵循同样策略：一次生成同风格 spritesheet，裁成有语义文件名的独立 PNG，再接入实际 UI 状态。
- 本轮没有提交用户提供的 API key。

### 2.8 UI/UX 重构与设计系统（2026-05-27）

核心文件：

- `entry/src/main/ets/pages/Index.ets` - 主要重构目标
- `entry/src/main/ets/services/FocusAiCoachService.ets` - AI 配置更新

本轮重构：

**信息架构重组：**
- 主页面从 5 个 Tab（今日、任务、资料、专注、复盘）重构为 3 个 Tab（今日、任务、我的）。
- "我的" Tab 整合了复盘统计、学习资源库和设置功能。
- 专注计时器和资源详情改为独立流程覆盖层，通过状态变量控制显示/隐藏。
- 新增状态变量：`showFocusTimer`、`showResourceDetail`、`aiLastRefreshTime`。

**视觉设计系统：**
- 新增设计 Token：
  - `SPACING`：统一的间距系统（xs: 4, sm: 8, md: 12, lg: 16, xl: 20, xxl: 24, xxxl: 32）
  - `RADIUS`：统一的圆角系统（sm: 8, md: 12, lg: 16, xl: 20, full: 9999）
  - `SHADOW_CARD` / `SHADOW_FLOAT`：统一的阴影系统
  - `PAGE_BG_START` / `PAGE_BG_END`：页面背景渐变
  - `CARD_GLASS` / `CARD_GLASS_BLUR`：毛玻璃效果参数
- 页面背景使用微妙渐变：`['#F3F6FB', '#E8EDF5']`
- 卡片应用毛玻璃效果：半透明白色 `#F8FFFFFF` + `backdropBlur(20)`

**AI 集成配置：**
- 默认 API 已更新为用户提供的配置：
  - Endpoint: `https://token-plan-cn.xiaomimimo.com/anthropic`
  - Model: `mimo-v2.5-pro`
- AI Coach 支持手动刷新和任务变更后自动刷新
- Study Resources 支持手动触发 AI 提炼
- 所有远程调用失败时自动降级到本地规则

**组件化策略：**
- 采用 @Builder 渐进式拆分，保持 Index.ets 作为主容器
- 新增 @Builder 方法：`ProfileTab()`、`FocusTimerOverlay()`、`ResourceDetailOverlay()`
- 不创建独立组件文件，避免 ArkUI 构建问题

**待完成：**
- 毛玻璃效果需要在真机/模拟器上验证
- App 图标生成（生图 API 暂不可用）
- 完整的功能回归测试

## 3. 可选后端状态

后端目录：`focus-server/`

技术栈：

- Spring Boot
- MyBatis
- MySQL
- Maven
- Lombok

后端已包含：

- 用户接口。
- 项目 CRUD。
- 任务 CRUD。
- 番茄记录接口。
- 统计接口。
- 同步 push / pull 接口。
- `init.sql`。
- 统一 Result / DTO / Mapper / XML。

后端运行前需要：

1. 启动 MySQL。
2. 执行 `focus-server/src/main/resources/init.sql`。
3. 按本机数据库账号密码修改 `focus-server/src/main/resources/application.yml`。
4. 再运行 Spring Boot 或打包 jar。

当前前端主流程不依赖后端。若答辩需要展示后端，可以展示接口代码、数据库表、Maven 打包结果和 optional sync 设计。

## 4. 构建验证

### 4.1 前端 HAP 构建

可用命令：

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

最近一次已验证结果：

- `BUILD SUCCESSFUL in 1 min 13 s 686 ms`（2026-05-27 AI Coach、UI micro-assets、设置持久化与格式化模块化后）
- 输出：`entry/build/default/outputs/default/entry-default-unsigned.hap`
- 所有 `focus_*.png` 已用 Pillow 打开验证。
- `git diff --check` 通过。
- 精确密钥扫描 `sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}` 没有命中项目文件。

注意：

- 当前未配置 signingConfigs，因此输出是 unsigned HAP。
- 签名安装需要在 DevEco Studio 配置个人证书。
- hvigor daemon 端口可能自动降级，不影响构建。
- 已知 warning 包括签名缺失、部分 API deprecated、后台任务 syscap 差异、Preferences / RDB 可能抛异常提示。
- AI Coach 和运行设置相关 Preferences 异常已做降级处理，不会阻断本地主流程。

### 4.2 后端 Maven 构建

在 `focus-server/` 下运行：

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;D:\Tools\apache-maven-3.9.10\bin;$env:Path"
mvn -q -DskipTests package
```

最近一次已验证结果：

- 命令退出码为 `0`。
- jar 路径：`focus-server/target/focus-server-0.0.1-SNAPSHOT.jar`

## 5. 重要 ArkTS / ArkUI 坑

这些是之前构建和真机截图反馈里踩过的坑，后续改 UI 时要继续遵守：

- ArkUI 透明色格式是 `#AARRGGBB`，不是 `#RRGGBBAA`。例如半透明白应写 `#1AFFFFFF`。
- 不要在 Scroll / Row 内用装饰性 `height('100%')` 画侧边条，容易把卡片撑满整屏。优先用 `border({ width: { left: 3 } })`。
- 不要在 `@Builder` 里给 `linearGradient.colors` 写复杂三元嵌套数组。
- 不要给 `@Builder` 传函数参数作为回调，之前会触发编译产物数量错误。
- 不要给 `.shadow()` 写复杂三元对象字面量。
- 重复使用的奖励/植物视觉不要用概念图硬裁；优先使用独立 PNG 或 spritesheet。
- ArkWeb 预览器能力不完整，必须用模拟器或真机验证。
- 后台任务能力存在设备 syscap 差异，需要保留降级提示。

## 6. 当前已知限制

- 当前目录是 Git 仓库，可以在根目录使用 `git status` / `git diff`；注意 `.trellis/` 任务文件也可能出现工作区变更。
- `Index.ets` 仍然较大。为了保证期末构建稳定，这次没有强行拆大量组件；后续可按 Today / Tasks / Focus / Review 渐进提取。
- 任务详情编辑、截止日期选择器、通知调度还不是完整产品级。
- FocusAbility 完成番茄已尝试写入 RDB，但跨 Ability 的实时主页刷新仍以重新进入 / store refresh 为准。
- ArkWeb 已接入本地页面和 bridge，但仍需要模拟器 / 真机确认真实渲染。
- 服务卡片已配置并可构建，但仍需要设备上手动添加卡片验证。
- 后端 sync 作为 optional 设计保留，前端尚未把每个同步状态完整 UI 化。
- 远程 AI 是 optional enhancement；没有 endpoint/key 或网络时仍以本地规则建议为准。
- 未配置签名证书，不能直接生成已签名安装包。

## 7. 下一步建议

优先级最高：

1. 在 DevEco Studio 模拟器或真机运行，完整走查：本地登录、添加任务、完成任务、删除恢复、开始番茄、完成番茄、中断原因、复盘页。
2. 关闭并重启 App，确认 RDB 数据仍在。
3. 验证独立 `FocusAbility`：从任务进入、热启动切换任务、完成后回主页看记录。
4. 添加服务卡片并检查显示效果。
5. 在设置里测试远程 AI：保存 endpoint/model/key、留空保存保留 key、断网/错误 endpoint 降级到本地建议。
6. 配置签名证书，生成可安装 HAP。

可选增强：

1. 补任务编辑详情页。
2. 增加后端 baseUrl 设置和手动同步按钮。
3. 对接 `/api/sync/push` 与 `/api/sync/pull`。
4. 加真实 AVPlayer 白噪音素材。
5. 若继续扩展游戏化复盘，按 `focus_forest_spritesheet.png` 的方式维护统一素材表，再裁成独立资源。
6. 继续拆分 `Index.ets`，把四个 Tab 提取成更小的组件。

## 8. 答辩叙事建议

建议按这个顺序讲：

1. 为什么番茄钟产品不应该强依赖联网：个人效率工具需要离线可靠。
2. 本地优先架构：RDB 管任务 / 番茄，Preferences 管身份 / 设置。
3. 核心闭环：建任务 -> 专注 -> 完成 / 中断 -> 复盘。
4. 鸿蒙知识点：ArkTS UI、状态管理、UIAbility、Want、RDB、Preferences、ArkWeb、服务卡片、通知 / 后台任务。
5. 后端作为课程联调展示：Spring Boot + MyBatis + MySQL，保留同步接口。
6. AI 增强：本地规则始终可用，远程模型是可选教练，不改变 RDB 主数据。
7. 后续规划：同步 UI、任务详情、签名打包、真机体验优化。
