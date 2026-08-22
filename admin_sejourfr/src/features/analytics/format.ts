/**
 * Formatage francais de l'ecran Analytics. Trois regles y sont tenues d'un seul
 * endroit, parce qu'elles sont fausses des qu'un composant les recopie :
 *
 *  1. le separateur de milliers et l'espace avant `%` / `€` sont une ESPACE
 *     FINE INSECABLE (U+202F) — `toLocaleString` rend une insecable normale
 *     (U+00A0) ou une espace ordinaire selon le moteur, d'ou le remplacement ;
 *  2. le signe moins est le vrai signe mathematique (U+2212), pas un trait
 *     d'union ;
 *  3. une valeur ABSENTE se dit `—`, jamais `0`. « Aucun paiement » et « on ne
 *     sait pas » sont deux phrases differentes.
 */

/** Espace fine insecable. */
export const NB = "\u202f";

/** Signe moins typographique. */
const MINUS = "\u2212";

/** Valeur non mesuree. */
export const DASH = "\u2014";

function groupThousands(text: string): string {
  return text.replace(/[\u00a0\u202f\s]/g, NB);
}

export function int(value: number | null | undefined): string {
  if (value == null || !isFinite(value)) return DASH;
  return groupThousands(Math.round(value).toLocaleString("fr-FR"));
}

/** Pourcentage. `digits` par defaut a 1 decimale, comme la maquette. */
export function pct(value: number | null | undefined, digits = 1): string {
  if (value == null || !isFinite(value)) return DASH;
  return `${(value * 100).toFixed(digits).replace(".", ",")}${NB}%`;
}

/** Montant en centimes d'euro → « 19,99 € ». */
export function money(cents: number | null | undefined): string {
  if (cents == null || !isFinite(cents)) return DASH;
  const euros = cents / 100;
  return `${groupThousands(
    euros.toLocaleString("fr-FR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }),
  )}${NB}€`;
}

/** Montant arrondi a l'euro — axes de graphe, ou les decimales sont du bruit. */
export function money0(cents: number | null | undefined): string {
  if (cents == null || !isFinite(cents)) return DASH;
  return `${int(cents / 100)}${NB}€`;
}

/**
 * Variation relative. `null` des que la periode precedente vaut zero : on ne
 * divise pas par zero, et « on partait de rien » n'est pas « +100 % ».
 */
export function delta(current: number, previous: number): number | null {
  if (!previous || !isFinite(previous)) return null;
  const value = (current - previous) / previous;
  return isFinite(value) ? value : null;
}

/** Variation signee, avec le vrai signe moins. */
export function deltaPct(value: number | null): string {
  if (value == null || !isFinite(value)) return DASH;
  const sign = value >= 0 ? "+" : MINUS;
  const digits = Math.abs(value) < 0.1 ? 1 : 0;
  return `${sign}${Math.abs(value * 100).toFixed(digits).replace(".", ",")}${NB}%`;
}

/**
 * Rapport de deux mesures. `null` quand la base est nulle — c'est ce qui fait
 * apparaitre `—` au lieu d'un « 0,0 % » qu'on lirait comme une mesure.
 */
export function rate(value: number, base: number): number | null {
  if (!base || !isFinite(base)) return null;
  return value / base;
}

/** Largeur de barre bornee, en pourcentage d'une base. */
export function barWidth(value: number, base: number, min = 1.5): string {
  if (!base || !isFinite(base)) return `${min}%`;
  return `${Math.max(min, Math.min(100, (value / base) * 100))}%`;
}

/** « 3 personnes » / « 1 personne ». */
export function plural(value: number, one: string, many: string): string {
  return Math.round(value) > 1 ? many : one;
}

/**
 * Degrade du bleu SejourFR, du plus fonce au plus clair. Sert aux barres
 * successives d'un entonnoir : la couleur vient du token, jamais d'un hex.
 */
export function blueStep(index: number, total: number): string {
  const ratio = total <= 1 ? 0 : index / (total - 1);
  const weight = Math.round(100 - ratio * 45);
  return `color-mix(in srgb, var(--blue) ${weight}%, var(--paper))`;
}
