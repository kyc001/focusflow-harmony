# Focus App Deep Refactor Design

## Design Direction

Focus should become a local-first productivity app with optional local Spring Boot sync, not a backend-dependent demo. The core refactor centers on making the existing HarmonyOS app reliable and pleasant to use:

- RDB-backed app data for tasks, projects, and Pomodoro records.
- Preferences-backed auth/settings.
- A single repository/store facade used by Today, Tasks, Focus, Review, ArkWeb bridge, and service-card-adjacent data.
- Clearer page/component boundaries so UI polish can happen without destabilizing data logic.
- Spring Boot backend preserved as an optional local full-stack sync layer while remaining non-blocking for offline app use.

## Architecture Boundaries

### Frontend Layers

- `models/`: shared TypeScript/ArkTS interfaces and enums.
- `data/`: seed/default data only. It should initialize an empty local store, not remain the runtime source of truth.
- `services/database` or equivalent: RDB open/create/migration plus DAO-style CRUD helpers.
- `repository/`: app-facing local repository and optional auth/remote repositories.
- `services/`: native capability wrappers such as notification/background guard.
- `viewmodel/` or focused page-state classes: orchestrate UI state, filtering, timer state, and repository calls.
- `pages/` and `components/`: ArkUI views. Views should call viewmodel/store methods rather than mutate global arrays directly.

### Backend Boundary

`focus-server` remains an optional local sync/demo backend. It can keep direct mapper usage for this course project unless backend work becomes a direct implementation target. It should be documented as buildable, aligned with frontend schema names, and non-critical to offline app usage.

If frontend backend integration is added, it should use a small network boundary:

- `network/FocusHttpClient.ets`: base URL, JSON requests, timeout/error normalization, headers.
- `repository/RemoteFocusRepository.ets`: login/register, sync pull, sync push.
- `repository/SyncRepository.ets` or equivalent facade: coordinates local snapshot, push/pull, Preferences cursor, and sync status.

## Data Flow

### Startup

1. Entry page initializes `AuthRepository`.
2. Entry page initializes the local data repository.
3. Repository opens RDB and creates/migrates tables.
4. Repository checks whether local tables have data.
5. If empty, repository seeds default projects/tasks/pomodoros once.
6. UI loads a snapshot from repository into reactive page state.

### Task Mutation

1. UI action calls repository/store facade: add, toggle, soft delete, restore.
2. Repository writes to RDB first.
3. Repository refreshes its in-memory snapshot from RDB.
4. UI receives/requests the refreshed snapshot.
5. Repository records the local change as sync-pending or includes it in the next bulk snapshot push.
6. Best-effort sync can run after mutation or from a manual sync action; remote failure updates status only and must not roll back local success.

### Pomodoro Mutation

1. Focus page or FocusAbility completes/interrupts a Pomodoro.
2. Mutation writes a Pomodoro record to RDB.
3. If completed, linked task `pomodoroCount` increments.
4. Shared event/state refresh updates Today, Tasks, Review, and ArkWeb bridge data.
5. Notification/background wrappers remain best-effort native enhancements.

### Optional Backend Login / Sync

1. User can continue as guest/local mode without backend.
2. User can configure backend base URL and login/register against the local Spring Boot service if optional sync is enabled.
3. Auth response stores `token`, `userId`, username, nickname, and backend mode in Preferences.
4. Manual sync and automatic opportunistic sync use:
   - `POST /api/sync/push` with local projects/tasks/pomodoros.
   - `POST /api/sync/pull?since=<lastPullAt>` for backend updates.
5. Pulled records upsert into local RDB using timestamp comparison where possible.
6. Sync status appears in the UI as local-only, syncing, synced, or failed/offline.

Use `X-User-Id` because the current backend expects it; token can be stored/displayed but does not need Spring Security semantics in this refactor.

### ArkWeb Bridge

The injected bridge should read stats from the same local repository/store snapshot as the native review page. It should not compute from stale seed-only data.

## Data Contracts

### RDB Tables

Keep current core fields and add minimal sync-ready fields where useful:

- `projects`: `id`, `name`, `color`, `icon`, `updated_at`, `is_deleted`.
- `tasks`: `id`, `title`, `note`, `project_id`, `priority`, `due_at`, `status`, `pomodoro_count`, `created_at`, `updated_at`, `completed_at`, `tags_json`, `subtasks_json`.
- `pomodoros`: `id`, `task_id`, `start_at`, `duration`, `completed`, `interrupt_reason`, `updated_at`.
- Settings can remain Preferences unless there is a clear reason to query them relationally.

Use Unix milliseconds for timestamps. Serialize arrays with JSON because ArkTS models already expose `tags` and `subtasks` arrays while RDB rows need scalar columns.

### Repository Snapshot

Expose a simple snapshot object:

- projects
- tasks
- pomodoros
- settings
- derived stats helpers or stat methods

During this refactor, a pragmatic facade may preserve `focusStore` as a compatibility wrapper, but runtime truth should move to RDB-backed repository methods.

### Remote DTO Shape

Map frontend model names to backend entity field names:

- `projectId` <-> `project_id` in SQL / `projectId` in Java JSON.
- `dueAt`, `createdAt`, `updatedAt`, `completedAt`, `pomodoroCount`.
- `clientRequestId` generated for non-idempotent creates/pomodoro records.
- `tags` and `subtasks` remain local-only unless backend schema is expanded; document this if not synced.

## UI / UX Design

Focus is a work-focused productivity tool. The UI should be quiet and efficient:

- Today's page should answer: what should I focus on next, how much have I done today, and what is still open?
- Task page should support scanning, filtering, and quick actions without visual noise.
- Focus page should reduce choices while the timer is running.
- Review page should make progress legible but not compete with the core task/focus flow.
- Layout should use stable dimensions for timer rings, tab contents, rows, filters, and buttons to prevent jitter.
- Avoid large decorative gradients, nested cards, excessive rounded pills, or emoji-heavy status indicators unless they have a clear information role.

## Compatibility Notes

Known ArkTS/ArkUI pitfalls from `HANDOVER.md` must be preserved:

- ArkUI alpha color strings use `#AARRGGBB`, not `#RRGGBBAA`.
- Avoid `height('100%')` decorative sidebars inside unconstrained Scroll/Row layouts.
- Avoid ternary nested arrays in `linearGradient.colors` inside `@Builder`.
- Avoid passing function parameters into `@Builder` in ways that triggered previous compile bugs.
- Avoid complex ternary object literals in `.shadow()`.

## Rollback Shape

- Keep seed data and current UI behavior available as fallback while introducing the repository.
- Implement RDB-backed repository behind method names that can be rolled back to `FocusStore` if compilation breaks.
- Keep backend optional and non-blocking; do not couple frontend build or core local flows to backend availability.

## Trade-Offs

- Full architectural purity is less important than a stable course deliverable. A compatibility facade is acceptable if it keeps the app buildable.
- Real local persistence remains higher value than remote sync for user trust. Keeping the local backend available preserves final-assignment full-stack credibility without weakening offline product quality.
- UI polish should focus on consistency, hierarchy, spacing, and state feedback rather than another dramatic visual theme overhaul.
