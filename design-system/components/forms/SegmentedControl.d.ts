import * as React from 'react';

/**
 * Pill segmented control for capture mode, meal type and portion multipliers.
 */
export interface SegmentedControlProps {
  options: Array<string | number | { value: string | number; label: React.ReactNode; icon?: string }>;
  value?: string | number;
  onChange?: (value: any) => void;
  /** md 44px track (default), sm 36px track. */
  size?: 'sm' | 'md';
  /** dark = glass track for use over the camera viewfinder. */
  tone?: 'default' | 'dark';
  fullWidth?: boolean;
  /** Render labels in Geist Mono (portion multipliers). */
  numeric?: boolean;
  className?: string;
}

export declare function SegmentedControl(props: SegmentedControlProps): JSX.Element;
