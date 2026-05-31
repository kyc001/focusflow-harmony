# Implementation Plan: Typst Defense Slides

## Checklist

1. Inspect the final or current report content for consistent messaging.
2. Rewrite `report/defense-slides.typ` with the planned deck flow.
3. Add reusable Typst helpers for title, section labels, and screenshot placeholders.
4. Compile `report/defense-slides.pdf`.
5. Check slide count, readability, and placeholder labels.
6. Run report-folder secret scan.
7. Record validation results.

## Validation

```powershell
typst compile report/defense-slides.typ report/defense-slides.pdf
rg "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}|Bearer [A-Za-z0-9._-]{20,}" report
```

## Review Checklist

- Slide headlines tell the story without needing long narration.
- Screenshot placeholders are explicit.
- The deck includes implementation highlights, not just product marketing.
- The deck is aligned with the final report.
