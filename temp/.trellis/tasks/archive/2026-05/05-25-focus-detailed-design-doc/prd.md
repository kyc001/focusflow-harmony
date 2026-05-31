# Write Focus detailed design document

## Goal

Create a detailed Chinese design document for the Focus HarmonyOS final project that accurately explains the current local-first product, each implemented module, the data flow, the course knowledge points used, and how the optional Spring Boot backend fits into the defense story.

## Requirements

- Add a root-level `设计文档.md`.
- The document must be grounded in the current repository, especially:
  - `需求文档.md`
  - `HANDOVER.md`
  - `.trellis/spec/frontend/harmony-focus-local-first.md`
  - `entry/src/main/ets/models/FocusModels.ets`
  - `entry/src/main/ets/services/FocusDatabase.ets`
  - `entry/src/main/ets/services/FocusStore.ets`
  - `entry/src/main/ets/repository/AuthRepository.ets`
  - `entry/src/main/ets/pages/Index.ets`
  - `entry/src/main/ets/focusability/FocusAbility.ets`
  - `entry/src/main/ets/pages/FocusSolo.ets`
  - `entry/src/main/ets/services/FocusNativeServices.ets`
  - `entry/src/main/ets/formpages/FocusCard.ets`
  - `entry/src/main/resources/rawfile/charts/index.html`
  - `entry/src/main/module.json5`
  - `focus-server/`
- The document must clearly state that Focus is local-first and that the backend is optional.
- The document must record implementation details for frontend UI, data models, RDB, FocusStore, Preferences auth, UIAbility / Want, ArkWeb, native notifications/background task, service card, and optional backend modules.
- The document must map project modules to course knowledge points.
- The document must include database table design, core business flows, build / verification notes, known limitations, and defense talking points.
- Update `HANDOVER.md` to mention the new detailed design document.

## Acceptance Criteria

- [ ] `设计文档.md` exists at the repository root.
- [ ] `设计文档.md` is written in Chinese and is suitable for final-project submission or defense preparation.
- [ ] Every major implemented module is explained with purpose, file location, implementation method, and related course knowledge.
- [ ] Local-first architecture, RDB source-of-truth, and optional backend boundary are explicit.
- [ ] `HANDOVER.md` links or mentions `设计文档.md`.
- [ ] `git diff --check` passes.

## Notes

- This is a documentation-only task. No ArkTS, Java, or schema behavior should change.
