import type { ReactElement } from "react";
import type { SkillConstraintIcon } from "../../types/api";

/**
 * Dessin des 8 familles d'icône d'étiquette. La console n'affiche pas la valeur
 * brute de l'enum : un éditeur doit voir ce que le candidat verra, sinon il
 * choisit un mot-clé au lieu d'un signe. Les deux fronts mappent la même liste
 * fermée sur leur bibliothèque Lucide — ces tracés en sont l'équivalent local,
 * l'admin n'embarquant aucune librairie d'icônes.
 */
const PATHS: Record<SkillConstraintIcon, ReactElement> = {
  TONE: (
    <path d="M20.4 5.1a4.8 4.8 0 0 0-6.8 0L12 6.7l-1.6-1.6a4.8 4.8 0 1 0-6.8 6.8L12 20.3l8.4-8.4a4.8 4.8 0 0 0 0-6.8z" />
  ),
  PERSON: (
    <>
      <circle cx="12" cy="8" r="3.6" />
      <path d="M4.5 20.5a7.5 7.5 0 0 1 15 0" />
    </>
  ),
  TIME: (
    <>
      <circle cx="12" cy="12" r="8.5" />
      <polyline points="12 6.8 12 12 15.6 14" />
    </>
  ),
  PLACE: (
    <>
      <path d="M12 21.5s6.8-6 6.8-10.6a6.8 6.8 0 1 0-13.6 0C5.2 15.5 12 21.5 12 21.5z" />
      <circle cx="12" cy="10.6" r="2.4" />
    </>
  ),
  NUMBER: (
    <>
      <line x1="4.5" y1="9.5" x2="19.5" y2="9.5" />
      <line x1="4.5" y1="15" x2="19.5" y2="15" />
      <line x1="10" y1="4" x2="8.5" y2="20.5" />
      <line x1="15.5" y1="4" x2="14" y2="20.5" />
    </>
  ),
  TENSE: (
    <>
      <path d="M3.6 12a8.5 8.5 0 1 0 2.5-6" />
      <polyline points="3.2 3.4 3.2 8.4 8.2 8.4" />
      <polyline points="12 7.6 12 12 15 13.8" />
    </>
  ),
  STRUCTURE: (
    <>
      <circle cx="5.2" cy="7" r="1.4" />
      <circle cx="5.2" cy="12.5" r="1.4" />
      <circle cx="5.2" cy="18" r="1.4" />
      <line x1="9.6" y1="7" x2="19.5" y2="7" />
      <line x1="9.6" y1="12.5" x2="19.5" y2="12.5" />
      <line x1="9.6" y1="18" x2="19.5" y2="18" />
    </>
  ),
  EXAMPLE: (
    <path d="M12 3.2l2.3 5.6 5.6 2.3-5.6 2.3L12 19l-2.3-5.6L4.1 11.1l5.6-2.3z" />
  ),
};

export function ConstraintIcon({
  icon,
  size = 16,
  className,
}: {
  icon: SkillConstraintIcon;
  size?: number;
  className?: string;
}) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {PATHS[icon]}
    </svg>
  );
}
