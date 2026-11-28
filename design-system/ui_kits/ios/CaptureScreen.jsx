(function () {
  const { IconButton, Chip, SegmentedControl, TextField, Card, Icon, MealPhoto, ListRow } = window.NomnomDesignSystem_ec1f66;

  const MODES = [
    { value: 'photo', label: 'Photo AI', icon: 'sparkle' },
    { value: 'barcode', label: 'Barcode', icon: 'barcode' },
    { value: 'manual', label: 'Manual', icon: 'pencil-simple' },
  ];
  const HINTS = ['light oil', 'half rice', 'no sauce', 'shared plate'];

  function CaptureScreen({ mode = 'photo', onMode, onClose, onCaptured, onAdd, onEstimate, offline, quotaLeft }) {
    const D = window.NN_DATA;
    const [phase, setPhase] = React.useState('live');
    const [hints, setHints] = React.useState([]);
    const [q, setQ] = React.useState('');
    const [food, setFood] = React.useState(null);
    const [sheet, setSheet] = React.useState(false);
    const dark = mode !== 'manual';

    React.useEffect(() => {
      setSheet(false);
      if (mode !== 'barcode') return undefined;
      const t = setTimeout(() => { setFood(D.product); setSheet(true); }, 1600);
      return () => clearTimeout(t);
    }, [mode]);

    const shoot = () => {
      if (offline) { onCaptured && onCaptured({ pending: true }); return; }
      setPhase('analyzing');
      setTimeout(() => onCaptured && onCaptured({ pending: false }), 2100);
    };
    const toggleHint = h => setHints(hints.includes(h) ? hints.filter(x => x !== h) : hints.concat(h));
    const term = q.trim().toLowerCase();
    const results = D.recents.filter(f => f.name.toLowerCase().includes(term));

    return (
      <div className={'scr cap' + (dark ? ' cap--dark' : '')}>
        {dark ? <MealPhoto tone="dark" label={phase === 'analyzing' ? 'captured photo' : 'camera viewfinder'} className={'cap__view' + (mode === 'barcode' ? ' cap__view--bare' : '')} /> : null}
        <div className="scr__top cap__bar">
          <IconButton icon="x" label="Close" variant={dark ? 'glass' : 'filled'} onClick={onClose} />
          {mode === 'manual' ? <span className="cap__heading">Add manually</span> : null}
          {dark ? <IconButton icon={mode === 'photo' ? 'lightning-slash' : 'flashlight'} label="Light" variant="glass" /> : <span style={{ width: 44 }} />}
        </div>

        {mode === 'photo' && phase === 'live' ? (
          <div className="cap__bottom">
            {offline ? <div className="cap__note"><Icon name="cloud-slash" size={14} weight="bold" />Offline. Your photo is saved now and analysed later.</div> : null}
            {!offline && quotaLeft != null && quotaLeft <= 3 ? <div className="cap__note"><span><span className="nn-num">{quotaLeft}</span> photo scans left today</span></div> : null}
            <div className="cap__hints">
              <Chip size="sm" icon="microphone">Add a hint</Chip>
              {HINTS.map(h => <Chip key={h} size="sm" selected={hints.includes(h)} onClick={() => toggleHint(h)}>{h}</Chip>)}
            </div>
            <div className="cap__shutter-row">
              <IconButton icon="images" label="Photo library" variant="glass" size={48} />
              <button type="button" className="shutter" aria-label="Take photo" onClick={shoot}><i /></button>
              <span style={{ width: 48 }} />
            </div>
          </div>
        ) : null}

        {mode === 'photo' && phase === 'analyzing' ? (
          <div className="cap__analyzing">
            <div className="cap__analyzing-title"><Icon name="sparkle" size={18} weight="fill" />Looking at your plate</div>
            <div className="nn-shimmer cap__skel" style={{ width: '78%' }} />
            <div className="nn-shimmer cap__skel" style={{ width: '56%' }} />
            <div className="nn-shimmer cap__skel" style={{ width: '66%' }} />
          </div>
        ) : null}

        {mode === 'barcode' ? (
          <div className="cap__scan">
            <div className="reticle"><i /></div>
            <div className="cap__note">Point at a barcode</div>
            <Chip size="sm" icon="scan">No barcode? Snap the Nutrition Facts label</Chip>
          </div>
        ) : null}

        {mode === 'manual' ? (
          <div className="scr__scroll cap__manual">
            <TextField icon="magnifying-glass" placeholder="Search foods or describe a meal" value={q} onChange={setQ} clearable surface="card" />
            <button type="button" className="estimate" onClick={() => onEstimate && onEstimate(q)}>
              <Icon name="sparkle" size={22} weight="fill" />
              <span>
                <b>{term ? 'Estimate "' + q.trim() + '" with AI' : 'Estimate with AI'}</b>
                <small>Type it how you'd say it: 2 scrambled eggs in butter + sourdough toast</small>
              </span>
              <Icon name="caret-right" size={14} weight="bold" />
            </button>
            <div className="sec">
              <div className="sec__head"><span className="nn-overline">{term ? 'Results' : 'Recent'}</span></div>
              {results.length ? (
                <Card padding="none">
                  {results.map(f => (
                    <ListRow key={f.name} title={f.name} subtitle={f.brand + ' · ' + f.servings[0].label} chevron
                      value={<span className="nn-num">{Math.round((f.per100.kcal * f.servings[0].g) / 100)} kcal</span>}
                      onClick={() => { setFood(f); setSheet(true); }} />
                  ))}
                </Card>
              ) : <p className="empty-note">No saved foods match. Use Estimate with AI above.</p>}
            </div>
          </div>
        ) : null}

        {phase === 'live' ? <div className="cap__modes"><SegmentedControl tone={dark ? 'dark' : 'default'} options={MODES} value={mode} onChange={onMode} /></div> : null}
        <window.ServingSheet open={sheet} food={food} method={mode === 'barcode' ? 'barcode' : 'manual'} onClose={() => setSheet(false)} onAdd={m => { setSheet(false); onAdd && onAdd(m); }} />
      </div>
    );
  }

  Object.assign(window, { CaptureScreen });
})();
