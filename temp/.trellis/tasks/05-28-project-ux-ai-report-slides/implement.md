# Implementation Plan: Project UX AI Report Slides Overhaul

## Order

1. Complete planning artifacts for all four child tasks.
2. Start `05-28-ux-ui-modularization` and implement the app UX/modularity improvements.
3. Start `05-28-ai-integration-completion` and complete AI settings/request/fallback polish.
4. Start `05-28-course-report-completion` and finish report source/PDF.
5. Start `05-28-typst-defense-slides` and finish slides source/PDF.
6. Run final integration checks from the parent perspective.

## Validation Commands

Frontend build:

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

Typst PDFs:

```powershell
typst compile report/course-report.typ report/course-report.pdf
typst compile report/defense-slides.typ report/defense-slides.pdf
```

Whitespace and secret checks:

```powershell
git diff --check
rg "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}|Bearer [A-Za-z0-9._-]{20,}" .
```

## Review Gates

- Do not start implementation until child planning is reviewed or the user explicitly approves proceeding.
- Before each app-editing child, load `trellis-before-dev` and relevant frontend/shared specs.
- After app edits, load `trellis-check`.
- Before final response, summarize which validations ran and which could not run.
