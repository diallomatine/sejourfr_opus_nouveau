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
  /** Template d'examen lié à cet attempt (null si entraînement libre).
   *  Sert à marquer "Fait" sur la liste des examens et à proposer "Voir détails / Refaire". */
  examTemplateId?: string | null;
  examTemplateSlug?: string | null;
  examTemplateName?: string | null;
}

/** True si l'attempt correspond a une production EO/EE (mobile uniquement). */
export function isProductionAttempt(a: { epreuve?: EpreuveType | null }): boolean {
  return (
    a.epreuve === "TCF_EO" ||
    a.epreuve === "TCF_EE" ||
    a.epreuve === "TCF_COMPLET"
  );
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
