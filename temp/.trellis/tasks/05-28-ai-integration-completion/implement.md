# Implementation Plan: AI Integration Completion

## Checklist

1. Load `trellis-before-dev` for frontend/shared specs.
2. Inspect the current `FocusAiCoachService.ets` diff so user changes are not overwritten.
3. Search current AI handlers in `Index.ets`.
4. Normalize settings behavior:
   - no key echo;
   - blank save preserves prior key;
   - status copy is clear.
5. Harden request/fallback behavior if gaps remain.
6. Polish resource extraction guidance and selected-resource status if needed.
7. Run secret scan and `git diff --check`.
8. Run frontend HAP build.
9. Record validation results.

## Validation

```powershell
git diff --check
rg "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}|Bearer [A-Za-z0-9._-]{20,}" .
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

## Manual Checks When Device/Emulator Is Available

- Remote disabled: Today AI card still shows usable local advice.
- Blank key save: saved key is preserved and not displayed.
- Wrong endpoint: request falls back locally with visible status.
- Resource extraction: missing key or failed request still produces local summary and task suggestion.
