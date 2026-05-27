# Product maturity and course report

## Goal

Push the HarmonyOS learning-focus app toward a more mature course-demo product and deliver the required course report/slides.

The product should no longer feel like a simple Pomodoro demo. It should present as a learning operating system for students: local-first task/focus/review remains the core, while AI and a study-resource/document workflow make the app closer to the teacher's requirement that every page has real functionality. The written report and slides must be generated under `report/` and match the provided thesis/report requirements.

Working product name proposal: **知序**. Rationale: it is more mature than "Focus", fits learning order/planning/review, and still leaves room for an English subtitle such as "AI Study Flow".

## Confirmed Facts

- The app is a HarmonyOS ArkTS project under `entry/`.
- Current main app already has 4 real tabs: Today, Tasks, Focus, Review.
- The app also includes an independent `FocusAbility`, an ArkWeb review page, a service card, local RDB, Preferences settings, and optional backend code.
- RDB currently stores `projects`, `tasks`, and `pomodoros` in `focus.db`.
- `FocusStore` is the UI-facing facade for task/project/pomodoro flows.
- `FocusAiCoachService` already supports local heuristic advice and optional OpenAI-compatible remote requests through runtime endpoint/model/key settings.
- Runtime settings and AI settings use Preferences, not RDB.
- `report/` already contains the teacher/template materials:
  - `毕业论文初稿.docx`
  - `毕业论文初稿.pdf`
  - `论文样张.pdf`
  - `南开大学2020年本科毕业论文指导手册.docx`
- `typst` is available locally.
- `pdftotext` is available locally.
- `python-docx` is not currently installed in the default Python environment.
- The GitHub template URL is reachable by git (`Tr0py/NKU-thesis-template-2020`).

## Requirements

- Rename/polish the product identity away from the generic "Focus" name, unless implementation risk says to keep internal class/file names unchanged and only update visible product copy.
- Add a real study-resource/document workflow if scoped in:
  - local-first document/resource records
  - association with tasks or projects
  - AI-assisted summary / next action / task extraction
  - UI that is usable, not a placeholder page
- Preserve the existing local-first contract:
  - task/project/pomodoro records remain RDB-backed
  - AI stays optional and must degrade to local logic
  - no provided AI token may be committed to any file
- Improve course-demo value:
  - the app should clearly satisfy "4-5 pages, each with real function"
  - backend/database capability should be explainable in the report
  - AI capability should be explainable as an enhancement layer
- Generate additional image assets only when they directly support the upgraded product workflow.
- Write the course report under `report/`:
  - include 3-5 keywords
  - abstract introduces background/problem, then method and effect
  - use automatic heading hierarchy suitable for generated TOC
  - chapter 1: introduction, background/significance, related work/problem, organization
  - chapter 2: tool/framework selection and comparison
  - chapter 3: system design using MVVM framing; no code pasted
  - chapter 4: system implementation, screenshots/effects/critical issues; no code pasted
  - chapter 5: summary and outlook in separate sections/paragraphs
- Create Typst slides under `report/`.
- Keep final report/slides artifacts organized under `report/`.

## Acceptance Criteria

- [ ] Product naming is updated in visible app/documentation surfaces or explicitly documented as a report-only name if code rename is too risky.
- [ ] The app has at least one additional mature, real workflow beyond the existing task/focus/review loop, preferably study-resource/document centric.
- [ ] New/changed functionality builds successfully as a HAP.
- [ ] No committed file contains the provided Anthropic token or image API key.
- [ ] Report source and rendered deliverable are present under `report/`.
- [ ] Report follows the required chapter structure and avoids code blocks in chapters 3 and 4.
- [ ] Slides source and rendered deliverable are present under `report/`.
- [ ] Validation results are recorded in task docs.

## Notes

- Treat user-provided API credentials as runtime-only. Do not store them in repo files.
- Existing untracked `report/` files appear to be user-provided source materials and should be preserved.
- This is a complex task; create `design.md` and `implement.md` before starting implementation.

## Open Question

- Resolved: implement the higher-value product slice, a study-resource/document library with AI extraction, as long as the implementation remains stable and local-first.
