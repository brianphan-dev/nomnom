(function () {
  const { NavBar, IconButton, Button, Card, ListRow, Banner, Badge, Checkbox, ProgressBar, Icon } = window.NomnomDesignSystem_ec1f66;

  const POLICIES = [
    ['skip', 'Skip duplicates', 'Keep what is already in nomnom'],
    ['both', 'Keep both', 'Import everything, even if it repeats'],
    ['replace', 'Replace existing date', 'Imported days overwrite nomnom days'],
  ];

  function ImportScreen({ onBack, onDone }) {
    const D = window.NN_DATA;
    const [step, setStep] = React.useState(1);
    const [policy, setPolicy] = React.useState('skip');
    const [pct, setPct] = React.useState(0);
    React.useEffect(() => {
      if (step !== 4) return undefined;
      const a = setTimeout(() => setPct(100), 60);
      const b = setTimeout(() => setStep(5), 1700);
      return () => { clearTimeout(a); clearTimeout(b); };
    }, [step]);
    const back = () => (step > 1 && step < 4 ? setStep(step - 1) : onBack && onBack());

    return (
      <div className="scr">
        <div className="scr__top">
          <NavBar title="Import history" leading={<IconButton icon={step === 1 ? 'x' : 'caret-left'} label="Back" variant="filled" size={36} weight="bold" iconSize={16} onClick={back} />} />
          {step < 5 ? <div className="step"><span>Step {step} of 4</span><ProgressBar tone="neutral" size={4} value={step} max={4} /></div> : null}
        </div>

        {step === 1 ? (
          <div className="scr__scroll">
            <h1 className="detail__title">Where is your history?</h1>
            <Card padding="none">
              <ListRow icon="file-zip" title="MyFitnessPal" subtitle="Export .zip or Nutrition-Summary .csv" chevron onClick={() => setStep(2)} />
              <ListRow icon="heartbeat" title="Apple Health" subtitle="Read calories and macros already in Health" chevron onClick={() => setStep(2)} />
            </Card>
          </div>
        ) : null}

        {step === 2 ? (
          <React.Fragment>
            <div className="scr__scroll">
              <h1 className="detail__title">Here's what we found</h1>
              <Banner tone="info" icon="info" title="MyFitnessPal exports meal totals">
                You get one entry per meal per day (Breakfast, Lunch, Dinner, Snacks) with full calories and macros. Individual foods aren't in their export.
              </Banner>
              <div className="btn-row">
                {['Date', 'Meal', 'Calories', 'Protein', 'Carbs', 'Fat'].map(c => <Badge key={c} tone="positive" icon="check">{c}</Badge>)}
              </div>
              <Card padding="md">
                <table className="tbl">
                  <thead><tr><th>Date</th><th>Meal</th><th>kcal</th><th>P</th><th>C</th><th>F</th></tr></thead>
                  <tbody>{D.importRows.map((r, i) => <tr key={i}>{r.map((c, j) => <td key={j}>{c}</td>)}</tr>)}</tbody>
                </table>
              </Card>
              <p className="empty-note">421 meals between 3 Mar and 24 Nov 2026.</p>
            </div>
            <div className="scr__footer"><Button size="lg" fullWidth onClick={() => setStep(3)}>Looks right</Button></div>
          </React.Fragment>
        ) : null}

        {step === 3 ? (
          <React.Fragment>
            <div className="scr__scroll">
              <h1 className="detail__title">If a meal is already here</h1>
              <Card padding="md" style={{ paddingTop: 6, paddingBottom: 6 }}>
                {POLICIES.map(p => <Checkbox key={p[0]} checked={policy === p[0]} onChange={() => setPolicy(p[0])} label={p[1]} description={p[2]} />)}
              </Card>
            </div>
            <div className="scr__footer"><Button variant="accent" size="lg" fullWidth onClick={() => { setPct(0); setStep(4); }}>Import <span className="nn-num">421</span> meals</Button></div>
          </React.Fragment>
        ) : null}

        {step === 4 ? (
          <div className="receipt">
            <h2>Importing</h2>
            <p>This stays on your iPhone until it syncs.</p>
            <div style={{ width: 220, marginTop: 12 }}><ProgressBar tone="accent" size={8} value={pct} max={100} /></div>
          </div>
        ) : null}

        {step === 5 ? (
          <React.Fragment>
            <div className="receipt">
              <Icon name="check-circle" size={44} weight="fill" color="var(--positive)" />
              <h2>Import finished</h2>
              <p><span className="nn-num">412</span> meals imported · <span className="nn-num">9</span> duplicates skipped</p>
            </div>
            <div className="scr__footer"><Button size="lg" fullWidth onClick={onDone}>Back to Today</Button></div>
          </React.Fragment>
        ) : null}
      </div>
    );
  }

  Object.assign(window, { ImportScreen });
})();
