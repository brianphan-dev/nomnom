Bottom sheet with grabber for product match, serving calculator and pickers.

```jsx
<Sheet open={open} onClose={close} title="Greek yogurt, plain" footer={<Button variant="accent" size="lg" fullWidth>Add 150 kcal</Button>}>
  …serving chips and stepper…
</Sheet>
```

- Positions absolutely inside the nearest positioned ancestor; stays mounted so it can animate out.
