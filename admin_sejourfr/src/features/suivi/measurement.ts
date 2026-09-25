import type { AdminSuiviResponse, SuiviIndicator } from "../../types/api";
import { dayMonth } from "./dates";

/**
 * Pourquoi une valeur est `null` (Q16, D43). Le serveur rend `null` quand
 * l'indicateur n'a pas de date de debut de mesure, ou quand cette date tombe
 * apres le debut de la periode : un compteur qui n'existait pas n'a rien
 * compte, il n'a pas compte zero.
 */
export function unmeasuredNote(data: AdminSuiviResponse, indicator: SuiviIndicator): string {
  const start = data.measurementStart[indicator] ?? null;
  if (start == null) return "non mesuré";
  if (start > data.window.from) return `mesuré depuis le ${dayMonth(start)}`;
  return "inconnu";
}

/** Vrai si l'indicateur n'a aucune date de debut de mesure. */
export function isUnmeasured(data: AdminSuiviResponse, indicator: SuiviIndicator): boolean {
  return (data.measurementStart[indicator] ?? null) == null;
}
