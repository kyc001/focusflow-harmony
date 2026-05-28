# UX UI Modularization

## Goal

Improve the app from the user's perspective and make the ArkTS UI code easier to maintain without breaking the local-first data flow.

## Confirmed Facts

- `Index.ets` is the primary app container and is roughly 4.9k lines with many state fields, event handlers, and `@Builder` UI sections.
- The current UI includes login/start, Today, Tasks, Profile, resource detail, focus timer overlay, review detail, settings detail, AI settings, and study-resource flows.
- The product direction is visible as "ZhiXu / AI Study Flow" while internal file/class names still use `Focus*`.
- Prior work already moved some repeated display logic into `FocusFormatters.ets`.
- The Harmony-specific spec warns against risky ArkUI patterns and requires UI mutations to go through `FocusStore`.

## Requirements

- Perform a practical UX pass over the main workflows: first-run/login, Today dashboard, task management, study resources, focus timer, review/profile/settings.
- Improve visual consistency by centralizing design tokens and reusable style helpers where feasible.
- Modularize code with low build risk:
  - extract pure constants/helpers before moving stateful UI sections;
  - keep page state ownership clear;
  - avoid direct `focusStore` array mutation;
  - preserve existing Ability routes and resources.
- Fix obvious UX friction encountered during implementation, especially dense resource/AI states and unclear fallback messages.

## Acceptance Criteria

- [ ] A short UX audit is recorded in this task or implementation notes.
- [ ] Main UI changes improve hierarchy, visual consistency, and flow clarity without removing existing core functions.
- [ ] Repeated design values or pure helpers are extracted when they have multiple consumers or make `Index.ets` easier to scan.
- [ ] No local-first contract is violated: task/resource/Pomodoro mutations still go through `FocusStore`.
- [ ] Frontend HAP build is run after implementation, or any environment blocker is recorded.

## Out of Scope

- Backend changes.
- Replacing ArkUI with another UI framework.
- Large cross-file ArkUI component migration if it fails build validation.
- Real device screenshots.
