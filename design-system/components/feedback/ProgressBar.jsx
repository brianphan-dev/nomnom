import React from 'react';

export function ProgressBar({ value = 0, max = 100, tone = 'accent', size = 6, label, className = '' }) {
  const pct = max > 0 ? Math.min(100, Math.max(0, (value / max) * 100)) : 0;
  return (
    <div className={'nn-progress nn-progress--' + tone + ' ' + className} role="progressbar" aria-label={label} aria-valuenow={Math.round(value)} aria-valuemin={0} aria-valuemax={max} style={{ height: size }}>
      <span style={{ width: pct + '%' }} />
    </div>
  );
}
