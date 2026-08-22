import type { ReactNode } from "react";

/**
 * Jeu d'icones de l'ecran, dessine a la main. L'admin n'embarque aucune
 * librairie d'icones (meme parti pris que `ConstraintIcon` cote Competences).
 */
export type IconName =
  | "up"
  | "down"
  | "flat"
  | "calendar"
  | "chevron"
  | "right"
  | "close"
  | "alert"
  | "filter";

const PATHS: Record<IconName, ReactNode> = {
  up: (
    <>
      <path d="M12 19V5" />
      <path d="M6 11l6-6 6 6" />
    </>
  ),
  down: (
    <>
      <path d="M12 5v14" />
      <path d="M6 13l6 6 6-6" />
    </>
  ),
  flat: <path d="M5 12h14" />,
  calendar: (
    <>
      <rect x="3.5" y="5" width="17" height="15.5" rx="2.5" />
      <path d="M3.5 10h17" />
      <path d="M8 3v4M16 3v4" />
    </>
  ),
  chevron: <path d="M6 9l6 6 6-6" />,
  right: <path d="M9 6l6 6-6 6" />,
  close: <path d="M6 6l12 12M18 6L6 18" />,
  alert: (
    <>
      <path d="M12 4.5 21 20H3z" />
      <path d="M12 10v4.5" />
      <path d="M12 17.4v.2" />
    </>
  ),
  filter: (
    <>
      <path d="M4 6h16" />
      <path d="M7 12h10" />
      <path d="M10 18h4" />
    </>
  ),
};

interface IconProps {
  name: IconName;
  size?: number;
  stroke?: number;
}

export function Icon({ name, size = 16, stroke = 1.9 }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={stroke}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {PATHS[name]}
    </svg>
  );
}
