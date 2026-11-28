import React from 'react';
import { Badge } from '../core/Badge.jsx';
import { Button } from '../core/Button.jsx';
import { SegmentedControl } from '../forms/SegmentedControl.jsx';

const PORTIONS = [0.5, 0.75, 1, 1.25, 1.5, 2];

export function FoodItemRow({ name, serving, kcal = 0, confidence, multiplier = 1, onMultiplier, expanded, onToggle, onSwap, onRemove, threshold = 0.76, className = '' }) {
  const low = confidence != null && confidence < threshold;
  return (
    <div className={'nn-food' + (expanded ? ' is-expanded' : '') + ' ' + className}>
      <button type="button" className="nn-food__head" aria-expanded={!!expanded} onClick={onToggle}>
        <span className="nn-food__main">
          <span className="nn-food__name">{name}{low ? <Badge tone="check" icon="question">Check</Badge> : null}</span>
          <span className="nn-food__serving">{serving}</span>
        </span>
        <span className={'nn-food__mult nn-num' + (multiplier !== 1 ? ' is-changed' : '')}>{multiplier}×</span>
        <span className="nn-food__kcal"><span>{Math.round(kcal * multiplier)}</span><i>kcal</i></span>
      </button>
      {expanded ? (
        <div className="nn-food__panel">
          <SegmentedControl size="sm" numeric options={PORTIONS.map(p => ({ value: p, label: p + '×' }))} value={multiplier} onChange={onMultiplier} aria-label="Portion" />
          <div className="nn-food__actions">
            <Button size="sm" variant="ghost" icon="swap" onClick={onSwap}>Swap</Button>
            <Button size="sm" variant="ghost" icon="trash" onClick={onRemove}>Remove</Button>
          </div>
        </div>
      ) : null}
    </div>
  );
}
