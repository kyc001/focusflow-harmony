# Implementation Plan

1. [x] Add AI model/settings types and service.
2. [x] Add Preferences persistence for AI settings.
3. [x] Add AI coach state and actions to `Index.ets`.
4. [x] Add AI Coach UI cards to Today/Focus/Review areas.
5. [x] Add runtime AI settings controls.
6. [x] Add internet permission required by optional remote model calls.
7. [x] Generate image assets through the provided image API and copy them into Harmony resources.
8. [x] Reference generated visuals in the UI.
9. [x] Update handover/design docs with the AI enhancement and asset prompts.
10. [x] Run frontend build and inspect git diff for leaked secrets.
11. [x] Add Preferences persistence for runtime focus settings.
12. [x] Extract shared focus display formatters from the main page.

## Implementation Notes

- Remote AI settings are optional and stored under Preferences key `focus_ai`.
- Empty API key input preserves the saved key and does not echo it into the settings field.
- Local AI advice remains the fallback for missing config, failed HTTP, non-2xx responses, and empty responses.
- Concept visuals were generated for hero/coach surfaces.
- Forest review rewards use reusable sprite-style PNG assets and a `focus_forest_spritesheet.png` inspection sheet instead of concept-art tiles.
- A paid spritesheet generation attempt failed during SSL negotiation, so the final forest sprites were generated locally with Pillow to avoid repeated fixed-cost calls.
- A later paid `sin` route request generated `focus_ui_spritesheet.png` successfully; it was cropped locally into 16 semantic `focus_ui_*` PNG assets.
- The cropped UI micro-assets are wired into Today hero chips, quick add, next-focus, AI Coach, task rows, empty states, timer status, AI settings, and Review KPI/chart cards.
- Generated UI sprite work is treated as complete only after local cropping, PNG validation, resource references, and a HAP build.
- Runtime focus settings are stored under Preferences key `focus_settings`; timer durations, white noise, theme color, and notification preference are normalized and saved locally.
- `FocusFormatters.ets` owns timer, due-date, priority, and focus-state display helpers so `Index.ets` can keep moving toward smaller modules.

## Validation Commands

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

```powershell
rg --hidden -n "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}" . --glob '!.git/**' --glob '!oh_modules/**' --glob '!entry/build/**' --glob '!hvigor/**'
```

Latest validation:

- Frontend HAP build: `BUILD SUCCESSFUL in 1 min 13 s 686 ms`.
- `git diff --check`: passed.
- PNG validation: all `entry/src/main/resources/base/media/focus_*.png` opened and verified with Pillow.
- Precise secret scan: no `sk-...` or `tp-...` token matches in tracked/untracked project files outside ignored build/dependency folders.

## Rollback Points

- AI service/UI edits are isolated to new service files plus `Index.ets`.
- Runtime settings persistence can be rolled back by removing `FocusSettingsService.ets` and returning the settings controls to session-only page state.
- Resource references can be removed if generated images fail to package.
- UI micro-assets can be rolled back by removing `focus_ui_*` resources and the small ArkUI image placements without touching RDB, FocusStore, or AI advice logic.
