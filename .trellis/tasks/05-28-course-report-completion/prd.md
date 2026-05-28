# Course Report Completion

## Goal

Finish the Chinese course report for the HarmonyOS app under `report/`, aligned with the latest UX, local-first, study-resource, and AI integration work.

## Confirmed Facts

- `report/course-report.typ` and `report/course-report.md` already exist.
- The existing report follows the requested broad structure, but it needs review, polish, and screenshot placeholders for the latest project state.
- Teacher/template reference materials are present under `report/`.
- Typst is expected to produce the final PDF.

## Requirements

- Write the report in Chinese.
- Keep source under `report/course-report.typ`; keep or update `report/course-report.md` as a plain-text companion if useful.
- Include:
  - title page;
  - abstract;
  - 3-5 keywords;
  - automatic outline/table of contents;
  - chapter 1 introduction, background/significance, problem/related work, organization;
  - chapter 2 development tool/framework/database/backend selection and comparison;
  - chapter 3 system design with MVVM/local-first/RDB/AI/backend framing;
  - chapter 4 implementation effects, screenshots/placeholders, key problems and solutions;
  - chapter 5 summary and outlook.
- Do not paste source code in chapters 3 or 4.
- Use screenshot placeholders where actual screenshots are not yet available.
- Avoid committing secrets or private endpoint credentials in the report.

## Acceptance Criteria

- [ ] `report/course-report.typ` is complete and aligned with the implemented product.
- [ ] `report/course-report.pdf` is generated from Typst.
- [ ] The report includes screenshot placeholders for app screens/effects.
- [ ] Chapters 3 and 4 explain design/implementation without pasted code blocks.
- [ ] The report references AI as optional and local-first behavior as core.
- [ ] Typst compilation is run or any environment blocker is recorded.

## Out of Scope

- Real screenshots; placeholders are explicitly acceptable.
- Fabricating test results that were not run.
- Changing app code from the report task.
