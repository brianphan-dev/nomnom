# nomnom — Product Requirements Document (PRD)

> **Document Purpose:** Handoff specification for Design & Engineering covering product vision, iOS & iPhone Duo UX requirements, core user journeys, and locked backend/auth architecture for the **nomnom** MVP.  
> **Status:** MVP Architecture & Scope Locked (Nov 2026)  
> **Target Platforms:** iPhone, **iPhone Duo** (5.4" Folded Cover + 7.6" Unfolded Dual-Pane), and iPad (iOS / iPadOS 18+)

---

## 1. Product Vision & Goals

**nomnom** is a fast, calm, user-owned iOS food diary designed to make daily meal logging effortless without diet-culture bloat, ads, or data lock-in.

### Core Value Propositions
1. **Camera-First AI Meal Logging:** Snap a photo of a plate and automatically identify foods, estimate serving sizes, and calculate calories and macros — with optional detection of sauces, cooking oils, and seasonings tucked cleanly behind an expandable drawer.
2. **Zero-Friction Fallbacks:** Seamlessly switch to **Barcode Scanning** (with Nutrition Facts Label OCR if unlisted) or **Manual Search / Natural-Language Entry** whenever AI photo capture isn't ideal.
3. **True Multi-Device Sync:** Manage and view your diary seamlessly across multiple iOS devices (iPhone, iPhone Duo, iPad) backed by persistent cloud storage.
4. **Full Data Portability (In & Out):** Import existing history from **MyFitnessPal** and **Apple Health**, and export your complete meal archive (JSON, CSV, photos, and optional Obsidian Markdown) at any time.

### Design Principles
- **Speed over ceremony:** Primary meal logging should take **under 5–10 seconds** from launch to saved entry.
- **Calm, neutral tone:** No guilt-inducing red alerts, aggressive streak pressure, weight-loss funnels, or ads.
- **Transparent AI, human in control:** Never silently lock in an AI guess — surface confidence indicators and make portion/sauce adjustments effortless in 1 tap.
- **Offline-first reliability:** Logging, recent foods, and viewing history must work instantaneously offline, syncing automatically in the background.
- **Native Apple polish:** Respect Dynamic Type, WCAG AA contrast, Light & Dark modes, and native iOS haptics/gestures.

---

## 2. Supported Devices & Adaptive Layout Requirements

Design deliverables must cover **three primary viewport states** (SwiftUI adaptive size classes):

| Form Factor | Display Specs | Horizontal Size Class | UX & Layout Strategy |
| :--- | :--- | :--- | :--- |
| **Standard iPhone** | 6.1"–6.9" OLED · Dynamic Island | Compact | Clean single-column vertical flow with thumb-zone primary capture actions and bottom tab navigation. |
| **iPhone Duo — Folded** | **5.4" Cover Display** (1398 × 2034, 460 ppi) · Dynamic Island | Compact (Tight) | **One-handed quick-capture mode:** Prioritizes fast camera/barcode snapping and glanceable daily totals without unfolding. Keep tap targets >= 44pt, avoid dense multi-column grids, and collapse secondary metadata. |
| **iPhone Duo — Unfolded** | **7.6" Inner Foldable** (1878 × 2670, 430 ppi) · Under-display camera (no Dynamic Island) | Regular (Dual-Pane) | **Adaptive `NavigationSplitView` book layout:** Keep primary list/capture on the left pane and contextual detail/controls on the right pane (avoid awkward center-hinge overlap on interactive buttons). |
| **iPad** | iPadOS Split / Full | Regular | Inherits the iPhone Duo Unfolded dual-pane layout automatically. |

### Fold / Unfold Continuity Requirement
- Users will frequently **snap a meal photo folded** on the 5.4" cover display and **unfold to 7.6"** for portion review or editing. State (draft photo, AI analysis progress, unsaved edits) must transition seamlessly between compact and dual-pane layouts without losing progress.

---

## 3. Core User Journeys & Screen-by-Screen UX Requirements

### Screen 1 — Sign In & Onboarding
- **Primary Action:** Native **Sign in with Apple** button (MVP authentication provider).
- **Future Extensibility:** Leave visual/architectural breathing room in the auth stack for **Sign in with Google** (Phase 2 — hidden or clearly deferred for MVP, but auth screens and account-linking settings should anticipate multiple providers).
- **Optional Onboarding Shortcut:** Subtle secondary action *"Already tracking in MyFitnessPal? Import your history"* (or accessible immediately in Settings/Import).
- **Account Management & Deletion (App Store Mandatory — Guideline 5.1.1(v)):** Account Settings must include a clear, permanent **Delete Account** flow (with confirmation modal explaining permanent data deletion and Apple token revocation).
- **iPhone Duo Unfolded:** Split welcome screen — product value visuals on the left pane, Sign in with Apple + migration CTA on the right.

### Screen 2 — Today's Diary (Home Screen)
- **Header:** Date selector (`Today` / calendar picker) + unobtrusive **Cloud Sync Status Pill** (`Synced`, `Syncing...`, or `Offline · Queued`).
- **Daily Summary Card:** Calories logged vs. target + clean macro progress bars (**Protein**, **Carbs**, **Fat**) — calm visual hierarchy, expandable to view key micronutrients (fiber, sodium, sugar, etc.).
- **Quick Capture Bar:** Prominent primary CTA (**Snap Plate / Photo AI**) flanked by fast secondary triggers (**Scan Barcode**, **Manual Entry**).
- **Meal Timeline:** Chronological list of logged meals grouped or tagged by meal type (`Breakfast`, `Lunch`, `Dinner`, `Snack`) with photo thumbnail (when available), capture method badge (`Photo AI`, `Barcode`, `Manual`, `Imported`), total kcal, and macro summary.
- **Empty State:** Friendly, minimalist prompt inviting the first photo snap or MyFitnessPal import.
- **iPhone Duo Unfolded:** Master-detail split — Daily Summary + Meal Timeline on the left pane; tapping any meal opens its full **Meal Breakdown Inspector** live on the right pane without navigating away.

### Screen 3 — AI Plate Photo Capture (Primary Flow)
- **Mode Switcher:** Segmented control at top or bottom (`Photo AI | Barcode | Manual`) for instant switching if lighting or packaging makes another mode faster.
- **Viewfinder:** Clean full-bleed camera framing with photo library picker (`PhotosPicker`) for already-taken meal photos.
- **Optional 5-Word Context Hint:** Non-intrusive text/voice chip bar (e.g., *"chicken thighs, light oil, half rice"*) that users can ignore for 1-tap snapping or use to clarify hidden ingredients/portions.
- **Analyzing State:** Smooth ~1.5–2.5s progress state (skeleton/shimmer over captured thumbnail) while the Vision LLM analyzes the plate.
- **Offline State:** If offline when snapping, immediately save the photo locally with a `"Pending AI Analysis"` badge on Today's Diary and auto-process once back online.
- **Quota Feedback (Open Sign-Up Policy):** Gracefully display remaining daily AI photo quota only when approaching/reaching the daily cap, automatically offering Barcode and Manual entry as unlimited fallbacks.
- **iPhone Duo Folded vs. Unfolded:** Folded = ultra-clean 1-handed shutter; Unfolded = unobstructed viewfinder on the left pane, optional hints/recent meal templates on the right.

### Screen 4 — AI Review & Adjust (Signature Screen)
- **Top Header:** Editable meal title, meal type selector (`Breakfast | Lunch | Dinner | Snack`), and live-updating **Total Calories + P / C / F**.
- **Detected Items List:** Each food item displays name, estimated serving (`"1 fillet (~150g)"`), calories, and a **subtle amber "Check" badge** whenever AI confidence is below ~75–78%.
- **1-Tap Portion Multipliers:** Quick segmented pills (`0.5x`, `0.75x`, `1x`, `1.25x`, `1.5x`, `2x`) plus optional gram/unit editing that recalculate item and meal totals live.
- **Expandable "Sauces, Oils & Seasonings" Drawer:** Hidden cooking fats, sauces, dressings, and seasonings detected by AI are grouped into a collapsible section with **individual checkboxes** — keeping the default screen clean while allowing 1-tap removal if not consumed.
- **Correction Controls:** Swap an item (opens search), `+ Add missing item`, or **"Refine with text"** quick prompt (e.g., *"that's tofu, not chicken"*).
- **Save CTA:** Primary button (`Save XXX kcal to Diary`) writes an immutable nutrition snapshot.
- **iPhone Duo Unfolded:** Pinned meal photo + live totals + Sauces/Oils drawer on the **left pane**; scrollable Detected Items with portion multipliers on the **right pane** so users can visually compare the plate while adjusting portions.

### Screen 5 — Barcode Scanner + Label OCR (Fallback 1)
- **Live Scanner:** Native Apple VisionKit `DataScannerViewController` with clean framing reticle and automatic UPC-A / EAN-13 detection.
- **Product Match Sheet:** Displays product name, brand, data source attribution (`USDA` / `Open Food Facts`), serving unit chips (`1 cup 170g`, `100g`, `1 bar`), quantity stepper (`0.5` increments), and live macro recalculation.
- **Barcode Miss Fallback ("Snap Nutrition Facts Label"):** When a packaged item isn't in USDA or Open Food Facts, present a clear 1-tap prompt to photograph the package's **Nutrition Facts panel** — Vision AI extracts exact serving size & macros and caches the product locally for future scans.
- **iPhone Duo Unfolded:** Active scanner viewfinder on the left pane; matched product & serving calculator sheet docked cleanly on the right.

### Screen 6 — Manual Search & Default Calculator (Fallback 2)
- **Instant Local-First Search:** Searches local Recents, Favorites, and Custom Foods immediately (<10ms offline), followed by debounced USDA generic defaults.
- **Default Serving Calculator:** Selecting any food opens serving unit chips + quantity stepper calculating calories and macros from baseline per-100g defaults.
- **Natural-Language Fallback ("Estimate with AI"):** Freeform text input (e.g., *"1 medium bowl pho tai with hoisin"* or *"2 scrambled eggs in butter + sourdough toast"*) that parses into Screen 4 (AI Review) using default estimates.
- **iPhone Duo Unfolded:** Search results + AI text bar on the left pane; live Serving & Macro Calculator on the right.

### Screen 7 — External App Importer (MVP Migration)
- **MVP Supported Sources:**
  1. **MyFitnessPal (`.zip` or `Nutrition-Summary-*.csv`):** Native file picker parses MFP's CSV export. Design must clearly communicate that **MyFitnessPal exports roll up entries to the meal level** (`Breakfast`, `Lunch`, `Dinner`, `Snacks` totals per date) rather than individual foods.
  2. **Apple HealthKit Read:** Native permission flow to import existing historical dietary energy/macro samples directly from Apple Health without exporting files.
- **Import Wizard Flow:**
  1. Choose Source (`MyFitnessPal` or `Apple Health`)
  2. Auto-Mapped Column & Sample Row Preview (validating `Date`, `Meal`, `Calories`, `Protein`, `Carbs`, `Fat`, etc.)
  3. Duplicate-Handling Policy Selector (`Skip duplicates` [default], `Keep both`, `Replace existing date`)
  4. Import Progress & Summary Receipt (`X meals imported · Y duplicates skipped`)
- **iPhone Duo Unfolded:** Source picker & duplicate settings on the left pane; wide auto-mapped column & sample row preview table on the right.

### Screen 8 — Meal Detail, Cloud Sync & Data Portability
- **Meal Detail View:** Full macro + key micronutrient breakdown, original photo viewer, edit/delete actions (syncing edits/deletes to cloud and HealthKit).
- **Multi-Device Sync Status:** Shows connected/recently synced devices (`iPhone`, `iPhone Duo`, `iPad`), last sync timestamp, and manual "Sync Now" trigger.
- **Integrations:**
  - **Apple HealthKit Sync Toggle** (writes meals as idempotent `HKCorrelation` food records so edits/deletes never duplicate).
  - **Obsidian Daily Markdown Export** (preview & optional folder export with YAML frontmatter + macro tables).
- **One-Tap Full Portable Archive (`.zip`):** Exports `manifest.json`, `diary.json`, `meals.csv`, `meal_items.csv`, and compressed meal `photos/` (plus a matching lossless restore/import path).
- **iPhone Duo Unfolded:** Sync status & integration toggles on the left pane; live JSON / Markdown export preview on the right.

---

## 4. Locked Backend, Database & Authentication Architecture

The engineering stack is locked to prioritize **zero-SaaS ownership**, **low operating cost**, **strong privacy**, and **unified Swift development** across iOS and server.

### Architecture Decisions (ADR Summary)

| Layer | Locked Decision | Rationale & Design Implications |
| :--- | :--- | :--- |
| **Hosting** | **Self-Hosted VPS on Hetzner EU (`CX23`)** — 2 vCPU, 4 GB RAM, 40 GB NVMe, 20 TB traffic (~\$6.50–\$7/mo) | 4× the RAM of comparable US entry VPSs at ~\$7/mo. ~100ms US → EU latency is completely masked by offline-first local SQLite reads/writes on iOS. |
| **Backend Stack** | **Custom API in Server-Side Swift (`Hummingbird` / `Vapor`) + Caddy TLS** | Shares one `NomNomShared` Swift Package (`Meal`, `MealEntryItem`, `SyncBatch`, `NutritionSnapshot` `Codable` structs) across iOS and Linux server — zero client/server schema drift. Caddy provides automatic Let's Encrypt HTTPS. |
| **Database** | **PostgreSQL 17** (with daily `age`-encrypted `pg_dump` -> Cloudflare R2) | Full relational integrity, `JSONB`, `pg_trgm` fuzzy food search, multi-writer concurrency, and zero migration pain as user count grows. |
| **Photo Storage** | **Cloudflare R2** via short-lived presigned PUT/GET URLs | Permanent free tier (**10 GB storage**, **\$0 egress** ≈ 50 user-years of ~150 KB HEIC meal photos). Keeps binary media off VPS RAM/disk. |
| **Authentication** | **Sign in with Apple (MVP)** · Provider-agnostic schema ready for **Google Sign-In (Phase 2)** | Complies with **App Store Guideline 4.8** from day 1. Backend verifies Apple `identityToken` via Apple JWKS, mints ephemeral 5-min `.p8` ES256 client secrets on-the-fly (eliminating 6-month rotation outages), and revokes Apple tokens via `/auth/revoke` on in-app account deletion (**Guideline 5.1.1(v) / TN3194**). Accounts key on immutable `(provider, provider_sub)` — never on email (supports Hide My Email relays safely). |
| **Access Policy** | **Open Sign-Up + Per-User Daily AI Quota** + Apple App Attest | Allows seamless onboarding for family/friends/beta users while protecting Vision LLM API spend via per-user daily photo caps (e.g., 15–25 AI scans/day) and `DCAppAttestService` request verification. |
| **AI & Food APIs** | **Server-Side Model Router** (`gemini-3.5-flash-lite` / `claude-haiku-5-5` / `gemini-3.8-flash`) + **USDA FoodData Central** + **Open Food Facts** | Paid API tiers (zero model training on meal photos); EXIF GPS stripped on-device before upload; server performs Atwater calorie consistency validation (`4*P + 4*C + 9*F`) and caches USDA/OFF barcode hits in Postgres. |
| **Client Local Store & Sync** | **Local `GRDB` SQLite** + atomic `sync_outbox` + server-assigned monotonic `sync_seq` cursor | 100% offline-first iOS UX (<10ms launch); server `sync_seq` prevents missed meals from phone clock skew; background `URLSession` syncs HEIC photos independently to R2. |
| **MVP Importers** | **MyFitnessPal (CSV / ZIP)** + **Apple HealthKit Read** | Parsed on-device with deterministic dedupe fingerprints (`sha256(source + local_date + meal_slot + kcal + macros)`) and synced cleanly to Postgres via standard outbox. |

### Estimated Operating Cost (4-User Household Baseline)
- **Hetzner EU `CX23` (4 GB RAM):** ~\$7.00/mo
- **Cloudflare R2 (Photos + Daily Encrypted DB Backups):** \$0.00/mo (within 10 GB free tier)
- **Vision & Text LLM API (~420 meals/mo across 4 users):** ~\$0.64/mo
- **USDA FoodData Central + Open Food Facts:** \$0.00/mo
- **Total Monthly Infra + AI:** **~\$7.64/mo** (**~\$191/yr** including the \$99/yr Apple Developer Program)

---

## 5. High-Level Data Model (Reference for Design & Engineering)

- **`User`** & **`AuthIdentity`**: `user_id` (UUIDv7), `display_name` (persisted on 1st Apple sign-in), `provider` (`apple | google`), `provider_sub` (immutable unique key), `is_private_email`, encrypted provider refresh token (for Apple `/auth/revoke`).
- **`Meal`**: `id` (UUIDv7), `local_date` (`YYYY-MM-DD`), `eaten_at` (UTC), `timezone_id`, `meal_type`, `title`, `notes`, `capture_method` (`photo_ai | barcode | label_ocr | manual_db | manual_ai | imported_mfp | imported_healthkit`), `ai_status` (`none | pending | analyzed | failed`), `healthkit_correlation_uuid`, `sync_seq`, `deleted_at`.
- **`MealEntryItem` *(Immutable Logged Snapshot)***: `id`, `meal_id`, `food_item_id?`, `display_name`, `brand?`, `serving_label`, `quantity`, `gram_weight?`, `portion_multiplier`, `confidence?`, snapshot macros & micros (`calories_kcal`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g`, `sugar_g`, `saturated_fat_g`, `sodium_mg`, etc.), and `ingredients_json` (toggleable sauces, oils, and seasonings).
- **`FoodItem` & `ServingOption`**: Reusable cached USDA/OFF/custom catalog storing canonical per-100g nutrients + named serving units (`1 cup = 158g`).
- **`PhotoAsset`**: `id`, `meal_id`, `local_filename`, `sha256_hash`, `r2_object_key`, `upload_state` (`local_only | uploading | synced`).

---

## 6. MVP Milestones

1. **Phase 1 — Core Photo-First MVP:** SwiftUI iOS + iPhone Duo adaptive shell, Sign in with Apple + Swift VPS API + Postgres 17 + R2, Photo AI Capture + Review & Adjust (portion multipliers + sauces/oils drawer), Today's Diary, and TestFlight Internal distribution.
2. **Phase 2 — Fallbacks, Multi-Device Sync & Migration:** Offline `GRDB` delta sync (`sync_seq`), VisionKit Barcode Scanner + USDA/OFF lookup + Label OCR fallback, Manual Search + AI text estimator, and **MyFitnessPal CSV/ZIP + Apple HealthKit Read** importers.
3. **Phase 3 — Full Portability, HealthKit Write & Polish:** Idempotent HealthKit write sync, one-tap full ZIP Export/Restore + Obsidian daily Markdown export, in-app Account Deletion (`/auth/revoke`), WidgetKit / Action Button App Intents, and Phase 2 Google Sign-In readiness.

---

## 7. Open Questions for the Design Team

Please explore and propose visual solutions for these key UX decisions during design exploration:

1. **Launch Destination:** Should opening `nomnom` land on **Today's Diary** (with a prominent thumb-zone Camera CTA) or offer an optional user setting to launch straight into the **AI Camera**?
2. **iPhone Duo Folded (5.4") Hierarchy:** On the tighter 5.4" cover display, what is the cleanest way to present daily calories + P/C/F macros + 3 capture triggers without feeling cramped?
3. **iPhone Duo Unfolded (7.6") Right Pane on Home:** When viewing Today's Diary unfolded, should the right pane default to the **most recently logged meal's detail breakdown**, a **weekly calorie/macro trend summary**, or a toggle between both?
4. **AI Confidence & Sauce Disclosure:** How should low-confidence AI items (<75%) and the expandable **Sauces, Oils & Seasonings** drawer be styled so they feel helpful and effortless rather than clinical or noisy?
5. **Quota & Offline States:** How should the **Daily AI Quota** limit (under Open Sign-Up) and **Offline `"Pending AI Analysis"`** meal cards look so the user always knows what's happening without friction?
6. **MyFitnessPal Rollup Messaging:** On the Import Preview screen, how can we clearly and reassuringly explain MFP's meal-level rollup (`Breakfast` total row vs. individual food items) without overwhelming non-technical users?
