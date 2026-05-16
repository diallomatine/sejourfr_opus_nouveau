// Types miroirs des DTOs renvoyés par le backend Spring Boot.
// Garde-les synchronisés avec les records côté Java.

// ============ ENUMS ============
export type Module = "CIVIQUE" | "TCF";
export type TargetProcedure = "CSP" | "CR" | "NAT";
export type TargetLevel = "A2" | "B1" | "B2";
export type Difficulty = "EASY" | "MEDIUM" | "HARD";
export type QuestionType = "KNOWLEDGE" | "SITUATION";
export type AttemptType = "TRAINING" | "MOCK_EXAM" | "REVIEW";
export type MediaType = "AUDIO" | "IMAGE" | "VIDEO";
export type Role = "USER" | "ADMIN";

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
  passageText?: string;
  media?: MediaResponse;
  choices: ChoicePublicResponse[];
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

// ============ ERREURS API ============
export interface ApiError {
  status: number;
  error: string;
  message: string;
  path?: string;
  timestamp?: string;
  fieldErrors?: Record<string, string>;
}
