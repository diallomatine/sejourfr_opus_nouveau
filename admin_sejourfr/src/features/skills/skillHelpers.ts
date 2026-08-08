import type {
  SkillConstraintIcon,
  SkillConstraintTagDto,
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

// ---------------------------------------------------------------------------
// Guidage de l'écran de saisie (check-list, étiquettes, amorce, astuce)
// ---------------------------------------------------------------------------

/** Bornes serveur (`AdminSkillService`) : un dépassement part en 422. */
export const CHECKLIST_MIN = 2;
export const CHECKLIST_MAX = 4;
export const CONSTRAINT_TAGS_MIN = 1;
export const CONSTRAINT_TAGS_MAX = 3;

/** Bornes de rédaction : elles tiennent la mise en page de l'écran candidat. */
export const CHECKLIST_ITEM_MAX_WORDS = 6;
export const CONSTRAINT_LABEL_MAX_WORDS = 3;
export const ANSWER_STARTER_MIN_WORDS = 4;
export const ANSWER_STARTER_MAX_WORDS = 8;
export const TIP_MAX_WORDS = 15;

/** Les 8 valeurs de l'enum backend `SkillConstraintIcon`, dans son ordre. */
export const CONSTRAINT_ICONS: SkillConstraintIcon[] = [
  "TONE",
  "PERSON",
  "TIME",
  "PLACE",
  "NUMBER",
  "TENSE",
  "STRUCTURE",
  "EXAMPLE",
];

export const CONSTRAINT_ICON_LABEL: Record<SkillConstraintIcon, string> = {
  TONE: "Ton",
  PERSON: "Personne",
  TIME: "Moment",
  PLACE: "Lieu",
  NUMBER: "Quantité",
  TENSE: "Temps du récit",
  STRUCTURE: "Structure",
  EXAMPLE: "Exemple",
};

/** Ce que chaque famille couvre — repris mot pour mot de l'enum backend. */
export const CONSTRAINT_ICON_HELP: Record<SkillConstraintIcon, string> = {
  TONE: "registre, politesse, ton",
  PERSON: "destinataire, vouvoiement, personne",
  TIME: "moment, durée, temps verbal",
  PLACE: "lieu, situation géographique",
  NUMBER: "quantité, nombre d'éléments",
  TENSE: "temps du récit (passé composé, imparfait)",
  STRUCTURE: "organisation, enchaînement, connecteurs",
  EXAMPLE: "exemple, illustration, précision concrète",
};

/** Compte les mots d'un texte libre. Sert aux compteurs et aux garde-fous. */
export function countWords(text: string): number {
  const clean = text.trim();
  return clean.length === 0 ? 0 : clean.split(/\s+/).length;
}

/**
 * L'amorce doit se terminer par les points de suspension : c'est ce qui la
 * donne à lire comme un début de phrase et non comme une réponse. On accepte
 * les trois points saisis au clavier et on les normalise en « … ».
 */
export function normalizeAnswerStarter(text: string): string {
  const clean = text.trim();
  if (clean.length === 0) return "";
  return clean.endsWith("...") ? `${clean.slice(0, -3)}…` : clean;
}

/** Le préfixe « Astuce : » est ajouté par les fronts : le stocker le doublerait. */
export function startsWithAstucePrefix(text: string): boolean {
  return /^astuce\s*:/i.test(text.trim());
}

type GuidanceState = "complete" | "partial" | "absent";

interface GuidanceFields {
  checklist: string[] | null;
  constraintTags: SkillConstraintTagDto[] | null;
  answerStarter: string | null;
  tip: string | null;
}

/**
 * Un sujet peut légalement vivre sans guidage — mais il est alors incomplet :
 * l'écran candidat retombe sur la consigne. « partial » est le cas à corriger
 * en priorité, il signale un sujet à moitié rédigé.
 */
export function guidanceState(prompt: GuidanceFields): GuidanceState {
  const filled = [
    prompt.checklist !== null && prompt.checklist.length > 0,
    prompt.constraintTags !== null && prompt.constraintTags.length > 0,
    prompt.answerStarter !== null && prompt.answerStarter.trim().length > 0,
    prompt.tip !== null && prompt.tip.trim().length > 0,
  ].filter(Boolean).length;
  if (filled === 4) return "complete";
  return filled === 0 ? "absent" : "partial";
}

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
