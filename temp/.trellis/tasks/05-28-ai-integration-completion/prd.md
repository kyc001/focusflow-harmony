# AI Integration Completion

## Goal

Complete the app's remote AI learning-assistant integration so it is useful in demos, clear to users, and explicit when the remote service is not configured or does not return a usable response.

## Confirmed Facts

- `FocusAiCoachService.ets` stores AI settings in Preferences under `focus_ai`.
- The service uses runtime AI settings from Preferences and calls a remote chat-completions compatible endpoint for task advice and resource insight.
- `Index.ets` has AI settings UI state, manual refresh, model list fetching, resource extraction, and user-facing AI status messages.
- The latest user requirement explicitly rejects local AI suggestions and offline/no-network fallback behavior.
- The current working tree already includes uncommitted AI service changes; implementation must inspect and preserve intentional user edits.

## Requirements

- Make AI runtime settings coherent:
  - endpoint/model/API key are user-provided at runtime;
  - blank key save should preserve an existing saved key;
  - the saved key should not be echoed into visible text input.
- Make remote request behavior robust:
  - normalize endpoint to a chat-completions URL;
  - return explicit remote AI status objects for disabled/no-key/non-2xx/empty/unparseable/request-failure cases;
  - keep timeout reasonable for mobile demo use.
- Make user-facing status clear:
  - successful remote AI vs remote AI not ready/failed should be visible;
  - resource extraction should indicate selected resource and result source;
  - missing key should guide the user to settings without breaking the flow.
- Keep AI read-only with respect to core data except the explicit resource-insight update and "create task from resource" user action through `FocusStore`.

## Acceptance Criteria

- [ ] AI settings UI never displays a saved API key.
- [ ] Remote disabled or empty key returns an explicit "configure remote AI" status, without local advice/insight.
- [ ] Remote request failure returns an explicit remote-service status, without local advice/insight.
- [ ] Resource extraction saves summary/key points only after the resource exists locally.
- [ ] No API key or bearer token pattern is found by the secret scan.
- [ ] Frontend HAP build is run after implementation, or any environment blocker is recorded.

## Out of Scope

- Building a proprietary AI proxy service.
- Persisting API keys outside Preferences.
- Making AI required for startup, task creation, focus, or review.
