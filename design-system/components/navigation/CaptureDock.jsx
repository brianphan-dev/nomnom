import React from 'react';
import { Icon } from '../core/Icon.jsx';

export function CaptureDock({ onSnap, onBarcode, onManual, compact, className = '' }) {
  return (
    <div className={'nn-dock' + (compact ? ' nn-dock--compact' : '') + ' ' + className}>
      <button type="button" className="nn-dock__side" onClick={onBarcode}><Icon name="barcode" size={24} /><span>Barcode</span></button>
      <button type="button" className="nn-dock__snap" aria-label="Snap plate" onClick={onSnap}><Icon name="camera" size={compact ? 26 : 30} weight="fill" /></button>
      <button type="button" className="nn-dock__side" onClick={onManual}><Icon name="pencil-simple" size={24} /><span>Manual</span></button>
    </div>
  );
}
