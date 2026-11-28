import * as React from 'react';

/**
 * Inline P / C / F summary in Geist Mono with macro-coloured letters.
 */
export interface MacroLineProps {
  protein?: number;
  carbs?: number;
  fat?: number;
  size?: 'sm' | 'md';
  className?: string;
}

export declare function MacroLine(props: MacroLineProps): JSX.Element;
