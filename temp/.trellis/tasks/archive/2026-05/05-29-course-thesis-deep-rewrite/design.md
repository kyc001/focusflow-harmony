# Design: Course Thesis Deep Rewrite

## Scope and Boundaries

This task is documentation-focused. The primary editable surface is the LaTeX report under `report/nku-thesis-template-2020/`. Project source files under `entry/` and `focus-server/` are evidence sources, not implementation targets.

The rewrite should preserve the existing thesis template and chapter structure unless compilation or readability demands a small structural adjustment.

## Source Evidence Strategy

Use repository files as the ground truth:

- `entry/src/main/ets/models/FocusModels.ets` for domain entities, statuses, and data contracts.
- `entry/src/main/ets/services/FocusDatabase.ets` for RDB schema, migrations, persistence, and ResultSet handling.
- `entry/src/main/ets/services/FocusStore.ets` for local-first state flow and computed statistics.
- `entry/src/main/ets/services/FocusAiCoachService.ets` for local/remote AI behavior and fallback boundaries.
- `entry/src/main/ets/services/FocusNativeServices.ets` for notifications and background task protection.
- `entry/src/main/ets/pages/Index.ets` and `FocusSolo.ets` for ArkUI page implementation.
- `entry/src/main/ets/focusability/FocusAbility.ets`, `entryability/EntryAbility.ets`, and extension ability files for lifecycle discussion.
- `entry/src/main/resources/rawfile/charts/index.html` for ArkWeb review chart implementation.
- `focus-server/src/main/java/` and `focus-server/src/main/resources/` for backend APIs, persistence, and sync design.
- Existing report references and sample thesis files for formatting expectations.

## Report Architecture

The report should read as a coherent thesis-style engineering paper:

- Chapter 1: Motivation, problem statement, research goal, contributions.
- Chapter 2: Related work and technical background.
- Chapter 3: Requirements analysis with functional and non-functional requirements.
- Chapter 4: System design with architecture, data model, AI design, backend boundary, and local-first principles.
- Chapter 5: Implementation with module-level details and key technical problems.
- Chapter 6: Testing and verification with realistic manual/build checks.
- Chapter 7: Conclusion, innovations, limitations, and future work.

## Accuracy Rules

- Claims must map to repository evidence or be phrased as design intent / future work.
- Optional backend sync must be described as optional if the client UI does not fully productize sync.
- AI remote capability must be described as enhancement over local rules, not a hard dependency.
- Any build/test result should only be reported after rerunning or clearly marked as previous evidence.
- Keep API keys and private local paths out of the final prose unless the path is already part of repo-local documentation and useful for reproduction.

## LaTeX Considerations

- Preserve UTF-8 Chinese text.
- Keep tables within page width using `tabularx` or narrower columns.
- Prefer focused tables/algorithms that explain real system behavior.
- Use existing bibliography style and update `nkthesis.bib` only when needed.
- Regenerate PDF using the template's existing build method when possible.

## Rollback

Because this task edits report artifacts, rollback can be done file-by-file using git diff. Avoid touching unrelated app source files unless explicitly required.
