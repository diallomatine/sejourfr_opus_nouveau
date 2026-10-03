import type { AdminSuiviResponse, SuiviIndicator } from "../../types/api";
import * as measurement from "../../lib/measurement";

/** `lib/measurement.ts` lu sur la réponse Suivi (date de début et bornes servies). */
export function unmeasuredNote(data: AdminSuiviResponse, indicator: SuiviIndicator): string {
  return measurement.unmeasuredNote(data.measurementStart[indicator], data.window.to);
}

export function measuredSinceNote(
  data: AdminSuiviResponse,
  indicator: SuiviIndicator,
): string | null {
  return measurement.measuredSinceNote(
    data.measurementStart[indicator],
    data.window.from,
    data.window.to,
  );
}
