# HarmonyOS ArkTS Focus App Guidelines

Project-specific implementation knowledge for this repository lives here. This codebase is a HarmonyOS Stage-model ArkTS app, not an Electron/React app.

## Primary Specs

### [Frontend](./frontend/index.md)

ArkUI, Ability lifecycle, FocusStore, local-first RDB/Preferences, runtime settings, AI, resources, and visual asset contracts.

- [Harmony Focus Local-First](./frontend/harmony-focus-local-first.md)
- Legacy frontend files are archival references only unless `frontend/index.md` explicitly points to them.

### [Shared](./shared/index.md)

Cross-cutting rules that still apply to ArkTS work:

- [Code Quality](./shared/code-quality.md)
- [ArkTS / TypeScript Conventions](./shared/typescript.md)
- [Git Conventions](./shared/git-conventions.md)
- [Timestamp Handling](./shared/timestamp.md)

### [Guides](./guides/index.md)

Thinking guides for cross-layer local-first changes, reuse checks, schema changes, semantic changes, and debugging retrospectives.

## Legacy Specs

Some backend, big-question, and older frontend files were imported from an Electron template. Treat them as historical references only unless a current Harmony spec links to a specific rule and says it applies.

Do not use Electron IPC, React hook, Vite, Tailwind, or electron-builder instructions when editing `entry/src/main/ets/**`.

## Current Tech Stack

- Platform: HarmonyOS Stage model
- UI: ArkUI `.ets` pages/builders
- Data: RDB via `FocusDatabase`, UI-facing facade via `FocusStore`
- Preferences: runtime settings and AI settings services
- Native surfaces: `FocusAbility`, service card, notifications/background best effort, ArkWeb review page
- Build: DevEco/Hvigor `assembleHap`

## Usage

1. Start with `frontend/index.md` and `frontend/harmony-focus-local-first.md` for app work.
2. Use `guides/index.md` to choose thinking checklists before broad changes.
3. Update specs when implementation uncovers a project-specific contract, gotcha, or convention.
