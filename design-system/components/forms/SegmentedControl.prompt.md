Pill segmented control for capture mode, meal type and portion multipliers.

```jsx
<SegmentedControl options={['Breakfast', 'Lunch', 'Dinner', 'Snack']} value={type} onChange={setType} />
<SegmentedControl tone="dark" value={mode} onChange={setMode} options={[{ value: 'photo', label: 'Photo AI', icon: 'sparkle' }, { value: 'barcode', label: 'Barcode', icon: 'barcode' }, { value: 'manual', label: 'Manual', icon: 'pencil-simple' }]} />
```

- Max 4 text options at md; 6 numeric options at sm.
