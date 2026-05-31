# Frontend Development Guidelines

This repository is a HarmonyOS ArkTS app. The frontend implementation path is ArkUI + Ability lifecycle + local-first services, not Electron/React.

## Project-Specific Must Read

| File | Description | Priority |
| --- | --- | --- |
| [harmony-focus-local-first.md](./harmony-focus-local-first.md) | ArkTS, RDB, FocusStore, FocusAbility, ArkWeb, runtime settings, resources, AI, and visual asset contracts | **Must Read** |
| ../shared/[code-quality.md](../shared/code-quality.md) | Mandatory quality rules shared across layers | **Must Read** |
| ../shared/[typescript.md](../shared/typescript.md) | ArkTS/TypeScript typing expectations | Reference |

## Current Tech Stack

- Platform: HarmonyOS Stage model
- UI: ArkUI declarative components in `entry/src/main/ets/pages/`
- Language: ArkTS / TypeScript-style syntax
- Local data: RDB through `FocusDatabase`, surfaced to pages through `FocusStore`
- Runtime preferences: Preferences services such as `focusSettingsService` and `focusAiCoachService`
- Visual assets: PNG resources under `entry/src/main/resources/base/media/`

## Pre-Development Checklist

- Read [harmony-focus-local-first.md](./harmony-focus-local-first.md) before changing Today, Focus, Review, Resources, settings, AI, or Ability handoff behavior.
- Search for existing page builders, design tokens, image resources, and store mutations before adding new components or constants.
- Keep UI mutations local-first: write through `FocusStore` or the relevant Preferences service, refresh/copy state back, and never require the backend for core flows.
- Use ArkUI alpha colors in `#AARRGGBB` form. Do not add web-style `#RRGGBBAA` alpha colors.
- Prefer semantic existing media resources over generating new images. If generating assets, crop/save final PNGs under `entry/src/main/resources/base/media/` and wire them by semantic resource name.
- Treat any API key or proxy endpoint provided during a session as runtime-only. Do not write secrets into source, docs, task files, scripts, or generated assets.

## Quality Check

- Run the Harmony frontend build after ArkUI, media, model, or service changes:

```powershell
$env:JAVA_HOME='D:\Tools\java\jdk-21'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:OHOS_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony'
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry assembleHap
```

- Run `git diff --check`.
- Run a secret scan before reporting completion:

```powershell
rg "sk-" .
```

## Legacy Notes

Older Electron/React spec files in this folder are archival generic references only. Do not use them as the primary implementation guide for this project, and do not follow Electron IPC, React hook, Vite, or CSS-module instructions when editing ArkTS code.

**Language**: All documentation should be written in English.
