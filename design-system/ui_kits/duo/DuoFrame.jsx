(function () {
  const { Icon, NavBar, Card, MacroBar } = window.NomnomDesignSystem_ec1f66;

  // iPhone Duo: folded 5.4" cover (466 × 678 pt) or unfolded 7.6" inner display (890 × 626 pt, two panes).
  function DuoFrame({ unfolded, left, right, children }) {
    return (
      <div className={'duo' + (unfolded ? ' duo--unfolded' : '')} style={{ width: unfolded ? 890 : 466, height: unfolded ? 626 : 678 }}>
        <div className="duo__status">
          <span>9:41</span>
          <span><Icon name="cell-signal-full" weight="fill" size={16} /><Icon name="wifi-high" weight="bold" size={16} /><Icon name="battery-full" weight="fill" size={22} /></span>
        </div>
        {unfolded ? null : <div className="duo__island" />}
        {unfolded ? (
          <React.Fragment>
            <div className="duo__pane">{left}</div>
            <div className="duo__hinge" />
            <div className="duo__pane">{right}</div>
          </React.Fragment>
        ) : <div className="duo__pane">{children}</div>}
        <div className="duo__home" />
      </div>
    );
  }

  // Default right pane on Today when no meal is selected.
  function WeekTrend() {
    const D = window.NN_DATA, w = D.week, target = D.targets.kcal;
    const max = Math.max.apply(null, w.kcal.concat(target)) * 1.08;
    const done = w.kcal.slice(0, 6);
    const avg = Math.round(done.reduce((a, b) => a + b, 0) / done.length);
    return (
      <div className="scr">
        <div className="scr__top"><NavBar largeTitle="This week" subtitle={w.range} /></div>
        <div className="scr__scroll">
          <Card>
            <span className="kcal-lg">{avg.toLocaleString('en-US')}<small>avg kcal a day</small></span>
            <div className="week">
              <div className="week__target" style={{ bottom: (target / max) * 100 + '%' }}><span>{target.toLocaleString('en-US')}</span></div>
              {w.kcal.map((k, i) => (
                <div key={i} className={'week__col' + (i === 6 ? ' is-today' : '')}>
                  <div className="week__bar" style={{ height: (k / max) * 100 + '%' }} />
                  <span>{w.days[i]}</span>
                </div>
              ))}
            </div>
          </Card>
          <Card>
            <div className="detail__macros" style={{ marginTop: 0 }}>
              <MacroBar macro="protein" value={w.avg.protein} target={D.targets.protein} />
              <MacroBar macro="carbs" value={w.avg.carbs} target={D.targets.carbs} />
              <MacroBar macro="fat" value={w.avg.fat} target={D.targets.fat} />
            </div>
          </Card>
          <p className="empty-note">Tap a meal on the left to see its breakdown here.</p>
        </div>
      </div>
    );
  }

  Object.assign(window, { DuoFrame, WeekTrend });
})();
