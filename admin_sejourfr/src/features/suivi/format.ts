/**
 * Formatage fr-FR de l'ecran Suivi, tenu d'un seul endroit :
 *
 *  1. separateur de milliers et espace avant `%` / `€` = ESPACE FINE INSECABLE
 *     (U+202F) ; `toLocaleString` rend une insecable normale ou une espace
 *     ordinaire selon le moteur, d'ou le remplacement ;
 *  2. signe moins typographique (U+2212) ;
 *  3. une valeur ABSENTE se dit `—`, jamais `0` : « aucun achat » et « on ne
 *     sait pas » sont deux phrases differentes.
 *
 * Aucun pourcentage n'est calcule ici : ceux qui s'affichent sont servis.
 */

export const NB = "\u202f";
export const DASH = "\u2014";
const MINUS = "\u2212";

function groupThousands(text: string): string {
  return text.replace(/[\u00a0\u202f\s]/g, NB);
}

export function int(value: number | null | undefined): string {
  if (value == null || !Number.isFinite(value)) return DASH;
  return groupThousands(Math.round(value).toLocaleString("fr-FR"));
}

/**
 * Pourcentage SERVI en pourcent a une decimale (64.0 → « 64 % »,
 * 11.4 → « 11,4 % »). La decimale nulle est omise, comme dans le template.
 */
export function pct(value: number | null | undefined): string {
  if (value == null || !Number.isFinite(value)) return DASH;
  return `${groupThousands(
    value.toLocaleString("fr-FR", { maximumFractionDigits: 1 }),
  )}${NB}%`;
}

/** Variation servie, toujours signee : « +12,4 % », « −3 % ». */
export function signedPct(value: number | null | undefined): string {
  if (value == null || !Number.isFinite(value)) return DASH;
  const sign = value > 0 ? "+" : value < 0 ? MINUS : "";
  return `${sign}${pct(Math.abs(value))}`;
}

/** Centimes d'euro → « 156,42 € ». */
export function money(cents: number | null | undefined): string {
  if (cents == null || !Number.isFinite(cents)) return DASH;
  const text = groupThousands(
    Math.abs(cents / 100).toLocaleString("fr-FR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }),
  );
  return `${cents < 0 ? MINUS : ""}${text}${NB}€`;
}

/** Montant retire (TVA, frais) : « −33,30 € », « 0,00 € » s'il est nul. */
export function deduction(cents: number | null | undefined): string {
  if (cents == null || !Number.isFinite(cents)) return DASH;
  return cents === 0 ? money(0) : money(-Math.abs(cents));
}

/** « 12 achats », « 1 achat », « — achats ». */
export function count(value: number | null | undefined, one: string, many: string): string {
  return `${int(value)} ${value === 1 ? one : many}`;
}
