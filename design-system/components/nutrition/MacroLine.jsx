import React from 'react';

export function MacroLine({ protein, carbs, fat, size = 'sm', className = '' }) {
  const r = v => (v == null ? '–' : Math.round(v));
  return (
    <span className={'nn-macroline nn-macroline--' + size + ' nn-num ' + className}>
      <span><b className="nn-m-protein">P</b>{r(protein)}</span>
      <span><b className="nn-m-carbs">C</b>{r(carbs)}</span>
      <span><b className="nn-m-fat">F</b>{r(fat)}</span>
    </span>
  );
}
