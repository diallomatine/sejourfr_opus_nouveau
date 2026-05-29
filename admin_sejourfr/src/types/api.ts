// Enums du backend, en string union pour simplicité.

export type Module = "CIVIQUE" | "TCF";

export type Difficulty = "CSP" | "CR" | "NAT" | "A2" | "B1" | "B2";

export type QuestionType =
  | "CONNAISSANCE"
  | "MISE_SITUATION"
  | "CO"
  | "CE"
  | "STRUCTURE";

export type Role = "USER" | "ADMIN";

export type TargetProcedure = "CSP" | "CR" | "NAT";
export type TargetLevel = "A2" | "B1" | "B2";

export type MessageStatus =
  | "NOUVEAU"
  | "LU"
  | "EN_COURS"
  | "REPONDU"
  | "ARCHIVE";

export type MessageSender = "USER" | "ADMIN";

export type MediaType = "AUDIO" | "IMAGE" | "VIDEO";

export type PassageType = "TEXTE" | "AUDIO" | "DIALOGUE";

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------
export interface AuthenticatedUser {
  id: string;
  email: string;
  firstName: string | null;
  lastName: string | null;
  role: Role;
}

export interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  expiresInSeconds: number;
  tokenType: "Bearer";
  user: AuthenticatedUser;
}

// ---------------------------------------------------------------------------
// Pagination generique du backend
// ---------------------------------------------------------------------------
export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
}

// ---------------------------------------------------------------------------
// Erreur API
// ---------------------------------------------------------------------------
export interface ApiError {
  timestamp: string;
  status: number;
  error: string;
  message: string;
  path: string;
  fieldErrors?: { field: string; message: string }[];
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------
export interface DashboardDto {
  questionsCivique: number;
  questionsCiviqueActive: number;
  questionsTcf: number;
  questionsTcfActive: number;
  usersTotal: number;
  conversationsUnread: number;
}

// ---------------------------------------------------------------------------
// Themes
// ---------------------------------------------------------------------------
export interface ThemeDto {
  id: string;
  module: Module;
  code: string;
  name: string;
  description: string | null;
  displayOrder: number;
  questionCount: number;
}

export interface ThemeWriteRequest {
  module: Module;
  code: string;
  name: string;
  description?: string;
  displayOrder: number;
}

// ---------------------------------------------------------------------------
// Questions
// ---------------------------------------------------------------------------
export interface ChoiceDto {
  id: string;
  label: string;
  correct: boolean;
  displayOrder: number;
}

export interface ChoiceWriteRequest {
  label: string;
  correct: boolean;
  displayOrder: number;
}

export interface QuestionDto {
  id: string;
  module: Module;
  themeId: string;
  themeName: string;
  passageId: string | null;
  passageType: PassageType | null;
  passagePreview: string | null;
  mediaId: string | null;
  mediaUrl: string | null;
  mediaType: MediaType | null;
  mediaInlineSvg: string | null;
  difficulty: Difficulty;
  questionType: QuestionType;
  statement: string;
  explanation: string | null;
  active: boolean;
  createdAt: string;
  updatedAt: string | null;
  choices: ChoiceDto[];
}

// ---------------------------------------------------------------------------
// Passages
// ---------------------------------------------------------------------------
export interface PassageDto {
  id: string;
  type: PassageType;
  content: string | null;
  themeId: string | null;
  themeName: string | null;
  mediaId: string | null;
  mediaUrl: string | null;
  mediaType: MediaType | null;
  questionCount: number;
}

export interface PassageWriteRequest {
  type: PassageType;
  content?: string | null;
  themeId: string;
  mediaId?: string | null;
}

// ---------------------------------------------------------------------------
// Médias
// ---------------------------------------------------------------------------
export interface MediaDto {
  id: string;
  type: MediaType;
  url: string;
  originalFilename: string | null;
  contentType: string | null;
  sizeBytes: number | null;
  durationSec: number | null;
  altText: string | null;
  /**
   * SVG inline. Quand renseigné, l'admin/runner affiche ce balisage SVG
   * plutôt que de charger url. Utilisé pour les captures TCF compréhension
   * écrite générées dans les seeds.
   */
  inlineSvg: string | null;
  createdAt: string;
}

export interface MediaCreateFromUrlRequest {
  type: MediaType;
  url: string;
  durationSec?: number;
  altText?: string;
}

export interface QuestionWriteRequest {
  module: Module;
  themeId: string;
  passageId?: string | null;
  mediaId?: string | null;
  difficulty: Difficulty;
  questionType: QuestionType;
  statement: string;
  explanation?: string;
  active?: boolean;
  choices: ChoiceWriteRequest[];
}

// ---------------------------------------------------------------------------
// Examens blancs (ExamTemplate + règles)
// ---------------------------------------------------------------------------
export interface AdminExamTemplateRuleDto {
  id: string;
  themeId: string | null;
  themeName: string | null;
  questionType: QuestionType | null;
  difficulty: Difficulty | null;
  questionCount: number;
  position: number;
}

export interface AdminExamTemplateDto {
  id: string;
  slug: string;
  module: Module;
  targetLevel: TargetLevel | null;
  targetProcedure: TargetProcedure | null;
  name: string;
  subtitle: string | null;
  description: string | null;
  durationSeconds: number;
  totalQuestions: number;
  passingScore: number;
  free: boolean;
  published: boolean;
  position: number;
  createdAt: string;
  updatedAt: string | null;
  rules: AdminExamTemplateRuleDto[];
}

export interface AdminExamTemplateRuleWriteRequest {
  themeId?: string | null;
  questionType?: QuestionType | null;
  difficulty?: Difficulty | null;
  questionCount: number;
}

export interface AdminExamTemplateWriteRequest {
  slug: string;
  module: Module;
  targetLevel?: TargetLevel | null;
  targetProcedure?: TargetProcedure | null;
  name: string;
  subtitle?: string | null;
  description?: string | null;
  durationSeconds: number;
  totalQuestions: number;
  passingScore: number;
  free: boolean;
  published: boolean;
  position: number;
  rules: AdminExamTemplateRuleWriteRequest[];
}

export interface ExamCompositionSuggestionDto {
  targetTotal: number;
  poolSize: number;
  warning: string | null;
  rules: {
    themeId: string | null;
    themeName: string | null;
    difficulty: Difficulty | null;
    questionCount: number;
    available: number;
  }[];
}

// ---------------------------------------------------------------------------
// Conversations
// ---------------------------------------------------------------------------
export interface ConversationSummaryDto {
  id: string;
  userId: string;
  userEmail: string;
  userFullName: string;
  subject: string;
  status: MessageStatus;
  createdAt: string;
  lastMessageAt: string;
  unreadForAdmin: boolean;
  lastMessagePreview: string;
  messageCount: number;
}

export interface MessageDto {
  id: string;
  conversationId: string;
  senderType: MessageSender;
  authorId: string;
  authorName: string;
  body: string;
  createdAt: string;
}

export interface ConversationDetailDto {
  id: string;
  userId: string;
  userEmail: string;
  userFullName: string;
  subject: string;
  status: MessageStatus;
  createdAt: string;
  lastMessageAt: string;
  unreadForAdmin: boolean;
  unreadForUser: boolean;
  messages: MessageDto[];
}

// ---------------------------------------------------------------------------
// Audio questions (pipeline TCF Comprehension Orale generee)
// Voir backend : com.sejourfr.app.audioquestion.*
// ---------------------------------------------------------------------------
export type AudioLevel = "A2" | "B1" | "B2";

export type AudioTheme =
  | "vie_pratique_logement"
  | "travail"
  | "sante"
  | "administratif"
  | "transports"
  | "consommation"
  | "medias_numerique"
  | "environnement";

export type AudioContentType =
  | "annonce"
  | "monologue"
  | "dialogue"
  | "interview"
  | "reportage";

export type CompetenceCo =
  | "co_reperage_explicite"
  | "co_detail_specifique"
  | "co_idee_principale"
  | "co_inference_intention"
  | "co_ton_attitude"
  | "co_reformulation";

export type QuestionStatus = "DRAFT" | "ACTIVE" | "ARCHIVED";

export type GenerationStatus =
  | "SUCCESS"
  | "FAILED_VALIDATION"
  | "FAILED_RATE_LIMIT"
  | "FAILED_ANTHROPIC"
  | "FAILED_ANTHROPIC_PARSE"
  | "FAILED_CONTENT_VALIDATION"
  | "FAILED_DUPLICATE"
  | "FAILED_AZURE_SPEECH"
  | "FAILED_R2_UPLOAD"
  | "FAILED_DB"
  | "FAILED_TIMEOUT"
  | "REJECTED_BY_ADMIN";

export type AudioMode = "WRITTEN_QUESTION" | "FULL_AUDIO";

export interface GenerateAudioQuestionRequest {
  niveau: AudioLevel;
  theme?: AudioTheme | null;
  typeSouhaite?: AudioContentType | null;
  competenceVisee?: CompetenceCo | null;
  consignesSpecifiques?: string | null;
  audioMode?: AudioMode | null;
}

export interface AudioVoiceDto {
  role: string;
  azureVoice: string;
  gender: "F" | "M";
}

export interface AudioPreviewDto {
  mediaId: string;
  url: string;
  durationSec: number;
  speakerCount: number;
  voices: AudioVoiceDto[];
  transcript: string;
  contextDescription: string | null;
  audioMode?: AudioMode | null;
}

export interface AudioQuestionContentDto {
  statement: string;
  explanation: string;
  competenceCode: CompetenceCo | null;
  difficulty: AudioLevel;
  theme: AudioTheme | null;
}

export interface AudioChoiceDto {
  id: string;
  label: string;
  isCorrect: boolean;
  displayOrder: number;
}

export interface AudioGenerationMetadataDto {
  generatedAt: string;
  generationDurationMs: number;
  costEur: number;
  anthropicInputTokens: number | null;
  anthropicOutputTokens: number | null;
  anthropicCacheReadTokens: number | null;
  azureCharactersCount: number | null;
}

export interface QuestionPreviewDto {
  questionId: string;
  status: QuestionStatus;
  audio: AudioPreviewDto;
  question: AudioQuestionContentDto;
  choices: AudioChoiceDto[];
  metadata: AudioGenerationMetadataDto;
}

export interface ValidationResultDto {
  questionId: string;
  status: QuestionStatus;
  activatedAt: string;
}

export interface GenerationLogDto {
  id: string;
  questionId: string | null;
  adminUserId: string;
  requestedParams: string;
  promptVersion: string | null;
  anthropicModel: string | null;
  anthropicInputTokens: number | null;
  anthropicOutputTokens: number | null;
  anthropicCacheReadTokens: number | null;
  anthropicCostEur: number | null;
  azureCharactersCount: number | null;
  azureCostEur: number | null;
  r2ObjectKey: string | null;
  durationMs: number | null;
  status: GenerationStatus;
  errorMessage: string | null;
  createdAt: string;
}

/**
 * Format d'erreur etendu retourne par AudioQuestionExceptionHandler.
 * Reprend ApiError + code applicatif + details libres.
 */
export interface AudioApiError {
  timestamp: string;
  status: number;
  error: string;
  code: string;
  message: string;
  path: string;
  details?: Record<string, unknown>;
}

// ---------------------------------------------------------------------------
// Audio drafts (workflow batch parallele a la generation unitaire)
// Voir backend : com.sejourfr.app.audioquestion.AudioDraftService
// ---------------------------------------------------------------------------
export type AudioDraftStatus =
  | "TEXT_VALIDATED"
  | "AUDIO_GENERATING"
  | "AUDIO_PENDING_REVIEW"
  | "PUBLISHED"
  | "REJECTED";

export interface AudioDraftChoiceDto {
  label: string;
  isCorrect: boolean;
  displayOrder: number;
}

export interface AudioDraftDto {
  id: string;
  difficulty: AudioLevel | null;
  competenceCode: string | null;
  themeId: string | null;
  themeName: string | null;
  transcriptText: string;
  statement: string;
  explanation: string | null;
  choices: AudioDraftChoiceDto[];
  voiceRecommended: string | null;
  status: AudioDraftStatus;
  audioUrl: string | null;
  audioDurationSec: number | null;
  audioVoiceUsed: string | null;
  audioGeneratedAt: string | null;
  batchId: string | null;
  createdAt: string;
  rejectionReason: string | null;
}

export interface BatchGenerationOutcome {
  draftId: string;
  success: boolean;
  errorMessage: string | null;
}

export interface BatchGenerationResultDto {
  batchId: string | null;
  requested: number;
  succeeded: number;
  failed: number;
  outcomes: BatchGenerationOutcome[];
}

export interface PendingReviewCountDto {
  count: number;
}

// ============================================================================
// Audios des exemples EO (Expression Orale)
// ============================================================================

export type ExampleAudioStatus =
  | "NONE"
  | "PENDING"
  | "GENERATING"
  | "GENERATED"
  | "PUBLISHED"
  | "ERROR";

export interface ExampleAudioDto {
  id: string;
  taskId: string;
  titre: string;
  resume: string | null;
  contenu: string;
  audioStatus: ExampleAudioStatus;
  audioUrl: string | null;
  audioVoice: string | null;
  audioDurationSec: number | null;
  audioGeneratedAt: string | null;
  audioBatchId: string | null;
  audioError: string | null;
  createdAt: string;
}

export interface ExampleAudioBatchOutcome {
  exampleId: string;
  success: boolean;
  errorMessage: string | null;
}

export interface ExampleAudioBatchResultDto {
  batchId: string | null;
  requested: number;
  succeeded: number;
  failed: number;
  outcomes: ExampleAudioBatchOutcome[];
}

// ============================================================================
// Plans + Abonnements (lot 4c admin)
// ============================================================================

export type BillingCycle = "NONE" | "MONTHLY" | "THREE_MONTHS" | "SIX_MONTHS" | "YEARLY";
export type ModuleAccess = "NONE" | "CIVIQUE" | "TCF" | "INTEGRAL";
export type SubscriptionSource = "STRIPE" | "APPLE" | "GOOGLE";
export type SubscriptionStatus =
  | "ACTIVE"
  | "TRIAL"
  | "IN_GRACE"
  | "PENDING"
  | "CANCELED"
  | "EXPIRED"
  | "REFUNDED";

/** Abonnement récurrent (SUBSCRIPTION) ou pass à durée fixe (ONE_TIME, lot 5). */
export type PlanPurchaseType = "SUBSCRIPTION" | "ONE_TIME";

/** Vue admin d'un Plan (lecture + édition partielle). */
export interface AdminPlanDto {
  id: string;
  code: string;
  name: string;
  billingCycle: BillingCycle;
  price: number;
  originalPrice: number | null;
  moduleAccess: ModuleAccess;
  durationDays: number;
  purchaseType: PlanPurchaseType;
  active: boolean;
  stripePriceId: string | null;
  appleProductId: string | null;
  googleProductId: string | null;
}

/**
 * Patch partiel d'un Plan. Champs omis = non touchés.
 * `originalPrice` à 0 ou négatif retire le prix barré.
 * `stripePriceId` / `appleProductId` / `googleProductId` à "" effacent le SKU.
 */
export interface AdminPlanUpdateRequest {
  price?: number;
  originalPrice?: number;
  active?: boolean;
  stripePriceId?: string;
  appleProductId?: string;
  googleProductId?: string;
}

/** Vue admin d'une UserSubscription enrichie (user + plan). */
export interface AdminSubscriptionDto {
  id: string;
  userId: string;
  userEmail: string;
  userFirstName: string | null;
  userLastName: string | null;
  source: SubscriptionSource;
  status: SubscriptionStatus;
  externalTransactionId: string | null;
  originalTransactionId: string;
  productId: string | null;
  autoRenew: boolean;
  startsAt: string;
  endsAt: string | null;
  updatedAt: string;
  planId: string | null;
  planCode: string | null;
  planName: string | null;
  moduleAccess: ModuleAccess | null;
  planPrice: number | null;
}

export interface AdminSubscriptionListResponse {
  items: AdminSubscriptionDto[];
  total: number;
  page: number;
  size: number;
}

export interface AdminSubscriptionFilters {
  source?: SubscriptionSource;
  status?: SubscriptionStatus;
  moduleAccess?: ModuleAccess;
  search?: string;
  page?: number;
  size?: number;
}

/** Réponse de POST /api/billing/cancel et /api/admin/subscriptions/{id}/cancel.
 * - DONE : Stripe a enregistré la résiliation côté serveur.
 * - REDIRECT : Apple/Google n'autorisent pas l'annulation serveur ; le
 *   redirectUrl est la page de gestion du store à transmettre au client. */
export interface CancelSubscriptionResponse {
  action: "DONE" | "REDIRECT";
  message: string;
  redirectUrl: string | null;
}
