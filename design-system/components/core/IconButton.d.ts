import * as React from 'react';

/**
 * Circular icon-only button for nav bars, camera overlays and inline actions.
 */
export interface IconButtonProps {
  /** Phosphor icon name. */
  icon: string;
  /** Accessible label (required, no visible text). */
  label: string;
  /** plain = no fill, filled = tinted, ink = solid dark, accent = persimmon, glass = translucent over camera/photo. */
  variant?: 'plain' | 'filled' | 'ink' | 'accent' | 'glass';
  /** Diameter in px. Default 44 (minimum tap target). */
  size?: number;
  iconSize?: number;
  weight?: 'regular' | 'bold' | 'fill';
  disabled?: boolean;
  onClick?: React.MouseEventHandler<HTMLButtonElement>;
  className?: string;
  style?: React.CSSProperties;
}

export declare function IconButton(props: IconButtonProps): JSX.Element;
