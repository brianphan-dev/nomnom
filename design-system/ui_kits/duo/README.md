# nomnom iPhone Duo UI kit

Foldable layouts, reusing the iPhone screens from `../ios/`. Open `index.html` and switch views with the control above the device.

- **Folded · Today** (466 × 678 pt cover display): compact summary and compact capture dock.
- **Unfolded · Today** (890 × 626 pt): diary on the left; week trend on the right until a meal is tapped, then that meal's inspector.
- **Unfolded · Review**: photo, title, totals, sauces drawer and Save on the left; detected items with portion multipliers on the right.
- **Unfolded · Sign in**: product visual left, copy and Sign in with Apple right.

Point sizes are derived from the PRD's pixel specs at @3x. Nothing interactive sits within 20pt of the hinge. iPad inherits the unfolded layout.

Files: `index.html`, `DuoFrame.jsx` (frame + `WeekTrend`), `duo.css`.
