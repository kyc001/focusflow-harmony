# Design: Course Report Completion

## Document Structure

The report will be a Typst source with predictable sections:

1. Title page.
2. Abstract and keywords.
3. Table of contents.
4. Chapter 1: introduction.
5. Chapter 2: tool and framework selection.
6. Chapter 3: system design.
7. Chapter 4: system implementation.
8. Chapter 5: summary and outlook.

## Content Strategy

- Present "知序 / AI Study Flow" as the visible product name.
- Keep internal `Focus*` names out of user-facing prose unless explaining engineering compatibility.
- Explain local-first architecture as the core contribution.
- Explain AI as optional enhancement with local fallback.
- Explain study resources as the mature workflow that connects documents to tasks and focus.
- Mention backend as optional course full-stack demonstration, not a dependency.

## Screenshot Placeholders

Use Typst figure boxes with clear labels such as:

- login / product entry;
- Today dashboard and AI coach;
- task management;
- study resource library and AI extraction;
- focus timer;
- review/statistics;
- settings / AI configuration.

## Formatting Notes

- Keep Chinese prose readable and formal enough for a course report.
- Avoid source-code listings in chapters 3 and 4.
- Use tables for selection comparison and module/database summaries.
- If the existing Typst source has encoding issues, rewrite the affected source cleanly rather than patching mojibake text piecemeal.

## Rollback

The report task is isolated under `report/`. If Typst formatting fails, keep the source readable and record the compile error before revising.
