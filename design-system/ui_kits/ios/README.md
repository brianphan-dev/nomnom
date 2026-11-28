# nomnom iPhone UI kit

Interactive click-through of the iPhone app at 402 × 874 pt. Open `index.html`.

Flow: Sign in → Today → capture dock → Photo AI (shutter → analysing → Review & adjust → Save) or Barcode (auto-match → serving sheet) or Manual (search → serving sheet, or Estimate with AI → Review). Tap a meal for its detail. The gear opens Settings (sync, integrations, import wizard, delete account).

Stage controls above the device: Light/Dark, Online/Offline (offline captures become "Pending AI analysis" and resolve when you go back online), Filled/Empty diary, Restart.

Files
- `index.html`: app shell and navigation state
- `data.js`: sample content (`window.NN_DATA`)
- `kit.css`: screen-level layout only; all component styling comes from the design system
- `SignInScreen.jsx`, `TodayScreen.jsx`, `CaptureScreen.jsx`, `ServingSheet.jsx`, `ReviewScreen.jsx`, `MealDetailScreen.jsx`, `SettingsScreen.jsx`, `ImportScreen.jsx`
- `ios-frame.jsx`: device bezel

Not built: date picker, item swap search, Refine with text input, Nutrition Facts label capture, Obsidian export preview, archive export. Their entry points are present but inert.
