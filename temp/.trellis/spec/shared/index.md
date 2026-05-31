# Shared Development Guidelines

These guidelines apply to this HarmonyOS ArkTS app unless a package-specific spec says otherwise. Older Electron-oriented files are retained only as archival references.

---

## Documentation Files

| File                                               | Description                       | When to Read           |
| -------------------------------------------------- | --------------------------------- | ---------------------- |
| [code-quality.md](./code-quality.md)               | Code quality mandatory rules      | Always                 |
| [typescript.md](./typescript.md)                   | TypeScript best practices         | Type-related decisions |
| [git-conventions.md](./git-conventions.md)         | Git commit and branch conventions | Before committing      |
| [timestamp.md](./timestamp.md)                     | Timestamp format specification    | Date/time handling     |
| [pnpm-electron-setup.md](./pnpm-electron-setup.md) | Legacy pnpm + Electron setup notes | Archive/reference only |

---

## Quick Navigation

| Task                  | File                                       |
| --------------------- | ------------------------------------------ |
| Code quality rules    | [code-quality.md](./code-quality.md)       |
| Type annotations      | [typescript.md](./typescript.md)           |
| Commit message format | [git-conventions.md](./git-conventions.md) |
| Branch naming         | [git-conventions.md](./git-conventions.md) |
| Timestamp handling    | [timestamp.md](./timestamp.md)             |

---

## Core Rules (MANDATORY)

| Rule                                 | File                                       |
| ------------------------------------ | ------------------------------------------ |
| No non-null assertions (`!`)         | [code-quality.md](./code-quality.md)       |
| Use explicit type annotations        | [typescript.md](./typescript.md)           |
| Follow commit message format         | [git-conventions.md](./git-conventions.md) |
| Use Unix milliseconds for timestamps | [timestamp.md](./timestamp.md)             |

---

## Before Every Commit

- [ ] Harmony frontend build passes when ArkTS/resources changed
- [ ] `git diff --check` passes
- [ ] No non-null assertions (`!`)
- [ ] Commit message follows format
- [ ] Tests pass (if applicable)

---

## Code Review Checklist

- [ ] Types are explicit, not `any`
- [ ] Error handling is proper
- [ ] Naming follows conventions
- [ ] No duplicate code

---

**Language**: All documentation must be written in **English**.
