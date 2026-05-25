# Design: Focus Detailed Design Document

## Scope

The deliverable is a root-level Chinese Markdown document, `设计文档.md`, plus a small `HANDOVER.md` update. The task does not change runtime behavior.

## Source Of Truth

The document must describe the repository as it exists after the local-first refactor and frontend polish:

- Product docs: `需求文档.md`, `HANDOVER.md`
- Frontend contracts: `.trellis/spec/frontend/harmony-focus-local-first.md`
- Harmony app configuration: `entry/src/main/module.json5`, `entry/src/main/resources/base/profile/*.json`
- ArkTS model/data/store:
  - `entry/src/main/ets/models/FocusModels.ets`
  - `entry/src/main/ets/data/SeedData.ets`
  - `entry/src/main/ets/services/FocusDatabase.ets`
  - `entry/src/main/ets/services/FocusStore.ets`
  - `entry/src/main/ets/repository/AuthRepository.ets`
- ArkUI pages and native capabilities:
  - `entry/src/main/ets/pages/Index.ets`
  - `entry/src/main/ets/pages/FocusSolo.ets`
  - `entry/src/main/ets/focusability/FocusAbility.ets`
  - `entry/src/main/ets/services/FocusNativeServices.ets`
  - `entry/src/main/ets/formpages/FocusCard.ets`
- ArkWeb asset: `entry/src/main/resources/rawfile/charts/index.html`
- Optional backend: `focus-server/`

## Document Structure

`设计文档.md` should be organized for both grading and defense:

1. Project overview and product positioning.
2. Requirements loop and user scenario.
3. Overall architecture and local-first rationale.
4. Directory and module map.
5. Frontend module design:
   - models and seed data
   - `FocusDatabase`
   - `FocusStore`
   - `AuthRepository`
   - `Index.ets` UI tabs and state
   - `FocusAbility` / `FocusSolo`
   - `FocusNativeServices`
   - `FocusCard`
   - ArkWeb review page and bridge
6. Data model and database tables.
7. Core business flows.
8. Optional backend design.
9. Course knowledge mapping.
10. UX design and frontend polish.
11. Build verification and known limitations.
12. Defense narrative and future work.

## Boundaries And Tradeoffs

- Emphasize local-first RDB as the primary architecture. Do not present the backend as required for app usage.
- Explain backend as a thin optional sync / full-stack demonstration layer.
- Do not claim unimplemented features are complete. Mark task editing, backend sync UI, signed HAP, device ArkWeb verification, and service-card device verification as limitations or future work.
- Mention that `Index.ets` remains large intentionally for delivery stability; gradual component extraction is future engineering work.
- Keep technical explanations concrete enough to map to files and code behavior, but readable enough for a course design document.

## Rollback

Documentation changes can be reverted by removing `设计文档.md`, reverting the `HANDOVER.md` mention, and deleting this task's planning artifacts if needed before archive.
