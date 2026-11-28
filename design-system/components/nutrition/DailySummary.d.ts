import * as React from 'react';

/**
 * Daily summary card: calories logged vs target, three macro bars, expandable micronutrients.
 */
export interface DailySummaryProps {
  kcal?: number;
  target?: number;
  protein?: { value: number; target?: number };
  carbs?: { value: number; target?: number };
  fat?: { value: number; target?: number };
  /** Expandable micronutrient list, e.g. { label: 'Fiber', value: '18 g' }. */
  micros?: Array<{ label: string; value: string }>;
  defaultExpanded?: boolean;
  /** Condensed layout for the iPhone Duo cover display. */
  compact?: boolean;
  className?: string;
}

export declare function DailySummary(props: DailySummaryProps): JSX.Element;
