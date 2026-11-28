(function () {
  const { NavBar, SyncPill, IconButton, DailySummary, MealRow, Card, CaptureDock, Button } = window.NomnomDesignSystem_ec1f66;

  function TodayScreen({ meals = [], sync = 'synced', queued, selectedId, compactSummary, compactDock, onSnap, onBarcode, onManual, onMeal, onSettings, onImport }) {
    const D = window.NN_DATA;
    const sum = k => meals.reduce((a, m) => a + (m.pending ? 0 : m[k] || 0), 0);
    return (
      <div className="scr">
        <div className="scr__top">
          <NavBar
            largeTitle="Today"
            subtitle={compactSummary ? null : D.today}
            leading={<SyncPill status={sync} queued={queued} />}
            trailing={<React.Fragment>
              <IconButton icon="calendar-blank" label="Pick a date" variant="filled" size={36} />
              <IconButton icon="gear-six" label="Settings" variant="filled" size={36} onClick={onSettings} />
            </React.Fragment>}
          />
        </div>
        <div className="scr__scroll" style={{ paddingBottom: compactDock ? 104 : 130 }}>
          <DailySummary
            compact={compactSummary}
            kcal={sum('kcal')} target={D.targets.kcal}
            protein={{ value: sum('protein'), target: D.targets.protein }}
            carbs={{ value: sum('carbs'), target: D.targets.carbs }}
            fat={{ value: sum('fat'), target: D.targets.fat }}
            micros={meals.length ? D.micros : []}
          />
          <div className="sec">
            <div className="sec__head"><span className="nn-overline">Meals</span>{meals.length ? <span className="nn-overline">{meals.length} logged</span> : null}</div>
            {meals.length ? (
              <Card padding="none" style={{ padding: 8 }}>
                {meals.map(m => <MealRow key={m.id} {...m} selected={m.id === selectedId} onClick={() => onMeal && onMeal(m)} />)}
              </Card>
            ) : (
              <Card tone="outline" className="empty">
                <h2>Nothing logged yet</h2>
                <p>Snap your first plate with the camera button below, or bring your history over from MyFitnessPal.</p>
                <Button size="sm" variant="secondary" icon="download-simple" onClick={onImport}>Import history</Button>
              </Card>
            )}
          </div>
        </div>
        <div className="scr__dock"><CaptureDock compact={compactDock} onSnap={onSnap} onBarcode={onBarcode} onManual={onManual} /></div>
      </div>
    );
  }

  Object.assign(window, { TodayScreen });
})();
