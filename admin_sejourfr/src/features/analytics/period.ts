import type { AnalyticsRange } from "../../types/api";
import { parisToday } from "./dates";

/**
 * Periode choisie a l'ecran. Les fenetres glissantes envoient `days` ; la
 * journee en cours et la plage personnalisee envoient `from`/`to`, calcules ici
 * en Europe/Paris. Le serveur renvoie toujours les bornes qu'il a APPLIQUEES :
 * ce sont elles qui s'affichent, jamais celles-ci.
 */
export type PeriodChoice =
  | { kind: "today" }
  | { kind: "sliding"; days: number }
  | { kind: "custom"; from: string; to: string };

export const PERIOD_PRESETS: { id: string; label: string; choice: PeriodChoice }[] = [
  { id: "today", label: "Aujourd'hui", choice: { kind: "today" } },
  { id: "7", label: "7 jours", choice: { kind: "sliding", days: 7 } },
  { id: "30", label: "30 jours", choice: { kind: "sliding", days: 30 } },
  { id: "90", label: "90 jours", choice: { kind: "sliding", days: 90 } },
];

export const DEFAULT_PERIOD: PeriodChoice = { kind: "sliding", days: 7 };

export function resolveRange(choice: PeriodChoice): AnalyticsRange {
  const today = parisToday();

  switch (choice.kind) {
    case "today":
      return { from: today, to: today };
    case "sliding":
      return { days: choice.days };
    case "custom":
      return { from: choice.from, to: choice.to };
  }
}

export function isSameChoice(a: PeriodChoice, b: PeriodChoice): boolean {
  if (a.kind !== b.kind) return false;
  if (a.kind === "sliding" && b.kind === "sliding") return a.days === b.days;
  if (a.kind === "custom" && b.kind === "custom") {
    return a.from === b.from && a.to === b.to;
  }
  return true;
}

/** Identifiant du preset selectionne, ou `custom` pour une plage saisie. */
export function choiceId(choice: PeriodChoice): string {
  const preset = PERIOD_PRESETS.find((p) => isSameChoice(p.choice, choice));
  return preset ? preset.id : "custom";
}
