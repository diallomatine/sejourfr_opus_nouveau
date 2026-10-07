import type { SuiviPeriodPreset, SuiviRange } from "../types/api";
import { MONTH_PATTERN, monthBounds, parisCurrentMonth } from "./dates";

/**
 * Période d'un écran de pilotage (Suivi, Activité, Productions IA) : un preset
 * du serveur, une plage personnalisée `from`/`to`, ou — seulement pour un écran
 * qui l'offre — « Tout » (aucune borne). La table des jours couverts vit côté
 * serveur (`SuiviPeriodPreset.window`) ; ici, seulement l'identifiant d'URL,
 * le libellé du sélecteur et la lecture/écriture de `?period&from&to&month`.
 * Chaque écran a SA période par défaut, jamais écrite dans l'URL : « Aujourd'hui »
 * pour Suivi et Activité (`readPeriod`), « Tout » pour Productions IA
 * (`readOpenPeriod`, DI-35).
 */
export type PeriodId = "all" | "today" | "yesterday" | "7d" | "30d" | "month" | "custom";

export type PresetPeriodId = Exclude<PeriodId, "custom" | "all">;

const PRESETS: Record<PresetPeriodId, SuiviPeriodPreset> = {
  today: "TODAY",
  yesterday: "YESTERDAY",
  "7d": "LAST_7_DAYS",
  "30d": "LAST_30_DAYS",
  month: "MONTH",
};

export const PERIOD_LABELS: Record<PeriodId, string> = {
  all: "Tout",
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

/** Période d'un écran qui offre « Tout » : `range` null = aucune borne. */
export interface OpenPeriodState extends Omit<PeriodState, "range"> {
  range: SuiviRange | null;
}

/**
 * Lit la période de l'URL parmi celles qu'offre l'écran. Absente, illisible ou
 * non offerte ⇒ le défaut de l'écran ; plage personnalisée incomplète ou
 * inversée ⇒ le défaut aussi (elle partirait en 400).
 */
function resolvePeriod(
  params: URLSearchParams,
  offered: readonly PeriodId[],
  fallback: "today" | "all",
): OpenPeriodState {
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
  const offeredPreset =
    raw != null && Object.hasOwn(PRESETS, raw) && offered.includes(raw as PeriodId)
      ? (raw as PresetPeriodId)
      : null;
  const period = offeredPreset ?? fallback;
  if (period === "all") return { period, from, to, month: current, range: null };
  // « Mois » : le mois courant passe par le preset du serveur (à date) ; un mois
  // passé part en plage du 1er au dernier jour. Un mois illisible ou futur ⇒ courant.
  const rawMonth = params.get("month") ?? "";
  if (period === "month" && MONTH_PATTERN.test(rawMonth) && rawMonth < current) {
    return { period, from, to, month: rawMonth, range: monthBounds(rawMonth) };
  }
  return { period, from, to, month: current, range: { preset: PRESETS[period] } };
}

/** Écran borné (Suivi, Activité) : défaut « Aujourd'hui », jamais « Tout ». */
export function readPeriod(params: URLSearchParams, offered: readonly PeriodId[]): PeriodState {
  const state = resolvePeriod(params, offered, "today");
  return { ...state, range: state.range ?? { preset: PRESETS.today } };
}

/** Écran qui offre « Tout » et en fait son défaut (Productions IA, DI-35). */
export function readOpenPeriod(params: URLSearchParams, offered: readonly PeriodId[]): OpenPeriodState {
  return resolvePeriod(params, offered, "all");
}

export interface PeriodPatch {
  period?: PeriodId;
  from?: string;
  to?: string;
  month?: string;
}

/**
 * Écrit la période dans l'URL ; le défaut DE L'ÉCRAN n'est pas écrit (« Aujourd'hui »
 * sauf mention contraire), un preset efface la plage.
 */
export function writePeriod(
  next: URLSearchParams,
  patch: PeriodPatch,
  defaultPeriod: "today" | "all" = "today",
): void {
  const write = (key: string, value: string | null) => {
    if (value) next.set(key, value);
    else next.delete(key);
  };
  if (patch.period !== undefined) {
    write("period", patch.period === defaultPeriod ? null : patch.period);
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

/**
 * `preset` OU `from`/`to`, jamais les deux (400) : la forme de `SuiviRange` le
 * garantit. `null` (« Tout ») ⇒ aucun paramètre.
 */
export function rangeParams(range: SuiviRange | null): Record<string, string> {
  if (range == null) return {};
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
