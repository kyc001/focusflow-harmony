# AI Focus Coach and Visual Asset Iteration Design

## Architecture

Focus remains local-first. The new AI layer sits beside the existing `FocusStore` facade:

```text
ArkUI Coach Panel
  -> FocusAiCoachService
      -> local heuristic summary from FocusStore snapshots
      -> optional remote model call through configured endpoint/key
  -> Preferences-backed AI settings
```

The AI service does not write tasks or Pomodoro records directly. It reads local snapshots and returns advice text, next-step text, estimated minutes, risk level, and status metadata for UI display.

## Data Flow

Offline flow:

```text
Index UI -> FocusAiCoachService.generateLocalCoach()
  -> tasks/projects/pomodoros/settings snapshot
  -> deterministic advice object
  -> UI state
```

Remote flow:

```text
Index UI -> FocusAiCoachService.requestRemoteCoach()
  -> build compact prompt from FocusStore snapshot
  -> HTTP POST to configured OpenAI-compatible endpoint
  -> parse text safely
  -> UI state
  -> fallback to local advice on error
```

## Contracts

- AI settings are stored in Preferences, not RDB:
  - `ai.endpoint`
  - `ai.apiKey`
  - `ai.model`
  - `ai.enabled`
- Default endpoint/model are non-secret defaults.
- The API key is only stored after user input at runtime.
- The saved API key is not echoed into the settings input; leaving the input blank preserves the existing key.
- Empty or failed remote responses fall back to local coaching.
- The remote prompt must be compact and avoid sending unnecessary personal data.
- AI advice is display-only and must not write tasks, projects, Pomodoro records, or RDB schema.

## UI Placement

Add the coach where it helps the core workflow:

- Today tab: show next-action guidance near the next task.
- Focus tab: show a session plan and anti-interruption nudge.
- Settings-side panel: allow runtime AI endpoint/key/model configuration.

## Visual Assets

Use different asset strategies by role:

- Concept visuals:
  - `focus_ai_hero.png`: calm study desk / local-first focus assistant visual for Today hero.
  - `focus_coach_orbit.png`: compact abstract coaching visual for AI Coach card.
- Reusable review/reward sprites:
  - `focus_forest_spritesheet.png`: 4x3 sheet for visual inspection and future cropping.
  - `focus_plant_*`: independent plant-growth icons for forest unlock tiles.
  - `focus_reward_*`: timer, streak, path, compost/review, and locked-state reward icons.
- Reusable UI micro-assets:
  - `focus_ui_spritesheet.png`: 4x4 paid generated sheet for shared product states.
  - `focus_ui_*`: cropped 256x256 icons for empty states, quick add, next-focus, AI/local/remote status, timer, notifications, completion, interruption risk, review charts, settings, and sync bridge.

Assets are saved under `entry/src/main/resources/base/media/` and referenced through `$r('app.media.<name>')`.

Large concept images are not suitable for repeated UI elements. Repeated reward visuals must be separate icons or crop-friendly sprites.
Generated UI spritesheets are only considered complete after local cropping, PNG validation, and wiring into actual ArkUI states/cards.

## Risk / Rollback

- If Harmony network API syntax differs by SDK, keep the UI and offline coach shipped and disable remote calls behind graceful error status.
- Generated images are additive resources; rollback is deleting the new media references and files.
- If the paid image API is unstable, avoid repeated requests without explicit approval; use local deterministic sprites for reusable UI assets.
- No schema migration is needed.
