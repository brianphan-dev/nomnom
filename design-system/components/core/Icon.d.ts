import * as React from 'react';

/**
 * Phosphor icon-font glyph; use for every icon in the product.
 */
export interface IconProps {
  /** Phosphor icon name without the "ph-" prefix, e.g. "camera", "barcode", "cloud-check". */
  name: string;
  /** Pixel size. Default 20. */
  size?: number;
  /** "regular" for most UI, "bold" inside buttons and badges, "fill" for the shutter and selected states. */
  weight?: 'regular' | 'bold' | 'fill';
  color?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function Icon(props: IconProps): JSX.Element;
