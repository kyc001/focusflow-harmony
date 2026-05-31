# Polish Focus Frontend Presentation Implementation Plan

## Phase 0: Readiness

- [x] Load Trellis session context.
- [x] Read frontend index and Focus-specific Harmony local-first spec.
- [x] Preserve RDB / FocusStore contracts.

## Phase 1: UI Audit

- [x] Inspect `Index.ets` structure and existing visual constants.
- [x] Identify high-impact builders to modify with low compile risk.
- [x] Inspect `FocusSolo.ets` and `FocusCard.ets` for consistency opportunities.

## Phase 2: Main App Polish

- [x] Refine color/surface constants only where helpful.
- [x] Polish login screen and local-first presentation.
- [x] Polish Today hero and quick-add flow.
- [x] Polish task rows, filter/search surfaces, and empty states.
- [x] Polish focus timer card and action hierarchy.
- [x] Polish review KPI/chart surfaces.

## Phase 3: Secondary Surfaces

- [x] Align `FocusSolo.ets` with the refined focus surface.
- [x] Adjust service card styling if safe.

## Phase 4: Documentation

- [x] Update `HANDOVER.md` with the latest frontend polish pass.
- [x] Record any remaining manual visual checks.

## Phase 5: Verification

- [x] Run frontend HAP build.
- [x] Review warnings and document known non-blockers.
- [x] Check git diff for unintended backend/data changes.

## Verification Notes

- Frontend HAP build passed on 2026-05-25: `BUILD SUCCESSFUL in 24 s 855 ms`.
- HAP output timestamp after polish: `entry/build/default/outputs/default/entry-default-unsigned.hap`.
- Known warnings remain non-blocking: no signing config, hvigor daemon fallback, `getContext` deprecated, notification/background-task API warnings, and RDB/Preferences exception warnings.
- Backend build was not rerun because this task did not touch backend code or contracts.
- Manual emulator/real-device visual screenshot verification remains recommended.

## Validation Command

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

## Non-Goals

- No backend sync UI.
- No RDB schema changes.
- No new third-party UI packages.
- No large component extraction unless required for safe styling.
