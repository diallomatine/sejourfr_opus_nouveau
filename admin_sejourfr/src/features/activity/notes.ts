import { measuredSinceNote, unmeasuredNote } from "../../lib/measurement";
import type { ActivityIndicator, AdminActivityResponse } from "../../types/api";

/** Raison d'une valeur `null` de la réponse, lue sur la date de début de l'indicateur. */
export function activityUnmeasured(data: AdminActivityResponse, indicator: ActivityIndicator): string {
  return unmeasuredNote(data.measurementStart[indicator], data.window.to);
}

/** « mesuré depuis le JJ/MM » quand le bloc n'est servi qu'à partir d'un jour de la période. */
export function activityMeasuredSince(
  data: AdminActivityResponse,
  measuredSince: string | null,
): string | null {
  return measuredSinceNote(measuredSince, data.window.from, data.window.to);
}
