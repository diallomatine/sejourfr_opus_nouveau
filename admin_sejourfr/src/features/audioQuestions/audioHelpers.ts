import type {
  AudioContentType,
  AudioLevel,
  AudioMode,
  AudioTheme,
  CompetenceCo,
  GenerationStatus,
} from "../../types/api";

export const LEVEL_OPTIONS: ReadonlyArray<{ value: AudioLevel; label: string; hint: string }> = [
  { value: "A2", label: "A2 — CSP (Carte de séjour pluriannuelle)", hint: "15–30 s, message simple" },
  { value: "B1", label: "B1 — CR (Carte de résident)", hint: "30–60 s, conversation pratique" },
  { value: "B2", label: "B2 — NAT (Naturalisation)", hint: "60–120 s, interview/reportage" },
];

export const THEME_OPTIONS: ReadonlyArray<{ value: AudioTheme; label: string }> = [
  { value: "vie_pratique_logement", label: "Vie pratique & logement" },
  { value: "travail", label: "Travail" },
  { value: "sante", label: "Santé" },
  { value: "administratif", label: "Administratif (banque, opérateur, livraison)" },
  { value: "transports", label: "Transports" },
  { value: "consommation", label: "Consommation" },
  { value: "medias_numerique", label: "Médias & numérique" },
  { value: "environnement", label: "Environnement" },
];

export const TYPE_OPTIONS: ReadonlyArray<{ value: AudioContentType; label: string }> = [
  { value: "annonce", label: "Annonce" },
  { value: "monologue", label: "Monologue / message" },
  { value: "dialogue", label: "Dialogue" },
  { value: "interview", label: "Interview" },
  { value: "reportage", label: "Reportage" },
];

export const AUDIO_MODE_OPTIONS: ReadonlyArray<{ value: AudioMode; label: string; hint: string }> = [
  {
    value: "WRITTEN_QUESTION",
    label: "Question et choix écrits (défaut)",
    hint: "Seul le document sonore est lu. Question + 4 réponses affichées à l'écran.",
  },
  {
    value: "FULL_AUDIO",
    label: "Tout lu dans l'audio",
    hint: "Document + question + 4 réponses lus. L'écran ne montre que Réponse A/B/C/D.",
  },
];

export function audioModeLabel(mode: AudioMode | null | undefined): string {
  if (!mode) return "—";
  return AUDIO_MODE_OPTIONS.find((o) => o.value === mode)?.label ?? mode;
}

export const COMPETENCE_OPTIONS: ReadonlyArray<{ value: CompetenceCo; label: string }> = [
  { value: "co_reperage_explicite", label: "Repérage explicite (heure, lieu, nom)" },
  { value: "co_detail_specifique", label: "Détail spécifique (prix, quantité, condition)" },
  { value: "co_idee_principale", label: "Idée principale / sujet" },
  { value: "co_inference_intention", label: "Inférence / intention" },
  { value: "co_ton_attitude", label: "Ton / attitude" },
  { value: "co_reformulation", label: "Reformulation" },
];

export function levelLabel(level: AudioLevel): string {
  return LEVEL_OPTIONS.find((o) => o.value === level)?.label.split(" — ")[0] ?? level;
}

export function themeLabel(theme: AudioTheme | null | undefined): string {
  if (!theme) return "—";
  return THEME_OPTIONS.find((o) => o.value === theme)?.label ?? theme;
}

export function competenceLabel(code: CompetenceCo | null | undefined): string {
  if (!code) return "—";
  return COMPETENCE_OPTIONS.find((o) => o.value === code)?.label ?? code;
}

export const STATUS_LABELS: Record<GenerationStatus, string> = {
  SUCCESS: "Succès",
  FAILED_VALIDATION: "Validation",
  FAILED_RATE_LIMIT: "Rate limit",
  FAILED_ANTHROPIC: "Anthropic",
  FAILED_ANTHROPIC_PARSE: "Parsing",
  FAILED_CONTENT_VALIDATION: "Contenu invalide",
  FAILED_DUPLICATE: "Doublon",
  FAILED_AZURE_SPEECH: "Azure Speech",
  FAILED_R2_UPLOAD: "Upload R2",
  FAILED_DB: "Base de données",
  FAILED_TIMEOUT: "Timeout",
  REJECTED_BY_ADMIN: "Rejeté",
};

/**
 * Mapping vers les tones du composant Tag (cf components/ui/Tag).
 * SUCCESS -> active (vert), FAILED_* -> draft (gris), RATE_LIMIT -> muted.
 */
export function statusTone(status: GenerationStatus): "active" | "draft" | "muted" {
  if (status === "SUCCESS") return "active";
  if (status === "FAILED_RATE_LIMIT") return "muted";
  return "draft";
}

export function formatEur(amount: number | null | undefined): string {
  if (amount == null) return "—";
  return amount.toLocaleString("fr-FR", {
    style: "currency",
    currency: "EUR",
    minimumFractionDigits: 2,
    maximumFractionDigits: 4,
  });
}

export function formatDuration(ms: number | null | undefined): string {
  if (ms == null) return "—";
  if (ms < 1000) return `${ms} ms`;
  return `${(ms / 1000).toFixed(1)} s`;
}

export function formatSeconds(s: number | null | undefined): string {
  if (s == null) return "—";
  const total = Math.round(s);
  const mm = Math.floor(total / 60);
  const ss = total % 60;
  return mm > 0 ? `${mm}m ${ss.toString().padStart(2, "0")}s` : `${ss} s`;
}
