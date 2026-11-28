import * as React from 'react';

/**
 * Inline notice for quota, offline and import explanations.
 */
export interface BannerProps {
  tone?: 'neutral' | 'check' | 'info' | 'accent';
  /** Phosphor icon name. */
  icon?: string;
  title?: React.ReactNode;
  children?: React.ReactNode;
  /** Trailing action, usually a small Button. */
  action?: React.ReactNode;
  className?: string;
}

export declare function Banner(props: BannerProps): JSX.Element;
