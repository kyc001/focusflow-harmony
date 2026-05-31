# 课程论文深度重写与毕业论文格式完善

## Goal

Analyze the whole HarmonyOS ArkTS project and substantially expand the course report in `report/nku-thesis-template-2020/` so it reads like a thesis-style course paper for the Mobile Application Development course.

The report should remain honest about the course context: it is not a real undergraduate thesis, but it should follow the thesis template's structure, formatting conventions, technical depth, and evidence style.

## Confirmed Facts

- The project is a HarmonyOS ArkTS application named "知序" / ZhiXu, with a local-first study workflow product direction.
- The frontend lives under `entry/src/main/ets/` and includes ArkUI pages, UIAbilities, service card support, RDB/Preferences services, AI coach service, design tokens, native notification/background services, and an ArkWeb chart page.
- The backend lives under `focus-server/` and uses Spring Boot, MyBatis, MySQL-style schema resources, controllers, DTOs, entities, and mapper XML files.
- The current report is in the NKU thesis template under `report/nku-thesis-template-2020/`, especially `main.tex`, `abstract.tex`, `course-report.tex`, `references.tex`, and `nkthesis.bib`.
- The report folder also contains thesis-format references such as `论文样张.pdf`, `毕业论文初稿.pdf/.docx`, and `南开大学2020年本科毕业论文指导手册.docx`.
- Existing report content already covers background, requirements, design, implementation, testing, and conclusion, but the user feels it is still too simple.

## Requirements

- Deeply inspect the project source instead of writing generic prose.
- Target a complete thesis-like course report while controlling length: approximately 20 pages in the NKU template and roughly 5,000-8,000 Chinese characters/words of main report content, depending on table and bibliography pagination.
- Expand the report's technical content around real implemented modules:
  - HarmonyOS application lifecycle and Ability design.
  - ArkTS / ArkUI page structure and state management.
  - Local-first data flow through models, store, RDB, and Preferences.
  - Study resource library and AI dual-mode assistant behavior.
  - Pomodoro execution, interruption recording, native notification/background integration, and FocusAbility.
  - ArkWeb review charts and service card / backup extension points where applicable.
  - Optional Spring Boot backend, REST APIs, persistence model, and sync boundary.
- Improve thesis-style quality:
  - Clearer motivation, problem definition, requirements, architecture, implementation details, testing evidence, limitations, and future work.
  - More specific tables, algorithms, architecture descriptions, and implementation explanations grounded in project files.
  - Consistent product naming: user-facing name "知序" / ZhiXu; internal code may retain Focus-prefixed classes.
  - No fake claims about unavailable experiments, deployments, users, or measurements.
- Preserve the NKU thesis template structure and keep LaTeX compilable.
- Avoid leaking API keys, local secrets, or private credentials.

## Acceptance Criteria

- [ ] The old `.trellis/tasks/05-29-thesis-rewrite/` task is archived/completed and not reused for this work.
- [ ] A new Trellis task exists for this work and contains PRD, design, and implementation planning artifacts.
- [ ] The report aims for about 20 pages / 5,000-8,000 words or Chinese-character-equivalent main content, favoring technical density over filler.
- [ ] The report text is expanded with project-specific analysis rather than generic course-report filler.
- [ ] The main LaTeX files compile successfully, or any remaining compilation blocker is documented with the exact cause.
- [ ] The final PDF is regenerated when the local LaTeX toolchain permits it.
- [ ] The report remains accurate to the actual app and backend implementation.
- [ ] The final response summarizes changed files, verification commands, and any remaining risks.

## Out of Scope

- Implementing new app features unless a report claim reveals a small documentation/code mismatch that must be fixed.
- Rewriting the NKU thesis class/style file except for minimal compatibility fixes if compilation requires it.
- Producing a real undergraduate thesis submission with official student identity fields beyond the placeholders already present.
- Fabricating empirical user-study data, benchmark numbers, or deployment outcomes.

## Open Questions

- None blocking. The user selected a complete thesis-like style with controlled length.
