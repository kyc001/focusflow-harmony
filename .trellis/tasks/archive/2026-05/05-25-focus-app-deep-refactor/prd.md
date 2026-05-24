# Focus App Deep Refactor

## Goal

Turn the existing Focus HarmonyOS course project into a stable, defensible final-assignment app: a local-first Pomodoro and study task manager with real on-device persistence, clearer architecture, stronger demonstration flow, and preserved HarmonyOS course highlights.

The refactor should improve the product and code where the current design is weak, including the requirement document itself. The default direction is not a total rewrite; it is a deep stabilization and architecture refactor around the existing working prototype.

The user has explicitly chosen product maturity over checklist breadth: prioritize stable core flows, real data persistence, clear UX, maintainable frontend structure, and a polished app experience. Course-feature coverage still matters, but only when it supports the product instead of bloating it.

## User Value

- A student can open the app, enter local or guest mode, manage study tasks, run a Pomodoro session, record interruptions, and review study data even when the backend is unavailable.
- When the local Spring Boot service is running, the student can optionally register/login and sync local tasks/Pomodoro records to the backend for a full-stack demo.
- The app demonstrates this semester's key HarmonyOS content in a coherent story: ArkTS declarative UI, state management, UIAbility, Preferences, RDB, ArkWeb, service card, notification/background task wrappers, and optional Spring Boot integration.
- The final project is easier to explain during defense because product scope, architecture, and trade-offs are explicit rather than inflated by every possible feature.
- The frontend should feel like a mature productivity app: low-friction task entry, legible hierarchy, predictable controls, useful empty states, stable responsive layout, and no visual gimmicks that hurt repeated use.

## Confirmed Facts

- The repository is a HarmonyOS Stage model project with an `entry` module and a Spring Boot optional backend under `focus-server`.
- The root directory is not currently a Git repository.
- Existing frontend files include:
  - `entry/src/main/ets/pages/Index.ets` as a large 64KB main page containing login, tabs, task UI, Pomodoro UI, review charts, styling helpers, and much of the state orchestration.
  - `entry/src/main/ets/services/FocusStore.ets` as an in-memory state source seeded from `SeedData.ets`.
  - `entry/src/main/ets/services/FocusDatabase.ets` which creates RDB tables but does not yet provide DAO CRUD used by the UI.
  - `entry/src/main/ets/repository/AuthRepository.ets` using Preferences for local auth/guest state.
  - `entry/src/main/ets/focusability/FocusAbility.ets` and `pages/FocusSolo.ets` for a singleton focus window using Want/AppStorage for task title.
  - `rawfile/charts/index.html` for ArkWeb review charts.
  - a service card implementation under `entryformability` and `formpages`.
- Existing backend files include controllers, mappers, DTOs, entities, init SQL, and a Maven build. Relevant endpoints already exist for `/api/user/login`, `/api/user/register`, `/api/sync/pull`, `/api/sync/push`, task CRUD, project CRUD, Pomodoro CRUD, and stats.
- `HANDOVER.md` records previous build success for both frontend HAP and backend jar, plus known warnings and UI/layout bugs already fixed.
- The current demand document is broader than the current implementation and overstates some required items, such as full backend dependency, `@ohos/mpchart`, RCP, JWT, distributed data, AI, and advanced sync.

## Product Requirements

- Keep Focus as a local-first study productivity app, not a backend-dependent enterprise system.
- Prioritize a stable, polished product over maximum course-feature breadth.
- Update the requirement/design direction so the backend is an optional local sync/full-stack demo layer, while the app core fully works offline.
- Preserve the four practical app areas:
  - Today: current focus target, quick task creation, progress summary, today tasks.
  - Tasks: search/filter, priority/project grouping, complete/delete/restore flows.
  - Focus: Pomodoro timer, interruption reason, notification/background guard wrappers.
  - Review: native summary plus ArkWeb chart integration and learning forest/gamification.
- Keep login lightweight: local account and guest mode are first-class; backend login/register can be shown as an optional enhancement when the local service is configured and reachable.
- Keep Spring Boot + MyBatis + MySQL as a course-aligned optional local sync backend, but do not let it block app usability.
- Prefer stable, demonstrable features over speculative add-ons. RCP, JWT, distributed data, AI suggestions, real white-noise assets, and full remote conflict sync are optional stretch items unless explicitly selected later.

## Refactor Requirements

- Introduce real local persistence for tasks, projects, Pomodoro records, and settings where feasible:
  - RDB should store tasks/projects/pomodoros.
  - Preferences should store auth and lightweight settings.
  - ResultSet usage must be released when added.
  - UI should load from persisted data and write changes through a repository/DAO path instead of relying only on seeded memory state.
- Reduce `Index.ets` responsibility:
  - Extract reusable components and/or page sections when it lowers risk and improves readability.
  - Keep ArkUI compile compatibility lessons from `HANDOVER.md` in mind.
  - Avoid broad visual churn unless required by layout defects or readability.
- Improve data flow:
  - Centralize task and Pomodoro mutations.
  - Ensure focus completion/interruption updates the same data source used by Today/Tasks/Review.
  - Use AppStorage/EventHub or a comparable simple event path for cross-Ability refresh where practical.
- Keep room for optional local backend integration:
  - Provide a configurable backend base URL suitable for local machine / LAN testing.
  - Implement HTTP client wrappers for login/register and sync pull/push only if core persistence and UX are already stable.
  - Keep sync best-effort: local RDB write succeeds first; backend failure records user-facing sync status and does not lose local work.
  - Store token/userId/sync cursor in Preferences.
  - Prefer `/api/sync/push` and `/api/sync/pull` for bulk demo sync rather than wiring every UI action directly to remote CRUD.
- Align documentation with implementation:
  - Rewrite/update `需求文档.md` so it reflects the refined local-first architecture and realistic final deliverables.
  - Update `HANDOVER.md` with what changed and how to build/verify.
- Preserve buildability:
  - Frontend HAP build should pass with the known local environment variables if available.
  - Backend Maven package should pass or failures should be documented with concrete cause.
- UX quality is part of the refactor, not a cosmetic afterthought:
  - The first screen after login should make the next action obvious.
  - Common controls should be reachable and readable on phone-sized layouts.
  - Empty/error/offline states should explain what happened without looking like debug text.
  - Visual hierarchy should stay restrained and work-focused, with product polish coming from spacing, typography, state feedback, and consistency.

## Acceptance Criteria

- [ ] `需求文档.md` is updated to describe the refined local-first product, realistic scope, architecture, and deliverables.
- [ ] The updated product scope explicitly prioritizes stable app-core maturity and UX polish over broad optional feature coverage.
- [ ] The frontend no longer depends only on `FocusStore` seeded memory for core task/Pomodoro persistence; RDB-backed CRUD or a clearly staged local repository is used for the main flows.
- [ ] The app design leaves a clear path to connect to the local Spring Boot backend for register/login and sync when configured; implementation can stay optional if it would weaken the core product.
- [ ] Backend sync failure leaves local usage intact and shows a clear status rather than blocking task/Pomodoro flows.
- [ ] Task create, complete, soft delete, restore, and Pomodoro complete/interruption flows update one consistent state source and refresh Today/Tasks/Review.
- [ ] `Index.ets` is meaningfully reduced or reorganized so major UI sections/state/data operations are easier to maintain.
- [ ] The main frontend flows are UX-reviewed for hierarchy, empty states, mobile layout, and repeat-use ergonomics.
- [ ] FocusAbility cold start and hot start continue to parse Want parameters.
- [ ] ArkWeb review page still loads from `rawfile/charts/index.html` and the injected bridge still returns stats.
- [ ] Service card config and basic rendering are not broken by the refactor.
- [ ] Backend remains buildable and documented as the optional local sync/full-stack demo layer.
- [ ] Frontend build is run; any warnings or environment blockers are recorded.
- [ ] Backend build is run or explicitly skipped with reason.
- [ ] `HANDOVER.md` records the final architecture, verification commands, known warnings, and remaining manual device-test steps.

## Out Of Scope By Default

- Full JWT/Spring Security migration.
- RCP implementation.
- Distributed-data-object cross-device sync.
- AI assistant integration.
- Full AVPlayer white-noise asset pipeline.
- Signed HAP generation, because signing requires DevEco credentials/certificate setup.
- Device/emulator visual verification unless the environment exposes a runnable device target.

## Open Questions

- None blocking. The accepted product direction is local-first mature app core, with backend as optional backup/sync/course-demo layer.
