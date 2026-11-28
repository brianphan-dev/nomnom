Detected food item on AI Review: name, serving, kcal, Check badge and an expandable portion-multiplier panel.

```jsx
<Card padding="none">
  <FoodItemRow name="Salmon fillet" serving="1 fillet (~150g)" kcal={280} confidence={0.93} multiplier={m} onMultiplier={setM} expanded={open} onToggle={() => setOpen(!open)} />
</Card>
```

- Only one row is expanded at a time; expand the first low-confidence row by default.
