import React from 'react';

export function Card({ tone = 'surface', padding = 'lg', as: Tag = 'div', className = '', children, ...rest }) {
  return <Tag className={'nn-card nn-card--' + tone + ' nn-card--p-' + padding + ' ' + className} {...rest}>{children}</Tag>;
}
