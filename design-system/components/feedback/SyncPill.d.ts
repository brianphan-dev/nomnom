import * as React from 'react';

/**
 * Quiet cloud-sync status pill for the Today header: Synced, Syncing…, Offline · Queued.
 */
export interface SyncPillProps {
  status?: 'synced' | 'syncing' | 'offline';
  /** Number of queued changes shown when offline. */
  queued?: number;
  onClick?: React.MouseEventHandler<HTMLButtonElement>;
  className?: string;
}

export declare function SyncPill(props: SyncPillProps): JSX.Element;
