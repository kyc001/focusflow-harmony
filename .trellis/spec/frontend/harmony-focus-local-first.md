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

### 5. Good / Base / Bad Cases

Good:

- Quick add calls `focusStore.addTask()`, writes RDB, calls `refresh()`, and updates `Index` state with `syncFromStore()`.
- Completing a Pomodoro records a row in `pomodoros` and increments the linked task's `pomodoro_count`.
- `FocusSolo` receives `taskId` and writes completion through `focusStore.recordPomodoro()`.

Base:

- Backend is not running; local account, guest mode, tasks, focus, and review still work.
- ArkWeb cannot be previewed; native review stats still show meaningful data.

Bad:

- Mutating `focusStore.tasks` directly from UI without RDB write.
- Computing review stats from `SeedData.ets` after startup.
- Parsing Want only in `onCreate`, causing singleton hot-start task changes to be ignored.
- Using `#RRGGBBAA` alpha colors in ArkUI.

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
