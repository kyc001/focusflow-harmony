# Design: AI Integration Completion

## Boundaries

This task touches the optional AI enhancement layer:

- `entry/src/main/ets/services/FocusAiCoachService.ets`
- AI-related builders and handlers in `entry/src/main/ets/pages/Index.ets`
- model interfaces only if required for clearer status fields

It must not change RDB schema or backend code.

## Contracts

- Preferences keyspace: `focus_ai`.
- AI settings model stays:

```typescript
interface AiCoachSettings {
  enabled: boolean;
  endpoint: string;
  model: string;
  apiKey: string;
}
```

- AI response models stay display-oriented: `AiCoachAdvice` and `ResourceInsight`.

## Fallback Flow

For task advice:

1. Generate local fallback from current tasks/projects/pomodoros/settings.
2. If remote mode is disabled or API key is empty, return local fallback.
3. If remote mode is enabled, call the normalized endpoint.
4. For non-2xx, empty, parse failure, or thrown error, return local fallback with a visible source/status.
5. For valid remote content, parse into the existing display model.

For resource insight:

1. Generate local fallback from saved resource content.
2. Apply the same remote/fallback rules.
3. Save insight through `focusStore.updateResourceInsight()` only from the UI action after the resource exists.

## Security

- No provided tokens in source, docs, task files, or generated scripts.
- Runtime key input can be written only through Preferences.
- The settings UI should keep the key input blank after load/save.

## UX

- Show source labels such as local, remote, or fallback.
- Use non-blocking messages for missing key and request failure.
- Keep manual refresh/extract buttons available; disable only during the active request.

## Rollback Points

- Revert AI UI copy/status changes without touching service behavior if build errors arise.
- Revert service parser changes separately from settings UI changes.
