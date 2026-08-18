import type {
  FunnelBreakdownCounts,
  FunnelPlatform,
  FunnelStage,
  PageViewEvent,
} from "../../types/api";

/**
 * Libellés partagés par les deux sections de l'écran. Ils vivaient en double
 * (page + entonnoir), donc deux réseaux pouvaient s'appeler différemment selon
 * le tableau qui les affichait.
 */

const SOURCE_LABELS: Record<string, string> = {
  tiktok: "TikTok",
  instagram: "Instagram",
  whatsapp: "WhatsApp",
  facebook: "Facebook",
  youtube: "YouTube",
  direct: "Accès direct",
  autre: "Autre",
  inconnu: "Provenance inconnue",
};

export function sourceLabel(source: string): string {
  return SOURCE_LABELS[source] ?? source;
}

/** Provenance non exploitable : comptes antérieurs à la mesure. */
export const UNKNOWN_SOURCE = "inconnu";

export const STAGE_LABELS: Record<FunnelStage, string> = {
  SIGNUP: "Inscription",
  DIAGNOSTIC_STARTED: "Diagnostic commencé",
  DIAGNOSTIC_COMPLETED: "Diagnostic terminé",
  PAYWALL_VIEWED: "Écran Premium affiché",
  SUBSCRIBE_CLICKED: "Clic sur « S'abonner »",
  CHECKOUT_STARTED: "Paiement ouvert",
  PURCHASE: "Paiement abouti",
};

export const PLATFORM_LABELS: Record<FunnelPlatform, string> = {
  WEB: "Web",
  MOBILE: "Mobile",
  UNKNOWN: "Non renseigné",
};

/** Colonnes du détail par provenance et par plateforme, dans l'ordre des étapes. */
export const BREAKDOWN_COLUMNS: {
  key: keyof FunnelBreakdownCounts;
  label: string;
}[] = [
  { key: "signups", label: "Inscrits" },
  { key: "diagnosticsStarted", label: "Diag. commencé" },
  { key: "diagnosticsCompleted", label: "Diag. terminé" },
  { key: "paywallViewed", label: "Premium vu" },
  { key: "subscribeClicked", label: "Clic abonnement" },
  { key: "checkoutStarted", label: "Paiement ouvert" },
  { key: "purchases", label: "Payants" },
];

export const EVENT_LABELS: Record<PageViewEvent, string> = {
  VIEW: "Page vue",
  CTA: "CTA historique cliqué",
  DIAGNOSTIC_VIEWED: "Diagnostic vu",
  DIAGNOSTIC_STARTED: "Diagnostic démarré",
  DIAGNOSTIC_WRITTEN_COMPLETED: "Écrit terminé",
  DIAGNOSTIC_ORAL_COMPLETED: "Oral terminé",
  DIAGNOSTIC_COMPLETED: "Diagnostic analysé",
  DIAGNOSTIC_RESULT_VIEWED: "Résultat consulté",
  PLAN_OPENED: "Plan ouvert",
  PLAN_RECOMMENDED_EXERCISE_STARTED: "Exercice recommandé démarré",
  SOCIAL_LANDING_DIAGNOSTIC_CLICKED: "CTA diagnostic social cliqué",
  DIAGNOSTIC_ACCOUNT_REQUIRED: "Compte demandé (fin des productions)",
  DIAGNOSTIC_TO_PREMIUM_CLICKED: "CTA Premium depuis diagnostic",
};

export const EVENT_ORDER = Object.keys(EVENT_LABELS) as PageViewEvent[];
