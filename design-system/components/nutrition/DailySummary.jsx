import React from 'react';
import { Card } from '../core/Card.jsx';
import { Icon } from '../core/Icon.jsx';
import { ProgressBar } from '../feedback/ProgressBar.jsx';
import { MacroBar } from './MacroBar.jsx';

const fmt = n => Math.round(n).toLocaleString('en-US');

export function DailySummary({ kcal = 0, target = 2000, protein = {}, carbs = {}, fat = {}, micros = [], defaultExpanded = false, compact, className = '' }) {
  const [open, setOpen] = React.useState(defaultExpanded);
  const left = target - kcal;
  return (
    <Card className={'nn-summary' + (compact ? ' nn-summary--compact' : '') + ' ' + className} padding={compact ? 'md' : 'lg'}>
      <div className="nn-summary__top">
        <div>
          <div className="nn-summary__kcal">{fmt(kcal).split(',').map((p, i) => <React.Fragment key={i}>{i ? <span className="nn-sep">,</span> : null}{p}</React.Fragment>)}</div>
          {compact ? null : <div className="nn-summary__of">of {fmt(target)} kcal</div>}
        </div>
        <div className="nn-summary__left"><span className="nn-num">{fmt(Math.abs(left))}</span>{left >= 0 ? ' left' : ' over'}</div>
      </div>
      <ProgressBar tone="accent" size={compact ? 8 : 10} value={kcal} max={target} label="Calories" />
      <div className="nn-summary__macros">
        <MacroBar macro="protein" value={protein.value} target={protein.target} compact={compact} />
        <MacroBar macro="carbs" value={carbs.value} target={carbs.target} compact={compact} />
        <MacroBar macro="fat" value={fat.value} target={fat.target} compact={compact} />
      </div>
      {micros.length > 0 && !compact && open ? (
        <dl className="nn-summary__micros">
          {micros.map(m => <div key={m.label}><dt>{m.label}</dt><dd>{m.value}</dd></div>)}
        </dl>
      ) : null}
      {micros.length > 0 && !compact ? (
        <button type="button" className="nn-summary__toggle" aria-expanded={open} onClick={() => setOpen(!open)}>
          {open ? 'Fewer nutrients' : 'More nutrients'}<Icon name={open ? 'caret-up' : 'caret-down'} size={12} weight="bold" />
        </button>
      ) : null}
    </Card>
  );
}
