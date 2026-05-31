# Design: Project UX AI Report Slides Overhaul

## Architecture And Boundaries

This parent task is an integration wrapper. It owns the end-to-end product goals, child-task map, and final acceptance review. Direct code or document implementation should happen in child tasks.

Implementation boundaries:

- App UI and ArkTS changes belong to `05-28-ux-ui-modularization`.
- AI service/settings/remote failure-state behavior belongs to `05-28-ai-integration-completion`.
- Long-form report writing belongs to `05-28-course-report-completion`.
- Presentation writing belongs to `05-28-typst-defense-slides`.

The Harmony app must continue to follow the local-first contract: RDB remains the source of truth for projects/tasks/Pomodoro records/study resources; `FocusStore` remains the UI-facing facade; Preferences remain the storage layer for auth/settings/AI runtime configuration; AI remains an enhancement layer.

## Data Flow

App flow to preserve:

1. Page loads via database/settings initialization, `focusStore.refresh()`, and page-state sync.
2. UI actions call `FocusStore` or settings services.
3. Local data is written first.
4. Page state refreshes from local data.
5. Optional AI reads snapshots and returns display advice or resource insight.

Document flow:

1. Typst sources under `report/` are edited.
2. Screenshot placeholders are represented as labeled boxes/figures.
3. PDFs are generated from Typst.
4. Final review checks that report/slides align with the implemented product.

## Compatibility Notes

- Do not rename internal `Focus*` classes/files just to match the visible product name.
- Do not change RDB schema unless a child task explicitly scopes and validates it.
- Existing generated media and uncommitted files must be preserved unless the task directly requires touching them.
- Typst output can replace existing generated PDFs if the sources are intentionally updated.

## Rollback Shape

- App changes can be reverted child-by-child because UI and AI changes are separated.
- Report/slides changes are isolated under `report/` and can be regenerated from Typst.
- If a risky ArkUI split fails, keep the visible UX polish and revert only the structural extraction.
