import React from 'react';
import { Icon } from '../core/Icon.jsx';

export function ListRow({ icon, title, subtitle, value, chevron, trailing, tone = 'default', onClick, className = '' }) {
  const Tag = onClick ? 'button' : 'div';
  return (
    <Tag type={onClick ? 'button' : undefined} className={'nn-row nn-row--' + tone + ' ' + className} onClick={onClick}>
      {icon ? <span className="nn-row__icon"><Icon name={icon} size={18} /></span> : null}
      <span className="nn-row__text">
        <span className="nn-row__title">{title}</span>
        {subtitle ? <span className="nn-row__subtitle">{subtitle}</span> : null}
      </span>
      {value ? <span className="nn-row__value">{value}</span> : null}
      {trailing}
      {chevron ? <Icon name="caret-right" size={14} weight="bold" color="var(--text-tertiary)" /> : null}
    </Tag>
  );
}
