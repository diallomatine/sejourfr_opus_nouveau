import type {
  BandeCritere,
  ConfianceEvaluation,
  CritereCode,
  EpreuveType,
  EvaluationResultDto,
  NiveauCecrl,
} from "../../types/api";

export const NIVEAU_ORDER: NiveauCecrl[] = [
  "A1_NON_ATTEINT",
  "A1",
  "A2",
  "B1",
  "B2",
  "C1",
  "C2",
];

export const NIVEAU_LABEL: Record<NiveauCecrl, string> = {
  A1_NON_ATTEINT: "A1 non atteint",
  A1: "A1",
  A2: "A2",
  B1: "B1",
  B2: "B2",
  C1: "C1",
  C2: "C2",
};

export const CONFIANCE_LABEL: Record<ConfianceEvaluation, string> = {
  HAUTE: "Confiance haute",
  MOYENNE: "Confiance moyenne",
  FAIBLE: "Confiance faible",
};

export const BANDE_LABEL: Record<BandeCritere, string> = {
  TRES_BONNE_MAITRISE: "Très bonne maîtrise",
  SATISFAISANT: "Satisfaisant",
  EN_COURS_ACQUISITION: "En cours d'acquisition",
  FRAGILE: "Fragile",
  NON_EVALUABLE: "Non évaluable",
};

/**
 * Libellé de repli quand le feedback ne porte pas de `label` — repris de
 * `production-rubrics-v4.json`, accents rétablis.
 */
export const CRITERE_LABEL: Record<CritereCode, string> = {
  realisation_consigne: "Réalisation de la consigne",
  adequation_destinataire: "Adéquation au destinataire et au registre",
  chronologie_recit: "Chronologie et repères temporels",
  prise_position: "Prise de position claire",
  argumentation: "Justification et développement des arguments",
  developpement_reponses: "Développement des réponses",
  conduite_echange: "Conduite de l'échange et obtention des informations",
  lexique: "Étendue et maîtrise du lexique",
  morphosyntaxe: "Correction morphosyntaxique",
  coherence: "Clarté et enchaînement du message",
  pertinence: "Pertinence",
};

/** Critères disparus en v4, encore présents sur les évaluations en base. */
export const CRITERES_OBSOLETES: CritereCode[] = ["pertinence"];

export const EPREUVE_LABEL: Record<EpreuveType, string> = {
  CIVIQUE: "Examen civique",
  TCF_CO: "Compréhension orale",
  TCF_CE: "Compréhension écrite",
  TCF_STRUCTURE: "Structure de la langue",
  TCF_EO: "Expression orale",
  TCF_EE: "Expression écrite",
  TCF_COMPLET: "Examen blanc complet",
};

/** Les deux seules épreuves produisant des soumissions à annoter. */
export const EPREUVES_PRODUCTION: EpreuveType[] = ["TCF_EE", "TCF_EO"];

/**
 * Le feedback vient d'un JSONB non contraint : un champ annoncé numérique peut
 * arriver en chaîne, ou manquer. On normalise avant tout affichage.
 */
export function toNumber(value: unknown): number | null {
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

export function formatDecimal(value: number, digits = 1): string {
  return value.toLocaleString("fr-FR", {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  });
}

export function formatNote(value: number | null | undefined): string {
  if (value === null || value === undefined) return "—";
  return `${formatDecimal(value)} / 20`;
}

/** Écart signé, avec un vrai signe moins typographique. */
export function formatSigned(value: number, digits = 1): string {
  const sign = value > 0 ? "+" : value < 0 ? "−" : "";
  return `${sign}${formatDecimal(Math.abs(value), digits)}`;
}

export function formatPercent(value: number): string {
  return `${formatDecimal(value)} %`;
}

export function formatDateTime(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "—";
  return date.toLocaleString("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    year: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatDuration(seconds: number | null): string {
  if (seconds === null) return "—";
  const min = Math.floor(seconds / 60);
  const sec = seconds % 60;
  return min > 0 ? `${min} min ${String(sec).padStart(2, "0")}` : `${sec} s`;
}

export type HealthTone = "good" | "watch" | "bad";

export interface BiasReading {
  tone: HealthTone;
  /** Phrase complète, lisible par un non-statisticien. */
  sentence: string;
}

/**
 * Le backend calcule `ecart = note humaine − note IA`. Un écart moyen NÉGATIF
 * signifie donc que l'IA a mis plus de points que le correcteur : elle est trop
 * indulgente. C'est l'inverse de la lecture spontanée, d'où la phrase explicite.
 */
export function readBias(ecartMoyen: number, seuilHorsCible: number): BiasReading {
  const amplitude = Math.abs(ecartMoyen);
  const negligeable = seuilHorsCible / 12;
  const marque = seuilHorsCible / 3;

  if (amplitude < negligeable) {
    return {
      tone: "good",
      sentence:
        "Aucun biais net : l'IA ne penche globalement ni vers l'indulgence ni vers la sévérité.",
    };
  }

  const points = `${formatDecimal(amplitude)} point${amplitude >= 2 ? "s" : ""}`;
  const tone: HealthTone = amplitude >= marque ? "bad" : "watch";

  return ecartMoyen < 0
    ? {
        tone,
        sentence: `L'IA note en moyenne ${points} AU-DESSUS du correcteur : elle est trop indulgente.`,
      }
    : {
        tone,
        sentence: `L'IA note en moyenne ${points} EN DESSOUS du correcteur : elle est trop sévère.`,
      };
}

/** Même convention de signe, mais sur une seule production. */
export function readGap(ecart: number, seuilHorsCible: number): BiasReading {
  const amplitude = Math.abs(ecart);
  if (amplitude < 0.05) {
    return {
      tone: "good",
      sentence: "L'IA et le correcteur donnent exactement la même note.",
    };
  }

  const points = `${formatDecimal(amplitude)} point${amplitude >= 2 ? "s" : ""}`;
  const tone: HealthTone =
    amplitude > seuilHorsCible ? "bad" : amplitude >= seuilHorsCible / 2 ? "watch" : "good";

  return ecart < 0
    ? {
        tone,
        sentence: `L'IA a mis ${points} de plus que le correcteur : trop indulgente sur cette production.`,
      }
    : {
        tone,
        sentence: `L'IA a mis ${points} de moins que le correcteur : trop sévère sur cette production.`,
      };
}

export function readDispersion(
  ecartMoyenAbsolu: number,
  seuilHorsCible: number,
): HealthTone {
  if (ecartMoyenAbsolu >= seuilHorsCible / 2) return "bad";
  if (ecartMoyenAbsolu >= seuilHorsCible / 4) return "watch";
  return "good";
}

// ---------------------------------------------------------------------------
// Transcription
// ---------------------------------------------------------------------------

export type TranscriptSpeaker = "EXAMINER" | "CANDIDATE" | "UNKNOWN";

export interface TranscriptTurn {
  speaker: TranscriptSpeaker;
  text: string;
}

const TURN_MARKERS: { speaker: TranscriptSpeaker; patterns: RegExp[] }[] = [
  {
    speaker: "EXAMINER",
    patterns: [/^examinateur\s*:\s*/i, /^\[examinateur\]\s*/i],
  },
  {
    speaker: "CANDIDATE",
    patterns: [/^candidat(?:e)?\s*:\s*/i, /^\[candidat(?:e)?\]\s*/i],
  },
];

/**
 * Découpe une transcription en tours de parole. Une production non dialoguée
 * (EE, ou EO monologuée) ressort en un seul tour `UNKNOWN` : c'est le cas
 * normal, pas une erreur de parsing.
 */
export function parseTranscript(raw: string): TranscriptTurn[] {
  const turns: TranscriptTurn[] = [];

  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    let matched: TranscriptTurn | null = null;
    for (const marker of TURN_MARKERS) {
      const pattern = marker.patterns.find((p) => p.test(trimmed));
      if (pattern) {
        matched = {
          speaker: marker.speaker,
          text: trimmed.replace(pattern, "").trim(),
        };
        break;
      }
    }

    if (matched) {
      turns.push(matched);
      continue;
    }

    const current = turns[turns.length - 1];
    if (current) {
      current.text = `${current.text} ${trimmed}`.trim();
    } else {
      turns.push({ speaker: "UNKNOWN", text: trimmed });
    }
  }

  return turns;
}

export function isDialogue(turns: TranscriptTurn[]): boolean {
  return turns.some((t) => t.speaker !== "UNKNOWN");
}

// ---------------------------------------------------------------------------
// Rétrocompatibilité v3
// ---------------------------------------------------------------------------

/**
 * Une évaluation antérieure à la v4 n'a ni confiance, ni bande, ni
 * accomplissement. On le signale à l'écran pour que le correcteur sache
 * pourquoi la fiche est moins fournie — l'absence reste un cas valide.
 */
export function isLegacyEvaluation(evaluation: EvaluationResultDto): boolean {
  const feedback = evaluation.feedback;
  if (evaluation.confiance !== null) return false;
  if (!feedback) return true;
  if (feedback.accomplissement) return false;
  return !(feedback.scores_criteres ?? []).some((c) => c.bande !== undefined);
}

export function critereLabel(code: CritereCode, label?: string): string {
  return label ?? CRITERE_LABEL[code] ?? code;
}
