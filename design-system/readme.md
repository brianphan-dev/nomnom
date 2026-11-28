# nomnom Design System

nomnom is a fast, calm, user-owned iOS food diary. You snap a photo of a plate, the app identifies the foods and estimates calories and macros, you check the numbers and save. Barcode scanning and manual search are always-available fallbacks. The diary works offline, syncs across iPhone, iPhone Duo (foldable) and iPad, imports from MyFitnessPal and Apple Health, and exports everything at any time. No ads, no streak pressure, no diet-culture tone.

## Sources

- **GitHub:** https://github.com/brianphan-dev/nomnom (branch `main`). At the time of writing the repo contains only `README.md`, a product requirements document. There is no source code, no design file, no logo and no brand guideline.
- Everything visual in this system (colour, type, shape, components, screens) is therefore a **proposal** derived from the PRD's design principles, not a recreation of an existing product. Explore the repository as it grows to keep this system grounded in the real app.

## Products

One product, three layouts:

| Surface | Kit | Notes |
| --- | --- | --- |
| iPhone (compact) | `ui_kits/ios/` | Single column, thumb-zone capture dock |
| iPhone Duo folded 5.4" (compact, tight) | `ui_kits/duo/` | Condensed summary, compact dock |
| iPhone Duo unfolded 7.6" / iPad (regular) | `ui_kits/duo/` | Two panes either side of the hinge |

## UX decisions (where this system departs from or resolves the PRD)

1. **No tab bar.** The MVP has one destination (Today) plus Settings. The bottom of the screen belongs to the `CaptureDock`: a persimmon shutter flanked by Barcode and Manual. Settings is a header button.
2. **Launch destination: Today**, with the shutter one tap away. "Open to camera" is an opt-in switch in Settings.
3. **Newest meal first** in the timeline, so the meal you just saved is under your eye.
4. **Portion multipliers are per-row and collapsed.** Each detected item shows a small `1×` pill; tapping the row reveals the six multiplier pills plus Swap and Remove. The first low-confidence row opens by default. Six pills under every row was too noisy.
5. **AI confidence is one word.** Items under ~76% get a honey "Check" badge. No percentages.
6. **Sauces, oils & seasonings** is a collapsed row showing count and added kcal (`3 · +122`). Expanded, each extra is a checkbox; unchecking strikes it through and updates the Save button total.
7. **The Save button carries the live total** ("Save 697 kcal to diary").
8. **Quota** appears only at 3 scans or fewer, as a quiet pill above the shutter. **Offline** captures save immediately as a "Pending AI analysis" row with a dashed thumbnail and are analysed when the connection returns.
9. **Duo unfolded Today:** the right pane shows the week trend until a meal is selected, then becomes that meal's inspector. Closing the inspector returns to the trend.
10. **Duo folded:** compact summary (calories, one-line macros) and a compact dock. No secondary metadata.
11. **MyFitnessPal rollup** is explained with one info banner and a four-row sample table on the import preview.
12. **Going over target is not an error.** The summary says "140 over" in the same neutral colour. Nothing turns red.

## CONTENT FUNDAMENTALS

- **Voice:** plain, calm, matter-of-fact. State the fact, then the next step. Never scold, cheer or sell.
- **Person:** second person ("your diary", "your plate"). The app is "we" only when it explains something it will do ("We'll analyse this photo as soon as you're back online").
- **Casing:** sentence case everywhere, including buttons and titles. The product name is always lowercase: `nomnom`. Capture modes are proper nouns: Photo AI, Barcode, Manual.
- **Length:** buttons are 1 to 4 words plus a number. Banners are a short title and one sentence.
- **Numbers:** always digits, always Geist Mono, thousands separators (`1,118`), units lowercase with a space (`612 kcal`, `14 g`) except inside tight macro lines (`62/120g`, `P38 C58 F24`). Multipliers use the multiplication sign: `1.5×`.
- **Punctuation:** middle dot `·` separates metadata (`Lunch · 12:40`). Ellipsis only for in-progress states (`Syncing…`). No exclamation marks.
- **No emoji.** No streak language, no "goals crushed", no weight-loss framing, no guilt.
- **AI honesty:** say "estimate" and "Check", never "detected with 71% confidence". The person is always the one who saves.

Examples

| Situation | Copy |
| --- | --- |
| Primary save | Save 697 kcal to diary |
| Over target | 140 over |
| Quota | 3 photo scans left today / Barcode and manual entry are always unlimited. |
| Offline capture | Offline. Your photo is saved now and analysed later. |
| Pending row | Pending AI analysis |
| Empty diary | Nothing logged yet / Snap your first plate with the camera button below, or bring your history over from MyFitnessPal. |
| Delete account | Delete your account? / This permanently deletes your diary, photos and synced data on every device, and revokes Sign in with Apple. |
| Sign-in hero | A food diary you can *keep up with.* |

## VISUAL FOUNDATIONS

**Overall feel.** Cool, quiet stone surfaces; one warm persimmon accent; an editorial serif for names and titles; monospaced numerals. Round shapes throughout.

**Colour** (`tokens/colors.css`)
- *Stone* (cool neutral, hue 255) carries almost everything. App background is `--stone-100`, cards are white, ink is `--stone-950`.
- *Persimmon* is the single brand accent. It is reserved for the shutter, the one Save/Add action per screen, the calorie progress bar, and changed-value highlights. Text on persimmon is ink, never white.
- *Macros*: protein is blueberry, carbs matcha, fat plum. Each has a soft tint, a fill and an AA text step.
- *Status*: honey is the only warning hue and only means "Check this AI estimate". Matcha marks success. Beet appears only on destructive actions (Delete). There is no red alert state.
- Fills (`--fill-1`, `--fill-2`) are translucent ink so they work on both the app background and cards.
- Light and dark themes: set `data-theme="dark"` on any ancestor.

**Type** (`tokens/typography.css`)
- *Instrument Serif* for display, large titles, meal titles and dialog titles. Regular weight only; italic for a single emphasised phrase.
- *Geist* for all UI text, on the iOS Dynamic Type "Large" ramp (17/22 body).
- *Geist Mono* for every numeral: calories, grams, multipliers, table cells, plus small uppercase overlines.

**Spacing and layout** (`tokens/spacing.css`)
- 4pt grid. Screen margin 20. Card padding 16 or 20. Gaps between cards 16.
- Minimum tap target 44. Control heights 32 / 44 / 56. Shutter 72.
- Fixed elements: the capture dock floats 26pt above the bottom edge on Today; Save/Add buttons pin to the bottom of review and sheet flows. On Duo unfolded nothing interactive sits within 20pt of the hinge.

**Shape.** Controls are pills. Thumbnails 16, rows and banners 20, cards 28, sheets 36. Nested radii step down by the padding (card 28 with 8 padding holds rows at 20).

**Cards.** White, 28 radius, no border, no shadow, on the stone background. Variants: sunken (tinted fill), outline (hairline only, used for empty states), accent (persimmon tint).

**Borders.** Hairlines (`--border-hairline`) only as inset row separators and outline cards. Unselected chips and checkboxes use `--border-strong`.

**Elevation.** Flat by default. Only three things cast shadows: switch/segment knobs (`--shadow-knob`), floating chrome such as the capture dock and dialogs (`--shadow-float`), and bottom sheets (`--shadow-sheet`). No inner shadows.

**Transparency and blur.** Used only for chrome that floats over content: the capture dock (`--surface-chrome` + `--blur-chrome`) and glass controls over the camera viewfinder (`--glass-fill`). Captions over the camera sit in dark translucent capsules rather than on protection gradients.

**Backgrounds.** Solid colour only. No gradients, patterns, textures or illustrations.

**Imagery.** Meal photos taken by the user are the only imagery, shown un-filtered with rounded corners. Until real photos exist, `MealPhoto` renders a striped placeholder with a mono caption.

**Motion.** Short and quiet. `--ease-out` (iOS-style decelerate) for sheets and progress bars at 420ms; `--ease-standard` at 120 to 220ms for presses and fades. Screens fade up 8pt. The analysing state is a shimmer. No bounces, no confetti, no celebratory animation. `prefers-reduced-motion` is respected.

**Interaction states.**
- Press: scale to 0.97 (0.92 to 0.94 for circular buttons). On device this pairs with a light haptic.
- Hover (pointer devices): ink buttons lighten one step, accent lightens one step, tinted and ghost controls gain `--fill-1`/`--fill-2`.
- Focus: 2px persimmon outline, 2px offset.
- Selected: chips invert to ink; segments lift onto a white knob; meal rows gain `--fill-1`.
- Disabled: 38% opacity.

## ICONOGRAPHY

- The native app will use **SF Symbols**. They cannot be shipped on the web, so this system substitutes the **Phosphor** icon font (https://phosphoricons.com), loaded from CDN in `tokens/fonts.css`. **This is a substitution**; map each name to the nearest SF Symbol in the Swift build.
- Three weights: `regular` for general UI, `bold` inside buttons, badges and small controls, `fill` for the shutter, the Apple logo and selected states.
- Use the `Icon` component (`<Icon name="camera" weight="fill" />`) or the raw classes (`<i class="ph ph-camera">`).
- Core vocabulary: `camera` (snap), `barcode`, `pencil-simple` (manual), `sparkle` (anything AI), `question` (Check), `clock` (pending), `cloud-check` / `arrows-clockwise` / `cloud-slash` (sync), `download-simple` (import), `export`, `heartbeat` (Apple Health), `trash`.
- No emoji. No unicode glyphs as icons, apart from typographic `×` and `·` in text. No custom SVG icons.
- **App icon:** a persimmon seen from above on deep green (`assets/app-icon.svg`, dark variant `assets/app-icon-dark.svg`; card `guidelines/brand-app-icon.html`). Chosen from `explorations/App Icons.html` (option 2a). The master is a full-bleed square; apply the platform corner mask. The deep green ground (#1f4127) is used only by the icon and is not a UI token.
- **Wordmark:** there is no separate logo. The name is set in Instrument Serif, lowercase, as plain type (`guidelines/brand-wordmark.html`), optionally with the app icon to its left.

## Components

`components/core/`: Icon, Button, IconButton, Badge, Chip, Card
`components/forms/`: TextField, Checkbox, Switch, Stepper, SegmentedControl
`components/feedback/`: SyncPill, ProgressBar, Banner, Dialog, Sheet
`components/navigation/`: NavBar, ListRow, CaptureDock
`components/nutrition/`: MealPhoto, MacroLine, MacroBar, DailySummary, MealRow, FoodItemRow

Each has `Name.jsx`, `Name.d.ts` and `Name.prompt.md`. Styling lives in the group's CSS file (`core.css`, `forms.css`, …), imported by `styles.css`, using `nn-` prefixed classes and tokens only.

**Intentional additions.** The source defines no component inventory, so this is a from-scratch set sized to the eight PRD screens. `Icon` exists only to wrap the Phosphor font. `Dialog` and `Sheet` position absolutely inside the nearest positioned ancestor so they work inside device frames.

## Index

- `styles.css`: the one file consumers link. Imports everything below.
- `tokens/`: `fonts.css` (Google Fonts + Phosphor imports), `colors.css`, `typography.css`, `spacing.css` (spacing, radii, elevation, motion), `base.css` (body defaults, `.nn-num`, `.nn-overline`, keyframes).
- `components/`: 25 components in five groups, one `*.card.html` per group.
- `assets/`: `app-icon.svg`, `app-icon-dark.svg`.
- `guidelines/`: 19 foundation specimen cards (Colors, Type, Spacing, Motion, Brand).
- `explorations/`: `App Icons.html`, the icon option canvas (rounds 1 and 2).
- `ui_kits/ios/`: interactive iPhone click-through (`index.html`), screens as JSX.
- `ui_kits/duo/`: iPhone Duo folded and unfolded layouts.
- `thumbnail.html`: project tile.
- `github.md`: source repo association and screen map.
- `SKILL.md`: agent skill entry point.

## Caveats

- Fonts are loaded from Google Fonts by `@import`; no font binaries are in the project. Instrument Serif, Geist and Geist Mono are proposals, not an existing brand choice.
- Phosphor stands in for SF Symbols.
- The app icon is a flat vector sketch made in this project, not final artwork. No photography or illustrations were provided; photo slots are placeholders.
- "iPhone Duo" dimensions are derived from the PRD's pixel specs (466 × 678 pt folded, 890 × 626 pt unfolded).
