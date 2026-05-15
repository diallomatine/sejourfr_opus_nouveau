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
