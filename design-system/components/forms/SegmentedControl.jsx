import React from 'react';
import { Icon } from '../core/Icon.jsx';

export function SegmentedControl({ options = [], value, onChange, size = 'md', tone = 'default', fullWidth = true, numeric, className = '', ...rest }) {
  const cls = ['nn-seg', 'nn-seg--' + size, 'nn-seg--' + tone, fullWidth ? 'nn-seg--full' : '', className].join(' ');
  return (
    <div role="tablist" className={cls} {...rest}>
      {options.map(o => {
        const opt = o !== null && typeof o === 'object' ? o : { value: o, label: String(o) };
        const on = opt.value === value;
        return (
          <button key={String(opt.value)} type="button" role="tab" aria-selected={on} className={'nn-seg__item' + (on ? ' is-selected' : '') + (numeric ? ' nn-num' : '')} onClick={() => onChange && onChange(opt.value)}>
            {opt.icon ? <Icon name={opt.icon} size={size === 'sm' ? 14 : 16} weight={on ? 'bold' : 'regular'} /> : null}
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}
