Quiet cloud-sync status pill for the Today header: Synced, Syncing…, Offline · Queued.

```jsx
<SyncPill status="offline" queued={2} />
```

- Never use red or amber here. Offline is a normal state.
