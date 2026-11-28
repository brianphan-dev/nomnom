import React from 'react';
import { Icon } from './Icon.jsx';

const METHODS = {
  photo_ai: ['Photo AI', 'sparkle'],
  barcode: ['Barcode', 'barcode'],
  label_ocr: ['Label', 'scan'],
  manual: ['Manual', 'pencil-simple'],
  imported: ['Imported', 'download-simple'],
};

export function Badge({ tone = 'neutral', icon, method, children, className = '', ...rest }) {
  const m = method ? METHODS[method] : null;
  const ic = icon || (m && m[1]);
  return (
    <span className={'nn-badge nn-badge--' + tone + ' ' + className} {...rest}>
      {ic ? <Icon name={ic} size={12} weight="bold" /> : null}
      {children || (m && m[0])}
    </span>
  );
}
