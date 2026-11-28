import React from 'react';

export function Icon({ name, size = 20, weight = 'regular', color, className = '', style, ...rest }) {
  const cls = (weight === 'regular' ? 'ph' : 'ph-' + weight) + ' ph-' + name + ' nn-icon ' + className;
  return <i className={cls} aria-hidden="true" style={{ fontSize: size, color, ...style }} {...rest} />;
}
