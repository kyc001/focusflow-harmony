# Focus App Deep Refactor Implementation Plan

## Phase 0: Readiness

- [ ] Read relevant frontend/shared Trellis specs before editing via `trellis-before-dev`.
- [ ] Re-read `HANDOVER.md` known ArkTS pitfalls before touching UI builders.
- [ ] Capture current build commands and environment variables.

## Phase 1: Documentation Scope Reset

- [ ] Rewrite `需求文档.md` around local-first mature product scope.
- [ ] Keep optional backend/course highlights but demote speculative features to stretch.
- [ ] Update acceptance/delivery sections to match what the implementation can prove.

## Phase 2: Local Persistence Foundation

- [ ] Expand `FocusDatabase.ets` into an RDB access layer with open/create/migration helpers.
- [ ] Add row mapping for `FocusProject`, `FocusTask`, and `PomodoroRecord`.
- [ ] Add CRUD/read APIs for projects/tasks/pomodoros.
- [ ] Add seed-on-empty initialization.
- [ ] Ensure ResultSet objects are released in query paths.
- [ ] Keep timestamps in Unix milliseconds.

## Phase 3: Repository / State Facade

- [ ] Introduce a local repository or refactor `FocusStore` to become RDB-backed.
- [ ] Preserve existing UI method semantics where possible: add task, toggle, soft delete, restore, record Pomodoro, stats.
- [ ] Add an explicit async initialization and refresh path.
- [ ] Route ArkWeb bridge stats through the same store/repository data.

## Phase 4: Optional Local Backend Integration

- [ ] Keep backend buildable and documented as optional backup/sync/full-stack demo infrastructure.
- [ ] Add HTTP client and UI wiring only after core persistence and UX are stable.
- [ ] If added, backend failure must remain non-blocking for local task/Pomodoro operations.

## Phase 5: UI Flow Stabilization

- [ ] Update `Index.ets` to load async persisted data and refresh after mutations.
- [ ] Ensure quick add, complete, delete, restore, Pomodoro complete, and Pomodoro interrupt all update one state source.
- [ ] Keep optional backend/sync affordances from crowding the primary task/focus workflow.
- [ ] Improve empty states, button labels, and first-action clarity.
- [ ] Reduce `Index.ets` size by extracting safe, low-risk components or helpers if build compatibility allows.
- [ ] Keep visual changes restrained and product-focused.

## Phase 6: Cross-Ability Refresh

- [ ] Keep FocusAbility cold/hot Want parsing.
- [ ] Make FocusAbility completion/interruption behavior compatible with the main repository/store refresh path where practical.
- [ ] If full cross-Ability writeback is risky, document the limitation and keep the in-tab Focus flow fully persistent.

## Phase 7: Verification

- [ ] Run frontend HAP build with DevEco/JDK environment variables.
- [ ] Run backend Maven package.
- [ ] Run or document local backend startup requirements.
- [ ] Review changed UI code for ArkUI pitfalls listed in `HANDOVER.md`.
- [ ] Confirm no accidental dependency on backend for core offline app flow.

## Phase 8: Handover

- [ ] Update `HANDOVER.md` with new architecture, changed files, verification results, known warnings, and remaining manual device checks.
- [ ] Record remaining stretch items clearly.

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
- [ ] User approves planning artifacts or asks for implementation.
