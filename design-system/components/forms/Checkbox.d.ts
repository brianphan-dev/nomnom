import * as React from 'react';

/**
 * Circular checkbox row with label, description and trailing value; used in the Sauces, oils & seasonings drawer.
 */
export interface CheckboxProps {
  checked?: boolean;
  onChange?: (checked: boolean) => void;
  label?: React.ReactNode;
  description?: React.ReactNode;
  /** Trailing value, e.g. "+90 kcal". */
  trailing?: React.ReactNode;
  /** Strike through and dim the row when unchecked (item not consumed). */
  dimUnchecked?: boolean;
  disabled?: boolean;
  className?: string;
}

export declare function Checkbox(props: CheckboxProps): JSX.Element;
