# Implement: 论文重构执行计划

任务上下文加载顺序：implement.jsonl(无) → prd.md → design.md → 本文件。所有改动只在 `report/nku-thesis-template-2020/` 内的 `.tex`/`.bib`，不改 App 源码。

## 执行顺序(按 LaTeX 文件分阶段)

### 阶段 A 骨架与元数据(main.tex)
- [ ] A1 封面：学号 `191xxxx`→`2413575`、年级 `2026`→`2024`、题目定稿(中/英主副标题, 见 design §0)。
- [ ] A2 在导言区新增截图占位宏 `\shotPlaceholder{文件名}{说明}`(灰底 `\fbox{\parbox}`，缺图也能编译)。
- [ ] A3 校验 `\include` 顺序与 `\begin{spacing}{1.5}` 包裹正文。

### 阶段 B 摘要与关键词(abstract.tex)
- [ ] B1 中文摘要重写(背景→问题→方法→效果, ~430 字) + 5 关键词。
- [ ] B2 英文摘要 + keywords 对应改写。

### 阶段 C 正文六章(course-report.tex 全量重写)
- [ ] C1 第 1 章 序论(1.1 背景意义 / 1.2 国内外研究现状 / 1.3 主要工作 / 1.4 组织结构)。
- [ ] C2 第 2 章 相关技术与开发工具选型(2.1–2.5 技术背景 + 2.6 含语言/IDE/架构/后端 4 张对比表与选型理由)。
- [ ] C3 第 3 章 系统设计(3.1 需求目标 / 3.2 MVVM 总体 / 3.3 模型层+表3-1~3-2 / 3.4 视图层+图3-3 / 3.5 控制层+表3-3 / 3.6 资料闭环+图3-4 / 3.7 AI+算法3-1 / 3.8 后端边界+表3-4+图3-5；图3-1/3-2 架构与 MVVM)。
- [ ] C4 第 4 章 系统实现(4.1 环境工程+表4-1 / 4.2 五大闭环 / 4.3 AI 安全 / 4.4 卡片诚实说明 / 4.5 关键问题 / 4.6 运行效果含图4-1~4-6 占位)。
- [ ] C5 第 5 章 测试与结果分析(5.1 策略 / 5.2 用例表5-1 / 5.3 构建兼容 / 5.4 结果分析与局限)。
- [ ] C6 第 6 章 总结与展望(两段, 正经面向未来)。

### 阶段 D 致谢与文献
- [ ] D1 acknowledgements.tex 保持正经、去空泛重复。
- [ ] D2 核对引用键：每条 `\cite` 都存在于 `nkthesis.bib`，无未引用告警致命问题；不新增编造文献。

### 阶段 E 编译与质检
- [ ] E1 编译通过(见验证命令)。
- [ ] E2 目录/交叉引用/文献渲染无 `??`、无未定义引用。
- [ ] E3 中文正文字数 ≥ 8000。
- [ ] E4 安全/合规扫描通过(无密钥/endpoint/CVK/正文代码块)。
- [ ] E5 通读润色，确保逻辑连贯、术语一致。

## 验证命令(PowerShell, 在 report/nku-thesis-template-2020/)

```
# 编译
latexmk -xelatex -interaction=nonstopmode main.tex
# 或手动：xelatex main; biber main; xelatex main; xelatex main

# 代码块自查(应无输出)
Select-String -Path course-report.tex -Pattern "lstlisting|begin\{verbatim\}"

# 密钥/endpoint/CVK 自查(应无输出)
Select-String -Path *.tex -Pattern "sk-[A-Za-z0-9]{10}|Bearer |xiaomimimo|Core Vision|CVK"

# 未定义引用自查
Select-String -Path main.log -Pattern "undefined|Warning: Citation"
```

字数粗算：统计 `course-report.tex` + `abstract.tex` 去除 `%` 注释与 `\command` 后的 CJK 字符数。

## 评审门(task.py start 前必须满足)
- prd.md / design.md / implement.md 三件齐备 ✓
- 用户已确认：6 章结构、8000–10000 字、截图占位、封面(学号 2413575/年级 2024)、题目授权调整 ✓
- 不变量清单(design §4)已固化 ✓

## 回滚点
- 旧稿由 git 跟踪，可随时 `git checkout -- course-report.tex` 恢复。
- 按 `\chapter` 为单元二分定位编译错误。
- 截图缺失用 `\shotPlaceholder` 宏兜底，不阻断编译。

## 风险与应对
- TikZ 图多→编译慢：先最小骨架编译通过，再逐图加入。
- 字数：六章预算 8500–9800，含缓冲；不足则在 §1.2/§2.6/§4.5 扩充论述(非灌水)。
- 中文排版：模板已配 xeCJK/字体，沿用现有 `\songti`/`\zihaowu` 等用法，不改 NKThesis.sty。
