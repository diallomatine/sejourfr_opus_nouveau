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

/**
 * Miroir de `com.sejourfr.app.audioquestion.domain.AudioMode`.
 *
 * `WRITTEN_QUESTION_SPOKEN_CHOICES` constate un defaut de contenu existant
 * (l'audio enonce les propositions avec leurs lettres alors que l'ecran
 * affiche leur texte) : il s'AFFICHE, il ne se DEMANDE pas — cf.
 * `AUDIO_MODE_OPTIONS`, qui ne propose que les deux modes generables.
 */
export type AudioMode =
  | "WRITTEN_QUESTION"
  | "FULL_AUDIO"
  | "WRITTEN_QUESTION_SPOKEN_CHOICES";

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

/**
 * Position d'une production DANS sa propre bande CECRL, en 3 crans (dérivé
 * serveur). C'est ce qui remplace, sur le résultat d'une TÂCHE, la note /20 qui
 * n'y est plus affichée côté candidat. Null sur les évaluations antérieures,
 * sur `A1_NON_ATTEINT` et sur C1/C2.
 */
export type SituationDansNiveau =
  | "ENTREE_DE_PALIER"
  | "PALIER_CONFIRME"
  | "PALIER_SOLIDE";

/** Bande de maîtrise par critère (notation v4). */
export type BandeCritere =
  | "TRES_BONNE_MAITRISE"
  | "SATISFAISANT"
  | "EN_COURS_ACQUISITION"
  | "FRAGILE"
  | "NON_EVALUABLE";

/**
 * `communiquer` · `interagir` · `lexique` · `morphosyntaxe` sont les 4 codes
 * de notre grille SejourFR depuis la v5 (alignée sur les dimensions évaluées au
 * TCF, sans reprendre la grille de correction officielle). Les autres codes ont
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

export interface VersionCibleeLevier {
  action: string;
  exemple: string;
}

export interface VersionCibleeSegment {
  extrait: string;
  apport: string;
}

/** v2, ÉCRIT. Sans `texte` il n'y a rien à montrer ; `segments` n'est qu'un
 *  surlignage, sa présence n'est jamais garantie. */
export interface VersionCibleeExempleCible {
  texte: string;
  segments?: VersionCibleeSegment[];
}

/** v2, ORAL. `original` est posé par le serveur (numéro de segment déjà résolu
 *  en texte) : jamais un entier ici. */
export interface VersionCibleeReformulation {
  original: string;
  reformule: string;
  apport: string;
}

export interface VersionCibleeARetenir {
  formule: string;
  explication?: string;
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
  /** Retiré du contrat de sortie en **v15 / tool-schema v9** : absent des
   *  évaluations récentes, encore présent sur celles déjà en base. */
  suggestions?: string[];
  /** Même sort que `suggestions` : retiré en **v15 / tool-schema v9**. */
  exemples_corriges?: ExempleCorrige[];
  avertissements?: string[];
  /**
   * Production réécrite en entier (v8), EE uniquement — absente en EO (voulu)
   * et sur toute évaluation antérieure à v8.
   */
  version_amelioree?: string | null;
  /**
   * Bloc « version au niveau visé » (second appel LLM, EE et EO) : la même
   * réponse rédigée au palier que le candidat vise, plus 2 à 3 leviers. Absent
   * de toutes les évaluations antérieures, et quand le niveau visé est déjà
   * atteint.
   *
   * Trois formes, une seule clé, distinguées à la présence de `exemple_cible`
   * (v2, ÉCRIT) ou de `reformulations` (v2, ORAL) :
   * - v2, écrit : `leviers` + `exemple_cible` + `a_retenir` ;
   * - v2, oral : `leviers` + `reformulations` + `a_retenir` — pas de texte
   *   modèle complet, la production orale n'est jamais réécrite en entier ;
   * - v1 (legacy, encore en base) : `texte` + `ce_qui_manque`, écrit seulement.
   *
   * Depuis la correction du 2026-08-11, le bloc peut être PARTIEL : seuls
   * `niveau_vise` (v1 et v2) sont structurants, `leviers` / `exemple_cible` /
   * `reformulations` / `a_retenir` tombent chacun indépendamment.
   */
  version_ciblee?: {
    niveau_vise: string;
    niveau_constate?: string | null;
    /** v2 : 2 à 3 leviers, du plus rentable au moins rentable. */
    leviers?: VersionCibleeLevier[];
    /** v2, ÉCRIT : la réponse réécrite au niveau visé, segments surlignables. */
    exemple_cible?: VersionCibleeExempleCible;
    /** v2, ORAL : 2 à 3 passages redits au niveau visé. Exclusif du précédent. */
    reformulations?: VersionCibleeReformulation[];
    /** v2 : la tournure à emporter ailleurs. */
    a_retenir?: VersionCibleeARetenir;
    /** v1 (legacy) : le modèle rédigé au niveau visé. Absent sous le contrat v2. */
    texte?: string;
    /** v1 (legacy) : les leviers en texte libre, ordre du backend préservé. */
    ce_qui_manque?: string[];
  } | null;
}

/**
 * La production a-t-elle pu être **observée** ? Miroir de
 * `ProductionEvaluabilite` (backend), **jamais `null`** : toutes les
 * évaluations antérieures sortent `EVALUABLE`, rien n'a été migré.
 *
 * `NON_EVALUABLE` = production vide, en langue non française ou recopiant la
 * consigne : les contrôles déterministes l'ont écartée **avant** tout appel au
 * correcteur. Il n'y a alors ni note, ni niveau, ni `scores_criteres` — et ces
 * absences sont des faits, pas des trous à combler.
 *
 * ⚠️ À ne pas confondre avec la valeur `"NON_EVALUABLE"` de
 * {@link BandeCritere}, qui qualifie **un critère**, pas la production entière.
 */
export type ProductionEvaluabilite = "EVALUABLE" | "NON_EVALUABLE";

/**
 * Vue front d'une évaluation IA (EvaluationResultDto backend). `niveauObserve`,
 * `confiance` et `avertissementNiveau` sont null pour les évaluations
 * antérieures au schéma v2/v3 — absence normale, aucun front ne doit planter
 * dessus.
 */
export interface EvaluationResultDto {
  /** **Jamais `null`** côté serveur. Un backend antérieur au champ ne le sert
   *  pas : seule la valeur `NON_EVALUABLE` **explicite** vaut « rien à
   *  observer », jamais son absence. */
  evaluabilite: ProductionEvaluabilite;
  noteSurVingt: number | null;
  niveauObserve: NiveauCecrl | null;
  confiance: ConfianceEvaluation | null;
  avertissementNiveau: string | null;
  /** Position dans la bande du niveau annoncé (3 crans), et son libellé composé
   *  (« A2 solide »). Null tous les deux en même temps. */
  situationDansNiveau: SituationDansNiveau | null;
  situationDansNiveauLabel: string | null;
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
  /** Intitulé éditorial du sujet (V028). `null` = pas de titre : les fronts
   *  candidats retombent sur « Sujet N » + consigne. */
  titre: string | null;
  consigne: string;
  contexte: string | null;
  dureeMaxSec: number | null;
  dureeMinSec: number | null;
  motsMin: number | null;
  motsMax: number | null;
}

/**
 * Miroir de AdminProductionTaskDto (`GET /api/admin/production-tasks`).
 * Inclut les sujets DÉSACTIVÉS et le drapeau `active` : la console doit voir
 * ce qu'elle édite, même dépublié. Seul le `titre` est modifiable.
 */
export interface AdminProductionTaskDto {
  id: string;
  epreuve: EpreuveType;
  tacheNumero: number;
  niveauCible: string | null;
  titre: string | null;
  consigne: string;
  contexte: string | null;
  active: boolean;
}

/** Corps de `PATCH /api/admin/production-tasks/{id}/titre`. `null` ou blanc
 *  = retirer le titre (sémantique de remplacement, comme les bornes des
 *  petits sujets). */
export interface AdminProductionTaskTitreRequest {
  titre: string | null;
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
  texteSoumis: string | null;
  motsCount: number | null;
  /**
   * Durée de l'enregistrement (EO). Seule trace qui subsiste de l'audio : il
   * n'est pas conservé, donc aucune URL n'est servie — ce qui reste d'une
   * production orale, c'est `transcription`.
   */
  mediaDurationSec: number | null;
  retryCount: number;
  erreurMessage: string | null;
  submittedAt: string;
  evaluation: EvaluationResultDto | null;
  transcription: string | null;
  /**
   * Ce que cette production a changé dans le Plan personnalisé du candidat.
   * **Nullable, et son absence est normale** (rien n'a bougé, ou les
   * observations — écrites après la correction — ne sont pas encore là). La
   * console ne l'affiche pas : le miroir existe pour que le DTO reste fidèle
   * au serveur.
   */
  planChange: PlanChangeDto | null;
}

/** De quoi nommer une compétence du Plan et y renvoyer. */
export interface PlanSkillRefDto {
  skillId: string;
  skillCode: string;
  title: string;
  section: SkillSection;
}

/** Les deux moitiés sont indépendamment nullables. */
export interface PlanChangeDto {
  confirmedSkill: PlanSkillRefDto | null;
  newPriority: PlanSkillRefDto | null;
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

// ============ ANALYTICS (GET /api/admin/analytics) ============
// Miroir manuel du contrat Analytics. Un SEUL endpoint sert tout l'ecran :
// cinq endpoints imposeraient cinq fenetres de temps a garder coherentes.
// Toutes les valeurs sont deja calculees et arrondies a somme conservee cote
// serveur — le front n'en recalcule aucune.

/** Pas de la serie temporelle, decide par le serveur selon l'amplitude. */
export type AnalyticsGrain = "HOUR" | "DAY" | "WEEK";

/** Periode reellement appliquee, telle que le serveur l'a resolue. */
export interface AnalyticsPeriod {
  id: string;
  label: string;
  days: number;
  grain: AnalyticsGrain;
}

/**
 * Le vecteur unique de mesure. Toutes les ventilations (source, pays, device,
 * campagne, serie) le reutilisent, ce qui garantit que deux blocs de l'ecran
 * ne peuvent pas repondre differemment a la meme question.
 *
 * `v` compte des VISITEURS DISTINCTS, jamais des vues ; `prem` compte des
 * CLIQUEURS UNIQUES ; `pay` ne compte que les comptes dont le PREMIER paiement
 * tombe dans la periode — un renouvellement n'est pas un nouvel abonne.
 */
export interface AnalyticsMetrics {
  /** Visiteurs uniques. */
  v: number;
  /** Clics « Faire mon diagnostic ». */
  cta: number;
  /** Diagnostics commences. */
  start: number;
  /** EE demarree. */
  ee1: number;
  /** EE terminee. */
  ee2: number;
  /** EO demarree. */
  eo1: number;
  /** EO terminee. */
  eo2: number;
  /** Rapport diagnostic affiche. */
  rep: number;
  /** Nouvelles inscriptions (table `users`). */
  sig: number;
  /** Clics « Debloquer mon plan », cliqueurs uniques. */
  prem: number;
  /** Checkouts commences. */
  ck: number;
  /** Paiements reussis (table `user_subscriptions`). */
  pay: number;
  /** Revenu reellement encaisse, en centimes d'euro. Jamais un prix reconstitue. */
  revEurCents: number;
}

/** Clef de mesure affichable dans un graphe ou un entonnoir. */
export type AnalyticsMetricKey = keyof AnalyticsMetrics;

export interface AnalyticsSourceStat {
  id: string;
  label: string;
  m: AnalyticsMetrics;
}

/**
 * Un point de la serie. `empty` marque un intervalle non encore ecoule (heures
 * a venir de la journee en cours) : il se saute au trace au lieu de dessiner un
 * zero qu'on lirait comme une chute.
 */
export interface AnalyticsSeriesPoint {
  label: string;
  short: string;
  iso: string | null;
  isoEnd: string | null;
  m: AnalyticsMetrics;
  empty: boolean;
}

export interface AnalyticsFunnelStep {
  k: AnalyticsMetricKey;
  label: string;
  /** La question a laquelle l'etape repond, affichee en sous-titre. */
  q: string;
  value: number;
  /** Conversion depuis l'etape precedente. `null` sur la premiere etape. */
  conv: number | null;
  lost: number;
  lostShare: number;
}

/** `id` vaut `UNKNOWN` quand la geo-IP n'a rien pu conclure — jamais un pays invente. */
export interface AnalyticsCountryStat {
  id: string;
  label: string;
  v: number;
  sig: number;
  rep: number;
  prem: number;
  pay: number;
  revEurCents: number;
}

export interface AnalyticsDeviceStat {
  id: string;
  label: string;
  platform: string;
  v: number;
  sig: number;
  rep: number;
  prem: number;
  pay: number;
  revEurCents: number;
}

export interface AnalyticsCampaignStat {
  id: string;
  source: string;
  sourceId: string;
  name: string;
  medium: string | null;
  content: string | null;
  v: number;
  start: number;
  rep: number;
  sig: number;
  prem: number;
  pay: number;
  revEurCents: number;
}

export interface AnalyticsCtaStat {
  id: string;
  label: string;
  /** L'ecran d'ou part le clic. */
  where: string;
  prem: number;
  ck: number;
  pay: number;
  revEurCents: number;
}

export interface AnalyticsTriggerStat {
  id: string;
  label: string;
  hint: string;
  sig: number;
  share: number;
}

export interface AnalyticsPathStat {
  chain: string[];
  sig: number;
  share: number;
}

/**
 * Un maillon de la chaine de progression d'un format de diagnostic. `value`
 * et `conv` (conversion depuis le maillon PRECEDENT, deja calculee cote
 * serveur) sont `null` quand l'evenement qui l'alimente n'existe pas encore
 * (CO/CE du format complet : les fronts n'emettent aujourd'hui que les
 * `_STARTED`) — jamais un zero invente a la place d'une mesure absente.
 */
export interface AnalyticsDiagChainStep {
  k: string;
  label: string;
  value: number | null;
  conv: number | null;
}

export interface AnalyticsDiagTypeStat {
  id: string;
  label: string;
  sub: string;
  start: number;
  done: number;
  prem: number;
  pay: number;
  /** Nombre d'epreuves du format (2 en rapide, 4 en complet). */
  steps: number;
  /**
   * Progression reelle du format, maillon par maillon (RAPID :
   * start→ee2→eo2→rep ; COMPLETE : start→ee2→eo2→co2→ce2→rep). Vide quand
   * rien n'est mesure sur la periode — jamais une chaine de zeros.
   */
  chain: AnalyticsDiagChainStep[];
}

/** `base` dit sur quel denominateur `v` se lit : `start` ou `rep`. */
export interface AnalyticsAbandonStat {
  id: string;
  label: string;
  sub: string;
  v: number;
  base: string;
  worst: boolean;
}

export interface AnalyticsAnnotation {
  iso: string;
  label: string;
  kind: string;
}

/**
 * Constat calcule cote serveur, sans LLM. `html` ne porte que de l'emphase
 * (`<b>`) : le front la nettoie avant affichage plutot que de faire confiance.
 */
export interface AnalyticsInsight {
  tone: "OK" | "WARN" | "BAD" | "NEUTRAL";
  html: string;
}

export interface AnalyticsResponse {
  period: AnalyticsPeriod;
  /** Bornes APPLIQUEES (yyyy-MM-dd, Europe/Paris, incluses). Elles font foi. */
  from: string;
  to: string;
  prevFrom: string | null;
  prevTo: string | null;
  /** Journee en cours : la periode n'est pas terminee. */
  partial: boolean;
  hourNow: number;
  /** Cumul de comptes, hors periode. */
  totalUsers: number;
  currency: string;
  total: AnalyticsMetrics;
  prev: AnalyticsMetrics;
  sources: AnalyticsSourceStat[];
  prevSources: AnalyticsSourceStat[];
  series: AnalyticsSeriesPoint[];
  prevSeries: AnalyticsSeriesPoint[];
  funnel: AnalyticsFunnelStep[];
  prevFunnel: AnalyticsFunnelStep[];
  countries: AnalyticsCountryStat[];
  devices: AnalyticsDeviceStat[];
  campaigns: AnalyticsCampaignStat[];
  ctas: AnalyticsCtaStat[];
  triggers: AnalyticsTriggerStat[];
  paths: AnalyticsPathStat[];
  diagTypes: AnalyticsDiagTypeStat[];
  abandon: AnalyticsAbandonStat[];
  annotations: AnalyticsAnnotation[];
  insights: AnalyticsInsight[];
}

/**
 * Periode demandee. `from`/`to` (bornes incluses, Europe/Paris) l'emportent sur
 * `days` ; une seule borne, `from > to` ou plus de 365 jours sont refuses en
 * 400, d'ou l'union exclusive : on n'envoie jamais les deux formes.
 */
export type AnalyticsRange = { days: number } | { from: string; to: string };

/** Filtres facultatifs, tous appliques cote serveur. */
export interface AnalyticsFilters {
  source: string | null;
  country: string | null;
  device: string | null;
  platform: string | null;
}

// ============ COMPÉTENCES TCF (EE/EO) — surface admin ============
// Miroir du §6 du contrat gelé « module Compétences TCF ».
// Le contenu (48 compétences, 240 sujets, 720 références) est éditorial :
// il vit en base et s'édite ici, pas en migration Flyway.

/**
 * Deux familles, un seul référentiel (enum backend `SkillSection`). `EE`/`EO`
 * sont l'EXPRESSION : une compétence y appartient à une des 6 tâches
 * officielles (`SkillTaskCode`) et s'entraîne sur des petits sujets. `CO`/`CE`
 * sont la COMPRÉHENSION : une compétence par palier (`CO-A2`, `CO-B1`, `CO-B2`
 * et leurs jumelles CE), **sans aucune tâche et sans aucun petit sujet** —
 * l'entraînement y est une série ciblée de QCM, pas une page de 5 sujets.
 */
export type SkillSection = "EE" | "EO" | "CO" | "CE";

export type SkillTaskCode = "EE1" | "EE2" | "EE3" | "EO1" | "EO2" | "EO3";

/**
 * Difficulté d'un petit sujet — enum backend `SkillDifficulty`. Le contrat
 * annonçait réutiliser `Difficulty`, mais celui-ci vaut CSP/CR/NAT/A2/B1/B2
 * (axe procédure/palier des questions QCM) : le backend a créé un enum dédié
 * plutôt que d'exposer EASY/MEDIUM/HARD à tous les DTO de questions.
 */
export type SkillDifficultyLevel = "EASY" | "MEDIUM" | "HARD";

export type SkillReferenceLevel = "INSUFFICIENT" | "EXPECTED" | "EXCELLENT";

/** Palier visé par une compétence. La colonne `skills.target_level` accepte A1, contrairement à `TargetLevel`. */
export type SkillTargetLevel = "A1" | "A2" | "B1" | "B2";

export interface SkillReferenceDto {
  level: SkillReferenceLevel;
  text: string;
  pedagogicalNote: string;
}

/**
 * Famille d'icône d'une étiquette de contrainte — enum backend
 * `SkillConstraintIcon`, **liste fermée**. Elle décrit une famille, pas un
 * dessin : chaque front choisit son icône. Ajouter une valeur suppose de la
 * mapper côté web ET mobile dans la même passe.
 */
export type SkillConstraintIcon =
  | "TONE"
  | "PERSON"
  | "TIME"
  | "PLACE"
  | "NUMBER"
  | "TENSE"
  | "STRUCTURE"
  | "EXAMPLE";

/**
 * Étiquette de contrainte lue depuis le serveur (record `SkillConstraintTag`,
 * stocké en JSONB). Elle dit **comment** produire, jamais **combien** : ni
 * longueur ni durée, que les fronts rendent déjà depuis `recommendedMinWords` /
 * `recommendedMaxWords` / `recommendedDurationSeconds`.
 */
export interface SkillConstraintTagDto {
  /** 1 à 3 mots. */
  label: string;
  icon: SkillConstraintIcon;
}

/**
 * Même forme sur le fil à l'écriture (`SkillConstraintTagInput`), à un détail
 * près : côté Java `icon` y est une **chaîne** et non l'enum, pour que le
 * service rende un 422 français énumérant la liste fermée au lieu d'un 400
 * technique du convertisseur. La console, elle, ne peut envoyer qu'une valeur
 * de l'union — l'icône se choisit, elle ne se saisit pas.
 */
export interface SkillConstraintTagInput {
  label: string;
  icon: SkillConstraintIcon;
}

export interface AdminSkillDto {
  id: string;
  section: SkillSection;
  /**
   * Tâche d'appartenance, `null` pour une compétence de COMPRÉHENSION
   * (section `CO` / `CE`) : celles-ci n'appartiennent à aucune des 6 tâches
   * officielles. Le domaine se lit sur `section`, le palier sur
   * `targetLevel` — jamais déduits de la tâche.
   */
  taskCode: SkillTaskCode | null;
  /** Immuable après création : les seeds et les codes de sujets s'appuient dessus. */
  code: string;
  title: string;
  /** Courte explication adressée au candidat : ce qu'il travaille et pourquoi ça compte au TCF. */
  description: string;
  /**
   * Critère général observé dans les 15 petits sujets de la compétence.
   * Colonne `skills.general_criterion`, NOT NULL. À ne pas confondre avec
   * `AdminSkillPromptDto.uniqueCriterion`, propre à un seul sujet.
   */
  generalCriterion: string;
  targetLevel: SkillTargetLevel;
  displayOrder: number;
  active: boolean;
  promptCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface AdminSkillPromptDto {
  id: string;
  skillId: string;
  skillCode: string;
  section: SkillSection;
  /** Immuable après création. */
  code: string;
  title: string;
  context: string;
  instruction: string;
  uniqueCriterion: string;
  /**
   * Guidage de l'écran de saisie — les quatre champs qui suivent sont
   * **facultatifs** (colonnes nullables, V026) : un sujet peut naître sans eux
   * et les fronts se dégradent alors sur la consigne. La console affiche « à
   * compléter » plutôt que de casser.
   *
   * `checklist` : 2 à 4 gestes à l'impératif, 6 mots maximum chacun.
   */
  checklist: string[] | null;
  /** 1 à 3 étiquettes. Jamais la longueur ni la durée : elles diviseraient la vérité. */
  constraintTags: SkillConstraintTagDto[] | null;
  /** Amorce grisée du champ de réponse, terminée par « … ». */
  answerStarter: string | null;
  /** Sans le préfixe « Astuce : » — les fronts l'ajoutent. */
  tip: string | null;
  /** Renseigné en section EE uniquement (CHECK en base). */
  recommendedMinWords: number | null;
  recommendedMaxWords: number | null;
  /** Renseigné en section EO uniquement (CHECK en base). */
  recommendedDurationSeconds: number | null;
  difficultyLevel: SkillDifficultyLevel;
  displayOrder: number;
  active: boolean;
  references: SkillReferenceDto[];
  attemptCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface AdminSkillDetailDto {
  skill: AdminSkillDto;
  prompts: AdminSkillPromptDto[];
}

export interface AdminSkillStatsDto {
  skillId: string;
  code: string;
  title: string;
  section: SkillSection;
  /** `null` pour une compétence de COMPRÉHENSION (section `CO` / `CE`) — cf. `AdminSkillDto.taskCode`. */
  taskCode: SkillTaskCode | null;
  promptCount: number;
  attemptCount: number;
  analysedCount: number;
  /** Ratio 0..1, calculé sur les seules tentatives analysées. Null si aucune. */
  validatedRate: number | null;
}

export interface AdminSkillFilters {
  section?: SkillSection;
  taskCode?: SkillTaskCode;
  active?: boolean;
  q?: string;
  page?: number;
  size?: number;
}

/**
 * POST : `generalCriterion` est **obligatoire** (colonne NOT NULL). L'omettre
 * fait échouer la création en 400.
 *
 * `section` et `taskCode` sont facultatifs **individuellement, jamais
 * ensemble** — le couple est arbitré par le serveur (422 sinon) : pour une
 * compétence d'EXPRESSION, la tâche suffit (la section s'en déduit, et
 * fournie elle doit concorder) ; pour une compétence de COMPRÉHENSION
 * (`CO`/`CE`), il n'existe aucune tâche, c'est la section seule qui est
 * envoyée. La console envoie donc soit `taskCode` (+ la section qui s'en
 * déduit), soit `section` seule sans `taskCode`.
 */
export interface AdminSkillCreateRequest {
  section?: SkillSection;
  taskCode?: SkillTaskCode;
  code: string;
  title: string;
  description: string;
  generalCriterion: string;
  targetLevel: SkillTargetLevel;
  displayOrder: number;
  active: boolean;
}

/**
 * PATCH : le `code`, la `section` et le `taskCode` ne sont jamais modifiables.
 * Toutes les colonnes visées sont NOT NULL, donc un champ absent vaut « ne
 * touche pas » ; le front envoie néanmoins toujours tous les champs.
 */
export interface AdminSkillUpdateRequest {
  title: string;
  description: string;
  generalCriterion: string;
  targetLevel: SkillTargetLevel;
  displayOrder: number;
  active: boolean;
}

/**
 * POST : les quatre champs de guidage sont facultatifs. Une liste vide vaut
 * `null` côté serveur (« aucune étiquette » et « je n'en envoie pas » décrivent
 * le même sujet) ; fournis, ils sont validés — 2 à 4 gestes, 1 à 3 étiquettes,
 * icône dans la liste fermée — et **tout est vérifié avant la moindre
 * écriture**, donc un refus ne laisse jamais un sujet à moitié modifié.
 */
export interface AdminSkillPromptCreateRequest {
  skillId: string;
  code: string;
  title: string;
  context: string;
  instruction: string;
  uniqueCriterion: string;
  checklist: string[] | null;
  constraintTags: SkillConstraintTagInput[] | null;
  answerStarter: string | null;
  tip: string | null;
  recommendedMinWords: number | null;
  recommendedMaxWords: number | null;
  recommendedDurationSeconds: number | null;
  difficultyLevel: SkillDifficultyLevel;
  displayOrder: number;
  active: boolean;
}

/**
 * PATCH : tous les champs éditables sont envoyés à chaque fois, y compris les
 * bornes de longueur à `null`. Un `null` vaut « efface », pas « ne touche pas » :
 * c'est ce qui garantit qu'un sujet EE ne porte jamais de durée et inversement
 * (CHECK `skill_prompts`). Le `code` et le `skillId` sont absents : immuables.
 *
 * **Les quatre champs de guidage suivent la même règle de remplacement** :
 * leurs colonnes sont nullables, donc un `null` y désigne un état atteignable
 * (« ce sujet n'a pas de guidage ») et non un état impossible. Sans cela, une
 * check-list posée par erreur serait ineffaçable depuis la console.
 */
export type AdminSkillPromptUpdateRequest = Omit<
  AdminSkillPromptCreateRequest,
  "skillId" | "code"
>;

/**
 * PUT atomique des 3 références d'un sujet : les 3 niveaux exactement, sans
 * doublon. Le backend remplace, il ne fusionne pas.
 */
export interface AdminSkillReferencesUpdateRequest {
  references: SkillReferenceDto[];
}


// ============================================================================
// COÛT IA — miroir strict de `AdminAiCostResponse` (lot L12)
//
// 🛑 **Deux colonnes de coût, JAMAIS additionnées.** `coutMicroUsd` est en
// millionièmes de DOLLAR, écrit par les pipelines actuels ; `coutLegacyCentimes`
// en centimes d'EURO, plus jamais écrit, présent sur les lignes anciennes. Deux
// unités, deux devises, deux époques : les sommer produirait un nombre qui ne
// veut rien dire.
//
// 🛑 **Un coût inconnu vaut `null`, jamais 0.** `lignesSansCout` les compte.
// Sans ce nombre, un total bas se lit « l'IA ne coûte presque rien » alors
// qu'il se lit « on ne sait pas ce qu'elle a coûté ».
// ============================================================================

export interface AiCostLigne {
  /** `null` sur le total : un agrégat d'ensemble n'a pas de nom. */
  cle: string | null;
  appels: number;
  /** 🛑 Appels dont le coût est **inconnu**. Jamais comptés zéro. */
  lignesSansCout: number;
  /** `null` sur une transcription : Whisper facture à la DURÉE, pas au token. */
  tokensInput: number | null;
  tokensOutput: number | null;
  tokensInputCacheHit: number | null;
  coutMicroUsd: number | null;
  coutLegacyCentimes: number | null;
}

export interface AiCostMoyen {
  sessions: number;
  /** `null` = aucun coût connu sur la fenêtre. Jamais 0. */
  moyenneMicroUsd: number | null;
  totalMicroUsd: number | null;
}

export interface AdminAiCostResponse {
  /** Bornes **appliquées** par le serveur, pas celles demandées. */
  from: string;
  to: string;
  total: AiCostLigne;
  parFamille: AiCostLigne[];
  parSource: AiCostLigne[];
  parModele: AiCostLigne[];
  diagnosticComplet: AiCostMoyen;
}


// ============================================================================
// NOTIONS CIVIQUES — miroir strict de `CivicNotionDto` / `QuestionTaggingDto`
// (lot L8)
//
// 🛑 **Référentiel de TRAVAIL, pas liste figée** (`50_` §6.1). Une notion qui
// fusionne est **désactivée** et pointe vers celle qui la reprend : elle n'est
// jamais supprimée, les questions déjà taguées gardent leur lien.
//
// 🛑 **Deux autorités, à ne pas confondre.** `notionCode` sur une question est
// le tag VALIDÉ par un humain. Les `suggestions` sont ce qu'une machine
// propose : elles accompagnent, elles ne décident pas.
// ============================================================================

export interface CivicNotionCouvertureMention {
  mention: string;
  questions: number;
}

export interface CivicNotionDto {
  id: string;
  code: string;
  label: string;
  /**
   * La **frontière métier** de la notion (V055) — ce qui la distingue de sa
   * voisine. Même texte que celui donné au prompt de pré-tagging : une seule
   * autorité pour le modèle, l'écran et le relecteur.
   * `null` pour une notion dont la frontière ne pose aucun problème.
   */
  description: string | null;
  themeCode: string;
  displayOrder: number;
  active: boolean;
  /** Code de la notion qui reprend celle-ci après fusion. `null` = vivante. */
  mergedIntoCode: string | null;
  questionsTaguees: number;
  /**
   * 🛑 La couverture se lit **par mention** : la règle de `50_` §6.1 dégrade
   * par notion ET par mention. Un total global cacherait qu'une notion pleine
   * en NAT est vide en CSP.
   */
  parMention: CivicNotionCouvertureMention[];
  /** 🛑 Une suggestion n'est **pas** une couverture. */
  suggestions: number;
}

/**
 * Une proposition de réponse de la question, telle qu'elle est servie au
 * relecteur. Le relecteur tague sur le SENS de la question : sans les
 * propositions ni la bonne réponse, il lui manque les deux tiers du texte que
 * le modèle, lui, a lu.
 */
export interface CivicTaggingChoix {
  label: string;
  correct: boolean;
}

/**
 * Ce que le serveur a écrit après relecture d'une suggestion.
 *
 * 🛑 `VALIDATED` et `CORRECTED` sont **décidés par le serveur** en comparant la
 * notion retenue à la suggestion la mieux notée : le client ne les envoie
 * jamais. C'est la métrique de qualité du pré-tagging, elle ne peut pas
 * dépendre de ce que le client croit avoir fait.
 */
export type CivicReviewVerdict = "VALIDATED" | "CORRECTED" | "REJECTED" | "SKIPPED";

/**
 * Ce que le CLIENT a le droit d'écrire dans `verdict`.
 *
 * 🛑 Volontairement **disjoint** de `CivicReviewVerdict` : `VALIDATED` et
 * `CORRECTED` n'y figurent pas, donc ils ne peuvent pas être envoyés — la
 * contrainte est portée par le type, pas par une consigne.
 *
 * `CONFIRM_NONE` est un **geste**, pas un verdict : le relecteur confirme que
 * le modèle a raison de ne trouver aucune notion. Le serveur le traduit en
 * `VALIDATED` et **refuse (400)** si la meilleure suggestion n'était pas
 * « aucune notion ».
 */
export type CivicTaggingGesteVerdict = "CONFIRM_NONE" | "REJECTED" | "SKIPPED";

export interface CivicTaggingSuggestion {
  /**
   * 🛑 `null` = le modèle a conclu qu'**aucune notion du référentiel ne
   * convient**. Ce n'est pas une absence de suggestion : `confidence`,
   * `rationale` et `reviewVerdict` sont servis normalement, et c'est
   * l'information qui révèle les **trous du référentiel**.
   *
   * 🛑 Ne jamais convertir ce `null` en chaîne sentinelle (`"AUCUNE"`, `"—"`) :
   * c'est lui qui distingue « le modèle a tranché : rien ne colle » d'une
   * question que le pré-tagging n'a pas couverte (`suggestions: []`). Une
   * sentinelle finirait par s'afficher telle quelle.
   */
  notionCode: string | null;
  notionLabel: string | null;
  /** 0 → 1. */
  confidence: number;
  /** Pourquoi le modèle propose cette notion. `null` = le job ne l'a pas écrit. */
  rationale: string | null;
  /**
   * 🛑 `null` = **pas encore relue**, jamais « rien à en dire ». C'est ce
   * champ, et lui seul, qui dit au relecteur qui revient ce qu'il a déjà
   * écarté. Typé `string` parce qu'un verdict inconnu d'un backend plus récent
   * ne doit pas casser l'écran — cf. `CivicReviewVerdict` pour les valeurs
   * connues.
   */
  reviewVerdict: string | null;
}

export interface CivicTaggingQuestion {
  questionId: string;
  enonce: string;
  /** Souvent le seul endroit où la notion est identifiable. `null` = absente. */
  explication: string | null;
  choix: CivicTaggingChoix[];
  themeCode: string;
  mention: string;
  /** 🛑 `null` = **pas encore taguée**, jamais « sans notion ». */
  notionCode: string | null;
  notionLabel: string | null;
  suggestions: CivicTaggingSuggestion[];
}

export interface CivicTaggingQueue {
  questions: CivicTaggingQuestion[];
  /** Questions civiques actives encore sans notion, **tous thèmes**. */
  resteATaguer: number;
}
