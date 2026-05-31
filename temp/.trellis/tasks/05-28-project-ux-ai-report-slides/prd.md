# Project UX AI Report Slides Overhaul

## Goal

Continue the HarmonyOS learning-focus project into a more polished course-demo product by improving UX, modularizing maintainable code boundaries, completing optional AI integration, and delivering the final written report plus Typst defense slides.

This parent task coordinates four independently verifiable child deliverables:

- `05-28-ux-ui-modularization`: UX polish and maintainable UI/code structure.
- `05-28-ai-integration-completion`: remote AI runtime integration, explicit failure states, and user-facing status.
- `05-28-course-report-completion`: final Chinese course report source and PDF.
- `05-28-typst-defense-slides`: Typst presentation source and PDF with screenshot placeholders.

## Confirmed Facts

- The repo is a HarmonyOS ArkTS project with the main app under `entry/`.
- `entry/src/main/ets/pages/Index.ets` is the main UI container and is currently large, with many `@State` fields and `@Builder` sections.
- Core data is local-first: RDB stores projects, tasks, Pomodoro records, and study resources; `FocusStore` is the UI-facing facade.
- `FocusAiCoachService.ets` uses runtime settings to call a remote chat-completions-style service for task advice and resource insight.
- `report/course-report.typ`, `report/course-report.md`, and `report/defense-slides.typ` already exist.
- Existing Trellis tasks contain useful history for prior UI/UX, AI, and report work; this task supersedes them for the current integrated request.

## Requirements

- Improve the user experience from a product perspective: clarify information hierarchy, primary flows, visual consistency, and actionable page states.
- Modularize code conservatively: extract repeated constants, pure helpers, and safe UI style helpers when this lowers maintenance cost.
- Complete AI integration as a remote enhancement with runtime settings, explicit not-ready/failure status, and no committed secrets.
- Complete the written Chinese course report under `report/`, following the requested chapter structure and using screenshot placeholders where needed.
- Complete Typst slides under `report/`, presenting the project's core content and highlights with screenshot placeholders.

## Acceptance Criteria

- [ ] Child tasks are planned with testable `prd.md`, `design.md`, and `implement.md` artifacts where complex.
- [ ] UX/UI/code modularization child passes frontend build validation or records any environment blocker.
- [ ] AI child preserves local-first behavior and passes a secret scan.
- [ ] Report source and rendered PDF exist under `report/`.
- [ ] Slides source and rendered PDF exist under `report/`.
- [ ] Report and slides include screenshot placeholders instead of pretending screenshots exist.
- [ ] Final integration check records build, Typst, and secret-scan results.

## Out of Scope

- Spring Boot backend feature changes.
- Signed HAP packaging, unless the local signing configuration already exists.
- Real device screenshots; placeholders are acceptable for this request.
- Committing API keys, model tokens, or other credentials.
- Rewriting the whole ArkUI app into a new architecture in one pass.

## Open Questions

No blocking product questions remain from repository evidence. The recommended implementation posture is stable delivery first: improve UX and modularity incrementally, then complete AI/report/slides artifacts.
