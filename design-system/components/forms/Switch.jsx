import React from 'react';

export function Switch({ checked, onChange, disabled, label, className = '', ...rest }) {
  return (
    <button type="button" role="switch" aria-checked={!!checked} aria-label={label} disabled={disabled} className={'nn-switch' + (checked ? ' is-on' : '') + ' ' + className} onClick={() => onChange && onChange(!checked)} {...rest}>
      <span className="nn-switch__knob" />
    </button>
  );
}
