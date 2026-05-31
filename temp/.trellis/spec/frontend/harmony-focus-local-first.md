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
- DB version: `3`
- Tables:
  - `projects(id, name, color, icon, updated_at, is_deleted)`
  - `tasks(id, title, note, project_id, priority, due_at, status, pomodoro_count, created_at, updated_at, completed_at, tags_json, subtasks_json)`
  - `pomodoros(id, task_id, start_at, duration, completed, interrupt_reason, updated_at)`
  - `study_resources(id, title, source_type, project_id, linked_task_id, content, summary, key_points_json, tags_json, status, created_at, updated_at, review_due_at)`

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
focusDatabase.getStudyResources(): Promise<StudyResource[]>
focusDatabase.addStudyResource(resource: StudyResource): Promise<StudyResource>
focusDatabase.updateStudyResource(resource: StudyResource): Promise<void>
```

UI-facing store:

```typescript
focusStore.refresh(): Promise<void>
focusStore.addTask(title: string, projectId: number, priority: number, dueOffsetHours: number): Promise<FocusTask>
focusStore.toggleTask(taskId: number): Promise<void>
focusStore.softDeleteTask(taskId: number): Promise<void>
focusStore.restoreTask(taskId: number): Promise<void>
focusStore.recordPomodoro(taskId: number, duration: number, completed: boolean, reason: string): Promise<void>
focusStore.addStudyResource(title: string, sourceType: string, projectId: number, content: string): Promise<StudyResource>
focusStore.updateResourceInsight(resourceId: number, insight: ResourceInsight): Promise<void>
focusStore.archiveResource(resourceId: number): Promise<void>
focusStore.restoreResource(resourceId: number): Promise<void>
focusStore.createTaskFromResource(resourceId: number, title: string, estimatedMinutes: number): Promise<FocusTask | undefined>
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
- Standalone `FocusAbility` / `FocusSolo` must load timer length through `focusSettingsService` when a `UIAbilityContext` is available, and must degrade to the default 25-minute timer if Preferences fail.
- Focus page visual polish must not introduce a runtime network dependency. Reuse `FocusDesignTokens` and semantic local media resources first; newly generated raster assets must be saved under `entry/src/main/resources/base/media/` before being referenced by ArkUI.

## Scenario: Study Resources and Document Import

### 1. Scope / Trigger

- Trigger: Any change touching the Resources tab, `StudyResource`, the `study_resources` RDB table, resource AI extraction, or document/file import.
- Product contract: resources are local-first learning objects. They may represent notes, links, courseware, PDFs, or picked local files.

### 2. Signatures

Study resource model:

```typescript
interface StudyResource {
  id: number;
  title: string;
  sourceType: string;
  projectId: number;
  linkedTaskId: number;
  content: string;
  summary: string;
  keyPoints: string[];
  tags: string[];
  status: number;
  createdAt: number;
  updatedAt: number;
  reviewDueAt: number;
}
```

Resource status values:

- `0`: active
- `1`: archived

Supported `sourceType` values:

- `note`: manually written note / memo
- `link`: web link or link description
- `courseware`: courseware or slide excerpt
- `pdf`: PDF / paper excerpt
- `file`: local document selected through `picker.DocumentViewPicker`

Document import entry point:

```typescript
const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
options.maxSelectNumber = 1;
options.fileSuffixFilters = ['学习资料|.pdf,.doc,.docx,.ppt,.pptx,.txt,.md'];
const uris: Array<string> = await documentPicker.select(options);
```

### 3. Contracts

- `study_resources` is additive. Do not change existing task/project/pomodoro schemas when adding resource behavior.
- Resource UI mutations must write through `FocusStore`, refresh from RDB, and copy state back into the page.
- File import stores a URI reference plus user notes in `StudyResource.content`; it does not copy binary files or parse document bodies in this iteration.
- Resource AI extraction updates `summary` and `keyPoints` only after the resource exists locally.
- Creating a task from a resource must create a normal RDB-backed `FocusTask` and then update `linkedTaskId` on the resource.
- Empty remote AI settings or request failures must return an explicit remote AI status and must not generate local replacement insight.

### 4. Validation & Error Matrix

| Condition | Required behavior |
| --- | --- |
| `study_resources` table is missing | `createTables()` creates it before resource queries run. |
| Resource query opens a `ResultSet` | Close it in `finally`. |
| User cancels the document picker | Keep the page usable and show a non-blocking "no file selected" message. |
| Document picker is unsupported in preview/device | Keep memo/text resource creation usable and show fallback guidance. |
| Resource title/content is empty | Do not write; show a validation message. |
| Remote AI disabled or unavailable | Show a remote AI configuration/service status; do not save generated summary/key points. |

### 5. Good / Base / Bad Cases

Good:

- User writes a memo in Resources -> `focusStore.addStudyResource()` -> RDB row persists -> list refreshes.
- User selects a file -> URI is saved as a `file` resource with notes -> remote AI extraction can turn the notes and URI context into task-ready insight.
- User taps "生成任务" -> a `FocusTask` is created locally and `linkedTaskId` is updated.

Base:

- No picker support: text memo and pasted-link workflows still work.
- No AI key: resource storage and manual review still work; AI extraction prompts the user to configure the remote service.

Bad:

- Showing add form, file import, AI extraction, filters, and full list all in one dense Resources view.
- Storing API keys or file binary content in source/task/report files.
- Writing resource UI state without going through `FocusStore`.

### 6. Tests Required

- Run `assembleHap` after changing resource UI, picker imports, media references, or resource data models.
- Run `git diff --check`.
- Run a secret scan for user-provided API token patterns.
- Manual device/emulator checks when available:
  - Add memo resource -> restart app -> resource persists.
  - Select a document -> save file resource -> row appears as `本地文件`.
  - Generate task from resource -> task appears in Today/Tasks and resource shows linked task.

### 7. Wrong vs Correct

#### Wrong

```typescript
this.resources.push(resource);
// Looks updated but restart loses the resource and AI/task links diverge from RDB.
```

#### Correct

```typescript
const saved: StudyResource = await focusStore.addStudyResource(title, sourceType, projectId, content);
this.selectedResourceId = saved.id;
this.syncFromStore();
```

#### Wrong

```typescript
// Treat picked files as copied local documents.
const content = 'file imported';
```

#### Correct

```typescript
const content: string = `文件：${pickedFileUri}\n备注：${note}`;
await focusStore.addStudyResource(title, 'file', projectId, content);
```

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
| Focus visual assets are missing or generation is unavailable | Keep the timer usable with existing local PNG resources and ArkUI shapes. |

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
  - Standalone `FocusAbility` opens with the selected task, uses saved focus minutes when available, and still starts/resets/completes with default settings when Preferences are unavailable.

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
- Product contract: AI must remain an enhancement layer. Tasks, projects, and Pomodoro records stay usable without API keys or AI preferences; AI cards should show explicit remote-service configuration/status messages instead of local AI suggestions.

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
focusAiCoachService.requestAdvice(...): Promise<AiCoachAdvice>
focusAiCoachService.requestResourceInsight(settings: AiCoachSettings, resource: StudyResource): Promise<ResourceInsight>
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
- `requestAdvice()` and `requestResourceInsight()` must call the remote chat-completions endpoint when enabled and keyed. When remote mode is disabled, the key is empty, the HTTP request fails, the response is non-2xx, or the response is empty/unparseable, they must return explicit status objects and must not generate local replacement advice/insight.
- AI reads `FocusStore` snapshots and returns display advice only; it must not write tasks, projects, Pomodoro records, or RDB schema.
- Hero/card visuals can be generated concept imagery. Repeated reward assets must be reusable sprites or independent icon PNGs, not one-off concept scenes.
- Paid related UI asset generation should prefer one grid spritesheet request, followed by local crop/validation into named PNG resources. Wire cropped sprites into real product states before considering the asset work complete.
- Keep generated UI micro-assets text-free: no readable text, letters, numbers, logos, watermarks, or large concept scenes. Use app text rendered by ArkUI instead of in-image labels.
- Image-generation API keys, custom endpoints, and local proxy ports are session/runtime inputs only. Use environment variables for one-off generation commands, never source files, spec files, task artifacts, reports, or scripts.

### 4. Validation & Error Matrix

| Condition | Required behavior |
| --- | --- |
| Preferences init/load/save fails | Use defaults or normalized in-memory settings; keep the app usable. |
| Remote AI disabled or missing key | Return explicit "configure remote AI" status; do not generate local advice. |
| Remote endpoint returns non-2xx | Return explicit remote-service status with the response code when available. |
| Remote response is empty or unparseable | Return explicit empty/unparseable response status. |
| User leaves API key input blank while saving | Preserve previously saved key. |
| Generated reward visual is a concept scene | Replace with spritesheet/individual icon assets before wiring to repeated UI. |
| Paid spritesheet is generated | Crop to stable resource names, validate PNGs, then reference selected assets in UI cards/states. |
| Generated UI asset contains text/logos | Reject or regenerate; do not ship text baked into reusable UI sprites. |

### 5. Good / Base / Bad Cases

Good:

- Today/Focus can show the AI card immediately after `focusStore.refresh()`, with a clear remote AI configuration prompt until the service is ready.
- The AI card updates after task mutations and Pomodoro completion/interruption.
- Review forest uses independent plant and reward icon resources for unlock states.
- A single generated UI spritesheet is cropped into `focus_ui_*` resources and reused across Today hero chips, empty states, task rows, timer status, AI settings, and Review cards.

Base:

- No API key: tasks, resources, focus, and review still work; AI cards show remote configuration guidance instead of local suggestions.
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
- On emulator/device, verify remote AI disabled mode, blank-key save behavior, successful remote response, and remote failure status when possible.

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
