import React from 'react';
import { ProgressBar } from '../feedback/ProgressBar.jsx';

const LABELS = { protein: 'Protein', carbs: 'Carbs', fat: 'Fat' };

export function MacroBar({ macro = 'protein', value = 0, target, label, compact, className = '' }) {
  const name = label || LABELS[macro];
  return (
    <div className={'nn-macrobar' + (compact ? ' nn-macrobar--compact' : '') + ' ' + className}>
      <div className="nn-macrobar__head">
        <span className="nn-macrobar__label">{name}</span>
        <span className="nn-macrobar__value">{Math.round(value)}<i>{target ? '/' + target + 'g' : 'g'}</i></span>
      </div>
      <ProgressBar tone={macro} value={value} max={target || value || 1} label={name} />
    </div>
  );
}
