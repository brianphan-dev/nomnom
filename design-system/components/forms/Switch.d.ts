import * as React from 'react';

/**
 * iOS-style toggle for settings rows.
 */
export interface SwitchProps {
  checked?: boolean;
  onChange?: (checked: boolean) => void;
  disabled?: boolean;
  /** Accessible label. */
  label?: string;
  className?: string;
}

export declare function Switch(props: SwitchProps): JSX.Element;
