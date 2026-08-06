import type {
  SkillDifficultyLevel,
  SkillReferenceDto,
  SkillReferenceLevel,
  SkillSection,
  SkillTargetLevel,
  SkillTaskCode,
} from "../../types/api";

export const SECTIONS: SkillSection[] = ["EE", "EO"];

export const SECTION_LABEL: Record<SkillSection, string> = {
  EE: "Expression écrite",
  EO: "Expression orale",
};

export const SECTION_TONE: Record<SkillSection, "ce" | "co"> = {
  EE: "ce",
  EO: "co",
};

export const TASK_CODES: SkillTaskCode[] = ["EE1", "EE2", "EE3", "EO1", "EO2", "EO3"];

/** Intitulés des 6 tâches, repris mot pour mot des §5 et §6 de la spec. */
export const TASK_TITLE: Record<SkillTaskCode, string> = {
  EE1: "Écrire un message court",
  EE2: "Raconter une expérience",
  EE3: "Donner son opinion",
  EO1: "Entretien dirigé : parler de soi",
  EO2: "Jeu de rôle : demander et obtenir des informations",
  EO3: "Exprimer et développer un point de vue",
};

export const TARGET_LEVELS: SkillTargetLevel[] = ["A1", "A2", "B1", "B2"];

export function targetLevelTone(
  level: SkillTargetLevel,
): "a2" | "b1" | "b2" | "muted" {
  if (level === "A2") return "a2";
  if (level === "B1") return "b1";
  if (level === "B2") return "b2";
  return "muted";
}

export const DIFFICULTY_LEVELS: SkillDifficultyLevel[] = ["EASY", "MEDIUM", "HARD"];

/**
 * Libellés repris tels quels de l'enum backend `SkillDifficulty` — et donc
 * identiques à ceux des deux fronts candidat. « Accessible » (et non « Facile »)
 * décrit le sujet sans juger celui qui le traite : l'éditeur doit voir en
 * console exactement le mot que le candidat lira.
 */
export const DIFFICULTY_LABEL: Record<SkillDifficultyLevel, string> = {
  EASY: "Accessible",
  MEDIUM: "Intermédiaire",
  HARD: "Exigeant",
};

export const DIFFICULTY_TONE: Record<SkillDifficultyLevel, "free" | "draft" | "premium"> =
  {
    EASY: "free",
    MEDIUM: "draft",
    HARD: "premium",
  };

/** Les 3 niveaux de référence, dans l'ordre imposé par le contrat (§3.5). */
export const REFERENCE_LEVELS: SkillReferenceLevel[] = [
  "INSUFFICIENT",
  "EXPECTED",
  "EXCELLENT",
];

export const REFERENCE_LABEL: Record<SkillReferenceLevel, string> = {
  INSUFFICIENT: "Insuffisant",
  EXPECTED: "Attendu",
  EXCELLENT: "Très réussi",
};

export const REFERENCE_HELP: Record<SkillReferenceLevel, string> = {
  INSUFFICIENT:
    "Ce qu'un candidat écrit quand le critère n'est pas tenu. Doit rester plausible, jamais caricatural.",
  EXPECTED: "La cible : le critère est tenu, sans virtuosité. C'est le repère principal.",
  EXCELLENT: "Le critère tenu avec aisance. Montre une marge, n'impose pas un modèle unique.",
};

/** Tâches proposées pour une section — un `taskCode` commence toujours par sa section. */
export function taskCodesForSection(section: SkillSection): SkillTaskCode[] {
  return TASK_CODES.filter((code) => code.startsWith(section));
}

export function sectionOfTaskCode(taskCode: SkillTaskCode): SkillSection {
  return taskCode.startsWith("EE") ? "EE" : "EO";
}

/** Longueur (EE) ou durée (EO) conseillée, rendue en une ligne lisible. */
export function formatRecommendation(prompt: {
  recommendedMinWords: number | null;
  recommendedMaxWords: number | null;
  recommendedDurationSeconds: number | null;
}): string {
  if (prompt.recommendedDurationSeconds !== null) {
    return `≃ ${prompt.recommendedDurationSeconds} s`;
  }
  if (prompt.recommendedMinWords !== null && prompt.recommendedMaxWords !== null) {
    return `≃ ${prompt.recommendedMinWords} à ${prompt.recommendedMaxWords} mots`;
  }
  return "—";
}

export function formatDate(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

export function truncate(text: string, max: number): string {
  const clean = text.trim();
  return clean.length <= max ? clean : `${clean.slice(0, max - 1)}…`;
}

/**
 * Un sujet est prêt à être servi quand ses 3 références sont rédigées.
 * Tolère une liste absente : le détail d'une compétence peut n'embarquer que
 * les résumés de sujets, auquel cas on affiche « à vérifier », pas une erreur.
 */
export function referencesComplete(
  references: SkillReferenceDto[] | undefined,
): boolean {
  if (!references || references.length !== REFERENCE_LEVELS.length) return false;
  return REFERENCE_LEVELS.every((level) =>
    references.some(
      (ref) =>
        ref.level === level &&
        ref.text.trim().length > 0 &&
        ref.pedagogicalNote.trim().length > 0,
    ),
  );
}

/**
 * Message d'un refus de suppression : la console n'invente rien, elle traduit
 * le 409 du backend (« des tentatives candidat référencent l'élément »).
 */
export function deletionBlockedMessage(kind: "skill" | "prompt"): string {
  const trail =
    "seulement désactivé(e). Décochez « Actif » pour le retirer des parcours " +
    "sans détruire leur historique.";
  return kind === "skill"
    ? `Des candidats ont déjà travaillé cette compétence : elle ne peut plus être supprimée, ${trail}`
    : `Des candidats ont déjà travaillé ce petit sujet : il ne peut plus être supprimé, ${trail}`;
}
