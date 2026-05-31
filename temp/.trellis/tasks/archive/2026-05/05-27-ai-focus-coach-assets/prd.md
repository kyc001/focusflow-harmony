# AI Focus Coach and Visual Asset Iteration

## Goal

Deepen Focus from a local-first Pomodoro/task tracker into a local-first learning assistant with optional AI coaching and generated product visuals.

The core app must remain usable offline. AI features are an enhancement layer: local rule-based coaching should always work, while remote model calls should be available only when the user configures an API endpoint and key.

## Requirements

- Add an AI Focus Coach surface that can read the current local task, Pomodoro history, completion/interruption stats, and project context.
- Provide useful offline coaching when no API key is configured:
  - recommend the next task
  - estimate a practical focus block
  - summarize recent interruption risks
  - propose one concrete next step
- Add optional remote model support through user-provided endpoint/key settings.
- Keep secrets out of the repository; no API key may be committed into source files or documentation.
- Preserve the local-first product contract: RDB remains the source of truth for tasks, projects, and Pomodoro records.
- Generate project visual assets with the provided image model API and store final assets in the workspace.
- Use generated visuals in the app where they improve the product experience without replacing core UI clarity.
- Update handover/product documentation to describe the AI enhancement and generated assets.

## Acceptance Criteria

- [ ] The app exposes an AI Coach card/panel in the main experience.
- [ ] Offline AI coaching works without network configuration and uses current local `FocusStore` data.
- [ ] Remote AI coaching can be enabled by entering endpoint and API key at runtime.
- [ ] Remote AI failures degrade gracefully to offline coaching with a visible status message.
- [ ] No committed file contains the provided API key.
- [ ] At least one generated visual asset is saved under project resources and referenced by the app.
- [ ] Image generation prompts are recorded for handover/reproducibility.
- [ ] Frontend HAP build is attempted and the result is recorded.

## Notes

- Relevant specs:
  - `.trellis/spec/frontend/harmony-focus-local-first.md`
  - `.trellis/spec/shared/code-quality.md`
  - `.trellis/spec/guides/cross-layer-thinking-guide.md`
