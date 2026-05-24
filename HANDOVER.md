# Focus App 交接文档

## 项目背景

- 工作目录：`D:\Study\26sp\arkts\final`
- 课程：《移动应用开发》期末大作业
- App 名称：Focus
- 最新需求版本：2026-05-22 15:11 更新后的 `需求文档.md`
- 技术栈：ArkTS + ArkUI，Stage 模型，HarmonyOS Next；后端 Spring Boot + MyBatis + MySQL
- 用户要求：按更新后的需求文档“从头开始依次实现”，实现前先判断是否有更好的设计方式，并在本文档记录取舍。
- 参考路径：
  - `D:\Study\26sp\arkts\hw4`：上一作业的 ArkTS 前端和 Spring Boot 后端，可参考工程结构、构建方式、接口封装写法。
  - `D:\Tools`：本机后端/Java/Maven 工具；打包前端与构建后端均可使用 `D:\Tools\java\jdk-21`，Maven 可使用 `D:\Tools\apache-maven-3.9.10`。

## 设计取舍（更新需求后的重新判断）

- 是否使用 MySQL / Java 后端：
  - 最新决策：不把 Spring Boot + MySQL 作为主线硬依赖。用户明确表示需求文档不是铁律，可以在不合理时修改；番茄钟 / TodoList 作为个人效率工具，强依赖 Java + MySQL 过重。
  - 主线改为“轻量本地优先”：鸿蒙端 RDB 存任务/番茄/项目，Preferences 存设置/登录态/同步游标；离线、游客、无后端情况下都能完整使用。
  - 后端定位改为“可选薄同步服务”：仅用于课程展示 http 联调、登录备份、多端同步，不阻塞 App 核心流程。已创建的 `focus-server` 保留为 optional，不再作为完成 App 的前置条件。
  - 若答辩老师强调后端，可展示 `focus-server` 的接口骨架和 init SQL；若强调产品合理性，则说明轻量本地优先是更适合该类型 App 的设计。
- 后端实现方式：
  - 保留 Spring Boot + MyBatis + MySQL，因为它最贴合课程要求和 `hw4` 参考资料。
  - 后端只做最小可用：用户、任务、项目、番茄、统计、同步接口；避免复杂微服务、Redis、Spring Security、消息队列等超出期末项目收益的重组件。
  - Token 第一版用轻量自生成 token，JWT 可作为加分项，不作为主线依赖。
- 后端是否引入 JWT/Spring Security：
  - 为了降低单人期末项目复杂度，第一版使用轻量 token 表示登录态，不引入 Spring Security。
  - Token 由后端登录接口返回，前端存入 Preferences；后续可把 token 校验替换为 JWT 拦截器作为加分项。
- 图表实现：
  - 新需求要求 ArkWeb + ECharts 必做差异化，前端会新增 rawfile H5 统计页。
  - `@ohos/mpchart` 可作为原生兜底，但当前优先做 ArkWeb，减少第三方 OHPM 依赖风险。
- MVVM/Repository：
  - 旧版本主页面偏单文件演示。更新后会补 `viewmodel / repository / network / database / utils` 分层骨架，现有 `FocusStore` 会转为演示态/本地兜底状态源。

## 已完成内容

- 已将默认 Hello World 工程扩展为 Focus App 原型。
- 已新增数据模型：
  - `entry/src/main/ets/models/FocusModels.ets`
  - 覆盖任务、项目、番茄记录、设置、学习森林植物等类型。
- 已新增种子数据：
  - `entry/src/main/ets/data/SeedData.ets`
  - 包含默认项目、示例任务、番茄历史、设置、植物解锁规则。
- 已新增本地状态服务：
  - `entry/src/main/ets/services/FocusStore.ets`
  - 支持任务新增、完成切换、软删除/恢复、番茄记录、周统计、项目统计、streak、学习森林解锁。
- 已新增 RDB 建表封装：
  - `entry/src/main/ets/services/FocusDatabase.ets`
  - 目前负责创建 `projects`、`tasks`、`pomodoros` 表；页面数据仍用内存状态演示，后续可继续接入 DAO 持久化。
- 已新增原生能力封装：
  - `entry/src/main/ets/services/FocusNativeServices.ets`
  - 通知权限/通知发布封装。
  - 后台延迟任务 `backgroundTaskManager.requestSuspendDelay` 封装，用于番茄钟运行保护。
- 已新增轻量登录 / 游客模式：
  - `entry/src/main/ets/repository/AuthRepository.ets`
  - 使用 Preferences 保存本地 token、用户名、昵称和 guest 标记。
  - App 启动时先显示登录页，可进入本地账户或游客模式；核心功能不依赖后端。
- 已替换主页面：
  - `entry/src/main/ets/pages/Index.ets`
  - 实现 4 个 Tab：今日、任务、专注、复盘。
  - 实现一多布局：使用 `GridRow`/`GridCol`，手机单列、宽屏并排。
  - 实现番茄钟状态：开始、暂停、完成、中断、重置。
  - 实现中断原因弹窗和历史记录。
  - 实现任务筛选、项目标签、四象限优先级、回收站。
  - 实现图表风格统计、热力图、streak 和第 7 步学习森林玩法。
- 已新增独立专注 Ability：
  - `entry/src/main/ets/focusability/FocusAbility.ets`
  - `entry/src/main/ets/pages/FocusSolo.ets`
  - 主页面点击任务会优先启动 `FocusAbility`，并通过 Want / AppStorage 传入任务标题；启动失败时回落到 Tab 内专注页。
- 已新增 ArkWeb 混合复盘：
  - `entry/src/main/resources/rawfile/charts/index.html`
  - 复盘 Tab 内通过 Web 组件加载本地 H5。
  - ArkTS 通过 `javaScriptProxy` 注入 `nativeBridge.getStats()` / `exportPng()` / `shareReport()`。
- 已新增服务卡片：
  - `entry/src/main/ets/entryformability/EntryFormAbility.ets`
  - `entry/src/main/ets/formpages/FocusCard.ets`
  - `entry/src/main/resources/base/profile/form_config.json`
  - 支持 `2*2` 和 `2*4`，展示今日待办 Top 3 与番茄进度。
- 已更新配置：
  - `entry/src/main/module.json5`
  - 添加 form extension、通知/后台/震动权限声明。
  - `entry/src/main/resources/base/element/string.json`
  - 更新应用名和服务卡片字符串。
- 已新增可选薄后端：
  - `focus-server/`
  - Spring Boot + MyBatis + MySQL，含 `init.sql`、Mapper/XML、Controller、DTO、统一 Result。
  - 提供用户、项目、任务、番茄、统计、同步接口。
  - 已写明它是可选同步层，不是 App 核心依赖。
- 已完成一轮前端 UI / UX 打磨：
  - `entry/src/main/ets/pages/Index.ets`
  - 登录页改为更清晰的本地优先入口，突出“端侧保存 / 可离线用 / 后端可选同步”。
  - 顶部 Header 增加本地保存状态条、连续打卡胶囊和明确的退出按钮，避免把退出藏在模式文字里。
  - 今日页新增“下一段专注”卡片、今日完成百分比、小统计块、空状态；快速添加任务展示默认项目/优先级，减少用户理解成本。
  - 任务管理页优化筛选为可换行胶囊，增加“全部项目 / 全部象限”、任务数量和空状态；任务行把操作按钮移到下方，避免窄屏拥挤。
  - 专注页增加运行状态胶囊、计时环呼吸动效、服务消息多行兜底，按钮色彩按开始/暂停/完成/中断区分。
  - 复盘页优化 KPI 卡、ArkWeb 说明和原生图表动效；学习森林 tile 增加轻微状态动画。
  - `entry/src/main/ets/pages/FocusSolo.ets`
  - 独立专注 Ability 改为沉浸式面板，增加当前任务区、运行状态、呼吸环、完成/暂停/重置操作。
  - `entry/src/main/ets/formpages/FocusCard.ets`
  - 服务卡片补充本地优先状态、进度胶囊和更稳定的任务行间距。
- 已完成第二轮视觉升级，解决“全白底 UI 普通”的问题：
  - `entry/src/main/ets/pages/Index.ets`
  - 全局视觉从白底卡片改为多层次仪表盘：页面底色改为柔和灰绿，普通卡片改为微暖白并增加阴影。
  - 顶部 Header 改为深色品牌栏，昵称、连续打卡、退出、本地保存状态均适配深色背景。
  - 今日页新增深色主视觉卡 `TodayHeroCard`，展示当前最重要任务、完成率、专注分钟、连续天数。
  - “下一段专注”和专注计时器改为深色主卡，形成明确视觉重点；进度、快速添加、任务、设置、白噪音、历史、复盘、森林等区域分别使用蓝、暖、绿、玫色轻底色，避免白卡堆叠。
  - 复盘 KPI、ArkWeb、图表、热力图、森林卡片分别增加分区底色，整体更像完整 App，而不是课程 demo 页面。
  - `entry/src/main/ets/pages/FocusSolo.ets`
  - 独立专注窗口同步改为深色沉浸式界面，当前任务卡、呼吸环、状态胶囊与主页面专注卡保持一致。
  - `entry/src/main/ets/formpages/FocusCard.ets`
  - 服务卡片改为深色小组件风格，和 App 主视觉统一。
- 已完成第三轮视觉升级，解决“UI 太丑、组件粗糙、风格不统一”的问题：
  - `entry/src/main/ets/pages/Index.ets`
  - 重写全局色卡：主色改为靛紫 `#5B6CFF`（含 deep / soft 三色阶），新增紫罗兰、青、暖、玫多套 tint + soft 配对，统一中性灰阶（TEXT_MAIN/SUB/MUTED/DIM）与表面层级；圆角阶梯升级为 14/16/20/22。
  - `cardStyle` 改为纯白大圆角 + 柔阴影（28 radius / 14 offset），新增 `cardStyleTight` 用于 KPI 等小卡，统一卡片层级。
  - 登录页改为深色渐变背景 + 白色玻璃化登录面板：FOCUS 大字 logo、品牌 F 渐变方块、双 feature 胶囊、独立标签输入框、渐变主按钮（带 5B6CFF 阴影投影）和淡灰游客按钮。
  - Header 改为 deep→accent_deep 三段渐变；F logo 渐变方块、🔥 streak 胶囊、半透明本地保存状态条；分明的标题 + 副标 + 模式描述层级。
  - 今日页 `TodayHeroCard` 改为三段渐变（DEEP → DEEP_3 → ACCENT_DEEP），加 🎯 装饰圆、状态胶囊和三个带色点的统计 stat（完成率/专注/连续）。
  - “下一段专注”改为 DEEP_2 → VIOLET 渐变 + 白底圆角箭头按钮；快速添加卡加 ✨ 角标、渐变 + 主按钮、灰底备选按钮，通知态切换为 SUCCESS_SOFT 视觉。
  - 进度环卡：环加粗 strokeWidth 12，分三色 MiniStat（带数字 + 单位 + 标签的色块）。
  - TaskRow 整体重写：每条任务变成独立浅灰卡片，左侧 4px 优先级色条；圆形复选 + 完成态描边，标题旁带 dueText 胶囊；项目/优先级/番茄计数为三类不同 tint 的小胶囊；操作按钮使用胶囊化圆角，主按钮 ACCENT，删除按钮中性灰；已完成态自动变灰底；新增 `priorityTint` 工具方法。
  - TasksTab 头部加副标 + 数量胶囊 + 回收站切换胶囊；FilterBar 加搜索图标和分组标题；项目/象限筛选改为 30 高度药丸 + 加粗激活态。
  - 专注页 TimerCard 改为三段渐变深色卡 + 双层柔光圆环（半透明白底），主操作按钮渐变 + 软阴影，中断/重置使用半透明白底胶囊；服务消息加 🛡 图标和多行兜底。
  - 设置卡加 ⏱ 图标 + 副标，三段滑块分别用 ACCENT/SUCCESS/VIOLET 颜色 + 滑块右侧带胶囊数值；白噪音卡加 🎧 图标 + 每种噪声 emoji（🌧/☕/⌨/🔊）+ ACCENT 胶囊选中态；历史卡加 📋 图标 + 左侧色条 + 时长胶囊。
  - 复盘页 KpiCard 改为 cardStyleTight + 圆角图标块 + 数字-单位下对齐；BarChart 柱子改为顶到底渐变 + 顶部数字标注；热力图加 4 级图例；CompletionCard 改为两侧 SUCCESS_SOFT / DANGER_SOFT 内嵌卡；ForestCard 加 🌳 图标 + 进度胶囊，PlantTile 改为大圆角色块 + 透明度区分锁定态，枯萎角落改为 DANGER_SOFT 提示行。
  - InterruptDialog 加 ⚠ 图标块、标题副标、渐变记录按钮和 22 圆角面板，背景蒙层加深。
  - `entry/src/main/ets/pages/FocusSolo.ets`
  - 改写为三段渐变全屏沉浸面板（DEEP → DEEP_3 → ACCENT_DEEP）；当前任务区改为半透明白色玻璃卡 + 进度胶囊；双层柔光圆环 + 12px 描边的环；开始 / 完成按钮均改为渐变 + 软阴影，重置按钮使用半透明白底；服务消息加 🛡 + 多行兜底。
  - `entry/src/main/ets/formpages/FocusCard.ets`
  - 卡片底改为同款三段渐变；F logo 渐变方块、🔥 4/6 胶囊；任务行改为 3px 色条 + 白色文本；番茄进度条使用半透明轨道 + ACCENT。
- 已完成第四轮视觉调和（针对"颜色变化太大、不协调"反馈）：
  - 调色板降饱和度：ACCENT 从 `#5B6CFF` 改为 `#4F63D2`（柔靛蓝），SUCCESS/WARNING/DANGER 全部改成莫兰迪系（`#1FA37A` / `#D88B2B` / `#D8556A`），各色对应 SOFT tint 同步降亮；VIOLET / TEAL 改为低饱和静色但实际不再用于 UI（保留常量便于未来扩展）。
  - 所有暗色卡片（Header / Hero / Timer / FocusSolo / FocusCard）统一为两色简单渐变 `DEEP → DEEP_3`，去掉原本各异的 `ACCENT_DEEP` / `VIOLET` 尾色和三段渐变；圆角统一从 22 降为 18。
  - Header / Hero 去掉 F logo 渐变方块和「🎯」/「●」装饰，仅保留品牌名、副标和 streak 胶囊；Hero 三个统计改为同色 + 中间竖向 1px 分隔线。
  - NextFocusCard 和 QuoteCard 从深色渐变改为白卡 + 3px 左侧色条，使页面只剩 Hero 一处深色重点。
  - ProgressCard / MiniStat 去掉 WARNING_SOFT / SUCCESS_SOFT / ACCENT_SOFT 三色 tint 块，改为 3 列同色文字 + 中间竖线；进度环 strokeWidth 12 → 10。
  - QuickAddCard 去掉 ✨ 装饰，按钮改为单色实底 ACCENT + 中性灰备选，不再用渐变。
  - TaskRow 改回行式列表（border-bottom 分隔，不再每条独立小卡）；复选改为细描边圆圈；项目/优先级/番茄数改为 dot · text · dot 的中点分隔形式，去掉 3 种 tint 胶囊；操作按钮 borderRadius 17 → 8，去胶囊化；ProjectPill 改为「色点 + 项目名」纯文本，不再 bold project.color 背景，移除 `priorityTint` 工具方法。
  - TasksTab 头部数量胶囊改为纯文字「N 项」；FilterBar 去搜索图标 emoji 与分组标签结构，搜索框直接 44 高；筛选 chip 圆角从 15 → 10。
  - TimerCard 单层 Progress 环（去掉双层柔光 + 呼吸动画 Column 包裹），按钮全部 borderRadius 12，开始/完成/暂停一律实色 + 半透白底，去掉所有渐变和 shadow glow；服务消息去 🛡 emoji。
  - SettingsCard / WhiteNoiseCard / HistoryCard 去掉 ⏱ / 🎧 / 📋 图标块和副标 emoji；三段滑块统一 ACCENT 色；噪音 chip 去 🌧 / ☕ / ⌨ / 🔊 emoji；删除 `noiseIcon` 工具方法；历史行去时长胶囊改为纯文字 + bottom border。
  - 复盘 KpiCard 去图标块和 tint，仅 label + value + unit，全部 TEXT_MAIN 字色；BarChart 柱子从渐变改为 ACCENT 实色 + 圆角，去图例；HeatMap 4 级图例改为浅灰 → 主色的同色阶；CompletionCard 改为一张白卡内左右两列纯数字 + 中间竖线（去掉 SUCCESS_SOFT / DANGER_SOFT 大色块）；ForestCard 去 🌳 图标块、🥀 emoji 和 SUCCESS 胶囊，枯萎角落改为 SURFACE_ALT 提示行；PlantTile 去 plant.color 五彩背景，统一 ACCENT_SOFT 解锁 / SURFACE_ALT 锁定 + 1px 边框、🍅 🔥 emoji 改为纯文字。
  - InterruptDialog 去掉 ⚠ icon 块和渐变记录按钮，统一为白底 + DANGER 实色按钮 + ACCENT_DEEP 配色。
  - LoginScreen 简化：去 F logo 渐变方块、AuthFeatureLine 双 tint 卡和 🔒 emoji；输入框圆角 14 → 12；登录按钮去渐变 + shadow glow，改为单色实底。
  - `entry/src/main/ets/pages/FocusSolo.ets`
  - 同步移除双层柔光圆环、按钮渐变 + shadow，按钮统一 ACCENT 实底 / 半透明白；当前任务卡保留半透明玻璃化但去掉 🎯 进度胶囊。
  - `entry/src/main/ets/formpages/FocusCard.ets`
  - 桌面卡片改为同款 DEEP → DEEP_3 两段渐变；去 F logo 渐变方块；任务行色条统一半透明白色，不再五彩区分。
- 视觉调和后再次构建成功（2026-05-22）：`BUILD SUCCESSFUL in 22 s 367 ms`，warning 与上一轮一致。
- 第五轮 bug 修复（根据真机截图反馈）：
  - **颜色格式 bug**（最严重）：ArkUI 颜色字符串是 `#AARRGGBB`（alpha 在前），不是 `#RRGGBBAA`。之前所有 `'#FFFFFF1A'`、`'#FFFFFF14'`、`'#FFFFFFCC'` 等被解析成「alpha=FF 不透明 + RGB=#FFFF1A 黄色」，导致顶部 streak 胶囊、退出按钮、计时器中断/重置按钮、状态徽章全部显示为亮黄色。批量替换 `Index.ets / FocusSolo.ets / FocusCard.ets` 中所有 `#FFFFFF<NN>` → `#<NN>FFFFFF`（共修复 39 处）。
  - **Hero / Timer 卡撑满整屏的 bug**：之前用 `Stack() { Column().width('100%').height('100%').linearGradient(...) ; Column() { content } }` 实现渐变背景层，但 Stack 在 Scroll 内无高度约束时会被拉伸到最大可用高度，从而吞掉整个屏幕。改为把 `.linearGradient(...)` 直接挂到内容 Column 上，删除 Stack 包裹，让卡片自然按内容收缩。
  - **NextFocus / Quote 卡过大、内容贴底的 bug**：侧边 3px 色条用了 `Column().width(3).height('100%')`，同样在 Row 内被拉伸。改用 `.border({ width: { left: 3 }, color: { left: ACCENT } })` 在 Row 自身画 3px 左边框，让 Row 高度自然由内容决定。
- 颜色 bug 修复后再次构建成功：`BUILD SUCCESSFUL in 1 min 25 s 736 ms`，HAP 输出位置不变；warning 与上一轮一致。
- 第六轮 bug 修复（"任务卡占满整页 + Header 像广告条"反馈）：
  - **TaskRow 同样的 height 100% bug**：之前给 NextFocus / Quote 修过侧边色条问题，但 TaskRow 也有 `Column().width(3).height('100%')` 当左侧优先级色条，仍然把 Row 拉伸到屏幕高度。改为在 Column 自身用 `.border({ width: { left: 3, bottom: 1 }, color: { left: priorityColor, bottom: BORDER_SOFT } })`，同时取消外层 Row + 内层 Column 的双层包裹，复选 + 内容 + 操作三段都放在一个 Column 内由 padding 控制间距。任务行高度现在按内容自然收缩。
  - **去掉永远固定的 Header**：之前 `build()` 在 Tabs 外层放 `this.Header()`，导致 Focus 品牌条永远占据屏幕顶部 80px。把 Header 信息（Focus 品牌 + 昵称 + 🔥 streak + 退出按钮）整合进今日 Tab 的 `TodayHeroCard` 顶部，外层 Column 只保留 Tabs。其他三个 Tab（任务/专注/复盘）顶部直接是页面内容（各自的标题），不再有任何顶栏。
  - 给四个 Tab 的 Scroll Column 统一加 `padding.top: 14`，避免去掉 Header 后内容贴顶。
  - 旧的 `@Builder Header()` 仍保留在 Index.ets 中作为死代码，未删除以便未来快速恢复，ArkTS 不会因未使用而报错。
- TaskRow + Header 调整后再次构建成功：`BUILD SUCCESSFUL in 1 min 14 s 268 ms`。
- 三轮视觉升级中遇到的 ArkTS 兼容性坑及修复：
  - 不要在 `@Builder` 中给 `linearGradient.colors` 写三元嵌套数组字面量（`cond ? [[c, 0], [d, 1]] : [[e, 0], [f, 1]]`），会触发 es2abc 语法错误。修复方式：把 if/else 上移到 Stack 内分别声明两个 `Column().linearGradient(...)` 节点。
  - 不要给 `@Builder` 传函数参数（如 `onTap: () => void`），会导致编译产物丢失一份程序而报 "size of programs is expected to be 14, but is 13"。修复方式：把那个 @Builder 拆掉，直接在 FilterBar 内 inline 写每个 Text chip 并就地绑定 onClick。
  - 不要给元素的 `.shadow()` 用三元返回不同字段值的对象（`cond ? { radius:14, color: c+'55', ... } : { ... }`）——直接去掉即可。

## 构建验证状态

- 第一次构建失败：系统环境变量 `DEVECO_SDK_HOME` 无效。
- 已改为在命令中临时设置：
  - `DEVECO_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk`
  - `OHOS_SDK_HOME=C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony`
- 第二次构建结果：
  - ArkTS 编译已通过。
  - 失败发生在 `PackageHap` 阶段，原因是系统找不到 Java Runtime。
- 前端最终构建已成功：
  - 临时设置 `JAVA_HOME=D:\Tools\java\jdk-21`
  - 命令：`hvigorw --mode module -p module=entry assembleHap`
  - 结果：`BUILD SUCCESSFUL`
  - HAP 输出：`D:\Study\26sp\arkts\final\entry\build\default\outputs\default\entry-default-unsigned.hap`
- 前端 UI 打磨后已再次构建成功：
  - 构建时间：2026-05-22
  - 命令：`hvigorw --mode module -p module=entry assembleHap`
  - 结果：`BUILD SUCCESSFUL in 1 min 17 s 699 ms`
  - 输出仍为：`D:\Study\26sp\arkts\final\entry\build\default\outputs\default\entry-default-unsigned.hap`
  - 仍有已知 warning：未配置 signingConfigs、`getContext` deprecated、通知 API deprecated、后台任务 syscap 差异、Preferences/RDB 方法可能抛异常提示；均未阻塞构建。
- 第二轮视觉升级后已再次构建成功：
  - 构建时间：2026-05-22
  - 命令：`hvigorw --mode module -p module=entry assembleHap`
  - 结果：`BUILD SUCCESSFUL in 1 min 14 s 221 ms`
  - 输出仍为：`D:\Study\26sp\arkts\final\entry\build\default\outputs\default\entry-default-unsigned.hap`
  - warning 与上一轮一致，均未阻塞构建。
- 第三轮视觉升级后已再次构建成功（含两次失败排错）：
  - 构建时间：2026-05-22
  - 命令：`"C:/Program Files/Huawei/DevEco Studio/tools/hvigor/bin/hvigorw" --mode module -p module=entry assembleHap`
  - 失败 #1：`PlantTile` 内 `.shadow(ternary ? {...} : {...})` 和 `TimerCard` / `FocusSolo` 中 `linearGradient.colors: ternary ? [[..]] : [[..]]` 触发 `10705000 Syntax Error: ',' expected` / `The size of programs is expected to be 14, but is 13`。
  - 失败 #2：`FilterChip` @Builder 接受函数参数 `(onTap: () => void)`，同样导致编译产物缺一份程序。
  - 修复后结果：`BUILD SUCCESSFUL in 22 s 470 ms`
  - 输出仍为：`D:\Study\26sp\arkts\final\entry\build\default\outputs\default\entry-default-unsigned.hap`
  - warning 与上一轮一致（signingConfigs 未配置、`getContext` deprecated、通知 API deprecated、后台任务 syscap 差异、Preferences/RDB 方法可能抛异常）。
- 后端最终构建已成功：
  - 命令：`mvn -q -DskipTests package`
  - 结果：成功生成 jar
  - Jar 输出：`D:\Study\26sp\arkts\final\focus-server\target\focus-server-0.0.1-SNAPSHOT.jar`
- 构建提示：
  - 当前项目未配置 signingConfigs，因此输出为 unsigned HAP。这不影响代码编译验证；真机安装/提交时需要在 DevEco Studio 配置签名证书。
  - hvigor daemon 端口不可用，自动降级为 no-daemon 模式，构建仍成功。

## 注意事项

- 当前 RDB 已有建表入口，但数据 CRUD 主要走 `FocusStore` 的本地状态，确保演示最稳。若继续增强，可将 `FocusStore` 的新增/更新/记录番茄同步落库。
- `@ohos/mpchart` 未安装，当前复盘页采用“ArkWeb H5 + 原生 ArkUI 图表兜底”的混合方案，减少第三方依赖风险。
- 后台任务 API 会提示“不是所有设备都支持”的 warning，属于 HarmonyOS syscap 差异；页面里有降级提示。
- 通知权限 API 有 deprecated warning，但可编译；后续可按当前 SDK 推荐 API 再替换。
- `focus-server` 使用 MySQL，需要先执行 `focus-server/src/main/resources/init.sql` 并按本机环境修改 `application.yml` 的数据库账号密码；不启动后端不影响 App 使用。

## 待办

1. 在 DevEco Studio 中配置个人签名证书，生成可安装的已签名 HAP。
2. 在模拟器/真机上走一遍演示流程：新增任务、开始番茄、完成番茄、中断记录、查看复盘、添加服务卡片。
3. 如需进一步加分，可把 `FocusStore` 的内存状态同步写入 RDB，并补充真实 AVPlayer 白噪音素材。
4. 若继续打磨 UI，可在真机截图基础上微调间距、字号和 Tab 栏文案；目前已通过编译，但尚未做设备截图走查。
