# UX Audit Notes

## Findings

- `Index.ets` carried the full design-token set inline, which made the top-level app container harder to scan before reaching actual state and behavior.
- The Resources flow had multiple modes, but users had to infer the current mode's purpose from the tab labels and dense card content.
- The resource AI action repeated remote-readiness checks inline, making UI copy and state less obvious.
- Card styling was close to consistent, but shared glass-card helpers still used one-off border colors.

## Improvements Applied

- Moved shared color, gradient, spacing, radius, and shadow tokens into `FocusDesignTokens.ets`.
- Added a compact Resources workflow hint row that names the active workspace, shows the selected resource, and surfaces AI readiness.
- Extracted AI readiness and Resources status text into small helper methods.
- Aligned shared card helper borders to the shared border token.

## Guardrails

- No data mutation path was changed.
- Resource and task writes still go through `FocusStore`.
- Stateful ArkUI builders stayed inside `Index.ets` to reduce build risk.
