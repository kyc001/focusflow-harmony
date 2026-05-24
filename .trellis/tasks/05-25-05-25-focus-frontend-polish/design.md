# Polish Focus Frontend Presentation Design

## Direction

The app should read as a focused, calm productivity tool. The best path is a restrained visual refinement over the existing UI, not a dramatic redesign that risks ArkUI build breakage.

The polish pass will keep the previous local-first architecture intact and work inside existing files:

- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/pages/FocusSolo.ets`
- `entry/src/main/ets/formpages/FocusCard.ets` if safe
- `HANDOVER.md` for notes

## Visual System

Use the existing palette as the base, but improve perceived polish through:

- more coherent surfaces: white cards, faint blue/green/warm tinted panels only where they carry meaning;
- more consistent border radii: avoid extreme rounded pills for every control;
- softer shadows on primary cards and fewer shadows on list rows;
- subtle section headers and microcopy;
- buttons with clearer hierarchy: primary solid, secondary neutral, danger muted red;
- stable rows and fixed minimum control heights.

Avoid:

- decorative full-screen gradients outside login/focus surfaces;
- color strings in `#RRGGBBAA` format;
- `height('100%')` decorative fills inside unconstrained layouts;
- complex ternary objects in `.shadow()`;
- nested card stacks.

## Targeted Changes

### Login

Improve first impression with a cleaner product mark, stronger "local-first" positioning, and a more polished credential panel. Keep local login and guest mode obvious.

### Today

Make the Today hero feel less like a raw data panel:

- clear top identity row,
- visible "local saved" status,
- current focus task emphasis,
- compact stats with separators.

Quick add should feel like the next natural action.

### Tasks

Improve list scan quality:

- clearer row rhythm,
- task title + metadata grouping,
- consistent action buttons,
- empty/recycle states that look intentional.

### Focus

Make timer card more demo-friendly:

- stronger focus surface,
- clear status,
- timer ring and controls visually balanced,
- service / notification messages quieter.

### Review

Make review cards more readable:

- KPI cards with clearer labels,
- chart sections with subtle axes/legend cues,
- completion/interruption contrast without loud colors.

### FocusSolo / Service Card

Keep independent focus and service card visually aligned with the main app. Make small safe changes only.

## Rollback Shape

Keep changes localized to style constants and builder layout blocks. If build breaks, revert the smallest affected section rather than undoing the full polish pass.

## Verification

- Run frontend HAP build with the known DevEco/JDK environment variables.
- Review changed code for known ArkUI pitfalls.
- If build passes but no emulator is available, document manual screenshot checks as remaining.
