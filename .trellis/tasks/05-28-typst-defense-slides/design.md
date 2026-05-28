# Design: Typst Defense Slides

## Deck Shape

Target 9-12 slides:

1. Title: 知序 / AI Study Flow.
2. Background and problem.
3. Product positioning and user workflow.
4. System architecture.
5. Local-first data persistence.
6. UX/UI optimization.
7. AI integration and fallback.
8. Study-resource workflow.
9. Implementation effects with screenshot placeholders.
10. Validation and course knowledge points.
11. Highlights.
12. Outlook / Q&A.

## Visual System

- Use a restrained academic/product palette.
- Avoid dense paragraphs.
- Prefer diagrams, two-column layouts, and labeled placeholder boxes.
- Placeholder boxes should clearly say what screenshot belongs there.

## Alignment With Report

- Use the same product naming and technical framing as the report.
- Keep backend as optional full-stack demonstration.
- Keep AI as optional enhancement.
- Mention local-first RDB and Preferences as the core implementation guarantee.

## Rollback

Slides are isolated under `report/`. If Typst layout becomes unstable, reduce custom layout and keep the generated PDF readable.
