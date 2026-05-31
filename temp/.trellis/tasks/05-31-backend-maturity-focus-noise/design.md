# Backend maturity and focus noise UX Design

## Architecture And Boundaries

This task improves the first complete user-facing slice without replacing the local-first architecture.

- Backend remains optional. It supports account registration/login and cloud data operations.
- Frontend remains local-first. RDB and Preferences are still the runtime source of truth.
- `FocusSyncService` owns HTTP calls to the backend.
- `Index.ets` owns the cloud-sync panel and focus-session white-noise controls.
- `FocusAmbientService` owns ambient audio playback and supported sound IDs.

## Data Flow

Account registration/login:

1. User enters username, nickname, and password in the cloud-sync panel.
2. `Index.ets` calls `focusSyncService.register()` or `focusSyncService.login()`.
3. `FocusSyncService` persists returned `userId`, `username`, `nickname`, and token in Preferences.
4. UI updates sync status and can call bidirectional sync.

Cloud data summary:

1. UI reads current local `FocusStore` arrays for local counts.
2. UI can call backend summary/list endpoints through `FocusSyncService` for cloud-facing status where needed.
3. Sync success calls `focusStore.refresh()` and `syncFromStore()`.

White noise:

1. UI selects one of `none`, `outdoor`, `ocean`, or `cricket`.
2. `updateNoiseSetting()` persists the normalized `FocusSettings.noise` value.
3. Starting a focus session calls `focusAmbientService.play(settings.noise as AmbientType, context)`.
4. Completing, interrupting, or resetting calls `focusAmbientService.stop()`.

## Contracts

- Supported ambient IDs: `none`, `outdoor`, `ocean`, `cricket`.
- UI display labels may be localized, but persisted values must use supported IDs.
- Registration uses the existing backend `RegisterRequest`: `username`, `password`, `nickname`.
- Backend auth remains demo-grade token storage for this slice; no security-hardening rewrite is included.
- Network errors return explicit UI messages and do not block local usage.

## Compatibility

- Existing users with old noise labels should be normalized to a supported ambient ID before playback.
- Existing backend endpoints and database schema should be reused.
- Avoid broad backend schema migrations unless a compile/runtime blocker is found.

## Tradeoffs

- This slice makes the backend feel usable from the app, but it does not implement a full admin console.
- It improves account and sync UX, but it does not introduce JWT/security middleware.
- It makes white noise visible and functional, but advanced audio controls such as volume and pause behavior can remain future work.

## Rollback

- Revert frontend changes to `Index.ets`, `FocusSyncService.ets`, `FocusSettingsService.ets`, and `SeedData.ets` if the UI slice regresses.
- Revert backend changes only if new endpoints or DTO edits are introduced and fail Maven build.
