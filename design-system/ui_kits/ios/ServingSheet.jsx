(function () {
  const { Sheet, Button, Chip, Stepper, Badge, MacroLine } = window.NomnomDesignSystem_ec1f66;

  // Product match (barcode) and default serving calculator (manual) share this sheet.
  function ServingSheet({ open, food, method = 'manual', onClose, onAdd }) {
    const [unit, setUnit] = React.useState(0);
    const [qty, setQty] = React.useState(1);
    React.useEffect(() => { setUnit(0); setQty(1); }, [food]);
    if (!food) return <Sheet open={false} />;
    const s = food.servings[unit] || food.servings[0];
    const v = k => (food.per100[k] * s.g * qty) / 100;
    const add = () => onAdd && onAdd({ title: food.name, kcal: v('kcal'), protein: v('p'), carbs: v('c'), fat: v('f'), method, items: [{ name: food.name, serving: qty + ' × ' + s.label, kcal: Math.round(v('kcal')) }] });
    return (
      <Sheet open={open} onClose={onClose} title={food.name}
        footer={<Button variant="accent" size="lg" fullWidth onClick={add}>Add <span className="nn-num">{Math.round(v('kcal'))}</span> kcal to diary</Button>}>
        <div className="serv">
          <div className="serv__meta">{food.brand}<Badge tone="info">{food.source}</Badge></div>
          <div className="btn-row">
            {food.servings.map((o, i) => <Chip key={o.label} selected={i === unit} onClick={() => setUnit(i)}>{o.label}{/^\d+g$/.test(o.label) ? null : <i>{o.g}g</i>}</Chip>)}
          </div>
          <div className="serv__qty"><span>Quantity</span><Stepper value={qty} onChange={setQty} min={0.5} /></div>
          <div className="serv__totals">
            <span className="kcal-lg">{Math.round(v('kcal'))}<small>kcal</small></span>
            <MacroLine size="md" protein={v('p')} carbs={v('c')} fat={v('f')} />
          </div>
        </div>
      </Sheet>
    );
  }

  Object.assign(window, { ServingSheet });
})();
