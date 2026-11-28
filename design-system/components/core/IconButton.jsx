import React from 'react';
import { Icon } from './Icon.jsx';

export function IconButton({ icon, label, variant = 'plain', size = 44, iconSize, weight = 'regular', className = '', style, ...rest }) {
  return (
    <button type="button" aria-label={label} className={'nn-iconbtn nn-iconbtn--' + variant + ' ' + className} style={{ width: size, height: size, ...style }} {...rest}>
      <Icon name={icon} size={iconSize || Math.round(size * 0.5)} weight={weight} />
    </button>
  );
}
