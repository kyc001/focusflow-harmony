# Design: Course Report Deep Rewrite

## Document Strategy

The revised paper should shift from "feature overview" to "graduation-thesis-style engineering analysis of a real HarmonyOS learning workflow". It should treat "知序" as a learning-loop system whose technical value is the connection between local-first storage, resource management, AI-assisted extraction, Pomodoro execution, and review analytics.

## Target Structure

1. Cover/title page.
2. Chinese abstract and keywords.
3. English abstract and keywords.
4. Table of contents.
5. Chapter 1: Introduction.
   - Background and problem.
   - Existing learning tools and limitations.
   - Project value and contributions.
   - Paper organization.
6. Chapter 2: Technology Background and Development Environment.
   - HarmonyOS, ArkTS, ArkUI.
   - RDB and Preferences.
   - Ability/AppStorage and ArkWeb.
   - Remote AI service integration.
   - Spring Boot/MyBatis/MySQL backend.
   - Typst document workflow.
7. Chapter 3: Requirements and Overall System Design.
   - User roles/scenarios.
   - Functional requirements.
   - Non-functional requirements: privacy, offline usability, maintainability, security.
   - Architecture: ArkUI page layer, state layer, store/service layer, RDB/Preferences layer, optional backend/AI.
8. Chapter 4: Data Model and Persistence Design.
   - Domain objects and status values.
   - RDB table design and local-first write flow.
   - Preferences settings design.
   - Data consistency and refresh strategy.
9. Chapter 5: Key Module Implementation Analysis.
   - Today/task flow.
   - Study resource workflow.
   - Remote AI extraction and failure boundary.
   - Pomodoro/FocusAbility flow.
   - Review/ArkWeb/statistics/forest.
   - UI design tokens and maintainability.
10. Chapter 6: Result Analysis and Testing.
    - Functional coverage.
    - Build validation.
    - Persistence validation plan.
    - Security and secret scanning.
    - Limitations.
11. Chapter 7: Summary and Outlook.
12. Acknowledgements.
13. References.

## Content Boundaries

- Do not include CVK as a used technology.
- Discuss only implemented technologies and project modules. Do not pad with unrelated class content.
- Do not paste source code; describe contracts, flows, and decisions in prose/tables/diagrams.
- Do not claim real user experiments, measured performance, cloud test minutes, or certification screenshots unless artifacts exist.
- Do not expose API keys or private endpoints.

## Evidence Sources

- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/pages/FocusSolo.ets`
- `entry/src/main/ets/focusability/FocusAbility.ets`
- `entry/src/main/ets/models/FocusModels.ets`
- `entry/src/main/ets/services/FocusStore.ets`
- `entry/src/main/ets/services/FocusDatabase.ets`
- `entry/src/main/ets/services/FocusSettingsService.ets`
- `entry/src/main/ets/services/FocusAiCoachService.ets`
- `entry/src/main/ets/repository/AuthRepository.ets`
- `entry/src/main/resources/rawfile/charts/index.html`
- `focus-server/` backend files when discussing backend role.
- Teacher requirements supplied in the user message.

## Formatting Design

- Keep Typst macros simple and robust.
- Use tables for technology comparison, requirements, RDB tables, module responsibilities, and validation matrix.
- Use architecture diagrams as text boxes or tables, not complex image dependencies.
- Keep screenshot placeholders, but present them as "待替换图" only where useful.
- Add references as a compact list; avoid unsupported citation tooling unless already configured.

## Validation Design

- Compile Typst to PDF.
- Count Chinese characters approximately from Typst source after removing markup, ensuring more than 5000 substantive characters.
- Scan report files for token patterns.
- Check that "CVK" / "Core Vision Kit" does not appear as a claimed technology.
- Check that body sections do not contain fenced/source-code blocks.

## Rollback

All work is isolated to `report/` and Trellis task files. If Typst compile fails, keep the previous generated PDF untouched until the source is corrected; do not change app code for this paper rewrite.
