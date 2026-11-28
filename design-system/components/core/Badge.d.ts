import * as React from 'react';

/**
 * Small pill label for capture method, AI confidence ("Check") and pending states.
 */
export interface BadgeProps {
  /** neutral (default), accent, check (amber, low AI confidence), positive, info, pending (outlined). */
  tone?: 'neutral' | 'accent' | 'check' | 'positive' | 'info' | 'pending';
  /** Phosphor icon name. */
  icon?: string;
  /** Shortcut: sets icon + label for a capture method. */
  method?: 'photo_ai' | 'barcode' | 'label_ocr' | 'manual' | 'imported';
  children?: React.ReactNode;
  className?: string;
}

export declare function Badge(props: BadgeProps): JSX.Element;
