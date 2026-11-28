Pill-shaped action button; one accent button per screen, everything else primary/secondary/ghost.

```jsx
<Button variant="accent" size="lg" fullWidth>Save <span className="nn-num">612</span> kcal to diary</Button>
<Button variant="secondary" icon="plus">Add missing item</Button>
```

- Wrap numbers in `<span className="nn-num">` so they render in Geist Mono.
- `accent` uses dark ink text on persimmon for AA contrast. Never white on persimmon.
- `destructive` is only for Delete account / Delete meal.
