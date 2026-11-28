import * as React from 'react';

/**
 * Rounded surface container (28px radius, no shadow) for grouped content.
 */
export interface CardProps {
  /** surface = white card, sunken = tinted fill, outline = hairline only, accent = persimmon tint. */
  tone?: 'surface' | 'sunken' | 'outline' | 'accent';
  /** none (for lists of rows), md 16px, lg 20px (default). */
  padding?: 'none' | 'md' | 'lg';
  as?: keyof JSX.IntrinsicElements;
  children?: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
}

export declare function Card(props: CardProps): JSX.Element;
