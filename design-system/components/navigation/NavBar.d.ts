import * as React from 'react';

/**
 * Screen header with leading/trailing slots and an optional serif large title.
 */
export interface NavBarProps {
  /** Small centered title (inline bar). */
  title?: React.ReactNode;
  /** Large serif title below the bar. */
  largeTitle?: React.ReactNode;
  subtitle?: React.ReactNode;
  leading?: React.ReactNode;
  trailing?: React.ReactNode;
  className?: string;
}

export declare function NavBar(props: NavBarProps): JSX.Element;
