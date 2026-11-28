import * as React from 'react';

/**
 * Pill-shaped action button; one accent button per screen, everything else primary/secondary/ghost.
 */
export interface ButtonProps {
  /** primary = ink, accent = persimmon (capture/save only), secondary = tinted fill, ghost = text only, destructive = beet tint. */
  variant?: 'primary' | 'accent' | 'secondary' | 'ghost' | 'destructive';
  /** sm 32px, md 44px (default), lg 56px. */
  size?: 'sm' | 'md' | 'lg';
  /** Leading Phosphor icon name. */
  icon?: string;
  iconRight?: string;
  iconWeight?: 'regular' | 'bold' | 'fill';
  fullWidth?: boolean;
  loading?: boolean;
  disabled?: boolean;
  children?: React.ReactNode;
  onClick?: React.MouseEventHandler<HTMLButtonElement>;
  className?: string;
}

export declare function Button(props: ButtonProps): JSX.Element;
