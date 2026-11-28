(function () {
  const { NavBar, IconButton, Button, Card, ListRow, Switch, Dialog } = window.NomnomDesignSystem_ec1f66;

  function SettingsScreen({ onBack, onImport, onSignOut }) {
    const [camera, setCamera] = React.useState(false);
    const [health, setHealth] = React.useState(true);
    const [syncing, setSyncing] = React.useState(false);
    const [ask, setAsk] = React.useState(false);
    const syncNow = () => { setSyncing(true); setTimeout(() => setSyncing(false), 1400); };
    return (
      <div className="scr">
        <div className="scr__top">
          <NavBar largeTitle="Settings" leading={<IconButton icon="caret-left" label="Back" variant="filled" size={36} weight="bold" iconSize={16} onClick={onBack} />} />
        </div>
        <div className="scr__scroll">
          <Card padding="md" className="account">
            <span className="account__avatar">b</span>
            <div><b>Brian</b><span>Signed in with Apple · Hide My Email</span></div>
          </Card>

          <div className="sec">
            <div className="sec__head"><span className="nn-overline">Sync</span><span className="nn-overline">Last synced 9:41</span></div>
            <Card padding="none">
              <ListRow icon="device-mobile" title="iPhone" subtitle="This device" value="Just now" />
              <ListRow icon="book-open" title="iPhone Duo" value="2 h ago" />
              <ListRow icon="device-tablet" title="iPad" value="Yesterday" />
            </Card>
            <Button variant="secondary" icon="arrows-clockwise" loading={syncing} onClick={syncNow}>{syncing ? 'Syncing' : 'Sync now'}</Button>
          </div>

          <div className="sec">
            <div className="sec__head"><span className="nn-overline">Capture</span></div>
            <Card padding="none">
              <ListRow icon="camera" title="Open to camera" subtitle="Skip Today and start on the viewfinder" trailing={<Switch checked={camera} onChange={setCamera} label="Open to camera" />} />
            </Card>
          </div>

          <div className="sec">
            <div className="sec__head"><span className="nn-overline">Integrations</span></div>
            <Card padding="none">
              <ListRow icon="heartbeat" title="Apple Health" subtitle="Write meals to Health" trailing={<Switch checked={health} onChange={setHealth} label="Apple Health" />} />
              <ListRow icon="markdown-logo" title="Obsidian daily notes" value="Off" chevron onClick={() => {}} />
            </Card>
          </div>

          <div className="sec">
            <div className="sec__head"><span className="nn-overline">Your data</span></div>
            <Card padding="none">
              <ListRow icon="download-simple" title="Import history" subtitle="MyFitnessPal or Apple Health" chevron onClick={onImport} />
              <ListRow icon="export" title="Export archive" subtitle="JSON, CSV and photos" value=".zip" chevron onClick={() => {}} />
            </Card>
          </div>

          <Card padding="none">
            <ListRow icon="sign-out" title="Sign out" onClick={onSignOut} />
            <ListRow icon="trash" title="Delete account" tone="destructive" onClick={() => setAsk(true)} />
          </Card>
          <p className="fine">nomnom 0.1 · No ads, no trackers</p>
        </div>
        <Dialog open={ask} onClose={() => setAsk(false)} title="Delete your account?"
          actions={[{ label: 'Delete account', variant: 'destructive', onClick: onSignOut }, { label: 'Keep account', onClick: () => setAsk(false) }]}>
          This permanently deletes your diary, photos and synced data on every device, and revokes Sign in with Apple. Export an archive first if you want a copy.
        </Dialog>
      </div>
    );
  }

  Object.assign(window, { SettingsScreen });
})();
