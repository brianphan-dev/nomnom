import React from 'react';
import { Icon } from './Icon.jsx';

export function Chip({ selected, icon, size = 'md', children, className = '', ...rest }) {
  return (
    <button type="button" aria-pressed={!!selected} className={'nn-chip nn-chip--' + size + (selected ? ' is-selected' : '') + ' ' + className} {...rest}>
      {icon ? <Icon name={icon} size={16} /> : null}
      {children}
    </button>
  );
}
