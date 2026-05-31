# Product Maturity and Course Report Design

## Product Direction

Visible product name: **知序**.

English subtitle: **AI Study Flow**.

The existing app remains a local-first study task and Pomodoro app. The maturity upgrade adds a fifth real workflow: **study resources/documents**. This gives the course project more than a timer/task demo: students can collect course materials, summarize them, generate actionable tasks, focus on the tasks, and review outcomes.

## Feature Scope

### App Feature Slice

Add a new Resources tab:

- local resource/document records
- resource title, excerpt/content, type, project, linked task, tags, status, timestamps
- quick add resource from pasted notes/link/text
- AI/local extraction:
  - summary
  - 3 key points
  - next task suggestion
  - estimated focus minutes
- one-click create task from a resource
- filter by project/status/type

This is intentionally text-first. It avoids file picker and binary file storage in this iteration, keeping the implementation stable for the course deadline while still satisfying "multi-document/resource" functionality.

### AI Scope

AI stays optional and local-first:

- Local extraction works without network or key.
- Remote extraction can reuse runtime AI settings.
- The app must not commit the Anthropic token or image API key.
- Existing remote OpenAI-compatible request support can stay; adding Anthropic-specific runtime provider support is optional if low risk.

If remote provider support is extended:

- `AiCoachSettings` gains a provider value such as `openai` or `anthropic`.
- OpenAI-compatible calls use `/v1/chat/completions`.
- Anthropic-compatible calls use `/v1/messages`.
- Both failures fall back to local extraction/advice.

### Report Scope

Generate report artifacts under `report/`:

- `report/course-report.md` as readable source.
- `report/course-report.typ` as Typst source for stable PDF generation.
- `report/course-report.pdf` rendered if Typst can compile it.
- Optionally `report/course-report.docx` if python-docx or Pandoc becomes available; otherwise record that PDF/source were generated.

The report must follow the teacher's structure:

1. Abstract and keywords.
2. Automatic table of contents.
3. Chapter 1: Introduction and organization.
4. Chapter 2: Tool and framework selection.
5. Chapter 3: System design with MVVM framing, database/network design, no code.
6. Chapter 4: System implementation with effects and key problems/solutions, no code.
7. Chapter 5: Summary and outlook as separate sections.

### Slides Scope

Generate Typst slides under `report/`:

- `report/defense-slides.typ`
- `report/defense-slides.pdf` if Typst can compile it

Slides should cover product positioning, requirements, architecture, AI/resource workflow, core implementation, validation, and outlook.

## Architecture

```text
ArkUI Resources Tab
  -> FocusStore resource methods
    -> FocusDatabase study_resources table
  -> FocusAiCoachService local/remote extraction
  -> existing task creation path
```

## Data Model

Add `StudyResource` model:

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

Status values:

- `0`: active
- `1`: archived

Source types:

- `note`
- `link`
- `pdf`
- `courseware`

RDB table:

```sql
study_resources(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  source_type TEXT NOT NULL,
  project_id INTEGER NOT NULL,
  linked_task_id INTEGER NOT NULL DEFAULT 0,
  content TEXT,
  summary TEXT,
  key_points_json TEXT,
  tags_json TEXT,
  status INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  review_due_at INTEGER NOT NULL DEFAULT 0
)
```

DB version should be bumped from `2` to `3`.

## UI Design

Add a fifth tab: `资料`.

Main sections:

- Resource hero: total resources, active resources, AI extraction count.
- Quick add card: title, type, project, content/excerpt.
- AI extraction card: local/remote mode, extracted summary and next task.
- Resource list: cards with status, project, summary, key points, linked task.
- Resource actions:
  - summarize locally
  - request remote AI extraction
  - create focus task
  - archive/restore

Brand copy should use `知序` in visible places. Internal class names can keep `Focus*` to avoid risky broad renames.

## Report Design

Use Typst for deterministic PDF output because `typst` is available locally. The GitHub template is a LaTeX thesis template for Nankai undergraduate theses and recommends XeLaTeX for template compilation; this project can still use the teacher-provided report requirements and local sample files while using Typst for the requested slides and a reliable course report PDF.

If a DOCX deliverable is required later, install or use `python-docx` and render-check with the doc skill.

## Risks and Rollback

- RDB schema change: keep additive table-only migration; no existing task/pomodoro schema changes.
- `Index.ets` is large: keep extraction modest and avoid broad component refactors this round.
- Remote provider syntax may differ: preserve local extraction and visible fallback messages.
- Report rendering: Typst compile may need font fallback adjustments on Windows.
- Generated assets: only create more images if existing assets cannot cover the new Resources workflow.

