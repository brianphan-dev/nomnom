import React from 'react';

export function NavBar({ title, largeTitle, subtitle, leading, trailing, className = '' }) {
  return (
    <header className={'nn-nav ' + className}>
      <div className="nn-nav__bar">
        <div className="nn-nav__side">{leading}</div>
        {title ? <div className="nn-nav__title">{title}</div> : null}
        <div className="nn-nav__side nn-nav__side--end">{trailing}</div>
      </div>
      {largeTitle ? <h1 className="nn-nav__large">{largeTitle}</h1> : null}
      {subtitle ? <div className="nn-nav__subtitle">{subtitle}</div> : null}
    </header>
  );
}
