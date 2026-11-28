import React from 'react';
import { Icon } from '../core/Icon.jsx';

export function Stepper({ value = 1, onChange, step = 0.5, min = 0, max = 99, format, label = 'Quantity', className = '' }) {
  const set = v => onChange && onChange(Math.min(max, Math.max(min, Math.round(v * 100) / 100)));
  return (
    <div className={'nn-stepper ' + className} role="group" aria-label={label}>
      <button type="button" aria-label="Decrease" disabled={value <= min} onClick={() => set(value - step)}><Icon name="minus" weight="bold" size={16} /></button>
      <span className="nn-stepper__value">{format ? format(value) : value}</span>
      <button type="button" aria-label="Increase" disabled={value >= max} onClick={() => set(value + step)}><Icon name="plus" weight="bold" size={16} /></button>
    </div>
  );
}
