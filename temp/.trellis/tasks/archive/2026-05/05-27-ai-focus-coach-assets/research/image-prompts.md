# Image Generation Prompts

The user provided an OpenAI-compatible `gpt-image-2` API. The API key is intentionally not recorded here.

Validated image bases:

- `https://sin.ioll.pp.ua`: preferred first route for future image generation. It generated the successful forest badge request earlier and the final UI micro-asset spritesheet. A later non-billed `/v1/models` probe with a normal `User-Agent` succeeded 5/5.
- `https://eo.ioll.pp.ua`: reliable backup route. A non-billed `/v1/models` probe succeeded 5/5 and was lower latency in that test; use it when `sin` is blocked/unstable or when a long return-origin timeout is useful.

Cost note: image requests have a fixed cost per request. For related reusable assets, prefer one spritesheet prompt and local cropping over many individual calls. If a request fails before completion, do not loop retries without explicit user approval.

Request note: Cloudflare routes may reject bare Python default request fingerprints. Use a normal `User-Agent` header for probes and generation requests.

## Planned Assets

### focus-ai-hero.png

Use case: productivity-visual  
Asset type: HarmonyOS app login and today hero visual  
Primary request: a calm premium study desk scene for a local-first focus app with subtle AI assistance  
Scene/backdrop: evening desk with phone-sized UI surfaces, notebook, timer, and soft lamp light  
Subject: focused study workflow, local data, Pomodoro planning  
Style/medium: polished 3D editorial product illustration, mature mobile app aesthetic  
Composition/framing: landscape hero with clean negative space, no text  
Lighting/mood: calm, warm lamp plus cool screen light, focused and trustworthy  
Color palette: balanced deep ink, warm amber, fresh green, restrained blue accents  
Constraints: no readable text, no logos, no watermarks, no brand marks

### focus-coach-orbit.png

Use case: productivity-visual  
Asset type: AI Coach card illustration  
Primary request: compact abstract visual of an AI study coach organizing tasks into a clear focus path  
Scene/backdrop: floating task chips, small timer rings, and a soft central guidance glow  
Style/medium: clean 3D app illustration, object-focused, not cartoonish  
Composition/framing: square composition, centered object, generous padding, no text  
Lighting/mood: precise, calm, helpful  
Color palette: white surface, ink accents, teal, amber, blue, small red alert accent  
Constraints: no readable text, no logos, no watermark

## Final Asset Strategy

### Generated concept visuals

- `entry/src/main/resources/base/media/focus_ai_hero.png`
- `entry/src/main/resources/base/media/focus_coach_orbit.png`

These are suitable for hero/card visuals where a polished scene helps the product feel richer.

### Generated UI micro-asset sprites

`https://sin.ioll.pp.ua` generated one paid 4x4 spritesheet request successfully in about 88 seconds:

- `entry/src/main/resources/base/media/focus_ui_spritesheet.png`

The spritesheet was then cropped locally into semantic 256x256 PNG resources:

- `focus_ui_empty_inbox.png`
- `focus_ui_quick_add.png`
- `focus_ui_next_marker.png`
- `focus_ui_priority_flag.png`
- `focus_ui_ai_orb.png`
- `focus_ui_local_cube.png`
- `focus_ui_remote_cloud.png`
- `focus_ui_timer_token.png`
- `focus_ui_pause_resume.png`
- `focus_ui_notification_bell.png`
- `focus_ui_completion_medal.png`
- `focus_ui_risk_shield.png`
- `focus_ui_review_bars.png`
- `focus_ui_heatmap_grid.png`
- `focus_ui_settings_sliders.png`
- `focus_ui_sync_bridge.png`

These assets are wired into Today hero chips, quick add, next-focus card, AI Coach status, task rows, empty states, timer status, AI settings, and Review KPI/chart cards.

Prompt used:

```text
Use case: game-asset-spritesheet
Asset type: reusable mobile UI micro-asset spritesheet for a HarmonyOS Focus/Pomodoro AI coach app
Primary request: create one clean 4 columns by 4 rows sprite sheet of separate, reusable UI icon assets. These are production app sprites, not a concept illustration.
Grid content, left to right, top to bottom:
1. quiet empty task inbox tray with one soft check tile
2. quick-add pencil token beside a small rounded task chip
3. selected next-task compass marker on a simple path
4. priority flag token with layered colored tabs
5. AI coach spark orb with tiny orbiting task chips, no letters
6. local-first database cube with small lock/check detail, no text
7. optional remote AI cloud with orbit ring, clearly secondary
8. Pomodoro focus timer token, no numbers
9. pause/resume control token using simple geometric bars/triangle, no letters
10. notification bell with a calm reminder ring
11. completion medal/check leaf reward
12. interruption risk shield with small alert dot, no exclamation mark text
13. weekly review bar chart tile with abstract bars only
14. heatmap progress grid tile with rounded squares
15. settings sliders tile with three small knobs
16. offline sync bridge tile: phone and small cloud separated by dotted path, no text
Style/medium: simplified premium 3D clay/plastic mobile app sprites, clean silhouettes, cohesive proportions, soft bevels, crisp edges, not photoreal, not cartoonish, no large environment.
Composition/framing: exact 4x4 grid, every asset centered in its own equal square cell, consistent scale, generous padding inside each cell, no item crosses cell boundaries.
Backdrop: perfectly flat very light warm gray background with faint thin separators between cells so cropping is easy.
Color palette: balanced deep ink, fresh green, teal, amber, restrained blue, small coral risk accent; avoid one-note purple or dark-blue dominance.
Constraints: no readable text, no logos, no watermark, no letters, no numbers, no humanoid character, no animals, no desk scene, no dense tiny details, no shadows crossing cell borders.
```

### Reusable forest sprites

The first generated forest badge looked like a concept illustration, not a reusable app/game asset. The final app therefore uses independent sprite-style PNG assets:

- `focus_forest_spritesheet.png`
- `focus_plant_seed.png`
- `focus_plant_seedling.png`
- `focus_plant_ginkgo.png`
- `focus_plant_pine.png`
- `focus_plant_bloom.png`
- `focus_plant_maple.png`
- `focus_plant_forest.png`
- `focus_reward_timer_token.png`
- `focus_reward_water.png`
- `focus_reward_stone_path.png`
- `focus_reward_compost.png`
- `focus_reward_locked_seed.png`

For future paid generation, use a single spritesheet prompt:

```text
Use case: game-asset-spritesheet
Asset type: reusable mobile app forest reward sprite sheet for a Focus/Pomodoro app
Primary request: create one clean 4 columns by 3 rows sprite sheet of separate forest growth reward icons, designed to be cropped into individual square PNG assets.
Grid content, left to right, top to bottom:
1. tiny seed in soil with one soft green sprout
2. two-leaf seedling in a small rounded soil mound
3. young ginkgo sapling with fan-shaped yellow-green leaves
4. compact pine sapling with simple triangular needle layers
5. small blue-violet flowering study tree, like jacaranda, rounded canopy
6. red maple sapling with three clean maple leaves
7. mature mini knowledge forest cluster with three simplified trees
8. golden Pomodoro timer token, icon-like, no numbers
9. blue water/progress droplet tile for streak nourishment
10. gray stepping stone path tile for daily progress
11. small compost/review corner with leaves, friendly and clean, no trash
12. locked dormant seed pod in a subtle frosted capsule
Style/medium: simplified premium 3D game asset icons, cohesive mobile UI sprite style, clean silhouettes, rounded clay/plastic forms, not a concept illustration.
Composition/framing: exact 4x3 grid, every item centered in its own equal square cell, consistent scale, generous padding inside each cell, no item crosses cell boundaries.
Backdrop: perfectly flat very light warm gray background with faint thin separators between cells so cropping is easy.
Constraints: no readable text, no logos, no watermark, no letters, no numbers, no humanoid character, no animals, no photoreal scene, no desk, no large background environment, no dense tiny details.
```

Implementation note: the checked-in forest sprites are local transparent PNGs generated with Pillow after the paid spritesheet request failed during SSL negotiation. They are deterministic, cheap to regenerate, and already wired into `ForestCard`.
