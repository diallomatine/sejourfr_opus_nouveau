import { dayMonth } from "./dates";

/**
 * Pourquoi une valeur servie est `null` (Q16, D43, D117), à partir de la date
 * de début de mesure de son indicateur et de la dernière borne servie : un
 * compteur qui n'existait pas n'a rien compté, il n'a pas compté zéro.
 */
export function unmeasuredNote(start: string | null | undefined, servedTo: string): string {
  if (start == null) return "non mesuré";
  if (start > servedTo) return `mesuré à partir du ${dayMonth(start)}`;
  return "inconnu";
}

/**
 * Mention d'une période servie qui CHEVAUCHE la date de début de mesure
 * (D117) : la valeur part de cette date. `null` si la période entière est
 * mesurée (ou pas du tout).
 */
export function measuredSinceNote(
  start: string | null | undefined,
  servedFrom: string,
  servedTo: string,
): string | null {
  if (start == null || start <= servedFrom || start > servedTo) return null;
  return `mesuré depuis le ${dayMonth(start)}`;
}
