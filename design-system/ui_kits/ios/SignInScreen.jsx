(function () {
  const { Button, Icon, MealPhoto } = window.NomnomDesignSystem_ec1f66;

  function SignInScreen({ onSignIn, onImport, split }) {
    const visual = <MealPhoto label="product visual" radius={36} style={{ width: '100%', height: '100%' }} />;
    const copy = (
      <div className="signin__body">
        <h1 className="signin__hero">A food diary you can <i>keep up with.</i></h1>
        <ul className="signin__points">
          <li><Icon name="camera" size={20} />Snap a plate. Calories and macros in a few seconds.</li>
          <li><Icon name="cloud-check" size={20} />Works offline and syncs across your devices.</li>
          <li><Icon name="export" size={20} />Your data stays yours. Export it any time.</li>
        </ul>
      </div>
    );
    const actions = (
      <div className="signin__actions">
        <Button size="lg" fullWidth icon="apple-logo" iconWeight="fill" onClick={onSignIn}>Sign in with Apple</Button>
        <button type="button" className="signin__import" onClick={onImport}>Already tracking in MyFitnessPal? <u>Import your history</u></button>
        <p className="signin__fine">No ads. No streaks. Delete your account any time.</p>
      </div>
    );
    if (split === 'left') return <div className="scr"><div className="scr__top"><div className="signin__mark"><img src="../../assets/app-icon.svg" alt="" />nomnom</div></div><div className="signin__visual" style={{ paddingBottom: 20 }}>{visual}</div></div>;
    if (split === 'right') return <div className="scr"><div className="scr__top" /><div style={{ flex: 1 }} />{copy}{actions}</div>;
    return (
      <div className="scr">
        <div className="scr__top"><div className="signin__mark"><img src="../../assets/app-icon.svg" alt="" />nomnom</div></div>
        <div className="signin__visual">{visual}</div>
        {copy}
        {actions}
      </div>
    );
  }

  Object.assign(window, { SignInScreen });
})();
