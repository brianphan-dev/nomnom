import React from 'react';

export function Sheet({ open, onClose, title, children, footer, scrim = true, className = '' }) {
  return (
    <div className={'nn-sheet-layer' + (open ? ' is-open' : '')} aria-hidden={!open}>
      {scrim ? <div className="nn-scrim" onClick={onClose} /> : null}
      <div className={'nn-sheet ' + className} role="dialog" aria-label={typeof title === 'string' ? title : undefined}>
        <div className="nn-sheet__grabber" />
        {title ? <div className="nn-sheet__title">{title}</div> : null}
        <div className="nn-sheet__body">{children}</div>
        {footer ? <div className="nn-sheet__footer">{footer}</div> : null}
      </div>
    </div>
  );
}
