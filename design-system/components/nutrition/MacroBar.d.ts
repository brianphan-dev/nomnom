import * as React from 'react';

/**
 * Labelled macro progress: value over target with a coloured bar.
 */
export interface MacroBarProps {
  macro?: 'protein' | 'carbs' | 'fat';
  /** Grams logged. */
  value?: number;
  /** Daily target in grams. */
  target?: number;
  label?: string;
  /** Single-line header for tight layouts. */
  compact?: boolean;
  className?: string;
}

export declare function MacroBar(props: MacroBarProps): JSX.Element;
