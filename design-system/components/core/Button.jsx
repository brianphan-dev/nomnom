import React from 'react';
import { Icon } from './Icon.jsx';

export function Button({ variant = 'primary', size = 'md', icon, iconRight, iconWeight = 'bold', fullWidth, loading, disabled, children, className = '', ...rest }) {
  const cls = ['nn-btn', 'nn-btn--' + variant, 'nn-btn--' + size, fullWidth ? 'nn-btn--full' : '', className].join(' ');
  const iconSize = size === 'sm' ? 16 : size === 'lg' ? 22 : 18;
  return (
    <button type="button" className={cls} disabled={disabled || loading} {...rest}>
      {loading ? <Icon name="circle-notch" size={iconSize} weight="bold" className="nn-spin" /> : icon ? <Icon name={icon} size={iconSize} weight={iconWeight} /> : null}
      {children != null && children !== false ? <span className="nn-btn__label">{children}</span> : null}
      {iconRight ? <Icon name={iconRight} size={iconSize} weight={iconWeight} /> : null}
    </button>
  );
}
