# Implementation Plan

## App Work

1. [x] Read required specs with `trellis-before-dev`.
2. [x] Add `StudyResource` and resource status/type constants to models.
3. [x] Extend `FocusDatabase`:
   - bump DB version to `3`
   - create `study_resources`
   - add query/insert/update methods
   - close result sets in `finally`
4. [x] Extend `FocusStore`:
   - resource snapshot
   - add/update/archive/restore resource
   - create task from resource
5. [x] Extend AI service with local resource extraction and optional remote extraction fallback.
6. [x] Add Resources tab UI in `Index.ets`.
7. [x] Update visible product naming to `知序` where low risk.
8. [x] Reuse existing `focus_ui_*` assets for resources; generate only if the UI lacks a suitable semantic asset.

### 2026-05-27 UI Density Follow-up

- Split the Resources tab into `资料库 / 备忘录 / 文件 / 提炼` workspaces so add, import, AI, and list flows are not all shown at once.
- Added `DocumentViewPicker`-based local file import in `Index.ets`; the app stores the selected file URI plus user notes as a local `file` resource.
- Applied a lighter glass/minimal surface treatment to shared cards and the bottom tab bar.

## Report and Slides Work

9. [ ] Extract useful structure from `report/论文样张.pdf` and existing docs.
10. [ ] Create `report/course-report.md`.
11. [ ] Create `report/course-report.typ` with automatic outline.
12. [ ] Compile `report/course-report.pdf`.
13. [ ] Create `report/defense-slides.typ`.
14. [ ] Compile `report/defense-slides.pdf`.

## Validation

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

```powershell
typst compile report/course-report.typ report/course-report.pdf
typst compile report/defense-slides.typ report/defense-slides.pdf
```

```powershell
git diff --check
rg --hidden -n "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}" . --glob '!.git/**' --glob '!oh_modules/**' --glob '!entry/build/**' --glob '!hvigor/**'
```

### Latest Results

- 2026-05-27: `assembleHap` passed. Existing warnings remain around `getContext` deprecation, database/preference calls that may throw, unsupported background task capability on some devices, and missing signing config.
- 2026-05-27: `git diff --check` passed.
- 2026-05-27: secret scan for `sk-*` / `tp-*` patterns returned no matches.

## Rollback Points

- Resource workflow can be rolled back by removing `StudyResource` model, `study_resources` DAO/store methods, and Resources tab references.
- Brand copy changes can be reverted independently because internal file/class names stay stable.
- Report/slides files live under `report/` and do not affect app build.

## Notes

- Do not write user-provided AI credentials into source, docs, report, slides, scripts, or task files.
- Do not use real API tokens in examples; use placeholders such as "runtime API key".
- File import now uses the system document picker and stores a local URI reference plus notes; binary file copying/parsing is intentionally out of scope for this iteration.
