// Types miroirs des DTOs renvoyés par le backend Spring Boot.
// Garde-les synchronisés avec les records côté Java.

// ============ ENUMS ============
export type Module = "CIVIQUE" | "TCF";
export type TargetProcedure = "CSP" | "CR" | "NAT";
export type TargetLevel = "A2" | "B1" | "B2";
// Le back code la difficulté sous forme de niveau de cible (civique = CSP/CR/NAT, TCF = A2/B1/B2)
// et pas via une echelle facile/moyen/difficile. La valeur affichee en tag vient directement de la.
export type Difficulty = "CSP" | "CR" | "NAT" | "A2" | "B1" | "B2";
// Aligne sur com.sejourfr.app.enums.QuestionType.
export type QuestionType =
  | "CONNAISSANCE"
  | "MISE_SITUATION"
  | "CO"
  | "CO_IMAGE"
  | "CE"
  | "STRUCTURE";
export type AttemptType = "TRAINING" | "MOCK_EXAM" | "REVIEW";
/**
 * Granularite fine d'un attempt. CIVIQUE = examen civique. TCF_CO/CE/STRUCTURE
 * = QCM TCF. TCF_EO/TCF_EE/TCF_COMPLET = productions evaluees par IA — pas
 * disponibles cote web pour l'instant (mobile uniquement).
 */
export type EpreuveType =
  | "CIVIQUE"
  | "TCF_CO"
  | "TCF_CE"
  | "TCF_STRUCTURE"
  | "TCF_EO"
  | "TCF_EE"
  | "TCF_COMPLET";
export type MediaType = "AUDIO" | "IMAGE" | "VIDEO";
export type Role = "USER" | "ADMIN";
export type AudioMode = "WRITTEN_QUESTION" | "FULL_AUDIO";

/**
 * Libelle francais d'un type de question, miroir du `displayLabel` cote mobile
 * (`mobile_sejourfr/lib/core/models/enums.dart`).
 */
export function questionTypeLabel(type: QuestionType): string {
  switch (type) {
    case "CONNAISSANCE":
      return "Connaissance";
    case "MISE_SITUATION":
      return "Mise en situation";
    case "CO":
    case "CO_IMAGE":
      return "Compréhension orale";
    case "CE":
      return "Compréhension écrite";
    case "STRUCTURE":
      return "Structure de la langue";
  }
}

// ============ AUTH ============
export type AuthProvider = "LOCAL" | "GOOGLE" | "APPLE";

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  targetProcedure?: TargetProcedure;
  targetLevel?: TargetLevel;
}

/**
 * Payload envoye a POST /api/auth/google. Le `idToken` est obtenu via
 * Google Identity Services dans le navigateur (credential.credential).
 */
export interface GoogleSignInRequest {
  idToken: string;
}

export interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  expiresInSeconds: number;
  tokenType: "Bearer";
}

export interface AuthenticatedUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: Role;
  targetProcedure?: TargetProcedure;
  targetLevel?: TargetLevel;
  /** Vrai si l'utilisateur a au moins un plan payant actif (CIVIQUE ou INTÉGRAL). */
  isPremium?: boolean;
  /** Accès au module Civique (vrai si un Plan donnant accès Civique ou Intégral est actif). */
  hasCivique?: boolean;
  /** Accès au module TCF (vrai si un Plan donnant accès Intégral est actif). */
  hasTcf?: boolean;
  /** Date d'expiration de l'accès payant (ISO 8601), null si pas de plan actif. */
  premiumEndsAt?: string | null;
  /** Moyen par lequel le compte a ete cree (mot de passe local vs social). */
  authProvider?: AuthProvider;
}

// ============ THEME ============
export interface ThemeUserResponse {
  id: string;
  module: Module;
  code: string;
  name: string;
  displayOrder: number;
  questionCount?: number;
}

// ============ MEDIA ============
export interface MediaResponse {
  id: string;
  type: MediaType;
  url?: string;
  durationSeconds?: number;
  transcript?: string;
  /**
   * Quand renseigné, le front rend ce SVG inline plutôt que de charger
   * url (utilisé pour les captures TCF compréhension écrite). Le SVG est
   * fourni par le backend (seed Flyway), donc considéré comme de confiance.
   */
  inlineSvg?: string | null;
}

// ============ QUESTION (vue user) ============
export interface ChoicePublicResponse {
  id: string;
  label: string;
  displayOrder: number;
  correct: boolean | null; // null tant que l'attempt n'est pas terminé
}

export interface QuestionPublicResponse {
  id: string;
  module: Module;
  themeId: string;
  themeName: string;
  difficulty: Difficulty;
  questionType: QuestionType;
  statement: string;
  /** Renvoyé uniquement quand l'attempt parent est finalisé (rapport post-examen). */
  explanation?: string | null;
  passageText?: string;
  media?: MediaResponse;
  /**
   * Audio joué sous l'image pour les questions CO_IMAGE (intro + 4 propositions
   * lues). Renseigné uniquement pour `questionType === "CO_IMAGE"` : `media`
   * porte alors l'image, `audioMedia` l'audio.
   */
  audioMedia?: MediaResponse;
  audioMode?: AudioMode | null;
  choices: ChoicePublicResponse[];
}

// ============ QUESTION (vue review : explication + correct résolu) ============
// Renvoyé par GET /api/me/questions/favorites, /api/me/questions/wrong,
// /api/me/questions/{id}/review. Le user a déjà tenté ou favori la question.
export interface ChoiceFullResponse {
  id: string;
  label: string;
  displayOrder: number;
  correct: boolean;
}

const SINGLE_LETTER = /^[A-Za-z]$/;

/**
 * Questions TCF CO FULL_AUDIO : tous les labels se réduisent à une seule lettre
 * (A/B/C/D), qui est la clé de réponse citée par l'audio et l'explication. On
 * trie alors les choix par label pour qu'ils s'affichent dans l'ordre A→D (et
 * que la pastille colle à l'explication). Les questions normales gardent leur
 * ordre d'origine. Générique sur `{ label }` pour couvrir les Choice*Response.
 */
export function orderedChoices<T extends { label: string }>(choices: T[]): T[] {
  const allLetters =
    choices.length > 0 && choices.every((c) => SINGLE_LETTER.test(c.label.trim()));
  if (!allLetters) return choices;
  return [...choices].sort((a, b) =>
    a.label.trim().toUpperCase().localeCompare(b.label.trim().toUpperCase()),
  );
}

export interface QuestionReviewResponse {
  id: string;
  module: Module;
  themeId: string;
  themeName: string;
  difficulty: Difficulty;
  questionType: QuestionType;
  statement: string;
  passageText?: string;
  media?: MediaResponse;
  audioMedia?: MediaResponse;
  audioMode?: AudioMode | null;
  explanation?: string | null;
  choices: ChoiceFullResponse[];
}

// ============ EXAM TEMPLATE (vitrine publique) ============
export interface ExamTemplateSummary {
  id: string;
  slug: string;
  module: Module;
  targetProcedure: TargetProcedure | null;
  targetLevel: TargetLevel | null;
  name: string;
  subtitle: string | null;
  description: string | null;
  durationSeconds: number;
  totalQuestions: number;
  passingScore: number;
  free: boolean;
  position: number;
}

// ============ ATTEMPT ============
export interface StartAttemptRequest {
  type: AttemptType;
  module: Module;
  examTemplateId?: string;
  themeId?: string;
  difficulty?: Difficulty;
  questionType?: QuestionType;
  size?: number;
  /** TRAINING sur un lot précis (découpage déterministe). size est ignoré. */
  lotNumero?: number;
  /** MOCK_EXAM scopé à une épreuve TCF QCM (CO/CE/STRUCTURE). */
  moduleExamQuestionType?: QuestionType;
}

/** Lot = chunk déterministe de questions (cf. backend LotService / LotDto). */
export interface LotDto {
  numero: number;
  difficulty?: string | null;
  totalQuestions: number;
  /** Dernier score sur ce lot (null si jamais fait). */
  lastScore?: number | null;
  lastAttemptedAt?: string | null;
  /** Id du dernier attempt fini sur ce lot (null si jamais fait) — sert à
   *  ouvrir le bilan sans relancer. */
  lastAttemptId?: string | null;
}

export interface AttemptQuestionResponse {
  id: string;
  position: number;
  question: QuestionPublicResponse;
  answered: boolean;
  selectedChoiceIds: string[];
  correct: boolean | null;
}

export interface AttemptResponse {
  id: string;
  type: AttemptType;
  module: Module;
  examTemplateId: string | null;
  examTemplateSlug: string | null;
  examTemplateName: string | null;
  totalQuestions: number;
  timeLimitSeconds?: number;
  passThreshold?: number;
  startedAt: string;
  finishedAt?: string;
  score?: number;
  levelAchieved: TargetLevel | null;
  /** Non-null pour un examen module TCF (CO/CE/STRUCTURE). */
  moduleExamQuestionType?: QuestionType | null;
  /** Thème civique scopé (séries + examens thématiques) — sert au retour
   *  de session vers l'écran d'origine. */
  themeId?: string | null;
  /** Score calibré 100-499 + niveau CECRL estimé (examens module TCF). */
  calibratedScore?: number | null;
  cecrlLevel?: NiveauCecrl | null;
  /** Détail par épreuve d'un examen TCF stratifié fini — `cecrlLevel` est le
   *  plancher de ces niveaux (règle TCF IRN : il faut le niveau partout). */
  epreuveResults?: AttemptEpreuveResult[];
  questions: AttemptQuestionResponse[];
}

/** Résultat d'une épreuve au sein d'un examen TCF (CO_IMAGE regroupée sous CO). */
export interface AttemptEpreuveResult {
  epreuve: QuestionType;
  correct: number;
  total: number;
  calibratedScore: number;
  cecrlLevel: NiveauCecrl;
}

export interface SubmitAnswerRequest {
  attemptQuestionId: string;
  choiceIds: string[];
}

export interface AnswerResultResponse {
  recorded: boolean;
  correct: boolean | null;
  correctChoiceIds: string[] | null;
  explanation: string | null;
}

// ============ PLAN (vitrine publique) ============
export type BillingCycle = "NONE" | "MONTHLY" | "YEARLY" | "THREE_MONTHS" | "SIX_MONTHS";
export type ModuleAccess = "NONE" | "CIVIQUE" | "TCF" | "INTEGRAL";

/** Nature commerciale d'un plan (lot 5). ONE_TIME = pass à durée fixe sans
 *  reconduction ; SUBSCRIPTION = abonnement récurrent (dormant). */
export type PlanPurchaseType = "SUBSCRIPTION" | "ONE_TIME";

export interface PlanPublicResponse {
  code: string;
  name: string;
  billingCycle: BillingCycle;
  /** Prix actuel (peut être prix de lancement). */
  price: number;
  /** Prix "normal" affiché barré (offre de lancement). Null si pas de réduction. */
  originalPrice: number | null;
  moduleAccess: ModuleAccess;
  /** Durée d'accès en jours. Source de vérité de la durée en mode ONE_TIME. */
  durationDays: number;
  /** ONE_TIME (pass) ou SUBSCRIPTION (abonnement). Le front rend une grille de
   *  passes pour ONE_TIME, le toggle de périodicité pour SUBSCRIPTION. */
  purchaseType: PlanPurchaseType;
  /** Product IDs store (SKU IAP) consommés par le mobile pour StoreKit / Play
   *  Billing. Inutilisés côté web (paiement Stripe). Null si non configurés. */
  appleProductId: string | null;
  googleProductId: string | null;
}

// ============ ATTEMPT SUMMARY (historique) ============
// Renvoyé par GET /api/me/attempts — version légère sans les questions.
export interface AttemptSummaryResponse {
  id: string;
  type: AttemptType;
  module: Module;
  /** Granularite fine. Distingue les attempts QCM (CIVIQUE, TCF_CO/CE/STRUCTURE)
   *  des productions EO/EE (TCF_EO/TCF_EE/TCF_COMPLET) qui n'ont ni
   *  totalQuestions ni score. */
  epreuve?: EpreuveType | null;
  /** Cohérence avec le backend Java : `difficulty` est utilisé indifféremment
   *  pour les niveaux TCF (A2/B1/B2) et les parcours civiques (CSP/CR/NAT). */
  difficulty?: Difficulty | TargetLevel | TargetProcedure | null;
  /** Null pour les attempts de production EO/EE (pas de QCM). */
  totalQuestions: number | null;
  passThreshold?: number | null;
  startedAt: string;
  finishedAt?: string | null;
  score?: number | null;
  /** Score calibré 100-499 d'un examen TCF stratifié (module ou template). */
  calibratedScore?: number | null;
  /** Niveau CECRL estimé sur un examen module TCF (null sinon). */
  cecrlLevel?: NiveauCecrl | null;
  /** Non-null pour un examen module TCF scopé à une épreuve (CO/CE/STRUCTURE). */
  moduleExamQuestionType?: QuestionType | null;
  /** Thème civique ciblé (lot ou examen thématique) — null pour un examen
   *  blanc complet 40 Q tous thèmes. */
  lotThemeId?: string | null;
  /** Template d'examen lié à cet attempt (null si entraînement libre).
   *  Sert à marquer "Fait" sur la liste des examens et à proposer "Voir détails / Refaire". */
  examTemplateId?: string | null;
  examTemplateSlug?: string | null;
  examTemplateName?: string | null;
}

/** True si l'attempt correspond a une production EO/EE. */
export function isProductionAttempt(a: { epreuve?: EpreuveType | null }): boolean {
  return (
    a.epreuve === "TCF_EO" ||
    a.epreuve === "TCF_EE" ||
    a.epreuve === "TCF_COMPLET"
  );
}

// ============================================================================
// PRODUCTION ÉCRITE / ORALE (TCF_EE / TCF_EO) — évaluation IA
// Miroirs de ProductionTaskDto / ProductionSubmissionDto / EvaluationResultDto /
// ProductionExampleDto côté Java + des enums SubmissionStatut / NiveauCecrl.
// ============================================================================

/** Cycle de vie d'une soumission (cf. enums.SubmissionStatut). EE saute
 *  TRANSCRIBING (pas de Whisper). En MVP synchrone on observe surtout
 *  SUBMITTED → EVALUATED (ou FAILED). */
export type SubmissionStatut =
  | "SUBMITTED"
  | "TRANSCRIBING"
  | "EVALUATING"
  | "EVALUATED"
  | "FAILED";

/** Niveau CECRL d'une éval IA (distinct de TargetLevel : inclut A1/C1/C2 +
 *  plancher A1_NON_ATTEINT). */
export type NiveauCecrl =
  | "A1_NON_ATTEINT"
  | "A1"
  | "A2"
  | "B1"
  | "B2"
  | "C1"
  | "C2";

/** POST /api/attempts/production — crée un attempt vide pour EO/EE. */
export interface ProductionAttemptStartRequest {
  module: Module;
  epreuve: EpreuveType;
  parentAttemptId?: string | null;
  /**
   * True pour une session d'examen blanc production (3 tâches). Marque
   * l'attempt côté backend : ses soumissions bypassent le quota
   * d'entraînement, et les sessions d'examen comptent dans le budget
   * gratuit (1 examen offert, le 2ᵉ consomme les essais EE/EO restants).
   */
  exam?: boolean;
}

/** Tâche EE/EO. La grille d'évaluation n'est volontairement pas exposée. */
export interface ProductionTaskDto {
  id: string;
  epreuve: EpreuveType;
  tacheNumero: number;
  niveauCible: string; // "A2" | "B1" | "B2"
  consigne: string;
  contexte: string | null;
  dureeMaxSec: number | null; // EO uniquement
  dureeMinSec: number | null; // EO uniquement
  motsMin: number | null; // EE
  motsMax: number | null; // EE
}

/** Réponse-modèle d'une tâche (onglet « Exemples »). audioUrl = EO seulement. */
export interface ProductionExampleDto {
  id: string;
  titre: string;
  resume: string | null;
  contenu: string;
  explications: string | null;
  audioUrl: string | null;
  planPoints: string[];
  niveauIndicatif: string | null;
}

/** Résultat IA. `feedback` est le JSONB brut (clés snake_case) — utiliser
 *  {@link parseEeFeedback} pour le normaliser avant affichage. */
export interface EvaluationResultDto {
  noteSurVingt: number | null;
  niveauCecrl: NiveauCecrl | null;
  justificationNiveau: string | null;
  feedback: Record<string, unknown> | null;
}

export interface ProductionSubmissionDto {
  id: string;
  attemptId: string;
  productionTaskId: string;
  /** Numéro de tâche (1/2/3) — sert à regrouper par tâche dans les hubs. */
  tacheNumero: number | null;
  statut: SubmissionStatut;
  mediaUrl: string | null; // EO
  texteSoumis: string | null; // EE
  motsCount: number | null;
  mediaDurationSec: number | null; // EO
  retryCount: number;
  erreurMessage: string | null;
  submittedAt: string;
  /** Null tant que statut != EVALUATED. */
  evaluation: EvaluationResultDto | null;
  transcription: string | null; // EO
}

/** Body JSON de POST /api/production-submissions (EE). */
export interface SubmitProductionTextRequest {
  productionTaskId: string;
  attemptId: string;
  texte: string;
}

/** Vrai tant que l'évaluation IA n'a pas abouti. */
export function isSubmissionPending(s: { statut: SubmissionStatut }): boolean {
  return s.statut !== "EVALUATED" && s.statut !== "FAILED";
}

/** Titre éditorial d'une tâche EE (parité `displayTitle` mobile). */
export function eeTaskTitle(tacheNumero: number): string {
  switch (tacheNumero) {
    case 1:
      return "Message simple";
    case 2:
      return "Récit d'expérience";
    case 3:
      return "Point de vue argumenté";
    default:
      return `Tâche ${tacheNumero}`;
  }
}

/** Sous-titre d'une tâche EE. */
export function eeTaskSubtitle(tacheNumero: number): string {
  switch (tacheNumero) {
    case 1:
      return "Rédiger un message court et cohérent";
    case 2:
      return "Raconter une expérience avec clarté";
    case 3:
      return "Justifier une opinion avec des arguments";
    default:
      return "";
  }
}

/** Titre éditorial d'une tâche EO (parité mobile). */
export function eoTaskTitle(tacheNumero: number): string {
  switch (tacheNumero) {
    case 1:
      return "Entretien dirigé";
    case 2:
      return "Expression d'un point de vue";
    case 3:
      return "Jeu de rôle";
    default:
      return `Tâche ${tacheNumero}`;
  }
}

/** Sous-titre d'une tâche EO. */
export function eoTaskSubtitle(tacheNumero: number): string {
  switch (tacheNumero) {
    case 1:
      return "Se présenter et répondre à des questions";
    case 2:
      return "Donner et défendre son opinion";
    case 3:
      return "Interagir dans une situation simulée";
    default:
      return "";
  }
}

/** Titre d'une tâche selon l'épreuve productive (EE / EO). */
export function productionTaskTitle(epreuve: EpreuveType, tacheNumero: number): string {
  return epreuve === "TCF_EO" ? eoTaskTitle(tacheNumero) : eeTaskTitle(tacheNumero);
}

/** Sous-titre d'une tâche selon l'épreuve productive (EE / EO). */
export function productionTaskSubtitle(epreuve: EpreuveType, tacheNumero: number): string {
  return epreuve === "TCF_EO" ? eoTaskSubtitle(tacheNumero) : eeTaskSubtitle(tacheNumero);
}

/** Durée lisible « 1 min 30 » / « 2 min » à partir de secondes. */
export function formatDurationSec(sec: number | null | undefined): string {
  if (sec == null || sec <= 0) return "";
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  if (m === 0) return `${s} s`;
  return s === 0 ? `${m} min` : `${m} min ${s}`;
}

/** Libellé affichable d'un niveau CECRL. */
export function niveauCecrlLabel(n: NiveauCecrl | null | undefined): string {
  if (!n) return "—";
  return n === "A1_NON_ATTEINT" ? "A1 non atteint" : n;
}

/** Position d'un niveau sur l'échelle affichée [A1, A2, B1, B2, C1, C2] (6
 *  segments). A1_NON_ATTEINT → -1 (sous le seuil A1). */
export function cecrlIndex(n: NiveauCecrl | null | undefined): number {
  switch (n) {
    case "A1_NON_ATTEINT":
      return -1;
    case "A1":
      return 0;
    case "A2":
      return 1;
    case "B1":
      return 2;
    case "B2":
      return 3;
    case "C1":
      return 4;
    case "C2":
      return 5;
    default:
      return -1;
  }
}

// ---- Feedback IA normalisé (le backend renvoie des clés snake_case) ----

export interface EeCriterion {
  code: string;
  label: string;
  noteSurVingt: number;
  commentaire: string | null;
}

export interface EeCorrection {
  original: string;
  corrige: string;
  explication: string | null;
}

export interface EeFeedback {
  noteGlobale: number | null;
  niveauCecrl: NiveauCecrl | null;
  justification: string | null;
  criteres: EeCriterion[];
  pointsForts: string[];
  pointsAAmeliorer: string[];
  suggestions: string[];
  exemplesCorriges: EeCorrection[];
  avertissements: string[];
}

function asRecord(v: unknown): Record<string, unknown> | null {
  return v && typeof v === "object" && !Array.isArray(v)
    ? (v as Record<string, unknown>)
    : null;
}

function asStringList(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.filter((x): x is string => typeof x === "string" && x.trim().length > 0);
}

function asNumber(v: unknown): number | null {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim() !== "" && !Number.isNaN(Number(v))) {
    return Number(v);
  }
  return null;
}

function asString(v: unknown): string | null {
  return typeof v === "string" && v.trim().length > 0 ? v : null;
}

/**
 * Normalise le `feedback` JSONB d'une {@link EvaluationResultDto} en structure
 * typée prête à l'affichage. Tolérant aux variations de clés (`justification`
 * vs `commentaire`, valeurs manquantes) pour rester robuste aux versions de
 * prompt IA.
 */
export function parseEeFeedback(
  evaluation: EvaluationResultDto | null | undefined,
): EeFeedback {
  const empty: EeFeedback = {
    noteGlobale: evaluation?.noteSurVingt ?? null,
    niveauCecrl: evaluation?.niveauCecrl ?? null,
    justification: evaluation?.justificationNiveau ?? null,
    criteres: [],
    pointsForts: [],
    pointsAAmeliorer: [],
    suggestions: [],
    exemplesCorriges: [],
    avertissements: [],
  };
  const fb = asRecord(evaluation?.feedback);
  if (!fb) return empty;

  const criteresRaw = Array.isArray(fb.scores_criteres) ? fb.scores_criteres : [];
  const criteres: EeCriterion[] = criteresRaw
    .map((c): EeCriterion | null => {
      const r = asRecord(c);
      if (!r) return null;
      const code = asString(r.code) ?? "";
      const note = asNumber(r.note_sur_20);
      return {
        code,
        label: asString(r.label) ?? eeCriterionLabel(code),
        noteSurVingt: note ?? 0,
        commentaire: asString(r.justification) ?? asString(r.commentaire),
      };
    })
    .filter((c): c is EeCriterion => c !== null);

  const correctionsRaw = Array.isArray(fb.exemples_corriges) ? fb.exemples_corriges : [];
  const exemplesCorriges: EeCorrection[] = correctionsRaw
    .map((e): EeCorrection | null => {
      const r = asRecord(e);
      if (!r) return null;
      const original = asString(r.original);
      const corrige = asString(r.corrige);
      if (!original && !corrige) return null;
      return {
        original: original ?? "",
        corrige: corrige ?? "",
        explication: asString(r.explication),
      };
    })
    .filter((e): e is EeCorrection => e !== null);

  return {
    noteGlobale: asNumber(fb.note_globale) ?? empty.noteGlobale,
    niveauCecrl: (asString(fb.niveau_cecrl) as NiveauCecrl | null) ?? empty.niveauCecrl,
    justification: asString(fb.justification_niveau) ?? empty.justification,
    criteres,
    pointsForts: asStringList(fb.points_forts),
    pointsAAmeliorer: asStringList(fb.points_a_ameliorer),
    suggestions: asStringList(fb.suggestions),
    exemplesCorriges,
    avertissements: asStringList(fb.avertissements),
  };
}

/** Libellé de repli pour un critère EE si le backend n'a pas fourni `label`. */
export function eeCriterionLabel(code: string): string {
  switch (code) {
    case "pertinence":
      return "Pertinence et développement du contenu";
    case "coherence":
    case "organisation":
      return "Organisation et cohérence";
    case "vocabulaire":
    case "lexique":
      return "Richesse et précision du vocabulaire";
    case "grammaire":
      return "Correction grammaticale";
    case "orthographe":
      return "Orthographe et ponctuation";
    case "clarte_ecrite":
      return "Clarté de l'expression écrite";
    default:
      return code ? code.charAt(0).toUpperCase() + code.slice(1).replace(/_/g, " ") : "Critère";
  }
}

// ============ STATS ============
export interface ThemeStatsResponse {
  themeId: string;
  themeName: string;
  answered: number;
  correct: number;
  total: number;
}

export interface UserStatsResponse {
  attemptsTotal: number;
  questionsAnswered: number;
  questionsCorrect: number;
  successRate: number; // 0..1
  byTheme: ThemeStatsResponse[];
}

/** Une catégorie du dashboard (GET /api/me/dashboard). */
export interface DashboardCategoryStat {
  /** Null pour les entrées synthétiques EE/EO. */
  themeId: string | null;
  /** Code stable : theme.code (CIV_PRINCIPES, TCF_CO…) ou TCF_EE / TCF_EO. */
  code: string;
  label: string;
  /** Progression 0-100 = réussite × confiance (confiance = min(1,
   *  répondues / min(40, pool)) ; EE/EO : moyenne des 3 dernières notes /20
   *  ×5 × min(1, n/3)). Null si jamais travaillé. */
  percent: number | null;
  answered: number;
  /** Pool de questions actives — 0 pour EE/EO. */
  total: number;
  /** Examens blancs finis scopés à la catégorie (0 pour EE/EO). */
  mockExams: number;
  /** Record / dernier / avant-dernier score brut sur les examens de la
   *  catégorie (page Progression). Null si pas assez d'examens. */
  bestMockScore: number | null;
  lastMockScore: number | null;
  prevMockScore: number | null;
  /** Dernier niveau CECRL évalué — EE/EO uniquement. */
  level: NiveauCecrl | null;
}

/** GET /api/me/dashboard — agrégat unique du tableau de bord web. */
export interface DashboardSummaryResponse {
  currentStreakDays: number;
  recordStreakDays: number;
  activeToday: boolean;
  mockExamsTotal: number;
  /** Totaux par module (TCF : sous-attempts d'examen complet exclus). */
  civiqueMockExams: number;
  tcfMockExams: number;
  /** Progression globale = moyenne des progressions des catégories renseignées. */
  globalSuccessPercent: number | null;
  estimatedTcfLevel: NiveauCecrl | null;
  civique: DashboardCategoryStat[];
  tcf: DashboardCategoryStat[];
}

// ============ HELPERS ============

/** Niveau TCF visé dérivé du parcours civique (CSP→A2, CR→B1, NAT→B2). */
export function tcfLevelFromProcedure(
  p: TargetProcedure | null | undefined,
): TargetLevel | null {
  return p === "NAT" ? "B2" : p === "CR" ? "B1" : p === "CSP" ? "A2" : null;
}

/** Niveau TCF effectif d'un utilisateur : targetLevel explicite, sinon dérivé
 *  du parcours, sinon B1 par défaut. Utilisé pour piocher les tâches EO/EE. */
export function resolveTcfLevel(
  user: Pick<AuthenticatedUser, "targetLevel" | "targetProcedure"> | null,
): TargetLevel {
  return user?.targetLevel ?? tcfLevelFromProcedure(user?.targetProcedure) ?? "B1";
}

export function canAccessModule(
  user: Pick<AuthenticatedUser, "hasCivique" | "hasTcf"> | null,
  module: Module,
): boolean {
  if (!user) return false;
  if (module === "CIVIQUE") return user.hasCivique ?? false;
  return user.hasTcf ?? false;
}

// ============ ERREURS API ============
export interface ApiError {
  status: number;
  error: string;
  message: string;
  path?: string;
  timestamp?: string;
  fieldErrors?: Record<string, string>;
}

// ============================================================================
// Billing : statut Premium + résiliation
// ============================================================================

export type SubscriptionSource = "STRIPE" | "APPLE" | "GOOGLE";

export type SubscriptionStatus =
  | "ACTIVE"
  | "TRIAL"
  | "IN_GRACE"
  | "PENDING"
  | "CANCELED"
  | "EXPIRED"
  | "REFUNDED";

/** Statut Premium agrégé toutes sources (Stripe + Apple + Google). Renvoyé
 * par `GET /api/billing/subscription-status`. Source de vérité unique côté
 * backend — le client NE décide PAS du Premium. */
export interface SubscriptionStatusResponse {
  isPremium: boolean;
  source: SubscriptionSource | null;
  productId: string | null;
  expiresAt: string | null;
  status: SubscriptionStatus | null;
  moduleAccess: ModuleAccess;
  autoRenew: boolean;
  /** True si l'accès vient d'un pass one-time (lot 5) : « Mon accès » sans
   *  résiliation. Absent (undefined) sur les anciens backends → traiter false. */
  oneTime?: boolean;
}

/** Réponse de `POST /api/billing/cancel`. Deux variantes :
 * - `DONE` : Stripe a enregistré la résiliation côté serveur (Premium reste
 *   ouvert jusqu'à `expiresAt`).
 * - `REDIRECT` : Apple/Google n'autorisent pas l'annulation serveur ; le
 *   `redirectUrl` pointe vers la page de gestion d'abonnement du store. */
export interface CancelSubscriptionResponse {
  action: "DONE" | "REDIRECT";
  message: string;
  redirectUrl: string | null;
}

/** Réponse de `DELETE /api/account` (suppression de compte).
 * La suppression aboutit toujours (`deleted=true`, anonymisation côté serveur) ;
 * `manualActionMessage` n'est rempli que si un abonnement Apple/Google reste à
 * résilier manuellement dans le store. */
export interface AccountDeletionResponse {
  deleted: boolean;
  hasActiveSubscription: boolean;
  subscriptionProvider: string | null;
  manualActionMessage: string | null;
}

// ============================================================================
// EXAMEN BLANC TCF COMPLET (TCF_COMPLET) — orchestration CO → CE → EE → EO
// Miroirs de FullTcfExamResponse / FullTcfExamSummaryResponse côté Java
// (controller FullTcfExamController). Le parent TCF_COMPLET porte 4
// sous-attempts, l'évaluation IA des productions EE/EO tourne en arrière-plan.
// ============================================================================

/** Statut agrégé d'un examen complet (cf. FullTcfExamResponse.FullTcfExamStatus).
 *  IN_PROGRESS : au moins une épreuve pas terminée. PENDING_EVALUATIONS : les 4
 *  terminées mais l'IA EE/EO n'a pas fini. COMPLETED : tout évalué,
 *  `finalCecrlLevel` posé (plancher des 4 épreuves). */
export type FullTcfExamStatus = "IN_PROGRESS" | "PENDING_EVALUATIONS" | "COMPLETED";

/** Une sous-épreuve de l'examen complet. `finishedAt` non nul = terminée. Pour
 *  CO/CE : `score`/`maxScore` (QCM). Pour EE/EO : `submissionsCount` (tâches
 *  EVALUATED sur 3) + `failedSubmissionIds` (à relancer). `cecrlLevel` apparaît
 *  une fois l'épreuve évaluée. */
export interface FullTcfExamSubAttempt {
  attemptId: string;
  epreuve: EpreuveType;
  finishedAt: string | null;
  cecrlLevel: NiveauCecrl | null;
  score: number | null;
  maxScore: number | null;
  submissionsCount: number | null;
  failedSubmissionIds: string[];
}

export interface FullTcfExamResponse {
  id: string;
  startedAt: string;
  finishedAt: string | null;
  finalCecrlLevel: NiveauCecrl | null;
  status: FullTcfExamStatus;
  subAttempts: FullTcfExamSubAttempt[];
}

export interface FullTcfExamSummaryResponse {
  id: string;
  startedAt: string;
  finishedAt: string | null;
  finalCecrlLevel: NiveauCecrl | null;
  status: FullTcfExamStatus;
  slotNumber: number | null;
}

/** Durée totale de l'examen complet (90 min). Constante backend
 *  `FullTcfExamService.FULL_EXAM_TOTAL_SECONDS`, non exposée dans le DTO. */
export const FULL_TCF_EXAM_DURATION_SEC = 90 * 60;

/** Ordre canonique des 4 épreuves de l'examen complet. */
export const FULL_TCF_EXAM_EPREUVES = [
  "TCF_CO",
  "TCF_CE",
  "TCF_EE",
  "TCF_EO",
] as const;
