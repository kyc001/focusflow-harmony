# Design: 知序课程论文深度重构(6 章, 南开 LaTeX)

本设计基于对真实代码的逐文件核对(FocusModels / FocusDatabase / FocusStore / FocusAiCoachService / FocusNativeServices / FocusAbility / FocusSolo / Index / FocusCard / SeedData / AuthRepository / FocusSettingsService / charts.html / focus-server)。论文所有技术陈述必须可在代码中找到依据。

## 0. 封面与文档骨架(main.tex)

- 学号 `191xxxx` → `2413575`；年级 `2026` → `2024`；姓名/专业/学院/导师保持；完成时间 2026 年 5 月。
- 题目定稿(授权调整)：中文主标题 **「知序：基于 HarmonyOS 的本地优先学习管理应用设计与实现」**，副标题 **「资料·任务·专注·复盘一体化学习闭环」**；英文 **「Design and Implementation of ZhiXu: A Local-First Study-Management Application on HarmonyOS」**。
- 文档顺序不变：`\include{abstract}` → `\tableofcontents` → `\include{course-report}`(6 章) → `\include{references}` → `\include{acknowledgements}`。
- 正文整体 `\begin{spacing}{1.5}` 保持。

## 1. 章节大纲与字数预算(目标中文正文 8500–9800 字)

### 摘要(abstract.tex 重写)
- 中文摘要 ~430 字：背景(资料分散/工具单点)→ 问题 → 方法(本地优先+MVVM+RDB/Preferences+可选AI+可选后端)→ 效果(离线闭环/构建通过)。
- 关键词(5)：HarmonyOS；ArkTS/ArkUI；本地优先架构；学习资料库；番茄工作法。(去掉"AI 学习助手"换"番茄工作法"以更贴合实现；或保留 5 选 5——见 implement 决定)
- 英文摘要与关键词对应改写。

### 第 1 章 序论(~1300 字)
- 1.1 研究背景与意义(资料碎片化、单点工具割裂、AI 与国产化机遇)
- 1.2 国内外研究现状：待办/GTD、番茄工作法、笔记工具、通用 AI 助手各自效果与**不足**；本地优先(local-first)研究脉络；引出"统一移动学习闭环 + 本地优先"必要性。
- 1.3 本文主要工作(5 条：实体与 RDB；3Tab+浮层+独立窗口的五大功能闭环；AI 增强与显式降级；HarmonyOS 平台能力；测试与构建验证)
- 1.4 论文组织结构

### 第 2 章 相关技术与开发工具选型(~1750 字)
- 2.1 HarmonyOS 与 Stage 模型(UIAbility/ExtensionAbility 生命周期)
- 2.2 ArkTS 语言与 ArkUI 声明式 UI(状态驱动、@State/@Builder/@StorageProp)
- 2.3 端侧持久化：RDB(关系型/结构化)与 Preferences(KV/运行时配置)分工
- 2.4 ArkWeb 与原生能力(Web+javaScriptProxy、notificationManager、backgroundTaskManager、AppStorage、服务卡片)
- 2.5 后端技术(Spring Boot/MyBatis/MySQL、REST)
- 2.6 **开发工具与框架选型对比**(老师点名)：
  - 表：移动端语言/平台对比(ArkTS+HarmonyOS vs Java/Kotlin+Android vs 跨端 Flutter/RN)→ 选 ArkTS(课程要求+声明式+端云能力)
  - 表：IDE 对比(DevEco Studio vs Android Studio vs Eclipse)→ 选 DevEco
  - 表：架构模式对比(MVVM vs MVC vs MVP)→ 选 MVVM
  - 表：后端/报告工具简述(Spring Boot；LaTeX/南开模板)

### 第 3 章 系统设计(~2300 字, MVVM 主线)
- 3.1 需求与设计目标(功能需求=五大闭环；非功能=离线可用/持久化/安全/可维护/兼容；本地优先约束)
- 3.2 总体架构与 MVVM 模式：**模型(FocusModels+FocusDatabase+三类 Preferences 服务)/视图(ArkUI 页面与浮层)/控制(FocusStore ViewModel)** 三部分职责与关系 + 优点论述【图3-1 架构, 图3-2 MVVM 职责】
- 3.3 模型层设计：四实体 + RDB 表结构(focus.db v3) + JSON 半结构化列 + 三态/归档枚举 + 3 个 Preferences 命名空间【表3-1 RDB 表, 表3-2 Preferences 命名空间】
- 3.4 视图层设计：登录门 → 3 主 Tab(今日/任务/我的) → 6 模态浮层 → FocusAbility 独立专注窗口；响应式(viewportWidth)【图3-3 导航结构】
- 3.5 控制层设计：FocusStore 单向数据流"页面操作→Store 写 RDB→refresh→syncFromStore 复制状态"；核心写入路径与一致性约束【表3-3 写入路径】
- 3.6 资料学习闭环设计：资料→(可选)AI 提炼→生成任务→番茄→复盘【图3-4 闭环】
- 3.7 AI 模块与网络设计：Chat Completions 兼容、Bearer、结构化解析；**显式降级**(未启用/无key/非2xx/空/不可解析)【算法3-1 远程 AI 降级】
- 3.8 后端与同步边界设计：REST 端点表、since 增量 pull、clientRequestId 幂等 push、统一 Result；明确移动端定位为可选同步【表3-4 端点, 图3-5 同步】

### 第 4 章 系统实现(~2300 字, 不贴代码)
- 4.1 开发环境与工程结构(客户端 entry/ets 目录树文字描述 + 后端分层)【表4-1 技术栈与版本】
- 4.2 五大功能闭环实现
  - 4.2.1 今日工作台与任务管理(快速添加只走 Store；搜索/筛选/四象限/软删除回收站；三态机)
  - 4.2.2 学习资料库与"资料—任务"闭环(多类型录入、文件 URI 引用、AI 提炼回写 summary/keyPoints、createTaskFromResource 回写 linked_task_id)
  - 4.2.3 番茄专注(内嵌 FocusTimerOverlay + 独立 FocusAbility/FocusSolo；Want→AppStorage→@StorageProp 交接；setInterval；完成→通知+recordPomodoro；后台 requestSuspendDelay 保护)
  - 4.2.4 复盘统计与可视化(Store 派生 completedPomodoros/totalFocusMinutes/weekFocusPoints/projectFocusPoints/streakDays；ArkWeb nativeBridge+render；学习森林解锁)
- 4.3 远程 AI 增强实现(设置归一化、**maskedAiKey 掩码 + 留空保留 key** 的安全处理、模型列表拉取)
- 4.4 服务卡片与扩展能力(EntryFormAbility/FocusCard、FormLink 拉起；**诚实说明当前静态演示数据**)
- 4.5 关键技术问题与解决(跨层一致性走 Store；AI 不稳定→显式状态；Ability 热启动 onNewWant；key 安全；文件导入仅 URI 的范围控制)
- 4.6 运行效果【图4-1~4-6 运行截图占位：登录/今日/任务/资料+AI/专注/复盘】

### 第 5 章 系统测试与结果分析(~1150 字)
- 5.1 测试策略(功能测试+构建验证+兼容性观察)
- 5.2 功能测试【表5-1 用例与结果】(沿用并扩充：登录、今日添加、任务三态、资料持久化、AI 未配置状态、资料生成任务、番茄完成/中断、复盘统计、设置持久化、独立专注交接)
- 5.3 构建验证与兼容性观察(hvigor HAP / Maven JAR；ArkWeb/通知/卡片/文件选择真机待验证项)
- 5.4 结果分析(完成度、页面复杂度=3Tab+6浮层+独立窗口+数十 Builder、本地优先达成度、诚实局限)

### 第 6 章 总结与展望(~750 字)
- 6.1 工作总结(一段)
- 6.2 研究展望(一段，正经未来方向：文档正文解析/OCR、后端同步 UI 产品化与冲突处理、本地小模型/缓存、错题与周报、真机兼容与无障碍)；**不自嘲**。

## 2. 图表清单(全部自动编号, 矢量优先)

| 编号 | 类型 | 内容 | 实现 |
|---|---|---|---|
| 图3-1 | TikZ | 总体分层架构 | 复用并精修现有 tikzpicture |
| 图3-2 | TikZ | MVVM 三层职责与数据流 | 新增 |
| 图3-3 | TikZ | 导航结构(登录/3Tab/浮层/独立窗口) | 新增 |
| 图3-4 | TikZ | 资料→AI→任务→番茄→复盘闭环 | 新增 |
| 算法3-1 | algorithm | 远程 AI 请求与显式降级 | 复用精修 |
| 图3-5 | TikZ | 后端 pull/push 增量同步 | 新增 |
| 图4-1~4-6 | 占位图 | 运行截图 | `\includegraphics` 占位 + 图注；缺图时用 `\fbox{\parbox}` 占位框避免编译失败 |
| 表2-1~2-4 | tabularx | 语言/IDE/架构/后端工具选型对比 | 新增 |
| 表3-1 | tabularx | RDB 4 表结构 | 精修现有 |
| 表3-2 | tabularx | Preferences 3 命名空间与键 | 新增 |
| 表3-3 | tabularx | 写入路径与一致性约束 | 精修现有 |
| 表3-4 | tabularx | 后端 REST 端点 | 新增 |
| 表4-1 | tabularx | 技术栈与版本 | 精修现有 |
| 表5-1 | tabularx | 功能测试用例与结果 | 精修扩充 |

截图占位策略：定义 `\newcommand{\shotPlaceholder}[1]` 输出灰底占位框 + 文件名提示，用户把 PNG 放入 `figures/` 后改为 `\includegraphics` 即可；**保证当前无图也能编译**。

## 3. 参考文献计划

优先复用 `nkthesis.bib` 现有真实条目：HarmonyOS/ArkTS(su2025/wu2025harmobridge/aytekin2026/liu2024/zhang2023)、移动学习(crompton2017/2018、sung2016、ducate2016、shadiev2017)、番茄(cirillo2018、santiago2022、ardilah2025、antonenko2017)、AI 教育(kasneci2023、kabudi2021、bewersdorff2025、wang2024、li2023)、本地优先(kleppmann2019、turnbull2023)、MVVM(epiloksa2022)、SQLite/移动 DB(xu2010、liu2011、kwon2024、oracle2024)、GTD(allen2001)、HarmonyOS 指南(harmonyos2024)。按章节合理引用，**不编造新文献**；如需 MyBatis/Spring 引用则只用官方文档形式(misc/url)。

## 4. 不变量(硬约束, 实现时逐条自检)

1. 正文**无源代码块**(`lstlisting`/`verbatim` 禁用于正文)；算法用 `algorithm` 伪代码可接受。
2. **不出现**真实 endpoint(`token-plan-cn.xiaomimimo.com`)、API Key、Bearer token。
3. **不写 CVK / Core Vision Kit**。
4. 诚实标注局限：服务卡片静态数据、文件导入仅 URI、移动端同步未产品化、AVPlayer 白噪音为预留入口、首启种子演示数据(但统计真实计算)。
5. 总结/展望**两段**、正经、面向未来、**不自嘲**。
6. 中文正文 **≥ 8000 字**。
7. 目录/编号/参考文献**自动生成**。
8. 关键词 3–5 个；摘要"背景→问题→方法→效果"顺序。

## 5. 技术映射(论文断言 ↔ 代码依据, 防止失真)

- MVVM：Model=FocusModels/FocusDatabase；View=Index/FocusSolo 等 ArkUI；ViewModel=FocusStore(单例, 统一写入+统计)。
- RDB：focus.db v3, 4 表, JSON 列, addColumnIfMissing 迁移, try-finally 关 ResultSet。
- Preferences：focus_settings(timer.*/appearance.*/audio.*/notification.*)、focus_ai(ai.*)、focus_auth(auth.*)。
- 导航：Tabs(BarPosition.End) 3 项 + Stack 6 浮层 + FocusAbility→FocusSolo。
- 专注交接：FocusAbility.parseWant→AppStorage('focus.taskId'/'focus.taskTitle')→FocusSolo @StorageProp。
- 原生：notificationManager.publish；backgroundTaskManager.requestSuspendDelay/cancel。
- AI：FocusAiCoachService Chat Completions，requestAdvice/requestResourceInsight，5 类降级 remoteAdviceStatus/remoteResourceStatus，parseRemote* 结构化解析；UI maskedAiKey + 留空保留(Index.ets:317/3338)。
- 复盘：FocusStore 统计方法 + ArkWeb(Web $rawfile + javaScriptProxy nativeBridge + runJavaScript('render()')) + charts.html getStats/fallbackStats。
- 后端：Spring Boot 3.2.0/Java17/MyBatis3.0.3/MySQL；端点见表3-4；SyncController pull(since)/push(clientRequestId 幂等)。
- 登录：AuthRepository 本地 token(local-/guest-)，**不调后端**。

## 6. 编译与验证流程

1. `cd report/nku-thesis-template-2020`
2. `xelatex main` → `biber main` → `xelatex main` → `xelatex main`(或 `latexmk -xelatex main`)
3. 检查：`main.pdf` 生成、目录/交叉引用无 `??`、参考文献渲染、无 LaTeX error。
4. 字数核查(去命令后中文字符计数 ≥ 8000)。
5. 安全扫描 `report/`：无 `sk-`/`Bearer`/`xiaomimimo`/api-key 模式。

## 7. 回滚点

- 每章为独立 `\section`/`\chapter` 编辑单元；编译失败时按章二分定位。
- 保留旧 `course-report.tex` 内容片段直至新稿编译通过(git 可恢复)。
- 截图占位用宏，避免缺图导致编译中断。
