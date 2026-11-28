import React from 'react';
import { Icon } from '../core/Icon.jsx';

const STATES = {
  synced: ['cloud-check', 'Synced'],
  syncing: ['arrows-clockwise', 'Syncing…'],
  offline: ['cloud-slash', 'Offline · Queued'],
};

export function SyncPill({ status = 'synced', queued, className = '', ...rest }) {
  const s = STATES[status] || STATES.synced;
  const label = status === 'offline' && queued ? 'Offline · ' + queued + ' queued' : s[1];
  return (
    <button type="button" className={'nn-sync nn-sync--' + status + ' ' + className} {...rest}>
      <Icon name={s[0]} size={14} weight="bold" className={status === 'syncing' ? 'nn-spin' : ''} />
      <span>{label}</span>
    </button>
  );
}
