import type { TagTone } from "../../components/ui/Tag";
import type {
  AdminProductionAnnotationFiltre,
  AdminProductionEpreuve,
  AdminProductionNiveauFiltre,
  AdminProductionPeriode,
  AdminProductionSignalementFiltre,
  AdminProductionStatutIa,
  AdminProductionTri,
  BandeCritere,
  EpreuveType,
  EtatSignalement,
  MotifSignalement,
} from "../../types/api";

export interface Option<T extends string> {
  value: T;
  label: string;
}

/**
 * Libellés des VALEURS DE FILTRE envoyées à `GET /api/admin/productions`
 * (valeur inconnue ⇒ 400). Ce que l'écran affiche d'une production — statut,
 * contexte, état de signalement — arrive servi sur la ligne, jamais d'ici.
 */
export const EPREUVE_OPTIONS: readonly Option<AdminProductionEpreuve>[] = [
  { value: "TCF_EE", label: "Expression écrite (EE)" },
  { value: "TCF_EO", label: "Expression orale (EO)" },
];

export const TACHE_OPTIONS: readonly Option<"1" | "2" | "3">[] = [
  { value: "1", label: "Tâche 1" },
  { value: "2", label: "Tâche 2" },
  { value: "3", label: "Tâche 3" },
];

export const NIVEAU_OPTIONS: readonly Option<AdminProductionNiveauFiltre>[] = [
  { value: "A1_NON_ATTEINT", label: "A1 non atteint" },
  { value: "A1", label: "A1" },
  { value: "A2", label: "A2" },
  { value: "B1", label: "B1" },
  { value: "B2", label: "B2" },
  { value: "SANS_NIVEAU", label: "Sans niveau" },
];

export const STATUT_OPTIONS: readonly Option<AdminProductionStatutIa>[] = [
  { value: "EN_COURS", label: "En cours" },
  { value: "EVALUEE", label: "Évaluée" },
  { value: "NON_EVALUABLE", label: "Non évaluable" },
  { value: "ECHEC", label: "Échec" },
];

export const SIGNALEMENT_OPTIONS: readonly Option<AdminProductionSignalementFiltre>[] = [
  { value: "SIGNALEES", label: "Signalées (à vérifier)" },
  { value: "VERIFIEES", label: "Vérifiées" },
  { value: "NON_SIGNALEES", label: "Non signalées" },
];

export const ANNOTATION_OPTIONS: readonly Option<AdminProductionAnnotationFiltre>[] = [
  { value: "NON_ANNOTEES", label: "À annoter" },
  { value: "ANNOTEES", label: "Annotées" },
];

export type PeriodChoice = AdminProductionPeriode | "CUSTOM";

export const PERIODE_OPTIONS: readonly Option<PeriodChoice>[] = [
  { value: "TODAY", label: "Aujourd'hui" },
  { value: "LAST_7_DAYS", label: "7 derniers jours" },
  { value: "LAST_30_DAYS", label: "30 derniers jours" },
  { value: "CUSTOM", label: "Personnalisée" },
];

export const SORT_OPTIONS: readonly Option<AdminProductionTri>[] = [
  { value: "DATE_DESC", label: "Plus récentes" },
  { value: "DATE_ASC", label: "Plus anciennes" },
  { value: "NIVEAU_DESC", label: "Niveau ↓ (B2 → A1)" },
  { value: "NIVEAU_ASC", label: "Niveau ↑ (A1 → B2)" },
  { value: "EPREUVE", label: "Épreuve puis tâche" },
];

/**
 * Motifs de `POST …/flags`. Aucun endpoint ne les liste : ils miroitent
 * l'enum `MotifSignalement` (codes figés par une contrainte SQL). Une fois le
 * signalement créé, c'est le `motifLabel` servi qui s'affiche.
 */
export const MOTIF_OPTIONS: readonly Option<MotifSignalement>[] = [
  { value: "NIVEAU_INCOHERENT", label: "Niveau incohérent" },
  { value: "SCORE_INCOHERENT", label: "Score incohérent" },
  { value: "FEEDBACK_INCORRECT", label: "Feedback incorrect" },
  { value: "REPONSE_MAL_COMPRISE", label: "Réponse mal comprise par l'IA" },
  { value: "TRANSCRIPTION", label: "Problème de transcription" },
  { value: "AUTRE", label: "Autre" },
];

export const EPREUVE_SIGLE: Partial<Record<EpreuveType, string>> = {
  TCF_EE: "EE",
  TCF_EO: "EO",
};

export const EPREUVE_NOM: Partial<Record<EpreuveType, string>> = {
  TCF_EE: "Expression écrite",
  TCF_EO: "Expression orale",
};

export const STATUT_TONE: Record<AdminProductionStatutIa, TagTone> = {
  EN_COURS: "info",
  EVALUEE: "success",
  NON_EVALUABLE: "warning",
  ECHEC: "danger",
};

export const SIGNALEMENT_TONE: Record<EtatSignalement, TagTone> = {
  AUCUN: "neutral",
  SIGNALE: "warning",
  VERIFIE: "success",
  RETIRE: "neutral",
};

export const BANDE_TONE: Record<BandeCritere, TagTone> = {
  TRES_BONNE_MAITRISE: "success",
  SATISFAISANT: "info",
  EN_COURS_ACQUISITION: "warning",
  FRAGILE: "danger",
  NON_EVALUABLE: "neutral",
};

export function isBande(value: string | null): value is BandeCritere {
  return value !== null && value in BANDE_TONE;
}

export const NON_DISPONIBLE = "Non disponible";

const INTEGER = new Intl.NumberFormat("fr-FR");

export function formatInteger(value: number | null): string {
  return value === null ? NON_DISPONIBLE : INTEGER.format(value);
}

const USD = new Intl.NumberFormat("fr-FR", {
  style: "currency",
  currency: "USD",
  minimumFractionDigits: 2,
  maximumFractionDigits: 6,
});

/** Coût servi en millionièmes de dollar US (USD × 10⁻⁶). */
export function formatMicroUsd(micro: number | null): string {
  return micro === null ? NON_DISPONIBLE : USD.format(micro / 1_000_000);
}

const EUR = new Intl.NumberFormat("fr-FR", { style: "currency", currency: "EUR" });

/** Ancienne colonne en centimes d'euro : affichée à part, jamais additionnée au coût USD. */
export function formatEuroCents(cents: number | null): string {
  return cents === null ? NON_DISPONIBLE : EUR.format(cents / 100);
}

/** « 2 min 41 », « 45 s », « 3 h 05 ». */
export function formatSeconds(seconds: number | null): string {
  if (seconds === null) return NON_DISPONIBLE;
  if (seconds < 60) return `${seconds} s`;
  if (seconds < 3600) {
    return `${Math.floor(seconds / 60)} min ${String(seconds % 60).padStart(2, "0")}`;
  }
  const hours = Math.floor(seconds / 3600);
  return `${hours} h ${String(Math.floor((seconds % 3600) / 60)).padStart(2, "0")}`;
}

/** Indicateur servi tel quel (part entre 0 et 1), sans conversion. */
export function formatRatio(value: number | null): string {
  if (value === null) return NON_DISPONIBLE;
  return value.toLocaleString("fr-FR", { maximumFractionDigits: 3 });
}

export function formatScore(value: number | null): string {
  if (value === null) return "—";
  return value.toLocaleString("fr-FR", { maximumFractionDigits: 2 });
}

export function shortId(id: string): string {
  return id.slice(0, 8);
}
