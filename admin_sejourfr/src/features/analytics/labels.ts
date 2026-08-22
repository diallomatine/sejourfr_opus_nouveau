import type { AnalyticsMetricKey } from "../../types/api";

/**
 * Libelles partages par l'ecran. Ils vivaient en double dans la maquette (un
 * tableau par onglet), donc deux blocs pouvaient nommer la meme etape
 * differemment. Ici, un seul endroit.
 *
 * Aucune valeur de dimension n'est filtree a l'affichage : `inconnu` n'est
 * JAMAIS masque (brief §83, un gros volume d'inconnu est lui-meme
 * l'information) et ne se confond pas avec `direct`, qui est une visite sans
 * provenance mais coherente (brief §84). Les libelles de ces valeurs viennent
 * du serveur, comme toutes les autres.
 */

export const STEP_LABELS: Record<string, string> = {
  v: "Visiteurs",
  cta: "Clics « Faire mon diagnostic »",
  start: "Diagnostics commencés",
  ee1: "EE démarrée",
  ee2: "EE terminée",
  eo1: "EO démarrée",
  eo2: "EO terminée",
  rep: "Rapport diagnostic affiché",
  prem: "Clics « Débloquer mon plan »",
  ck: "Checkouts commencés",
  pay: "Paiements réussis",
  sig: "Nouvelles inscriptions",
  revEurCents: "Revenu",
};

/** Etape precedente de chaque marche, pour lire une conversion. */
export const STEP_PREV: Record<string, AnalyticsMetricKey> = {
  cta: "v",
  start: "cta",
  ee1: "start",
  ee2: "ee1",
  eo1: "ee2",
  eo2: "eo1",
  rep: "eo2",
  prem: "rep",
  ck: "prem",
  pay: "ck",
  sig: "v",
};

export type TabId =
  | "overview"
  | "acquisition"
  | "diagnostic"
  | "conversion"
  | "users"
  | "retention";

export const TABS: { id: TabId; label: string; soon?: boolean }[] = [
  { id: "overview", label: "Vue d'ensemble" },
  { id: "acquisition", label: "Acquisition" },
  { id: "diagnostic", label: "Diagnostic" },
  { id: "conversion", label: "Conversion" },
  { id: "users", label: "Utilisateurs" },
  { id: "retention", label: "Rétention", soon: true },
];

/** Mesures affichables sur la courbe principale. */
export const CHART_METRICS: { id: AnalyticsMetricKey; label: string }[] = [
  { id: "v", label: "Visiteurs" },
  { id: "sig", label: "Inscriptions" },
  { id: "start", label: "Diagnostics" },
  { id: "prem", label: "Clics Premium" },
  { id: "pay", label: "Paiements" },
  { id: "revEurCents", label: "Revenus" },
];

export const PLATFORM_OPTIONS: { id: string; label: string }[] = [
  { id: "all", label: "Web + App" },
  { id: "WEB", label: "Web" },
  { id: "MOBILE", label: "App" },
];
