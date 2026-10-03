import type {
  SubscriptionSource,
  SuiviFunnelStepCode,
  SuiviPlatformFilter,
  SuiviTypeFilter,
} from "../../types/api";

export const STEP_LABELS: Record<SuiviFunnelStepCode, string> = {
  SUBJECT_VIEWED: "Sujet vu",
  SUBMITTED: "Soumis",
  ACCOUNT_ATTACHED: "Compte rattaché",
  REPORT_VIEWED: "Rapport vu",
  PLAN_VIEWED: "Plan consulté",
  UNLOCK_CLICKED: "Débloquer",
  PURCHASED: "Achat",
};

export const SCOPE_LABELS: Record<SuiviTypeFilter, string> = {
  ALL: "TCF + Civique",
  TCF: "TCF",
  CIVIQUE: "Civique",
};

export const TYPE_OPTIONS: { value: SuiviTypeFilter; label: string }[] = [
  { value: "ALL", label: "Tous" },
  { value: "TCF", label: "TCF" },
  { value: "CIVIQUE", label: "Civique" },
];

export const PLATFORM_OPTIONS: { id: SuiviPlatformFilter; label: string }[] = [
  { id: "ALL", label: "Toutes plateformes" },
  { id: "WEB", label: "Web" },
  { id: "IOS", label: "iOS" },
  { id: "ANDROID", label: "Android" },
];

export const PROVIDER_LABELS: Record<SubscriptionSource, string> = {
  STRIPE: "Stripe",
  APPLE: "Apple",
  GOOGLE: "Google",
};

const SOURCE_LABELS: Record<string, string> = {
  instagram: "Instagram",
  tiktok: "TikTok",
  facebook: "Facebook",
  direct: "Direct",
  autre: "Autre",
};

/** Groupe de source de la config ; un groupe inconnu s'affiche tel quel, capitalise. */
export function sourceLabel(group: string): string {
  return SOURCE_LABELS[group] ?? group.charAt(0).toUpperCase() + group.slice(1);
}
