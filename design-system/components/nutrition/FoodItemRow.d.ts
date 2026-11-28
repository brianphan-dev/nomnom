import * as React from 'react';

/**
 * Detected food item on AI Review: name, serving, kcal, Check badge and an expandable portion-multiplier panel.
 */
export interface FoodItemRowProps {
  name: string;
  /** e.g. "1 fillet (~150g)". */
  serving?: string;
  /** Calories at 1× portion. Displayed value is kcal × multiplier. */
  kcal?: number;
  /** AI confidence 0–1. Below threshold shows the amber Check badge. */
  confidence?: number;
  multiplier?: number;
  onMultiplier?: (multiplier: number) => void;
  /** Show portion pills and Swap / Remove. */
  expanded?: boolean;
  onToggle?: () => void;
  onSwap?: () => void;
  onRemove?: () => void;
  /** Default 0.76. */
  threshold?: number;
  className?: string;
}

export declare function FoodItemRow(props: FoodItemRowProps): JSX.Element;
