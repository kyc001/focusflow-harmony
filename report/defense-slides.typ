#set page(width: 16cm, height: 9cm, margin: 0.65cm, numbering: none)
#set text(font: ("Microsoft YaHei", "SimSun"), size: 18pt, lang: "zh")
#set par(leading: 0.55em)

#let title-slide(title, subtitle, foot) = align(center + horizon)[
  #text(size: 34pt, weight: "bold", fill: rgb("#0E1626"))[#title]
  #v(0.25cm)
  #text(size: 18pt, fill: rgb("#4258C9"))[#subtitle]
  #v(0.45cm)
  #text(size: 13pt, fill: rgb("#64748B"))[#foot]
]

#let slide-title(body) = [
  #text(size: 24pt, weight: "bold", fill: rgb("#0E1626"))[#body]
  #line(length: 100%, stroke: 1pt + rgb("#D8DEEA"))
  #v(0.25cm)
]

#let placeholder(label) = rect(width: 100%, height: 3.2cm, fill: rgb("#F8FAFC"), stroke: 1pt + rgb("#CBD5E1"), radius: 6pt, inset: 8pt)[
  #align(center + horizon)[
    #text(size: 15pt, weight: "bold", fill: rgb("#4258C9"))[截图占位：#label]
  ]
]

#title-slide[知序][AI Study Flow][面向大学生学习闭环的 HarmonyOS 应用]

#pagebreak()

#slide-title[01 选题背景]

- 学习资料、待办任务、番茄记录和复盘统计常常分散在不同工具中。
- 课程项目需要 4-5 个真实页面，每个页面都要有可操作功能。
- 本项目把资料、任务、专注、复盘串成一个移动端工作流。
- AI 定位为远程模型能力：配置后用于学习建议和资料提炼。

#pagebreak()

#slide-title[02 产品定位]

#text(size: 20pt, weight: "bold")[知序 = 从学习资料到专注行动的工作流]

- 今日：学习状态、快速添加、远程 AI 建议。
- 任务：搜索、筛选、完成、删除、恢复。
- 资料：资料库、文件引用、远程 AI 摘要、生成任务。
- 专注：番茄计时、中断记录、通知与后台守护。
- 复盘：ArkWeb 图表、热力图、学习森林。

#pagebreak()

#slide-title[03 系统架构]

#grid(columns: (1fr, 1fr, 1fr), gutter: 0.45cm)[
  #rect(fill: rgb("#EDF1FF"), radius: 6pt, inset: 12pt)[
    #strong[View]\ ArkUI 五页面\ 表单、筛选、状态反馈
  ]
][
  #rect(fill: rgb("#EAF5F0"), radius: 6pt, inset: 12pt)[
    #strong[Store]\ FocusStore\ RDB 快照与写入门面
  ]
][
  #rect(fill: rgb("#FBF1E2"), radius: 6pt, inset: 12pt)[
    #strong[Services]\ RDB / Preferences\ AI / Settings / Native
  ]
]

#v(0.35cm)

- Spring Boot + MyBatis + MySQL 用于全栈展示和后续同步扩展。
- AI 设置保存在 Preferences，API Key 不回显、不写入源码或报告。

#pagebreak()

#slide-title[04 核心亮点：学习资料库]

- 新增 `study_resources` 资料表。
- 支持备忘录、链接说明、课件摘录和文件 URI 引用。
- 资料可绑定项目、归档恢复、查看摘要和要点。
- AI 成功提炼后，一键生成专注任务并进入番茄流程。

#v(0.25cm)
#placeholder[资料库工作区]

#pagebreak()

#slide-title[05 远程 AI 集成]

- 运行时配置 endpoint、model、API Key。
- 支持拉取模型列表，空 Key 保存时保留旧密钥。
- 已保存 Key 不回显，界面只显示“已保存/未配置”。
- 未启用、缺 Key 或请求失败时显示状态提示，不生成替代 AI 建议。
- 资料摘要和要点只有远程 AI 成功返回后才写入 RDB。

#pagebreak()

#slide-title[06 数据库与持久化]

#table(
  columns: (1.7fr, 3.7fr, 2.2fr),
  inset: 7pt,
  [表], [内容], [用途],
  [projects], [项目名称、颜色、图标], [课程/方向组织],
  [tasks], [标题、备注、优先级、状态、标签、子任务], [任务闭环],
  [pomodoros], [开始时间、时长、完成/中断], [复盘统计],
  [study_resources], [标题、类型、内容、摘要、要点、关联任务], [资料库],
)

#pagebreak()

#slide-title[07 实现效果]

- App 形成 5 个真实页面，满足课程项目页面数量和功能要求。
- 资料页把“资料沉淀”变成“生成任务”的操作流。
- RDB 保存任务、资料和番茄记录，复盘统计来自真实记录。
- HAP 构建通过，报告与 slides 均可由 Typst 编译为 PDF。

#v(0.25cm)
#placeholder[今日页 / 资料页 / 复盘页截图]

#pagebreak()

#slide-title[08 总结与展望]

#text(size: 20pt, weight: "bold")[总结]

知序把学习资料、任务、番茄和复盘连接成闭环，并通过远程 AI 提升资料到行动的转化效率。

#v(0.35cm)

#text(size: 20pt, weight: "bold")[展望]

- 替换报告和 slides 中的实际截图。
- 完善后端同步 UI 与冲突处理。
- 扩展远程 AI 资料问答、复习计划和周报生成。
- 增强真机体验、无障碍和通知可靠性。
