import * as React from 'react';

/**
 * Minus / value / plus quantity control in 0.5 increments.
 */
export interface StepperProps {
  value?: number;
  onChange?: (value: number) => void;
  /** Default 0.5. */
  step?: number;
  min?: number;
  max?: number;
  format?: (value: number) => React.ReactNode;
  label?: string;
  className?: string;
}

export declare function Stepper(props: StepperProps): JSX.Element;
