# Polish Focus frontend presentation

## Goal

Improve the Focus app's frontend presentation so it looks more polished and product-ready for a final course demo, while preserving the local-first data architecture and the stable core flows from the previous refactor.

The user explicitly asked to beautify the frontend display and start immediately. This task should focus on high-impact visual and UX polish, not broad new functionality or backend work.

## Requirements

- Keep the app local-first and do not change RDB / FocusStore data contracts.
- Improve the first impression of the app:
  - login screen,
  - Today hero / next focus area,
  - quick-add card,
  - task list rows,
  - focus timer card,
  - review KPI / chart cards,
  - independent FocusAbility screen,
  - service card if low-risk.
- Make the UI look like a mature productivity app:
  - restrained color palette,
  - stronger hierarchy,
  - cleaner spacing,
  - more deliberate card surfaces,
  - better button affordances,
  - readable empty states and status text.
- Avoid over-decorating:
  - no huge marketing hero,
  - no noisy emoji-heavy UI,
  - no nested cards for page sections,
  - no one-note purple/blue gradient takeover,
  - no layout tricks known to break ArkUI.
- Preserve mobile readability:
  - text must not overflow compact controls,
  - task rows should remain scan-friendly,
  - timer controls should be reachable and visually distinct.
- Preserve buildability with DevEco hvigor.

## Acceptance Criteria

- [ ] Core data flow remains unchanged: UI mutations still go through `FocusStore` and RDB.
- [ ] `Index.ets` receives a meaningful visual polish pass without adding risky dependencies.
- [ ] `FocusSolo.ets` remains visually consistent with the main focus experience.
- [ ] Service card styling is improved or explicitly left unchanged if code risk outweighs value.
- [ ] ArkUI known pitfalls from `HANDOVER.md` are avoided.
- [ ] Frontend HAP build passes.
- [ ] `HANDOVER.md` is updated with the polish pass summary and verification result.

## Notes

- Backend Maven build is not required unless backend files are touched.
- Device/emulator screenshot verification is ideal but may not be available in this environment.
