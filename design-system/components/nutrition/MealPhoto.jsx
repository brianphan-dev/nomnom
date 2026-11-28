import React from 'react';
import { Icon } from '../core/Icon.jsx';

export function MealPhoto({ src, alt, size = 56, radius, label, tone = 'light', className = '', style }) {
  const s = { width: size, height: size, borderRadius: radius, ...(src ? { backgroundImage: 'url(' + src + ')' } : {}), ...style };
  const n = typeof size === 'number' ? size : 96;
  return (
    <div className={'nn-photo nn-photo--' + tone + (src ? ' has-src' : '') + ' ' + className} role="img" aria-label={alt || label || 'Meal photo'} style={s}>
      {src ? null : <Icon name="image" size={Math.max(18, Math.min(32, Math.round(n * 0.36)))} />}
      {!src && label ? <span>{label}</span> : null}
    </div>
  );
}
