# Harmony Focus Local-First Contracts

This project is a HarmonyOS ArkTS app, not an Electron/React app. Use this file as the primary frontend implementation spec for Focus. Legacy Electron-oriented spec files can still provide general quality ideas, but they must not override the contracts below.

## Scenario: RDB-Backed Local-First Focus App

### 1. Scope / Trigger

- Trigger: Any change touching tasks, projects, Pomodoro records, startup data loading, ArkWeb stats, or `FocusAbility` task handoff.
- Product contract: the app must remain fully usable without the Spring Boot backend.
- Architecture contract: RDB is the runtime source of truth for tasks/projects/pomodoros; `FocusStore` is the UI-facing compatibility facade.

### 2. Signatures

Local database:

- DB name: `focus.db`
- DB version: `2`
- Tables:
  - `projects(id, name, color, icon, updated_at, is_deleted)`
  - `tasks(id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, tags_json, subtasks_json)`
  - `pomodoros(id, task_id, start_at, duration, completed, interrupt_reason, updated_at)`

RDB facade:

```typescript
focusDatabase.init(context: common.UIAbilityContext): Promise<void>
focusDatabase.getProjects(): Promise<FocusProject[]>
focusDatabase.getTasks(): Promise<FocusTask[]>
focusDatabase.getPomodoros(): Promise<PomodoroRecord[]>
focusDatabase.addTask(task: FocusTask): Promise<FocusTask>
focusDatabase.updateTask(task: FocusTask): Promise<void>
focusDatabase.recordPomodoro(record: PomodoroRecord): Promise<PomodoroRecord>
focusDatabase.incrementTaskPomodoro(taskId: number): Promise<void>
```

UI-facing store:

```typescript
focusStore.refresh(): Promise<void>
focusStore.addTask(title: string, projectId: number, priority: number, dueOffsetHours: number): Promise<FocusTask>
focusStore.toggleTask(taskId: number): Promise<void>
focusStore.softDeleteTask(taskId: number): Promise<void>
focusStore.restoreTask(taskId: number): Promise<void>
focusStore.recordPomodoro(taskId: number, duration: number, completed: boolean, reason: string): Promise<void>
```

`FocusAbility` Want parameters:

```typescript
{
  taskId: number,
  taskTitle: string
}
```

AppStorage keys:

```typescript
focus.taskId: number
focus.taskTitle: string
auth.nickname: string
auth.guest: boolean
```

Runtime settings:

```typescript
interface FocusSettings {
  focusMinutes: number;
  shortBreakMinutes: number;
  longBreakMinutes: number;
  themeColor: string;
  noise: string;
  notificationEnabled: boolean;
}

focusSettingsService.init(context: common.UIAbilityContext): Promise<void>
focusSettingsService.loadSettings(): Promise<FocusSettings>
focusSettingsService.saveSettings(settings: FocusSettings): Promise<FocusSettings>
focusSettingsService.defaultSettings(): FocusSettings
```

### 3. Contracts

- All timestamps are Unix milliseconds except `PomodoroRecord.duration`, which is seconds.
- Task status values:
  - `0`: TODO
  - `1`: DONE
  - `2`: DELETED
- Pomodoro completion values:
  - `1`: completed
  - `0`: interrupted
- `tags` and `subtasks` are arrays in ArkTS models and JSON strings in RDB.
- Every UI mutation must write through `FocusStore`, then refresh from RDB, then update reactive page state.
- ArkWeb stats must read from `FocusStore`, not directly from seed data.
- Optional backend sync must run after local success and must not block local task/Pomodoro flows.
- `FocusAbility` must parse Want parameters in both `onCreate` and `onNewWant`.
- Runtime focus settings are stored in Preferences under `focus_settings`, not in RDB. The keys are `timer.focusMinutes`, `timer.shortBreakMinutes`, `timer.longBreakMinutes`, `appearance.themeColor`, `audio.noise`, and `notification.enabled`.
- Runtime settings must be normalized on load/save. Focus minutes clamp to 10-60, short break to 3-15, and long break to 10-30.
- UI changes to timer length, white noise, or notification preference must save through `focusSettingsService.saveSettings()`, then copy the normalized result back into `focusStore.settings` and page state.
- Preferences failures for runtime settings must degrade to defaults or normalized in-memory settings and must not block startup, task writes, or Pomodoro writes.

### 4. Validation & Error Matrix

| Condition | Required behavior |
| --- | --- |
| RDB not initialized before a write | Initialize with `UIAbilityContext` if available; otherwise show graceful local-record warning. |
| Query returns nullable column | Use helper fallback, never assume the column is non-null. |
| `ResultSet` is opened | Always close it in `finally`. |
| Local write succeeds but backend fails | Keep local data and show local/offline/sync-failed status when sync UI exists. |
| `FocusAbility` receives a new task while singleton already exists | `onNewWant` must refresh `focus.taskId` and `focus.taskTitle`. |
| ArkWeb unavailable in previewer | Keep native review summary usable and document device/emulator requirement. |
| Background task API unsupported | Keep timer usable and show best-effort message. |
| Runtime settings Preferences init/load/save fails | Keep app usable with default or normalized in-memory settings and show a non-blocking settings message. |

### 5. Good / Base / Bad Cases

Good:

- Quick add calls `focusStore.addTask()`, writes RDB, calls `refresh()`, and updates `Index` state with `syncFromStore()`.
- Completing a Pomodoro records a row in `pomodoros` and increments the linked task's `pomodoro_count`.
- `FocusSolo` receives `taskId` and writes completion through `focusStore.recordPomodoro()`.
- Dragging a timer slider or choosing white noise updates page state and saves normalized settings through `focusSettingsService`.

Base:

- Backend is not running; local account, guest mode, tasks, focus, and review still work.
- ArkWeb cannot be previewed; native review stats still show meaningful data.
- Preferences are unavailable; default focus settings are used and the timer remains usable.

Bad:

- Mutating `focusStore.tasks` directly from UI without RDB write.
- Computing review stats from `SeedData.ets` after startup.
- Parsing Want only in `onCreate`, causing singleton hot-start task changes to be ignored.
- Using `#RRGGBBAA` alpha colors in ArkUI.
- Mutating `this.settings.noise` or timer durations directly from ArkUI event handlers without saving through `focusSettingsService`.

### 6. Tests Required

Before reporting completion for changes in this area:

- Run frontend build:

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

- Run backend build when backend contracts or docs are touched:

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;D:\Tools\apache-maven-3.9.10\bin;$env:Path"
mvn -q -DskipTests package
```

- Manual emulator/device checks when available:
  - Add task -> restart app -> task persists.
  - Complete Pomodoro -> review stats change.
  - Interrupt Pomodoro -> interruption count changes.
  - Open the same singleton `FocusAbility` with another task -> title/id update.
  - ArkWeb review page loads from `rawfile/charts/index.html`.
  - Service card can be added and rendered.
  - Timer durations, notification preference, and white noise survive app restart when Preferences are available.

### 7. Wrong vs Correct

#### Wrong

```typescript
this.tasks.push(task);
// UI looks updated, but restart loses the task and review stats diverge.
```

#### Correct

```typescript
const saved: FocusTask = await focusStore.addTask(title, projectId, priority, dueOffsetHours);
this.selectedTaskId = saved.id;
this.syncFromStore();
```

#### Wrong

```typescript
this.settings.noise = noise;
// The selection works only for the current render and is lost after restart.
```

#### Correct

```typescript
this.settings.noise = noise;
const saved: FocusSettings = await focusSettingsService.saveSettings(this.settings);
focusStore.settings = saved;
this.settings = saved;
```

#### Wrong

```typescript
onCreate(want: Want): void {
  this.parseWant(want);
}
// Singleton hot starts keep showing the old task.
```

#### Correct

```typescript
onCreate(want: Want): void {
  this.parseWant(want);
}

onNewWant(want: Want): void {
  this.parseWant(want);
}
```

## Harmony ArkUI Gotchas

- ArkUI alpha colors are `#AARRGGBB`; do not write web-style `#RRGGBBAA`.
- Avoid decorative `height('100%')` in unconstrained `Scroll`, `Row`, or `Stack` layouts. It can stretch cards to the whole viewport.
- Avoid complex ternary nested arrays inside `linearGradient.colors` in builders.
- Avoid `@Builder` callback function parameters if the build pipeline starts reporting missing program counts.
- Keep backend sync affordances secondary; the primary product is local-first task/focus/review.

## Scenario: Optional AI Coach and App Visual Assets

### 1. Scope / Trigger

- Trigger: Any change touching AI coach advice, runtime AI settings, remote model calls, generated media resources, or review/reward visual assets.
- Product contract: AI must remain an enhancement layer. Tasks, projects, and Pomodoro records stay usable without network, API keys, or AI preferences.

### 2. Signatures

AI settings model:

```typescript
interface AiCoachSettings {
  enabled: boolean;
  endpoint: string;
  model: string;
  apiKey: string;
}
```

AI advice model:

```typescript
interface AiCoachAdvice {
  source: string;
  headline: string;
  nextAction: string;
  sessionPlan: string;
  risk: string;
  estimatedMinutes: number;
  confidence: number;
  generatedAt: number;
}
```

AI service:

```typescript
focusAiCoachService.init(context: common.UIAbilityContext): Promise<void>
focusAiCoachService.loadSettings(): Promise<AiCoachSettings>
focusAiCoachService.saveSettings(settings: AiCoachSettings): Promise<AiCoachSettings>
focusAiCoachService.generateLocalAdvice(...): AiCoachAdvice
focusAiCoachService.requestAdvice(...): Promise<AiCoachAdvice>
```

Harmony resources:

```typescript
$r('app.media.focus_ai_hero')
$r('app.media.focus_coach_orbit')
$r('app.media.focus_forest_spritesheet')
$r('app.media.focus_plant_seed')
$r('app.media.focus_plant_ginkgo')
$r('app.media.focus_plant_pine')
$r('app.media.focus_plant_bloom')
$r('app.media.focus_plant_maple')
$r('app.media.focus_plant_forest')
$r('app.media.focus_reward_timer_token')
$r('app.media.focus_reward_water')
$r('app.media.focus_reward_stone_path')
$r('app.media.focus_reward_compost')
$r('app.media.focus_reward_locked_seed')
$r('app.media.focus_ui_spritesheet')
$r('app.media.focus_ui_empty_inbox')
$r('app.media.focus_ui_quick_add')
$r('app.media.focus_ui_next_marker')
$r('app.media.focus_ui_priority_flag')
$r('app.media.focus_ui_ai_orb')
$r('app.media.focus_ui_local_cube')
$r('app.media.focus_ui_remote_cloud')
$r('app.media.focus_ui_timer_token')
$r('app.media.focus_ui_pause_resume')
$r('app.media.focus_ui_notification_bell')
$r('app.media.focus_ui_completion_medal')
$r('app.media.focus_ui_risk_shield')
$r('app.media.focus_ui_review_bars')
$r('app.media.focus_ui_heatmap_grid')
$r('app.media.focus_ui_settings_sliders')
$r('app.media.focus_ui_sync_bridge')
```

### 3. Contracts

- AI settings are stored in Preferences under `focus_ai`, not in RDB.
- Defaults must be non-secret: endpoint `https://api.openai.com/v1`, model `gpt-4o-mini`, empty API key, disabled remote mode.
- API keys are runtime input only. Never commit a provided key, test key, bearer token, or `sk-` value into source, docs, task files, or generated scripts.
- Empty API key input in the settings UI means "keep the saved key"; the UI must not echo the saved key back into a text field.
- `requestAdvice()` must fall back to `generateLocalAdvice()` when remote mode is disabled, the key is empty, the HTTP request fails, the response is non-2xx, or the response is empty/unparseable.
- AI reads `FocusStore` snapshots and returns display advice only; it must not write tasks, projects, Pomodoro records, or RDB schema.
- Hero/card visuals can be generated concept imagery. Repeated reward assets must be reusable sprites or independent icon PNGs, not one-off concept scenes.
- Paid related UI asset generation should prefer one grid spritesheet request, followed by local crop/validation into named PNG resources. Wire cropped sprites into real product states before considering the asset work complete.
- Keep generated UI micro-assets text-free: no readable text, letters, numbers, logos, watermarks, or large concept scenes. Use app text rendered by ArkUI instead of in-image labels.

### 4. Validation & Error Matrix

| Condition | Required behavior |
| --- | --- |
| Preferences init/load/save fails | Use defaults or normalized in-memory settings; keep the app usable. |
| Remote AI disabled or missing key | Return local advice and show local/fallback status. |
| Remote endpoint returns non-2xx | Return local advice with visible fallback source/status. |
| Remote response is empty or unparseable | Return local advice. |
| User leaves API key input blank while saving | Preserve previously saved key. |
| Generated reward visual is a concept scene | Replace with spritesheet/individual icon assets before wiring to repeated UI. |
| Paid spritesheet is generated | Crop to stable resource names, validate PNGs, then reference selected assets in UI cards/states. |
| Generated UI asset contains text/logos | Reject or regenerate; do not ship text baked into reusable UI sprites. |

### 5. Good / Base / Bad Cases

Good:

- Today/Focus can show local advice immediately after `focusStore.refresh()`.
- The AI card updates after task mutations and Pomodoro completion/interruption.
- Review forest uses independent plant and reward icon resources for unlock states.
- A single generated UI spritesheet is cropped into `focus_ui_*` resources and reused across Today hero chips, empty states, task rows, timer status, AI settings, and Review cards.

Base:

- No API key or no network: local advice still recommends a task, plan, next step, and risk note.
- Generated API is unavailable: keep existing workspace assets and do not keep retrying paid calls.
- If a spritesheet is good but not transparent, crop it into fixed square PNGs and use ArkUI containers/rounding consistently; do not attempt fragile ad hoc alpha removal unless the prompt was designed for chroma key.

Bad:

- Storing a provided API key in committed docs or source.
- Blocking app startup because Preferences or remote AI failed.
- Using a large concept illustration as a repeated plant tile or reward icon.
- Paying for many one-off related icon requests when one crop-friendly spritesheet would satisfy the UI need.

### 6. Tests Required

- Run the frontend HAP build after adding or renaming media resources.
- Validate every generated or cropped PNG can be opened and has expected dimensions before wiring resources.
- Run a secret scan before reporting completion:

```powershell
rg "sk-" .
```

- Manually inspect generated or local asset sheets before wiring them into repeated UI.
- On emulator/device, verify remote AI disabled mode, blank-key save behavior, local recompute, and remote failure fallback when possible.

### 7. Wrong vs Correct

#### Wrong

```typescript
this.aiApiKeyInput = settings.apiKey;
// The saved key is echoed back into visible UI state.
```

#### Correct

```typescript
this.aiApiKeyInput = '';
const nextApiKey: string = this.aiApiKeyInput.trim().length > 0 ? this.aiApiKeyInput : this.aiSettings.apiKey;
```

#### Wrong

```typescript
Text(plant.icon)
// Repeated rewards are text placeholders, not app assets.
```

#### Correct

```typescript
Image($r('app.media.focus_plant_seed')).plantAssetStyle(isUnlocked)
```

#### Wrong

```typescript
Image($r('app.media.focus_ui_spritesheet'))
// The whole sheet is shown inside one small UI state.
```

#### Correct

```typescript
Image($r('app.media.focus_ui_empty_inbox')).microAssetStyle(76)
// Use the cropped, semantic resource for the specific UI state.
```
