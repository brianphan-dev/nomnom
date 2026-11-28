Centered confirmation alert (e.g. Delete account).

```jsx
<Dialog open={open} onClose={close} title="Delete your account?" actions={[{ label: 'Delete account', variant: 'destructive', onClick: del }, { label: 'Keep account', onClick: close }]}>
  This permanently deletes your diary, photos and synced data, and revokes Sign in with Apple.
</Dialog>
```

- Positions absolutely inside the nearest positioned ancestor (the screen).
