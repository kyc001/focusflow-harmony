# Course Report Deep Rewrite

## Goal

Rewrite the Chinese course paper into a substantially stronger graduation-thesis-style project paper for the HarmonyOS app "知序", with at least 5000 Chinese characters of substantive body content. The paper should be written as seriously as a bachelor's thesis, not as a shallow feature list or casual course summary.

## User Intent

- The current paper feels too thin and superficial.
- The revised paper must deeply analyze this actual project: local-first learning workflow, ArkTS/ArkUI implementation, RDB and Preferences persistence, AI integration boundaries, FocusAbility handoff, ArkWeb review, backend role, and product/engineering trade-offs.
- Do not write about Core Vision Kit / CVK, because this project did not use it. The teacher mentioned CVK in class, but fabricating usage would weaken the paper.
- Target length: at least 5000 Chinese characters; longer is acceptable if the writing remains focused, formal, and evidence-backed.
- Positioning decision from the user: write it as a graduation paper. Discuss only technologies and modules actually used by the project.

## Confirmed Facts

- Current report sources:
  - `report/course-report.typ`
  - `report/course-report.md`
  - generated `report/course-report.pdf`
- Current Typst source has about 7k non-whitespace/markup-stripped characters, but much of it is high-level description. It needs deeper analysis and a more thesis-like structure.
- Existing project capabilities include:
  - HarmonyOS ArkTS / ArkUI app under `entry/src/main/ets`.
  - `FocusStore` facade for tasks, resources, Pomodoro records, statistics, and local-first writes.
  - `FocusDatabase` RDB schema with `projects`, `tasks`, `pomodoros`, and `study_resources`.
  - Preferences services for focus settings, AI settings, and auth profile.
  - `FocusAbility` and `FocusSolo` standalone focus mode with AppStorage handoff.
  - Study resources workflow: memo/link/courseware/pdf/file reference, AI extraction, task generation, archive/restore.
  - Remote AI service returns explicit status when disabled, unconfigured, failed, empty, or unparseable; no local fake AI advice should be described.
  - ArkWeb chart review and native review/forest statistics.
  - Optional Spring Boot/MyBatis/MySQL backend exists as full-stack demonstration and future sync base, but core app is local-first.
- Teacher requirements from latest class:
  - Paper should follow undergraduate thesis-style structure: cover, Chinese/English abstract and keywords, table of contents, introduction with research status and organization, background/tools, design/framework, experimental/result analysis, summary/outlook, acknowledgements, references.
  - Body should not paste source code; source code may be appendix only and does not count as body.
  - Summary/outlook should be serious and future-oriented, not self-deprecating.
  - Scoring values novelty, completeness, technical depth, page complexity, PPT aesthetics, format, backend/database complexity, and optional Huawei certification proof.

## Requirements

- Rewrite `report/course-report.typ` as the authoritative source.
- Keep `report/course-report.md` as a concise companion outline/summary updated to match the rewritten paper.
- Generate `report/course-report.pdf` from Typst after edits.
- Use Chinese formal academic/engineering prose.
- Include at minimum:
  - title page metadata;
  - Chinese abstract and keywords;
  - English abstract and keywords if feasible within Typst;
  - table of contents;
  - introduction with background, problem, related product/research status, project value, and organization;
  - technology background/tooling chapter covering HarmonyOS, ArkTS/ArkUI, RDB, Preferences, ArkWeb, Ability/AppStorage, Spring Boot/MyBatis/MySQL, Typst;
  - system requirements and architecture chapter;
  - data model and persistence chapter with RDB/Preferences contracts;
  - key workflow analysis: resources -> AI extraction -> task -> Pomodoro -> review;
  - implementation analysis of UI/state/data flow/security/failure handling;
  - result/evaluation chapter using build results, functional coverage, page complexity, and known limitations without fabricating user experiments;
  - summary/outlook;
  - acknowledgements and references.
- Explicitly say CVK is not part of this project only if needed to explain scope; otherwise omit it completely.
- Do not include real API keys, private endpoints, bearer tokens, or source-code blocks in the body.
- Emphasize:
  - local-first design as core engineering contribution;
  - remote AI as optional enhancement;
  - RDB/Preferences division;
  - safe AI settings handling;
  - resource workflow maturity;
  - backend/database presence and complexity without overstating runtime dependency.

## Acceptance Criteria

- [ ] `report/course-report.typ` is deeply rewritten and aligned with the real implemented project.
- [ ] Paper body has at least 5000 Chinese characters of substantive prose and reads as a graduation-thesis-style engineering paper.
- [ ] The report does not claim CVK usage.
- [ ] The report contains no source-code blocks in chapters/body sections.
- [ ] The report includes a serious summary/outlook and does not self-deprecate the project.
- [ ] `report/course-report.md` matches the revised paper at outline/summary level.
- [ ] `typst compile report/course-report.typ report/course-report.pdf` succeeds.
- [ ] Secret scan over `report/` finds no committed token/API-key patterns.

## Out of Scope

- Adding CVK features or claiming CVK was used.
- Changing app source code.
- Fabricating real user-study data, performance numbers, or screenshots.
- Completing PPT/recording/source-code zip in this task unless the user explicitly expands scope.

## Resolved Decisions

- Paper identity: graduation-thesis-style engineering paper.
- Technology scope: only write technologies the project actually used; do not pad the paper with unused class topics.
