import * as React from 'react';

/**
 * Pill text input with optional leading icon; doubles as the search field.
 */
export interface TextFieldProps {
  value?: string;
  onChange?: (value: string, event?: React.ChangeEvent<HTMLInputElement>) => void;
  placeholder?: string;
  /** Leading Phosphor icon name, e.g. "magnifying-glass". */
  icon?: string;
  /** Node rendered at the trailing edge (e.g. a mic IconButton). */
  trailing?: React.ReactNode;
  /** Show a clear button when there is a value. */
  clearable?: boolean;
  size?: 'md' | 'lg';
  /** fill = tinted (on cards/sheets), card = white (directly on the app background). */
  surface?: 'fill' | 'card';
  className?: string;
}

export declare function TextField(props: TextFieldProps): JSX.Element;
