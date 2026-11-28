import React from 'react';
import { Badge } from '../core/Badge.jsx';
import { MealPhoto } from './MealPhoto.jsx';
import { MacroLine } from './MacroLine.jsx';

export function MealRow({ title, time, mealType, kcal, protein, carbs, fat, method, photo, pending, selected, onClick, className = '' }) {
  return (
    <button type="button" className={'nn-meal' + (selected ? ' is-selected' : '') + (pending ? ' is-pending' : '') + ' ' + className} onClick={onClick}>
      <MealPhoto src={photo} size={56} />
      <span className="nn-meal__main">
        <span className="nn-meal__title">{title}</span>
        <span className="nn-meal__meta">{[mealType, time].filter(Boolean).join(' · ')}</span>
        <span className="nn-meal__foot">
          {pending ? <Badge tone="pending" icon="clock">Pending AI analysis</Badge> : <Badge method={method} />}
          {pending ? null : <MacroLine protein={protein} carbs={carbs} fat={fat} />}
        </span>
      </span>
      <span className="nn-meal__kcal"><span>{pending ? '–' : Math.round(kcal)}</span><i>kcal</i></span>
    </button>
  );
}
