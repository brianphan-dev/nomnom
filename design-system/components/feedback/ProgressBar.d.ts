import * as React from 'react';

/**
 * Rounded progress track for calories and macros.
 */
export interface ProgressBarProps {
  value?: number;
  max?: number;
  /** accent = calories; protein / carbs / fat = macro hues; neutral = ink. */
  tone?: 'accent' | 'protein' | 'carbs' | 'fat' | 'neutral';
  /** Track height in px. Default 6. */
  size?: number;
  /** Accessible label. */
  label?: string;
  className?: string;
}

export declare function ProgressBar(props: ProgressBarProps): JSX.Element;
