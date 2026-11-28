import React from 'react';
import { Icon } from '../core/Icon.jsx';

export function Checkbox({ checked, onChange, label, description, trailing, dimUnchecked, disabled, className = '' }) {
  return (
    <label className={'nn-check' + (dimUnchecked ? ' nn-check--dim' : '') + (disabled ? ' is-disabled' : '') + ' ' + className}>
      <input type="checkbox" checked={!!checked} disabled={disabled} onChange={e => onChange && onChange(e.target.checked)} />
      <span className="nn-check__box"><Icon name="check" weight="bold" size={14} /></span>
      {label || description ? (
        <span className="nn-check__text">
          <span className="nn-check__label">{label}</span>
          {description ? <span className="nn-check__desc">{description}</span> : null}
        </span>
      ) : null}
      {trailing ? <span className="nn-check__trailing">{trailing}</span> : null}
    </label>
  );
}
