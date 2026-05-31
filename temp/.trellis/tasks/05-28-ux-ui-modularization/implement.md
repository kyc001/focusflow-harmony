# Implementation Plan: UX UI Modularization

## Checklist

1. Load `trellis-before-dev` for frontend/shared specs.
2. Inspect `Index.ets` around repeated styles, tab/profile/resource/focus builders, and helper functions.
3. Record a compact UX audit:
   - friction;
   - intended improvement;
   - touched files.
4. Extract safe shared tokens/helpers if they reduce repetition.
5. Polish the main user flows with small, buildable edits.
6. Run `git diff --check`.
7. Run the frontend HAP build.
8. Record validation results.

## Validation

```powershell
git diff --check
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

## Risky Files

- `entry/src/main/ets/pages/Index.ets`: large stateful UI; avoid sweeping reorder-only edits.
- `entry/src/main/ets/pages/FocusSolo.ets`: Ability handoff must continue to work.
- Any new ArkUI helper import: validate immediately with build.
