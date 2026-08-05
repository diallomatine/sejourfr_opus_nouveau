// Enums du backend, en string union pour simplicité.

export type Module = "CIVIQUE" | "TCF";

export type Difficulty = "CSP" | "CR" | "NAT" | "A2" | "B1" | "B2";

export type QuestionType =
  | "CONNAISSANCE"
  | "MISE_SITUATION"
  | "CO"
  | "CO_IMAGE"
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

/**
 * Miroir de l'enum backend `QuestionMediaFilter` : valeurs du paramètre
 * `GET /api/admin/questions?media=…`. `NONE` (majuscules, comme tout le reste)
 * cible les questions sans média — ce n'est pas un type de média, d'où l'enum
 * distincte de `MediaType`.
 */
export type QuestionMediaFilter = MediaType | "NONE";

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
  audioMediaId: string | null;
  audioMediaUrl: string | null;
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
/**
 * Miroir exact de `MediaDto` (9 composants côté Java). `url` est null pour les
 * médias dont l'image vit en SVG inline : le balisage est alors porté par la
 * question (`QuestionDto.mediaInlineSvg`), jamais par le média lui-même.
 */
export interface MediaDto {
  id: string;
  type: MediaType;
  url: string | null;
  originalFilename: string | null;
  contentType: string | null;
  sizeBytes: number | null;
  durationSec: number | null;
  altText: string | null;
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
  /** Null pour une conversation issue du formulaire de contact (visiteur sans
   *  compte) ; userEmail/userFullName portent alors les coordonnées du contact. */
  userId: string | null;
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
  /** Null pour le message entrant d'un contact non connecté (formulaire). */
  authorId: string | null;
  authorName: string;
  body: string;
  createdAt: string;
}

export interface ConversationDetailDto {
  id: string;
  /** Null pour une conversation issue du formulaire de contact. */
  userId: string | null;
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
  inlineSvg: string | null;
  imageUrl: string | null;
  imageAltText: string | null;
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
  ssmlText: string | null;
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

/** MONTHLY/YEARLY sont conservés côté backend pour les anciens plans récurrents. */
export type BillingCycle = "NONE" | "MONTHLY" | "THREE_MONTHS" | "YEARLY";
/** Pas de `TCF` : l'accès au module TCF passe par `INTEGRAL`. */
export type ModuleAccess = "NONE" | "CIVIQUE" | "INTEGRAL";
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
  /** Solde de sessions EO temps réel du pass (ajustable par l'admin). */
  realtimeEoSessionsRemaining: number;
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

// ============ ÉVALUATION IA EO/EE (notation v4) ============
//
// Miroir de EvaluationResultDto (backend), consommé par `features/calibration/`.

export type NiveauCecrl = "A1_NON_ATTEINT" | "A1" | "A2" | "B1" | "B2" | "C1" | "C2";

export type ConfianceEvaluation = "HAUTE" | "MOYENNE" | "FAIBLE";

/** Bande de maîtrise par critère (notation v4). */
export type BandeCritere =
  | "TRES_BONNE_MAITRISE"
  | "SATISFAISANT"
  | "EN_COURS_ACQUISITION"
  | "FRAGILE"
  | "NON_EVALUABLE";

/**
 * `communiquer` · `interagir` · `lexique` · `morphosyntaxe` sont les 4 codes
 * de la grille v5 (calquée sur la vraie grille TCF). Les autres codes ont
 * disparu au fil des versions (v4 puis v3) mais restent portés par les
 * évaluations antérieures en base — on les garde ici pour ne pas planter sur
 * l'historique.
 */
export type CritereCode =
  | "communiquer"
  | "interagir"
  | "lexique"
  | "morphosyntaxe"
  | "realisation_consigne"
  | "adequation_destinataire"
  | "chronologie_recit"
  | "prise_position"
  | "argumentation"
  | "developpement_reponses"
  | "conduite_echange"
  | "coherence"
  | "pertinence";

export interface AccomplissementPoint {
  libelle: string;
  obligatoire: boolean;
}

/** Verdict global d'accomplissement de la consigne (v8). */
export type ObjectifAccomplissement =
  | "ATTEINT"
  | "PARTIELLEMENT_ATTEINT"
  | "NON_ATTEINT";

export interface AccomplissementFeedback {
  points_traites?: AccomplissementPoint[];
  points_oublies?: AccomplissementPoint[];
  /** Absent/null sur les évaluations antérieures à v8 — cas normal. */
  objectif?: ObjectifAccomplissement | null;
  objectif_resume?: string;
}

export interface ScoreCritereFeedback {
  code: CritereCode;
  label?: string;
  note_sur_20?: number;
  bande?: BandeCritere;
  commentaire?: string;
  preuve?: string;
}

/**
 * Un passage cité de la production avec sa correction. Objet depuis le premier
 * schéma d'outil (`production-evaluation-tool-schema-v1.0.json`) : jamais une
 * simple chaîne, quelle que soit l'ancienneté de l'évaluation en base.
 * `gain` (v5) est optionnel : ce que la reformulation démontre de plus.
 */
export interface ExempleCorrige {
  original: string;
  corrige: string;
  explication: string;
  gain?: string;
}

export interface PointAmeliorerExemple {
  avant: string;
  apres: string;
}

/**
 * Un point à améliorer (v5). Les évaluations déjà en base (~97, grilles
 * antérieures) portent une simple `string` — l'écran l'affiche alors comme un
 * `constat` seul, sans `comment` ni `exemple`.
 */
export interface PointAmeliorer {
  constat: string;
  comment?: string;
  exemple?: PointAmeliorerExemple;
}

/**
 * Structure libre du feedback JSONB — tous les champs sont facultatifs, une
 * évaluation v3 en base n'en porte qu'une partie (pas de bande, pas de
 * preuve, pas d'accomplissement). Absence = cas normal, pas une erreur.
 * `note_globale` porte une décimale depuis la v5 (ex. 12.5).
 * `points_forts` (≤ 2) et `exemples_corriges` (≤ 3) sont bornés côté serveur
 * depuis v8 — la longueur n'est pas revalidée côté front, seulement affichée.
 */
export interface EvaluationFeedback {
  note_globale?: number;
  confiance?: ConfianceEvaluation;
  confiance_raisons?: string[];
  accomplissement?: AccomplissementFeedback;
  scores_criteres?: ScoreCritereFeedback[];
  points_forts?: string[];
  /** `string` = format antérieur à v5, encore présent sur les évaluations en base. */
  points_a_ameliorer?: (string | PointAmeliorer)[];
  suggestions?: string[];
  exemples_corriges?: ExempleCorrige[];
  avertissements?: string[];
  /**
   * Production réécrite en entier (v8), EE uniquement — absente en EO (voulu)
   * et sur toute évaluation antérieure à v8.
   */
  version_amelioree?: string | null;
}

/**
 * Vue front d'une évaluation IA (EvaluationResultDto backend). `niveauObserve`,
 * `confiance` et `avertissementNiveau` sont null pour les évaluations
 * antérieures au schéma v2/v3 — absence normale, aucun front ne doit planter
 * dessus.
 */
export interface EvaluationResultDto {
  noteSurVingt: number | null;
  niveauObserve: NiveauCecrl | null;
  confiance: ConfianceEvaluation | null;
  avertissementNiveau: string | null;
  /** Le JSONB persisté peut être absent en base : null est un cas normal. */
  feedback: EvaluationFeedback | null;
}

// ============ PRODUCTIONS EO/EE (submissions + sujets) ============

export type EpreuveType =
  | "CIVIQUE"
  | "TCF_CO"
  | "TCF_CE"
  | "TCF_STRUCTURE"
  | "TCF_EO"
  | "TCF_EE"
  | "TCF_COMPLET";

export type SubmissionStatut =
  | "SUBMITTED"
  | "TRANSCRIBING"
  | "EVALUATING"
  | "EVALUATED"
  | "FAILED";

/** Miroir de ProductionTaskDto — catalogue des sujets EO/EE (`GET /api/production-tasks`). */
export interface ProductionTaskDto {
  id: string;
  epreuve: EpreuveType;
  tacheNumero: number;
  niveauCible: string | null;
  consigne: string;
  contexte: string | null;
  dureeMaxSec: number | null;
  dureeMinSec: number | null;
  motsMin: number | null;
  motsMax: number | null;
}

/**
 * Miroir de ProductionSubmissionDto. `evaluation` est null tant que le pipeline
 * IA n'a pas abouti ; `transcription` n'est renseignée que pour l'oral. Le DTO
 * ne porte PAS l'épreuve : elle se retrouve via `productionTaskId` dans le
 * catalogue des sujets.
 */
export interface ProductionSubmissionDto {
  id: string;
  attemptId: string | null;
  productionTaskId: string | null;
  tacheNumero: number | null;
  statut: SubmissionStatut;
  mediaUrl: string | null;
  texteSoumis: string | null;
  motsCount: number | null;
  mediaDurationSec: number | null;
  retryCount: number;
  erreurMessage: string | null;
  submittedAt: string;
  evaluation: EvaluationResultDto | null;
  transcription: string | null;
}

// ============ CALIBRATION DE LA NOTATION IA ============

/**
 * Une ligne de `GET /api/admin/calibration/submissions` : la soumission plus
 * les versions de l'évaluation IA. DTO propre à l'admin — la version de grille
 * n'intéresse que l'écran qui juge la notation, elle n'est pas ajoutée aux DTO
 * partagés avec le web et le mobile.
 *
 * `rubricsVersion` est null pour les évaluations antérieures à la colonne
 * `ai_evaluations.rubrics_version` : l'écran affiche « inconnue ». Une note
 * produite avec la grille v3 et une note v4.2 ne se comparent pas.
 */
export interface CalibrationSubmissionDto {
  submission: ProductionSubmissionDto;
  rubricsVersion: string | null;
  promptVersion: string | null;
}

/** Payload et réponse de POST /api/admin/calibration/submissions/{id}/human-note. */
export interface HumanCalibrationNoteDto {
  submissionId: string;
  noteHumaineSurVingt: number;
  niveauCecrlHumain: NiveauCecrl;
  commentaires: string | null;
}

/**
 * Santé de la notation (`GET /api/admin/calibration/stats`).
 *
 * Convention de signe du backend : `ecart = note humaine − note IA`.
 * `ecartMoyen` est donc un BIAIS signé — négatif = l'IA note au-dessus du
 * correcteur (trop indulgente), positif = trop sévère. `ecartMoyenAbsolu` est
 * une DISPERSION : la taille moyenne de l'erreur, quel que soit son sens.
 */
export interface CalibrationStatsDto {
  totalNotes: number;
  ecartMoyen: number;
  ecartMoyenAbsolu: number;
  ecartTypeAbsolu: number;
  ecartsHorsCible: number;
  /** Ratio sur 100. */
  pourcentageHorsCible: number;
  seuilHorsCible: number;
  calibre: boolean;
}

/** Écart entre le niveau brut du LLM et le niveau recalculé serveur. */
export interface NiveauCalibrationStatsDto {
  totalAvecNiveau: number;
  divergents: number;
  /** Ratio sur 100. */
  pourcentageDivergents: number;
}

// ============ AUDIENCE DES LANDINGS (page_views) ============

/** Une provenance et son entonnoir sur la fenêtre demandée. */
export interface PageViewSourceStat {
  source: string;
  views: number;
  ctaClicks: number;
  /** Part des vues ayant abouti à un clic CTA, en %. Null si aucune vue. */
  ctaRate: number | null;
}

export interface PageViewDailyStat {
  /** Jour ISO (yyyy-MM-dd), Europe/Paris. */
  day: string;
  views: number;
  ctaClicks: number;
}

/**
 * Audience agrégée d'une landing. Compte des VUES, pas des visiteurs uniques :
 * aucun identifiant de terminal n'est posé côté navigateur (cf. migration V020).
 */
export interface PageViewStatsResponse {
  path: string;
  days: number;
  views: number;
  ctaClicks: number;
  sources: PageViewSourceStat[];
  daily: PageViewDailyStat[];
}
