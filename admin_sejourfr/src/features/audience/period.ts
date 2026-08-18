import type { AudienceRange } from "../../types/api";
import { addDays, monthStart, parisToday, weekStart } from "./dates";

/**
 * Période choisie à l'écran. Les fenêtres glissantes envoient `days` (le
 * comportement d'origine, inchangé) ; les préréglages calendaires et le choix
 * d'une date envoient `from`/`to`, calculés ici, en Europe/Paris.
 */
export type PeriodChoice =
  | { kind: "today" }
  | { kind: "yesterday" }
  | { kind: "week" }
  | { kind: "month" }
  | { kind: "sliding"; days: number }
  | { kind: "day"; day: string };

export const PERIOD_PRESETS: { choice: PeriodChoice; label: string }[] = [
  { choice: { kind: "today" }, label: "Aujourd'hui" },
  { choice: { kind: "yesterday" }, label: "Hier" },
  { choice: { kind: "week" }, label: "Cette semaine" },
  { choice: { kind: "month" }, label: "Ce mois" },
  { choice: { kind: "sliding", days: 7 }, label: "7 jours" },
  { choice: { kind: "sliding", days: 30 }, label: "30 jours" },
  { choice: { kind: "sliding", days: 90 }, label: "90 jours" },
];

export const DEFAULT_PERIOD: PeriodChoice = { kind: "sliding", days: 30 };

export function resolveRange(choice: PeriodChoice): AudienceRange {
  const today = parisToday();

  switch (choice.kind) {
    case "today":
      return { from: today, to: today };
    case "yesterday": {
      const day = addDays(today, -1);
      return { from: day, to: day };
    }
    case "week":
      return { from: weekStart(today), to: today };
    case "month":
      return { from: monthStart(today), to: today };
    case "sliding":
      return { days: choice.days };
    case "day":
      return { from: choice.day, to: choice.day };
  }
}

export function isSameChoice(a: PeriodChoice, b: PeriodChoice): boolean {
  if (a.kind !== b.kind) return false;
  if (a.kind === "sliding" && b.kind === "sliding") return a.days === b.days;
  if (a.kind === "day" && b.kind === "day") return a.day === b.day;
  return true;
}
