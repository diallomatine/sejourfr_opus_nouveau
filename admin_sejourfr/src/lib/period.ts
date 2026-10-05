import type { SuiviPeriodPreset, SuiviRange } from "../types/api";
import { MONTH_PATTERN, monthBounds, parisCurrentMonth } from "./dates";

/**
 * Période d'un écran de pilotage (Suivi, Activité) : un preset du serveur ou
 * une plage personnalisée `from`/`to`. La table des jours couverts vit côté
 * serveur (`SuiviPeriodPreset.window`) ; ici, seulement l'identifiant d'URL,
 * le libellé du sélecteur et la lecture/écriture de `?period&from&to`.
 */
export type PeriodId = "today" | "yesterday" | "7d" | "30d" | "month" | "custom";

export type PresetPeriodId = Exclude<PeriodId, "custom">;

const PRESETS: Record<PresetPeriodId, SuiviPeriodPreset> = {
  today: "TODAY",
  yesterday: "YESTERDAY",
  "7d": "LAST_7_DAYS",
  "30d": "LAST_30_DAYS",
  month: "MONTH",
};

export const PERIOD_LABELS: Record<PeriodId, string> = {
  today: "Aujourd’hui",
  yesterday: "Hier",
  "7d": "7 jours",
  "30d": "30 jours",
  month: "Mois",
  custom: "Personnalisé",
};

const ISO_DAY = /^\d{4}-\d{2}-\d{2}$/;

export interface PeriodState {
  period: PeriodId;
  from: string;
  to: string;
  /** Mois choisi sous « Mois » (`yyyy-MM`), le mois courant par défaut. */
  month: string;
  range: SuiviRange;
}

/**
 * Lit la période de l'URL parmi celles qu'offre l'écran. Valeur illisible ou
 * non offerte ⇒ « Aujourd'hui » ; plage personnalisée incomplète ou inversée
 * ⇒ « Aujourd'hui » aussi (elle partirait en 400).
 */
export function readPeriod(params: URLSearchParams, offered: readonly PeriodId[]): PeriodState {
  const raw = params.get("period");
  const from = params.get("from") ?? "";
  const to = params.get("to") ?? "";
  const customValid =
    raw === "custom" &&
    offered.includes("custom") &&
    ISO_DAY.test(from) &&
    ISO_DAY.test(to) &&
    from <= to;
  const current = parisCurrentMonth();
  if (customValid) return { period: "custom", from, to, month: current, range: { from, to } };
  const period =
    raw != null && raw !== "custom" && Object.hasOwn(PRESETS, raw) && offered.includes(raw as PeriodId)
      ? (raw as PresetPeriodId)
      : "today";
  // « Mois » : le mois courant passe par le preset du serveur (à date) ; un mois
  // passé part en plage du 1er au dernier jour. Un mois illisible ou futur ⇒ courant.
  const rawMonth = params.get("month") ?? "";
  if (period === "month" && MONTH_PATTERN.test(rawMonth) && rawMonth < current) {
    return { period, from, to, month: rawMonth, range: monthBounds(rawMonth) };
  }
  return { period, from, to, month: current, range: { preset: PRESETS[period] } };
}

export interface PeriodPatch {
  period?: PeriodId;
  from?: string;
  to?: string;
  month?: string;
}

/** Écrit la période dans l'URL ; le défaut n'est pas écrit, un preset efface la plage. */
export function writePeriod(next: URLSearchParams, patch: PeriodPatch): void {
  const write = (key: string, value: string | null) => {
    if (value) next.set(key, value);
    else next.delete(key);
  };
  if (patch.period !== undefined) {
    write("period", patch.period === "today" ? null : patch.period);
    if (patch.period !== "custom") {
      next.delete("from");
      next.delete("to");
    }
    if (patch.period !== "month") next.delete("month");
  }
  if (patch.month !== undefined) {
    write("month", patch.month === parisCurrentMonth() ? null : patch.month);
  }
  if (patch.from !== undefined) write("from", patch.from);
  if (patch.to !== undefined) write("to", patch.to);
}

/** `preset` OU `from`/`to`, jamais les deux (400) : la forme de `SuiviRange` le garantit. */
export function rangeParams(range: SuiviRange): Record<string, string> {
  return "preset" in range ? { preset: range.preset } : { from: range.from, to: range.to };
}

/** Période de comparaison des tendances, telle que le serveur la choisit. */
export function comparedTo(preset: SuiviPeriodPreset | null): string {
  switch (preset) {
    case "TODAY":
      return "vs hier";
    case "YESTERDAY":
      return "vs avant-hier";
    case "LAST_7_DAYS":
      return "vs 7 jours précédents";
    case "LAST_30_DAYS":
      return "vs 30 jours précédents";
    default:
      return "vs période précédente";
  }
}
