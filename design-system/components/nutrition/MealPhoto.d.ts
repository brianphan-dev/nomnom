import * as React from 'react';

/**
 * Meal photo thumbnail; renders a striped placeholder when no src is given.
 */
export interface MealPhotoProps {
  src?: string;
  alt?: string;
  /** Width and height (px number or CSS length). Default 56. */
  size?: number | string;
  radius?: number | string;
  /** Mono caption shown in the placeholder. */
  label?: string;
  /** dark = viewfinder placeholder. */
  tone?: 'light' | 'dark';
  className?: string;
  style?: React.CSSProperties;
}

export declare function MealPhoto(props: MealPhotoProps): JSX.Element;
