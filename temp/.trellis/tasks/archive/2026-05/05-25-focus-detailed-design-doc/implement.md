# Implementation Plan

## Checklist

1. Read product docs, frontend spec, core ArkTS modules, ArkWeb asset, module config, and backend README / schema evidence.
2. Update Trellis planning artifacts (`prd.md`, `design.md`, `implement.md`).
3. Start the task after planning artifacts exist.
4. Add root `设计文档.md` with detailed module implementation notes and course knowledge mapping.
5. Update `HANDOVER.md` to reference the new design document.
6. Run documentation validation:
   - `git diff --check`
   - inspect `git diff --stat`
7. Commit documentation changes.
8. Archive the Trellis task and record the journal entry.

## Validation

This task is docs-only, so no frontend HAP or backend Maven build is required unless code files are accidentally changed. The required validation is:

```powershell
git diff --check
```

## Risk Points

- Chinese Markdown must stay UTF-8.
- The document must not overclaim optional backend sync as completed frontend integration.
- The document must distinguish implemented, demonstration, and future work.
- `HANDOVER.md` should receive a small targeted update only.
