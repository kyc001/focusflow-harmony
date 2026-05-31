# Focus App Deep Refactor Implementation Plan

## Phase 0: Readiness

- [x] Read relevant frontend/shared Trellis specs before editing via `trellis-before-dev`.
- [x] Re-read `HANDOVER.md` known ArkTS pitfalls before touching UI builders.
- [x] Capture current build commands and environment variables.

## Phase 1: Documentation Scope Reset

- [x] Rewrite `需求文档.md` around local-first mature product scope.
- [x] Keep optional backend/course highlights but demote speculative features to stretch.
- [x] Update acceptance/delivery sections to match what the implementation can prove.

## Phase 2: Local Persistence Foundation

- [x] Expand `FocusDatabase.ets` into an RDB access layer with open/create/migration helpers.
- [x] Add row mapping for `FocusProject`, `FocusTask`, and `PomodoroRecord`.
- [x] Add CRUD/read APIs for projects/tasks/pomodoros.
- [x] Add seed-on-empty initialization.
- [x] Ensure ResultSet objects are released in query paths.
- [x] Keep timestamps in Unix milliseconds.

## Phase 3: Repository / State Facade

- [x] Introduce a local repository or refactor `FocusStore` to become RDB-backed.
- [x] Preserve existing UI method semantics where possible: add task, toggle, soft delete, restore, record Pomodoro, stats.
- [x] Add an explicit async initialization and refresh path.
- [x] Route ArkWeb bridge stats through the same store/repository data.

## Phase 4: Optional Local Backend Integration

- [x] Keep backend buildable and documented as optional backup/sync/full-stack demo infrastructure.
- [x] Add HTTP client and UI wiring only after core persistence and UX are stable.
- [x] If added, backend failure must remain non-blocking for local task/Pomodoro operations.

## Phase 5: UI Flow Stabilization

- [x] Update `Index.ets` to load async persisted data and refresh after mutations.
- [x] Ensure quick add, complete, delete, restore, Pomodoro complete, and Pomodoro interrupt all update one state source.
- [x] Keep optional backend/sync affordances from crowding the primary task/focus workflow.
- [x] Improve empty states, button labels, and first-action clarity.
- [ ] Reduce `Index.ets` size by extracting safe, low-risk components or helpers if build compatibility allows.
- [x] Keep visual changes restrained and product-focused.

## Phase 6: Cross-Ability Refresh

- [x] Keep FocusAbility cold/hot Want parsing.
- [x] Make FocusAbility completion/interruption behavior compatible with the main repository/store refresh path where practical.
- [x] If full cross-Ability writeback is risky, document the limitation and keep the in-tab Focus flow fully persistent.

## Phase 7: Verification

- [x] Run frontend HAP build with DevEco/JDK environment variables.
- [x] Run backend Maven package.
- [x] Run or document local backend startup requirements.
- [x] Review changed UI code for ArkUI pitfalls listed in `HANDOVER.md`.
- [x] Confirm no accidental dependency on backend for core offline app flow.

## Phase 8: Handover

- [x] Update `HANDOVER.md` with new architecture, changed files, verification results, known warnings, and remaining manual device checks.
- [x] Record remaining stretch items clearly.

## Validation Commands

Frontend:

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
.\hvigor\bin\hvigorw --mode module -p module=entry assembleHap
```

Alternative frontend command if the wrapper path differs:

```powershell
& 'C:/Program Files/Huawei/DevEco Studio/tools/hvigor/bin/hvigorw' --mode module -p module=entry assembleHap
```

Backend:

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;D:\Tools\apache-maven-3.9.10\bin;$env:Path"
mvn -q -DskipTests package
```

Run backend command from `focus-server/`.

## Risky Files

- `entry/src/main/ets/pages/Index.ets`: very large, many ArkUI builders, high compile-risk.
- `entry/src/main/ets/services/FocusDatabase.ets`: persistence changes can affect app startup.
- `entry/src/main/ets/services/FocusStore.ets`: central data behavior.
- `entry/src/main/ets/network/` and remote repository files: backend URL and JSON contract risks.
- `entry/src/main/ets/pages/FocusSolo.ets`: separate Ability timer path.
- `entry/src/main/resources/rawfile/charts/index.html`: ArkWeb bridge contract.
- `需求文档.md` and `HANDOVER.md`: Chinese docs should remain readable UTF-8.

## Review Gate Before Start

- [x] User confirmed final product direction: local-first mature app core, backend optional for backup/sync/course demo.
- [x] User approves planning artifacts or asks for implementation.

## Final Verification Notes

- Frontend HAP build passed on 2026-05-25 with DevEco hvigor: `BUILD SUCCESSFUL in 24 s 280 ms`.
- HAP output: `entry/build/default/outputs/default/entry-default-unsigned.hap`.
- Backend Maven package passed on 2026-05-25 with exit code `0`.
- Backend jar path: `focus-server/target/focus-server-0.0.1-SNAPSHOT.jar`.
- Remaining manual check: emulator or real-device flow test for RDB persistence after app restart, ArkWeb render, FocusAbility writeback, and service-card display.
- Deferred deliberately: large `Index.ets` extraction, full backend sync UI, signed HAP, JWT/RCP/distributed/AI/AVPlayer extensions.
