# Implementation Plan: Course Report Deep Rewrite

## Checklist

1. Finish evidence review:
   - app pages/builders;
   - FocusStore/FocusDatabase/Preferences services;
   - AI service;
   - FocusAbility/FocusSolo;
   - ArkWeb chart page;
   - backend package.
2. Rewrite `report/course-report.typ` as a graduation-thesis-style paper.
3. Update `report/course-report.md` to match the new paper outline and claims.
4. Compile `report/course-report.typ` to `report/course-report.pdf`.
5. Validate:
   - approximate Chinese body length >= 5000 characters;
   - no CVK usage claim;
   - no body source-code blocks;
   - no secret/token patterns;
   - `git diff --check`.
6. Record validation results in `validation.md`.

## Writing Strategy

- Write formally and analytically.
- Use project-specific evidence and actual module names.
- Explain design decisions, trade-offs, data flow, failure handling, and limitations.
- Keep code out of the body; use tables and prose instead.
- Be honest about optional backend and remote AI boundaries.

## Validation Commands

```powershell
typst compile report/course-report.typ report/course-report.pdf
rg "CVK|Core Vision Kit|Vision Kit" report/course-report.typ report/course-report.md
rg "```|#raw|#code" report/course-report.typ report/course-report.md
rg "sk-[A-Za-z0-9_-]{20,}|tp-[A-Za-z0-9_-]{20,}|Bearer [A-Za-z0-9._-]{20,}" report
git diff --check
```

## Risky Files / Rollback Points

- `report/course-report.typ`: primary rewrite; keep Typst syntax simple.
- `report/course-report.pdf`: generated artifact; regenerate only after compile succeeds.
- `report/course-report.md`: companion summary; should not diverge from Typst paper.

If Typst compilation fails, fix the source before touching generated PDF again.
