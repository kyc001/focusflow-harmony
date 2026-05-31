# Backend maturity and focus noise UX

## Goal

Make the optional Spring Boot backend feel like a real application support layer, not only a hidden API demo, and make focus-session white noise visible and usable from the Focus experience.

The first implementation slice should prioritize user-visible maturity:

- Account flow in the app includes registration, login, logout, and clear sync status.
- Cloud sync explains and exposes the data it manages instead of feeling like a test button.
- Focus mode exposes white-noise choices directly in the focus flow, with values that match the local audio playback service.

## Requirements

- Preserve the local-first product contract. Core tasks, pomodoros, resources, settings, and guest usage must keep working without the backend.
- Reuse the existing Spring Boot backend endpoints where possible:
  - `POST /api/user/register`
  - `POST /api/user/login`
  - project/task/pomodoro/stats REST endpoints
  - `POST /api/sync/pull`
  - `POST /api/sync/push`
- Add missing frontend support for backend account creation.
- Improve the frontend cloud-sync panel so users can understand login state, register or login, sync data, and see a compact data-management summary.
- Keep backend sync optional and secondary. A backend failure must show a non-blocking status and must not erase local data.
- Align white-noise setting values with `FocusAmbientService` supported values: `none`, `outdoor`, `ocean`, `cricket`.
- Make white-noise controls visible from the focus session screen, not only from the settings overlay.
- Starting a focus session should play the selected ambient sound when it is not `none`.
- Completing, interrupting, or resetting a focus session should stop ambient playback.
- Existing ArkTS strict-mode rules must remain satisfied: no anonymous object literal types, no untyped object literals where ArkTS requires an explicit interface/class, no indexed field access on typed objects.

## Acceptance Criteria

- [ ] Frontend HAP build passes.
- [ ] Backend Maven package build passes.
- [ ] Cloud-sync UI supports registration and login through the existing backend.
- [ ] Cloud-sync UI exposes a compact data-management summary for projects, active tasks, completed pomodoros, and last sync status.
- [ ] Successful sync refreshes `FocusStore` through `focusStore.refresh()` and updates page state through `syncFromStore()`.
- [ ] Failed login/register/sync displays a readable status without blocking local flows.
- [ ] Focus screen includes direct white-noise controls with at least `none`, `outdoor`, `ocean`, and `cricket`.
- [ ] Settings and Focus screen use the same white-noise values and labels.
- [ ] Ambient playback uses the saved `FocusSettings.noise` value and no longer depends on legacy labels such as "rain" or "coffee".
- [ ] `git diff --check` passes.
- [ ] Secret scan for real API/token patterns passes.

## Notes

- Confirmed backend facts:
  - Spring Boot already has `UserController`, `ProjectController`, `TaskController`, `PomodoroController`, `StatsController`, and `SyncController`.
  - Backend README currently describes the server as an optional thin sync layer.
  - The frontend `FocusSyncService` currently exposes login, logout, pull, push, and bidirectional sync, but not registration or direct data summary requests.
- Confirmed frontend facts:
  - `FocusSettings.noise` exists and is persisted through `focusSettingsService`.
  - Existing settings UI uses display labels that do not match `FocusAmbientService` values.
  - `FocusAmbientService` supports `none`, `outdoor`, `ocean`, and `cricket`.
  - The focus page starts ambient playback from `settings.noise`, but the focus screen does not show a direct white-noise selector.
