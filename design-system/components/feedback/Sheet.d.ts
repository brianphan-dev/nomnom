import * as React from 'react';

/**
 * Bottom sheet with grabber for product match, serving calculator and pickers.
 */
export interface SheetProps {
  open?: boolean;
  onClose?: () => void;
  title?: React.ReactNode;
  children?: React.ReactNode;
  /** Pinned below the scrolling body, usually the primary Button. */
  footer?: React.ReactNode;
  /** Show the dimming scrim. Default true. */
  scrim?: boolean;
  className?: string;
}

export declare function Sheet(props: SheetProps): JSX.Element;
