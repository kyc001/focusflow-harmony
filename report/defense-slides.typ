#import "@preview/touying:0.7.3": *
#import themes.simple: *

#show: simple-theme.with(
  aspect-ratio: "16-9",
  primary: rgb("#4258C9"),
  footer: [知序 FocusFlow Harmony],
)

#set text(font: ("Microsoft YaHei", "SimSun"), size: 17pt, lang: "zh")
#set par(leading: 0.55em)

#let blue = rgb("#4258C9")
#let ink = rgb("#0E1626")
#let muted = rgb("#64748B")
#let line-color = rgb("#D8DEEA")
#let soft-blue = rgb("#EDF1FF")
#let soft-green = rgb("#EAF5F0")
#let soft-amber = rgb("#FBF1E2")
#let soft-gray = rgb("#F8FAFC")

#let tag(body, fill: soft-blue, stroke: none) = rect(
  fill: fill,
  stroke: stroke,
  radius: 5pt,
  inset: (x: 7pt, y: 4pt),
)[#text(size: 12pt, weight: "bold", fill: ink)[#body]]

#let card(fill: soft-gray, body) = rect(
  width: 100%,
  fill: fill,
  stroke: 0.7pt + line-color,
  radius: 6pt,
  inset: 9pt,
)[#body]

#let metric(num, label, fill: soft-blue) = card(fill: fill)[
  #text(size: 23pt, weight: "bold", fill: blue)[#num]
  #v(2pt)
  #text(size: 13pt, fill: muted)[#label]
]

#let phone-shot(path, caption) = [
  #box(height: 6.1cm)[#image(path, height: 6.1cm, fit: "contain")]
  #v(0.08cm)
  #align(center)[#text(size: 12pt, fill: muted)[#caption]]
]

#title-slide[
  #text(size: 38pt, weight: "bold", fill: ink)[知序]
  #v(0.2cm)
  #text(size: 19pt, fill: blue)[面向大学生学习闭环的 HarmonyOS 应用]
  #v(0.45cm)
  #text(size: 13pt, fill: muted)[ArkTS · RDB · Navigation · Spring Boot · MySQL/H2]
]

== 01 选题与目标

#grid(columns: (1.15fr, 0.85fr), gutter: 0.55cm)[
  #text(size: 24pt, weight: "bold", fill: ink)[解决“资料很多，行动很散”的学习问题]

  - 资料、任务、专注记录和复盘常分散在多个工具。
  - 课程要求原生 HarmonyOS、4-5 个功能页面、MVVM 和 Navigation。
  - 本项目把“资料 -> 任务 -> 专注 -> 复盘 -> 同步”做成闭环。
  - AI 作为可配置远程能力，用于学习建议和资料提炼。
][
  #metric[5+][真实功能页面]
  #v(0.2cm)
  #metric(fill: soft-green)[4 表][前端 RDB 数据模型]
  #v(0.2cm)
  #metric(fill: soft-amber)[2 库][MySQL / H2 后端存储]
]

== 02 功能闭环

#grid(columns: (1fr, 1fr, 1fr, 1fr, 1fr), gutter: 0.18cm)[
  #card(fill: soft-blue)[#text(size: 15pt)[#strong[资料]#linebreak()课程材料、链接、摘录]]
][
  #card(fill: soft-green)[#text(size: 15pt)[#strong[AI 提炼]#linebreak()摘要、要点、行动建议]]
][
  #card(fill: soft-amber)[#text(size: 15pt)[#strong[任务]#linebreak()优先级、标签、子任务]]
][
  #card(fill: rgb("#F4EEFF"))[#text(size: 15pt)[#strong[番茄]#linebreak()完成、中断、时长]]
][
  #card(fill: rgb("#EEF7FF"))[#text(size: 15pt)[#strong[复盘]#linebreak()统计、热力图、同步]]
]

#v(0.3cm)

#grid(columns: (1fr, 1fr, 1fr), gutter: 0.35cm)[
  #phone-shot("nku-thesis-template-2020/figures/app-today.jpeg", [今日页])
][
  #phone-shot("nku-thesis-template-2020/figures/app-tasks.jpeg", [任务页])
][
  #phone-shot("nku-thesis-template-2020/figures/app-profile.jpeg", [我的页])
]

== 03 技术架构

#grid(columns: (1fr, 1fr, 1fr), gutter: 0.35cm)[
  #card(fill: soft-blue)[
    #text(weight: "bold", fill: ink)[View]
    #v(0.1cm)
    ArkUI 声明式 UI、Tabs 主导航、Navigation 详情页栈、ArkWeb 复盘图表。
  ]
][
  #card(fill: soft-green)[
    #text(weight: "bold", fill: ink)[ViewModel / Store]
    #v(0.1cm)
    FocusStore 汇聚任务、资料、番茄和设置状态，统一刷新本地快照。
  ]
][
  #card(fill: soft-amber)[
    #text(weight: "bold", fill: ink)[Model / Services]
    #v(0.1cm)
    RDB、Preferences、HTTP 同步、AI 服务、通知与后台能力。
  ]
]

#v(0.35cm)

#card(fill: rgb("#FFFFFF"))[
  Spring Boot 3.2 + MyBatis 提供登录、项目、任务、番茄、统计和同步接口；默认 MySQL，可切 H2 快速演示。
]

== 04 课程知识点命中

#text(size: 14pt)[#table(
  columns: (1.2fr, 2.2fr, 2.2fr),
  inset: 5pt,
  stroke: 0.6pt + line-color,
  [知识点], [项目实现], [答辩可讲证据],
  [Navigation], [个人页详情使用 `NavPathStack` 和 `NavDestination`], [资料库、复盘、云同步、设置均为页面栈跳转],
  [RDB], [`projects/tasks/pomodoros/study_resources`], [`ResultSet` 在 `finally` 中释放],
  [Preferences], [登录态、AI 配置、轻量设置], [按需 flush，避免频繁落盘],
  [网络], [http GET/POST + Spring Boot], [`clientRequestId` 处理 POST 非幂等],
  [UIAbility], [EntryAbility、FocusAbility、Form、Backup], [独立专注窗口与桌面卡片],
)]

== 05 数据库与同步设计

#grid(columns: (1.05fr, 0.95fr), gutter: 0.45cm)[
  #text(size: 22pt, weight: "bold", fill: ink)[本地优先，可选云同步]

  - 前端 RDB 保存核心业务数据，离线可用。
  - 后端 MySQL 正式演示，H2 快速测试。
  - 同步兼容 snake_case / camelCase。
  - 番茄记录按 `clientRequestId` upsert，避免重复统计。
][
  #card(fill: soft-blue)[#text(size: 15pt)[
    #strong[前端 RDB]
    #v(0.1cm)
    projects / tasks / pomodoros / study_resources
  ]]
  #v(0.18cm)
  #card(fill: soft-green)[#text(size: 15pt)[
    #strong[后端数据库]
    #v(0.1cm)
    users / projects / tasks / pomodoros
  ]]
  #v(0.18cm)
  #card(fill: soft-amber)[#text(size: 15pt)[
    #strong[冲突控制]
    #v(0.1cm)
    updatedAt + clientRequestId
  ]]
]

== 06 稳定性与工程化

#grid(columns: (1fr, 1fr), gutter: 0.4cm)[
  #card(fill: soft-blue)[
    #strong[构建稳定]
    - `build-frontend.ps1` 固定 DevEco JBR
    - 规避系统 Oracle Java 注册表问题
    - `PackageHap` 与 `PackageApp` 均通过
  ]
][
  #card(fill: soft-green)[
    #strong[密钥安全]
    - AI Key 和 MySQL 密码进入本地 `.env`
    - 构建时生成被忽略的 `ai-env.json`
    - 源码和 README 不提交真实密钥
  ]
]

#v(0.25cm)

#grid(columns: (1fr, 1fr), gutter: 0.4cm)[
  #card(fill: soft-amber)[
    #strong[运行期防护]
    - 网络请求 try-catch
    - http 对象 finally 释放
    - RDB 查询结果集 finally close
  ]
][
  #card(fill: rgb("#F4EEFF"))[
    #strong[仓库清理]
    - `tools/` 和 LaTeX 中间产物不进 Git
    - `.gitattributes` 优化 GitHub 语言识别
    - README / PROJECT_CONTEXT 可复现实验环境
  ]
]

== 07 论文与交付物

#grid(columns: (1fr, 1fr), gutter: 0.45cm)[
  #card(fill: soft-blue)[
    #strong[论文已补齐]
    - 第一章加入国内外研究现状
    - 第二章加入横向技术选型对比
    - 第三章补 MVVM、Navigation、数据库设计
    - 第四章补性能与稳定性调优
  ]
][
  #card(fill: soft-green)[
    #strong[答辩提交包]
    - 课程设计报告 PDF
    - 前后端源码压缩包
    - 本 PPT PDF
    - 1-2 分钟运行录屏
  ]
]

#v(0.35cm)

#tag[已验证：前端 assembleApp 通过] #h(0.2cm)
#tag(fill: soft-green)[后端 mvn test 通过] #h(0.2cm)
#tag(fill: soft-amber)[论文 PDF 已生成]

== 08 总结与展望

#text(size: 22pt, weight: "bold", fill: ink)[总结]

知序完成了原生 HarmonyOS 前端、Spring Boot 后端、关系型数据库、本地持久化、AI 辅助和同步闭环，核心功能均来自真实业务数据而非静态展示。

#v(0.35cm)

#text(size: 22pt, weight: "bold", fill: ink)[展望]

- 增强同步冲突策略，从简单幂等去重扩展到更完整的版本合并。
- 扩展 AI 资料问答、阶段复习计划和周报生成。
- 完善真机通知、后台计时可靠性和更多无障碍体验。
