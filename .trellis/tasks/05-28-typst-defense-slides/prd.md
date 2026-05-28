# Typst Defense Slides

## Goal

Create a polished Typst slide deck under `report/` that presents the project's core content and highlights for defense, using placeholders for screenshots that are not yet available.

## Confirmed Facts

- `report/defense-slides.typ` and `report/defense-slides.pdf` already exist.
- The deck should be generated with Typst and should align with the final report and implemented app.
- The user explicitly asked to use placeholders for any real screenshots needed.

## Requirements

- Use Typst source at `report/defense-slides.typ`.
- Present the project in a defense-friendly flow:
  - title/product positioning;
  - problem background;
  - product workflow;
  - architecture and local-first data flow;
  - UX/UI improvements;
  - remote AI integration and failure-state design;
  - study-resource workflow;
  - implementation/validation;
  - highlights and outlook.
- Include screenshot placeholder areas for actual app screens.
- Keep slides concise and visually consistent.
- Do not include secrets or private credentials.

## Acceptance Criteria

- [ ] `report/defense-slides.typ` is complete.
- [ ] `report/defense-slides.pdf` is generated from Typst.
- [ ] The deck includes screenshot placeholders.
- [ ] The deck highlights UX, modularity/local-first architecture, remote AI integration, study resources, and course knowledge points.
- [ ] Typst compilation is run or any environment blocker is recorded.

## Out of Scope

- Real screenshot capture.
- Animated slides.
- Speaker-note system beyond concise slide content.
