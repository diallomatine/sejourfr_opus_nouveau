import type { AdminSuiviResponse, SuiviIndicator } from "../../types/api";
import { dayMonth } from "./dates";

/**
 * Pourquoi une valeur est `null` (Q16, D43, D117). Le serveur rend `null`
 * quand l'indicateur n'a pas de date de debut de mesure, ou quand la periode
 * tombe ENTIEREMENT avant cette date : un compteur qui n'existait pas n'a rien
 * compte, il n'a pas compte zero.
 */
export function unmeasuredNote(data: AdminSuiviResponse, indicator: SuiviIndicator): string {
  const start = data.measurementStart[indicator] ?? null;
  if (start == null) return "non mesuré";
  if (start > data.window.to) return `mesuré à partir du ${dayMonth(start)}`;
  return "inconnu";
}

/**
 * Mention d'une periode qui CHEVAUCHE la date de debut de mesure (D117) : le
 * serveur sert alors les chiffres depuis cette date, jamais avant. `null` si
 * la periode entiere est mesuree (ou pas du tout).
 */
export function measuredSinceNote(
  data: AdminSuiviResponse,
  indicator: SuiviIndicator,
): string | null {
  const start = data.measurementStart[indicator] ?? null;
  if (start == null || start <= data.window.from || start > data.window.to) return null;
  return `mesuré depuis le ${dayMonth(start)}`;
}

