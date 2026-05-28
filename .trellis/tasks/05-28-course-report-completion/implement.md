# Implementation Plan: Course Report Completion

## Checklist

1. Inspect existing `report/course-report.typ` and `report/course-report.md`.
2. Rewrite or polish the Typst report source against the required structure.
3. Add screenshot placeholder figures.
4. Update the Markdown companion if it remains useful.
5. Compile the PDF with Typst.
6. Check for missing source code restrictions and secret leakage.
7. Record validation results.

## Validation

```powershell
typst compile report/course-report.typ report/course-report.pdf
rg "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}|Bearer [A-Za-z0-9._-]{20,}" report
```

## Review Checklist

- Abstract states problem, method, and effect.
- Keywords count is 3-5.
- Chapter headings match the required structure.
- Chapter 3 and 4 do not paste code.
- Screenshot placeholders are labeled and visually distinct.
