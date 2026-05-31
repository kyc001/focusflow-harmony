# Design: UX UI Modularization

## Boundaries

This task changes `entry/src/main/ets` UI and supporting pure helpers only. It should not change backend code or commit generated report artifacts.

Likely files:

- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/pages/FocusSolo.ets` if focus UX needs matching polish
- `entry/src/main/ets/utils/FocusFormatters.ets`
- optional new UI helper file under `entry/src/main/ets/utils/` or `entry/src/main/ets/ui/`

## Modularization Strategy

Use staged modularization:

1. Extract or consolidate design tokens and style helpers that are used by multiple builders.
2. Extract pure display helpers into `utils` when they do not need ArkUI component state.
3. Keep stateful `@Builder` sections inside `Index.ets` unless a small cross-file extraction is clearly safe and build-verified.
4. Prefer fewer, clearer methods over a large risky rewrite.

This strategy satisfies the user's modularity goal while respecting ArkUI build risk and the existing state-heavy `Index.ets`.

## UX Direction

- Today: show current state, next action, and AI/local guidance with clear primary action.
- Tasks: support scanning, filtering, completion, delete/restore, and focus entry without visual clutter.
- Resources: clarify the workspaces and make AI extraction/task generation status obvious.
- Focus: reduce distractions, make timer state and completion/interruption actions unambiguous.
- Profile/Review/Settings: group lower-frequency features, but keep them easy to find.

## Contracts

- Do not mutate arrays in `focusStore` or page state as a substitute for RDB writes.
- Preserve AppStorage keys and `FocusAbility` handoff behavior.
- Keep alpha colors in ArkUI `#AARRGGBB` format.
- Avoid decorative `height('100%')` in unconstrained scroll layouts.
- Avoid passing callbacks as `@Builder` parameters if the build pipeline reports related ArkUI errors.

## Rollback Points

- Revert a new helper file if imports trigger ArkTS build issues.
- Keep visual tweaks even if deeper extraction is reverted.
- If a UI section becomes unstable, restore that section and preserve only token/helper consolidation.
