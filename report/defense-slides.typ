#set page(width: 16cm, height: 9cm, margin: 0.65cm, numbering: none)
#set text(font: ("Microsoft YaHei", "SimSun"), size: 18pt, lang: "zh")
#set par(leading: 0.55em)

#let slide-title(body) = [
  #text(size: 24pt, weight: "bold", fill: rgb("#0E1626"))[#body]
  #line(length: 100%, stroke: 1pt + rgb("#D8DEEA"))
  #v(0.25cm)
]

#align(center + horizon)[
  #text(size: 34pt, weight: "bold", fill: rgb("#0E1626"))[知序]
  #v(0.25cm)
  #text(size: 18pt, fill: rgb("#4258C9"))[AI Study Flow]
  #v(0.35cm)
  #text(size: 15pt, fill: rgb("#3F4A60"))[面向大学生学习闭环的 HarmonyOS 应用]
  #v(0.6cm)
  #text(size: 12pt, fill: rgb("#7A8398"))[ArkTS / ArkUI / RDB / Preferences / Spring Boot / AI]
]

#pagebreak()

#slide-title[01 选题背景]

- 课程资料分散在笔记、链接、课件和论文摘录中。
- 待办工具缺少资料上下文，番茄钟缺少任务闭环。
- 老师要求 4-5 个真实页面，每个页面都要有实际功能。
- 本项目目标：把资料、任务、专注、复盘连接成可用 App。

#pagebreak()

#slide-title[02 产品定位]

#text(size: 20pt, weight: "bold")[知序 = 学习资料到行动的本地优先工作流]

- 今日：学习进度、AI 建议、快速添加。
- 任务：搜索、筛选、完成、删除、恢复。
- 资料：多类型资料库、AI 摘要、生成任务。
- 专注：番茄计时、中断记录、通知与后台守护。
- 复盘：ArkWeb 图表、统计、学习森林。

#pagebreak()

#slide-title[03 系统架构]

#grid(columns: (1fr, 1fr, 1fr), gutter: 0.45cm)[
  #rect(fill: rgb("#EDF1FF"), radius: 6pt, inset: 12pt)[
    #strong[View]\ ArkUI 五页面\ 表单、筛选、状态反馈
  ]
][
  #rect(fill: rgb("#EAF5F0"), radius: 6pt, inset: 12pt)[
    #strong[ViewModel / Store]\ FocusStore\ 本地快照与写入门面
  ]
][
  #rect(fill: rgb("#FBF1E2"), radius: 6pt, inset: 12pt)[
    #strong[Model]\ RDB + Preferences\ 项目、任务、番茄、资料
  ]
]

#v(0.45cm)

- AI 服务是增强层，本地规则永远可用。
- Spring Boot + MyBatis + MySQL 是可选同步与全栈展示层。

#pagebreak()

#slide-title[04 本次核心创新：资料库]

- 新增 study_resources 本地表。
- 支持笔记、链接、课件、PDF/论文摘录四类资料。
- 资料可绑定项目、归档恢复、查看摘要和要点。
- 一键从资料生成专注任务，进入原有番茄闭环。

#v(0.35cm)

#rect(fill: rgb("#F8FAFC"), stroke: 1pt + rgb("#E4E9F2"), radius: 6pt, inset: 12pt)[
资料录入 -> AI/本地提炼 -> 生成任务 -> 番茄专注 -> 复盘统计
]

#pagebreak()

#slide-title[05 AI 功能设计]

- 本地规则：根据任务优先级、截止时间、中断次数、资料长度生成建议。
- 远程模型：运行时输入 endpoint、model、API Key，不写入源码。
- 失败回退：无密钥、网络失败、响应为空、格式异常时使用本地结果。
- 输出内容：摘要、三个要点、建议任务、预计专注分钟数。

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
- 新增资料页后，产品不再只是番茄钟，而是学习工作流。
- RDB 数据重启后仍保留，复盘统计来自真实记录。
- HAP 构建已通过，新增功能可编译打包。

#pagebreak()

#slide-title[08 总结与展望]

#text(size: 20pt, weight: "bold")[总结]

知序把学习资料、任务、番茄和复盘连接成闭环，并用 AI 提升资料到行动的转化效率。

#v(0.35cm)

#text(size: 20pt, weight: "bold")[展望]

- 文件选择、OCR、PDF 自动导入。
- 完整后端同步 UI 与冲突处理。
- AI 周报、资料问答、复习计划生成。
- 真机体验、无障碍和通知可靠性优化。
