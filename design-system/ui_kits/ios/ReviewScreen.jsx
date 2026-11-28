(function () {
  const { NavBar, IconButton, Button, SegmentedControl, MacroLine, MealPhoto, Card, FoodItemRow, Checkbox, Icon } = window.NomnomDesignSystem_ec1f66;

  // Shared state so the same parts can sit in one column (iPhone) or two panes (iPhone Duo unfolded).
  function useReview() {
    const D = window.NN_DATA;
    const [items, setItems] = React.useState(() => D.detected.map(d => ({ ...d, mult: 1 })));
    const [extras, setExtras] = React.useState(() => D.extras.map(e => ({ ...e })));
    const firstLow = D.detected.find(d => d.confidence < 0.76);
    const [open, setOpen] = React.useState(firstLow ? firstLow.id : null);
    const [drawer, setDrawer] = React.useState(false);
    const [type, setType] = React.useState('Dinner');
    const [title, setTitle] = React.useState(D.detectedTitle);
    const tot = k => items.reduce((a, i) => a + i[k] * i.mult, 0) + extras.filter(e => e.on).reduce((a, e) => a + e[k], 0);
    const totals = { kcal: Math.round(tot('kcal')), protein: tot('p'), carbs: tot('c'), fat: tot('f') };
    const meal = () => ({
      title, mealType: type, method: 'photo_ai', ...totals,
      items: items.map(i => ({ name: i.name, serving: i.mult === 1 ? i.serving : i.mult + '× ' + i.serving, kcal: Math.round(i.kcal * i.mult) }))
        .concat(extras.filter(e => e.on).map(e => ({ name: e.name, serving: e.serving, kcal: e.kcal }))),
    });
    return { items, setItems, extras, setExtras, open, setOpen, drawer, setDrawer, type, setType, title, setTitle, totals, meal };
  }

  function ReviewHeader({ r }) {
    return (
      <div className="rev__head">
        <label className="rev__titlewrap">
          <input className="rev__title" value={r.title} onChange={e => r.setTitle(e.target.value)} aria-label="Meal title" />
          <Icon name="pencil-simple" size={18} />
        </label>
        <SegmentedControl options={['Breakfast', 'Lunch', 'Dinner', 'Snack']} value={r.type} onChange={r.setType} />
        <div className="rev__totals">
          <span className="kcal-lg">{r.totals.kcal}<small>kcal</small></span>
          <MacroLine size="md" protein={r.totals.protein} carbs={r.totals.carbs} fat={r.totals.fat} />
        </div>
      </div>
    );
  }

  function ReviewItems({ r }) {
    const upd = (id, patch) => r.setItems(r.items.map(i => (i.id === id ? { ...i, ...patch } : i)));
    return (
      <div className="sec">
        <div className="sec__head"><span className="nn-overline">On the plate</span><span className="nn-overline">Tap to adjust</span></div>
        <Card padding="none">
          {r.items.map(i => (
            <FoodItemRow key={i.id} name={i.name} serving={i.serving} kcal={i.kcal} confidence={i.confidence}
              multiplier={i.mult} onMultiplier={m => upd(i.id, { mult: m })}
              expanded={r.open === i.id} onToggle={() => r.setOpen(r.open === i.id ? null : i.id)}
              onRemove={() => r.setItems(r.items.filter(x => x.id !== i.id))} />
          ))}
        </Card>
        <div className="btn-row" style={{ marginTop: 4 }}>
          <Button size="sm" variant="secondary" icon="plus">Add missing item</Button>
          <Button size="sm" variant="secondary" icon="chat-text">Refine with text</Button>
        </div>
      </div>
    );
  }

  function ReviewExtras({ r }) {
    const on = r.extras.filter(e => e.on);
    const kcal = on.reduce((a, e) => a + e.kcal, 0);
    return (
      <Card padding="none">
        <button type="button" className="drawer__head" aria-expanded={r.drawer} onClick={() => r.setDrawer(!r.drawer)}>
          <b>Sauces, oils & seasonings</b>
          <span>{on.length} · +{kcal}</span>
          <Icon name={r.drawer ? 'caret-up' : 'caret-down'} size={14} weight="bold" color="var(--text-tertiary)" />
        </button>
        {r.drawer ? (
          <div className="drawer__body">
            {r.extras.map(e => (
              <Checkbox key={e.id} checked={e.on} dimUnchecked label={e.name} description={e.serving} trailing={'+' + e.kcal}
                onChange={v => r.setExtras(r.extras.map(x => (x.id === e.id ? { ...x, on: v } : x)))} />
            ))}
          </div>
        ) : null}
      </Card>
    );
  }

  function ReviewSave({ r, onSave }) {
    return <Button variant="accent" size="lg" fullWidth onClick={() => onSave && onSave(r.meal())}>Save <span className="nn-num">{r.totals.kcal}</span> kcal to diary</Button>;
  }

  function ReviewScreen({ onClose, onRetake, onSave }) {
    const r = useReview();
    return (
      <div className="scr">
        <div className="scr__top">
          <NavBar title="Review" leading={<IconButton icon="x" label="Discard" variant="filled" size={36} onClick={onClose} />} trailing={<Button size="sm" variant="ghost" onClick={onRetake}>Retake</Button>} />
        </div>
        <div className="scr__scroll">
          <MealPhoto label="captured photo" radius={28} style={{ width: '100%', height: 150 }} />
          <ReviewHeader r={r} />
          <ReviewItems r={r} />
          <ReviewExtras r={r} />
        </div>
        <div className="scr__footer"><ReviewSave r={r} onSave={onSave} /></div>
      </div>
    );
  }

  Object.assign(window, { useReview, ReviewHeader, ReviewItems, ReviewExtras, ReviewSave, ReviewScreen });
})();
