import * as React from 'react';

/**
 * Selectable pill for serving units, context hints and filters.
 */
export interface ChipProps {
  selected?: boolean;
  /** Phosphor icon name. */
  icon?: string;
  size?: 'sm' | 'md' | 'lg';
  children?: React.ReactNode;
  onClick?: React.MouseEventHandler<HTMLButtonElement>;
  className?: string;
}

export declare function Chip(props: ChipProps): JSX.Element;
