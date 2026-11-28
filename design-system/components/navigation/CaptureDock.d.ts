import * as React from 'react';

/**
 * Floating thumb-zone capture bar: persimmon shutter flanked by Barcode and Manual. Replaces a tab bar on Today.
 */
export interface CaptureDockProps {
  onSnap?: () => void;
  onBarcode?: () => void;
  onManual?: () => void;
  /** Smaller variant for the iPhone Duo cover display. */
  compact?: boolean;
  className?: string;
}

export declare function CaptureDock(props: CaptureDockProps): JSX.Element;
