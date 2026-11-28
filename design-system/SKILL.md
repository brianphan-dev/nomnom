---
name: nomnom-design
description: Use this skill to generate well-branded interfaces and assets for nomnom, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for protoyping.
user-invocable: true
---

Read the readme.md file within this skill, and explore the other available files.
If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.
If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

Quick orientation:
- Link `styles.css` for tokens, fonts, icons and component classes. Set `data-theme="dark"` on an ancestor for dark mode.
- Components live in `components/<group>/` with a `.prompt.md` beside each one.
- `ui_kits/ios/` is the iPhone app click-through; `ui_kits/duo/` shows the foldable layouts. Reuse the screen JSX as a starting point.
- nomnom is an iOS app. The native build uses SF Symbols and SwiftUI; this system's Phosphor icons and CSS values are the reference to translate from.
- Rules that matter most: one persimmon action per screen, ink text on persimmon, numerals in Geist Mono, no red, no emoji, sentence case, calm copy.
