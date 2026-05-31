# Thinking Flows for HarmonyOS ArkTS Focus Apps

> **Purpose**: Systematic thinking guides to catch issues before they become bugs.
>
> **Core Philosophy**: 30 minutes of thinking saves 3 hours of debugging.

This project is a HarmonyOS ArkTS app. Some deeper guide files still contain Electron examples from the original template; use them only for the general thinking pattern, and translate layer names to the ArkTS/local-first architecture below.

---

## Available Thinking Guides

| Guide | Purpose | When to Use |
| --- | --- | --- |
| [Cross-Layer Thinking](./cross-layer-thinking-guide.md) | Think through data flow across layers | Features spanning UI, service, storage, Ability, or remote AI |
| [Pre-Implementation Checklist](./pre-implementation-checklist.md) | Verify readiness before coding | Before adding constants, logic, types, or UI builders |
| [Bug Root Cause Analysis](./bug-root-cause-thinking-guide.md) | Analyze bugs to understand preventability | After fixing any non-trivial bug |
| [Code Reuse Thinking](./code-reuse-thinking-guide.md) | Identify patterns and reduce duplication | When repeated ArkUI builders/tokens/helpers appear |
| [DB Schema Change](./db-schema-change-guide.md) | Ensure schema changes are fully deployed | When modifying RDB schema or data interpretation |
| [Semantic Change Checklist](./semantic-change-checklist.md) | Ensure all code is updated when changing meaning | Status values, timestamp units, settings, enums |
| [Transaction Consistency](./transaction-consistency-guide.md) | Ensure data consistency across write paths | Multi-table writes or local-first mutations |

---

## Harmony-Specific Layer Map

Use this map when a legacy guide says "renderer", "IPC", or "main process":

```
ArkUI Pages / Builders
        |
        v
Page State and AppStorage
        |
        v
FocusStore / Preferences Services
        |
        v
FocusDatabase / RDB and Preferences
        |
        v
Ability lifecycle, ArkWeb, native notifications, optional remote AI
```

Read flow examples:

- RDB -> `FocusStore.refresh()` -> page state copy -> ArkUI builders.
- Preferences -> settings service -> `focusStore.settings` -> page state.
- Ability Want params -> AppStorage keys -> `FocusSolo`.

Write flow examples:

- ArkUI action -> `FocusStore` mutation -> RDB write -> refresh -> page state copy.
- ArkUI settings change -> Preferences service save -> normalized result -> store/page state.
- Remote AI action -> explicit remote status/advice -> no local task writes unless the user triggers a local `FocusStore` mutation.

---

## Quick Reference

Use cross-layer thinking when:

- A feature touches 3+ layers, such as ArkUI + `FocusStore` + RDB.
- Data format changes between RDB JSON strings and ArkTS arrays.
- Want/AppStorage handoff changes for `FocusAbility`.
- Runtime settings, AI settings, or notification/background behavior changes.

Use the pre-implementation checklist when:

- Adding constants or design tokens.
- Creating a new ArkUI builder or reusable style helper.
- Changing task/resource/Pomodoro status handling.
- Adding generated or cropped media resources.

Use code reuse thinking when:

- Similar ArkUI cards, chips, metrics, or image styles repeat.
- The same colors, spacing, or text formatting appear in multiple files.
- A formatter can move into `FocusFormatters.ets` or a design value into `FocusDesignTokens.ets`.

Use DB/semantic/transaction guides when:

- RDB schema, task status, Pomodoro duration, resource content, or timestamp meaning changes.
- A write touches both a task/resource row and a Pomodoro/resource insight update.

---

## Pre-Modification Rule

Before changing any value or pattern, search first:

```powershell
rg "value_to_change" entry/src/main/ets
rg "builder_or_token_name" entry/src/main/ets
```

This prevents split-brain UI behavior, duplicated constants, and missed local-first write paths.

---

## Core Principles

1. **Search Before Write** - prefer existing ArkUI builders, tokens, services, and media resources.
2. **Think Before Code** - decide which layers read/write the value before editing.
3. **Preserve Local-First** - backend and remote AI must not block tasks, Pomodoros, resources, or settings.
4. **Verify All Layers** - changes often require ArkUI, service, RDB/Preferences, and Ability checks.
5. **Capture Learnings** - update `.trellis/spec/` when a new project-specific rule appears.

---

**Language**: All documentation should be written in **English**.
