(function () {
  const { NavBar, IconButton, Button, Badge, MealPhoto, Card, MacroBar, ListRow, Banner } = window.NomnomDesignSystem_ec1f66;

  // Full screen on iPhone; `embedded` turns it into the right-pane inspector on iPhone Duo unfolded.
  function MealDetailScreen({ meal, onBack, onDelete, embedded }) {
    const D = window.NN_DATA;
    if (!meal) return null;
    const hasPhoto = meal.method === 'photo_ai' || meal.pending;
    return (
      <div className="scr">
        <div className="scr__top">
          <NavBar
            leading={<IconButton icon={embedded ? 'x' : 'caret-left'} label={embedded ? 'Close' : 'Back'} variant="filled" size={36} weight="bold" iconSize={16} onClick={onBack} />}
            trailing={meal.pending ? null : <Button size="sm" variant="secondary">Edit</Button>}
          />
        </div>
        <div className="scr__scroll">
          {hasPhoto ? <MealPhoto label="meal photo" radius={28} style={{ width: '100%', height: embedded ? 140 : 180 }} /> : null}
          <div>
            <h1 className="detail__title">{meal.title}</h1>
            <div className="detail__meta">{meal.mealType} · {meal.time}{meal.pending ? <Badge tone="pending" icon="clock">Pending AI analysis</Badge> : <Badge method={meal.method} />}</div>
          </div>
          {meal.pending ? (
            <Banner icon="cloud-slash" title="Saved on this iPhone">We'll analyse this photo as soon as you're back online. Nothing else to do.</Banner>
          ) : (
            <React.Fragment>
              <Card>
                <span className="kcal-lg">{Math.round(meal.kcal)}<small>kcal</small></span>
                <div className="detail__macros">
                  <MacroBar macro="protein" value={meal.protein} />
                  <MacroBar macro="carbs" value={meal.carbs} />
                  <MacroBar macro="fat" value={meal.fat} />
                </div>
              </Card>
              <div className="sec">
                <div className="sec__head"><span className="nn-overline">Items</span></div>
                <Card padding="none">
                  {(meal.items || []).map(i => <ListRow key={i.name} title={i.name} subtitle={i.serving} value={<span className="nn-num">{i.kcal}</span>} />)}
                </Card>
              </div>
              <div className="sec">
                <div className="sec__head"><span className="nn-overline">Nutrients</span></div>
                <Card><dl className="micros">{D.micros.map(m => <div key={m.label}><dt>{m.label}</dt><dd>{m.value}</dd></div>)}</dl></Card>
              </div>
            </React.Fragment>
          )}
          <Button variant="destructive" fullWidth icon="trash" onClick={() => onDelete && onDelete(meal)}>Delete meal</Button>
        </div>
      </div>
    );
  }

  Object.assign(window, { MealDetailScreen });
})();
