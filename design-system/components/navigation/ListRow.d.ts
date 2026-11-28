import * as React from 'react';

/**
 * Settings-style row with icon, title, subtitle, value and trailing control; stack inside a Card with padding="none".
 */
export interface ListRowProps {
  /** Phosphor icon name shown in a circular tile. */
  icon?: string;
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  value?: React.ReactNode;
  chevron?: boolean;
  /** Trailing control, e.g. a Switch. */
  trailing?: React.ReactNode;
  tone?: 'default' | 'destructive';
  onClick?: () => void;
  className?: string;
}

export declare function ListRow(props: ListRowProps): JSX.Element;
