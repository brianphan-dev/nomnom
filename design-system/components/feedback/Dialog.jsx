import React from 'react';
import { Button } from '../core/Button.jsx';

export function Dialog({ open, title, children, actions = [], onClose }) {
  if (!open) return null;
  return (
    <div className="nn-scrim nn-scrim--center" onClick={onClose}>
      <div className="nn-dialog" role="alertdialog" aria-modal="true" aria-label={title} onClick={e => e.stopPropagation()}>
        <h2 className="nn-dialog__title">{title}</h2>
        {children ? <div className="nn-dialog__body">{children}</div> : null}
        <div className="nn-dialog__actions">
          {actions.map((a, i) => <Button key={i} variant={a.variant || 'secondary'} fullWidth onClick={a.onClick}>{a.label}</Button>)}
        </div>
      </div>
    </div>
  );
}
