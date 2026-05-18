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
  | "CE"
  | "STRUCTURE";
export type AttemptType = "TRAINING" | "MOCK_EXAM" | "REVIEW";
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
      return "Compréhension orale";
    case "CE":
      return "Compréhension écrite";
    case "STRUCTURE":
      return "Structure de la langue";
  }
}

// ============ AUTH ============
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
  /** Accès au module Civique (vrai si plan CIVIQUE_3MOIS ou INTEGRAL_3MOIS actif). */
  hasCivique?: boolean;
  /** Accès au module TCF (vrai si plan INTEGRAL_3MOIS actif). */
  hasTcf?: boolean;
  /** Date d'expiration de l'accès payant (ISO 8601), null si pas de plan actif. */
  premiumEndsAt?: string | null;
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
  url: string;
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
  questions: AttemptQuestionResponse[];
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

export interface PlanPublicResponse {
  code: string;
  name: string;
  billingCycle: BillingCycle;
  /** Prix actuel (peut être prix de lancement). */
  price: number;
  /** Prix "normal" affiché barré (offre de lancement). Null si pas de réduction. */
  originalPrice: number | null;
  moduleAccess: ModuleAccess;
  /** Durée d'accès en jours après paiement one-shot. 0 pour FREE. */
  durationDays: number;
}

// ============ ATTEMPT SUMMARY (historique) ============
// Renvoyé par GET /api/me/attempts — version légère sans les questions.
export interface AttemptSummaryResponse {
  id: string;
  type: AttemptType;
  module: Module;
  /** Cohérence avec le backend Java : `difficulty` est utilisé indifféremment
   *  pour les niveaux TCF (A2/B1/B2) et les parcours civiques (CSP/CR/NAT). */
  difficulty?: Difficulty | TargetLevel | TargetProcedure | null;
  totalQuestions: number;
  passThreshold?: number | null;
  startedAt: string;
  finishedAt?: string | null;
  score?: number | null;
  /** Template d'examen lié à cet attempt (null si entraînement libre).
   *  Sert à marquer "Fait" sur la liste des examens et à proposer "Voir détails / Refaire". */
  examTemplateId?: string | null;
  examTemplateSlug?: string | null;
  examTemplateName?: string | null;
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

// ============ HELPERS ============
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
