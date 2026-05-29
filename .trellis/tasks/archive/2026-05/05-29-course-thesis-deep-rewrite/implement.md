# Implementation Plan: Course Thesis Deep Rewrite

## Checklist

- [x] Confirm old thesis rewrite task is archived and new task exists.
- [x] Read relevant Trellis specs before editing.
- [x] Inspect report template files and formatting references.
- [x] Inspect frontend source modules for real architecture, data flow, UI, AI, native service, ArkWeb, and service-card details.
- [x] Inspect backend source modules for API and persistence details.
- [x] Map source evidence to report chapters while keeping the final paper near 20 pages / 5,000-8,000 words or Chinese-character-equivalent main content.
- [x] Expand `abstract.tex` if needed for better thesis-style summary.
- [x] Expand and polish `course-report.tex` with source-grounded sections, tables, and algorithms.
- [x] Update bibliography entries if new citations are introduced.
- [x] Compile the LaTeX report and fix report-level issues.
- [x] Inspect generated PDF for obvious formatting defects.
- [x] Run a final diff review to ensure only intended files changed.

## Validation Commands

Use the commands available in the local environment:

```powershell
git status --short
rg --files report/nku-thesis-template-2020
```

For LaTeX, prefer the template's existing workflow:

```powershell
Set-Location report/nku-thesis-template-2020
xelatex main.tex
biber main
xelatex main.tex
xelatex main.tex
```

If `latexmk` is available:

```powershell
latexmk -xelatex main.tex
```

## Risky Files

- `report/nku-thesis-template-2020/main.tex`: template metadata and package setup.
- `report/nku-thesis-template-2020/course-report.tex`: main rewrite target.
- `report/nku-thesis-template-2020/abstract.tex`: thesis abstract and keywords.
- `report/nku-thesis-template-2020/nkthesis.bib`: references.

## Review Gates

- Planning gate: user confirms desired depth/length before implementation.
- Accuracy gate: every major expanded claim is checked against source files.
- Build gate: LaTeX compiles or blocker is documented.
- Visual gate: generated PDF is opened/rendered if possible.
