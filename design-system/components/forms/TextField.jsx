import React from 'react';
import { Icon } from '../core/Icon.jsx';

export function TextField({ icon, value, onChange, placeholder, trailing, clearable, size = 'md', surface = 'fill', className = '', ...rest }) {
  return (
    <label className={'nn-field nn-field--' + size + ' nn-field--' + surface + ' ' + className}>
      {icon ? <Icon name={icon} size={20} color="var(--text-tertiary)" /> : null}
      <input className="nn-field__input" value={value} placeholder={placeholder} onChange={e => onChange && onChange(e.target.value, e)} {...rest} />
      {clearable && value ? (
        <button type="button" className="nn-field__clear" aria-label="Clear" onClick={() => onChange && onChange('')}>
          <Icon name="x-circle" weight="fill" size={18} />
        </button>
      ) : null}
      {trailing}
    </label>
  );
}
