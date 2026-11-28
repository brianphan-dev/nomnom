import React from 'react';
import { Icon } from '../core/Icon.jsx';

export function Banner({ tone = 'neutral', icon, title, children, action, className = '' }) {
  return (
    <div className={'nn-banner nn-banner--' + tone + ' ' + className} role="status">
      {icon ? <Icon name={icon} size={20} className="nn-banner__icon" /> : null}
      <div className="nn-banner__body">
        {title ? <div className="nn-banner__title">{title}</div> : null}
        {children ? <div className="nn-banner__text">{children}</div> : null}
      </div>
      {action ? <div className="nn-banner__action">{action}</div> : null}
    </div>
  );
}
