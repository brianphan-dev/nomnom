import * as React from 'react';

/**
 * Meal timeline row: thumbnail, title, meal type and time, capture badge, macros and kcal.
 */
export interface MealRowProps {
  title: string;
  time?: string;
  mealType?: 'Breakfast' | 'Lunch' | 'Dinner' | 'Snack' | string;
  kcal?: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  method?: 'photo_ai' | 'barcode' | 'label_ocr' | 'manual' | 'imported';
  /** Photo URL; placeholder when omitted. */
  photo?: string;
  /** Offline capture waiting for AI analysis. */
  pending?: boolean;
  selected?: boolean;
  onClick?: () => void;
  className?: string;
}

export declare function MealRow(props: MealRowProps): JSX.Element;
