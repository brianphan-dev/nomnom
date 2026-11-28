import * as React from 'react';

/**
 * Centered confirmation alert (e.g. Delete account).
 */
export interface DialogProps {
  open?: boolean;
  title: string;
  children?: React.ReactNode;
  actions?: Array<{ label: React.ReactNode; variant?: 'primary' | 'accent' | 'secondary' | 'ghost' | 'destructive'; onClick?: () => void }>;
  onClose?: () => void;
}

export declare function Dialog(props: DialogProps): JSX.Element;
