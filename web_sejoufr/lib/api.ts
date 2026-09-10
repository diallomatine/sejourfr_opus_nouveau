// Client HTTP minimal vers le backend Spring Boot.
// Compatible Server Components et Client Components (Next 16 / App Router).

import type {
  AnswerResultResponse,
  ApiError,
  AttemptResponse,
  CivicPlanDto,
  CivicPlanGrain,
  AttemptSummaryResponse,
  AttemptType,
  AuthenticatedUser,
  DashboardSummaryResponse,
  Difficulty,
  DiagnosticResponse,
  EpreuveType,
  ExamTemplateSummary,
  FullTcfExamResponse,
  FullTcfExamSummaryResponse,
  GoogleSignInRequest,
  LoginRequest,
  LotDto,
  LearningPlanDto,
  Module as ModuleEnum,
  PlanPublicResponse,
  ProductionAttemptStartRequest,
  ProductionBilanResponse,
  ProductionExampleDto,
  ProductionSubmissionDto,
  ProductionTaskDto,
  PublicDiagnosticResponse,
  TcfDiagnosticDto,
  CivicDiagnosticDto,
  PreparationDto,
  CivicDiagnosticResultDto,
  TcfDiagnosticResultDto,
  TcfReassessmentEligibilityDto,
  QuestionReviewResponse,
  QuestionType,
  RegisterRequest,
  SkillAnalysisQuotaDto,
  SkillAttemptDto,
  SkillDetailDto,
  SkillDto,
  SkillPromptDto,
  SkillReferenceDto,
  SkillSection,
  SkillSelfEvaluation,
  SkillTaskProgressDto,
  StartAttemptRequest,
  SubmitAnswerRequest,
  SubmitProductionTextRequest,
  SubmitSkillTextRequest,
  TargetProcedure,
  ThemeUserResponse,
  TokenResponse,
  UserStatsResponse,
} from "./types";
import {detectTrafficSource} from "./traffic-source";
import {cached, clearDataCache, invalidateCache, peekCached, primeCached} from "./data-cache";
import {requiresDiagnosticRevalidation} from "./diagnostic";
import {PRODUCTION_PROGRESS_PREFIXES} from "./production-catalog";
import {SKILLS_CACHE_PREFIX} from "./skill-catalog";

/**
 * Invalidation du cache mémoire (`lib/data-cache.ts`) — **le seul endroit** où
 * elle est décidée.
 *
 * Le catalogue du parcours TCF EE/EO (compétences, sujets, exemples) est mis en
 * cache pour la session : c'est du contenu éditorial, et le recharger à chaque
 * bascule de mode ou de tâche était précisément le défaut à corriger. Mais deux
 * données bougent avec l'usage — l'historique des soumissions et les compteurs
 * de progression / de quota. Elles sont donc purgées **ici, à la source**,
 * juste après l'écriture qui les rend fausses : un écran qui oublierait de le
 * faire afficherait une progression mensongère, et c'est le seul vrai piège de
 * ce cache.
 */
function invalidateProductionProgress(): void {
    for (const prefix of PRODUCTION_PROGRESS_PREFIXES) invalidateCache(prefix);
}

export const DIAGNOSTIC_CACHE_PREFIX = "diagnostic:";
export const LEARNING_PLAN_CACHE_PREFIX = "learning-plan:";

/** Diagnostic et Plan sont deux vues d'une même trajectoire. Toute production
 *  pertinente peut faire avancer l'une et réordonner l'autre. */
function invalidateDiagnosticAndPlan(): void {
    invalidateCache(DIAGNOSTIC_CACHE_PREFIX);
    invalidateCache(LEARNING_PLAN_CACHE_PREFIX);
}

/** Une production de compétence (ou son analyse) change les compteurs de
 *  l'épreuve entière : compétences, agrégat par tâche, détail d'une compétence. */
function invalidateSkillProgress(): void {
    invalidateCache(SKILLS_CACHE_PREFIX);
}

/** Après une écriture de production : l'historique et les bilans sont périmés. */
function afterProductionWrite(sub: ProductionSubmissionDto): ProductionSubmissionDto {
    invalidateProductionProgress();
    invalidateDiagnosticAndPlan();
    return sub;
}

/**
 * Pendant un polling, une production n'est vraiment « nouvelle » qu'en arrivant
 * à son état terminal : c'est là que la note apparaît. Purger à ce moment-là
 * évite qu'un écran des sujets, rouvert plus tard, affiche « Traité » sans note
 * sur une production pourtant évaluée depuis longtemps.
 */
function afterProductionRead(sub: ProductionSubmissionDto): ProductionSubmissionDto {
    if (sub.statut === "EVALUATED" || sub.statut === "FAILED") {
        invalidateProductionProgress();
        invalidateDiagnosticAndPlan();
    }
    return sub;
}

/** Même règle côté compétences : le statut d'un petit sujet (« Validé », « À
 *  renforcer ») se fixe à la fin de l'analyse, pas à la soumission. */
function afterSkillAttempt(attempt: SkillAttemptDto): SkillAttemptDto {
    if (attempt.statut === "EVALUATED" || attempt.statut === "FAILED" || attempt.statut === "RECORDED") {
        invalidateSkillProgress();
        invalidateCache(LEARNING_PLAN_CACHE_PREFIX);
    }
    return attempt;
}

// Base URL configurable via .env.local : NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
export const API_BASE_URL =
    process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8080";
// http://192.168.1.13:3000

// ============================================================================
// Storage du token (cookie pour SSR + localStorage pour CSR rapide)
// ============================================================================

export const ACCESS_TOKEN_KEY = "sejourfr.accessToken";
export const REFRESH_TOKEN_KEY = "sejourfr.refreshToken";

export const tokenStorage = {
    getAccess(): string | null {
        if (typeof window === "undefined") return null;
        return localStorage.getItem(ACCESS_TOKEN_KEY);
    },
    getRefresh(): string | null {
        if (typeof window === "undefined") return null;
        return localStorage.getItem(REFRESH_TOKEN_KEY);
    },
    set(tokens: TokenResponse) {
        if (typeof window === "undefined") return;
        localStorage.setItem(ACCESS_TOKEN_KEY, tokens.accessToken);
        localStorage.setItem(REFRESH_TOKEN_KEY, tokens.refreshToken);
        // Cookie léger pour permettre au middleware/SSR de connaître l'état.
        // `Secure` en prod (HTTPS) pour ne jamais transiter en clair ; omis en
        // dev (http://localhost) sinon le navigateur refuse le cookie.
        const secure = window.location.protocol === "https:" ? "; Secure" : "";
        document.cookie = `${ACCESS_TOKEN_KEY}=${tokens.accessToken}; path=/; max-age=${tokens.expiresInSeconds}; SameSite=Lax${secure}`;
    },
    clear() {
        if (typeof window === "undefined") return;
        localStorage.removeItem(ACCESS_TOKEN_KEY);
        localStorage.removeItem(REFRESH_TOKEN_KEY);
        document.cookie = `${ACCESS_TOKEN_KEY}=; path=/; max-age=0`;
        // La session s'arrête ici : le cache mémoire porte la progression d'un
        // candidat (sujets traités, notes, quotas). Le laisser en place le
        // servirait au compte suivant ouvert dans le même onglet.
        clearDataCache();
    },
};

// ============================================================================
// Fetch wrapper
// ============================================================================

export class ApiException extends Error {
    status: number;
    payload?: ApiError;

    constructor(status: number, message: string, payload?: ApiError) {
        super(message);
        this.status = status;
        this.payload = payload;
    }
}

interface FetchOptions extends RequestInit {
    auth?: boolean; // ajouter le Bearer
    json?: unknown; // body JSON à sérialiser
    /** Interne : court-circuite la tentative de refresh (utilisé par /auth/refresh). */
    skipRefresh?: boolean;
    /**
     * Extension Next.js : revalidation ISR (en secondes) ou tags de cache.
     * Utilisé pour les endpoints publics qui peuvent être servis depuis le cache
     * de la page statique (ex: /api/billing/plans sur la landing).
     */
    next?: { revalidate?: number | false; tags?: string[] };
}

// File d'attente partagée pour ne pas tenter plusieurs refresh en parallèle :
// si une seconde requête prend un 401 pendant qu'on rafraîchit déjà, elle
// attend la promesse en cours plutôt que de relancer un refresh concurrent.
let refreshPromise: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
    if (refreshPromise) return refreshPromise;

    refreshPromise = (async () => {
        const rt = tokenStorage.getRefresh();
        if (!rt) return null;
        try {
            const tokens = await rawFetch<TokenResponse>("/api/auth/refresh", {
                method: "POST",
                json: {refreshToken: rt},
                skipRefresh: true,
            });
            tokenStorage.set(tokens);
            return tokens.accessToken;
        } catch {
            tokenStorage.clear();
            return null;
        } finally {
            // Libère le slot pour les futurs refreshs.
            setTimeout(() => {
                refreshPromise = null;
            }, 0);
        }
    })();

    return refreshPromise;
}

/**
 * En-têtes d'identification du client, posés sur **toutes** les requêtes — un
 * seul point de câblage, jamais un ajout appel par appel.
 *
 * - `X-Sejourfr-Client: web` distingue le site des applications mobiles ;
 * - `X-Sejourfr-Source` transporte la provenance (TikTok, Instagram…) quand
 *   elle est connue. Le serveur ne la lit qu'à la création du compte et d'une
 *   session de diagnostic ; l'envoyer partout coûte quelques octets et évite de
 *   devoir la câbler sur chaque appel qui pourrait un jour compter.
 *
 * Rien n'est stocké côté navigateur : la provenance est relue de l'URL (ou du
 * referrer) à chaque requête. En rendu serveur, `detectTrafficSource` rend
 * `null` sans lever — l'en-tête est simplement absent.
 */
function clientHeaders(): Record<string, string> {
    const source = detectTrafficSource();
    return source
        ? {"X-Sejourfr-Client": "web", "X-Sejourfr-Source": source}
        : {"X-Sejourfr-Client": "web"};
}

async function rawFetch<T>(path: string, opts: FetchOptions = {}): Promise<T> {
    const {auth, json, headers, skipRefresh: _skip, cache, next, ...rest} = opts;

    const finalHeaders: Record<string, string> = {
        Accept: "application/json",
        ...clientHeaders(),
        ...((headers as Record<string, string>) || {}),
    };

    if (json !== undefined) {
        finalHeaders["Content-Type"] = "application/json";
    }

    if (auth) {
        const t = tokenStorage.getAccess();
        if (t) finalHeaders["Authorization"] = `Bearer ${t}`;
    }

    // Par défaut "no-store" pour ne pas servir de données utilisateur en cache.
    // Les endpoints publics peuvent surcharger via opts.cache ou opts.next pour
    // bénéficier du cache Next (ISR, tags) — voir billingApi.listPlans.
    const fetchInit: RequestInit & { next?: FetchOptions["next"] } = {
        ...rest,
        headers: finalHeaders,
        body: json !== undefined ? JSON.stringify(json) : rest.body,
    };
    if (next) {
        fetchInit.next = next;
    } else {
        fetchInit.cache = cache ?? "no-store";
    }

    const res = await fetch(`${API_BASE_URL}${path}`, fetchInit);

    if (!res.ok) {
        let payload: ApiError | undefined;
        try {
            payload = await res.json();
        } catch {
            // pas de JSON
        }
        throw new ApiException(
            res.status,
            payload?.message || `HTTP ${res.status}`,
            payload,
        );
    }

    if (res.status === 204) return undefined as T;
    return (await res.json()) as T;
}

/**
 * 401 définitif (refresh KO ou pas de refresh token) : purge le storage et
 * envoie l'utilisateur vers /connexion?next=<route courante>. Ne s'exécute
 * pas si on est déjà sur /connexion ou /inscription (évite la boucle quand
 * on tape de mauvais credentials).
 */
function redirectToLogin(): void {
    if (typeof window === "undefined") return;
    const path = window.location.pathname;
    if (path === "/connexion" || path === "/inscription") return;
    tokenStorage.clear();
    const next = encodeURIComponent(path + window.location.search);
    window.location.assign(`/connexion?next=${next}`);
}

async function apiFetch<T>(path: string, opts: FetchOptions = {}): Promise<T> {
    try {
        return await rawFetch<T>(path, opts);
    } catch (err) {
        // 401 sur endpoint protégé : tentative de refresh une fois, sinon redirect.
        // On n'intercepte pas /api/auth/* pour ne pas casser les formulaires login/refresh.
        if (
            err instanceof ApiException &&
            err.status === 401 &&
            !opts.skipRefresh &&
            typeof window !== "undefined" &&
            !path.startsWith("/api/auth/")
        ) {
            if (tokenStorage.getRefresh()) {
                const newToken = await refreshAccessToken();
                if (newToken) {
                    return rawFetch<T>(path, opts);
                }
            }
            redirectToLogin();
        }
        throw err;
    }
}

// ============================================================================
// Endpoints Auth
// ============================================================================

export const authApi = {
    async login(body: LoginRequest): Promise<TokenResponse> {
        const tokens = await apiFetch<TokenResponse>("/api/auth/login", {
            method: "POST",
            json: body,
        });
        tokenStorage.set(tokens);
        return tokens;
    },

    async register(body: RegisterRequest): Promise<TokenResponse> {
        const tokens = await apiFetch<TokenResponse>("/api/auth/register", {
            method: "POST",
            json: body,
        });
        tokenStorage.set(tokens);
        return tokens;
    },

    /**
     * Echange un ID token Google (obtenu via Google Identity Services dans le
     * navigateur) contre une session SejourFR. Cree le compte automatiquement
     * si l'email n'existe pas encore.
     */
    async google(body: GoogleSignInRequest): Promise<TokenResponse> {
        const tokens = await apiFetch<TokenResponse>("/api/auth/google", {
            method: "POST",
            json: body,
        });
        tokenStorage.set(tokens);
        return tokens;
    },

    async me(): Promise<AuthenticatedUser> {
        return apiFetch<AuthenticatedUser>("/api/auth/me", {auth: true});
    },

    async refresh(): Promise<string | null> {
        return refreshAccessToken();
    },

    async forgotPassword(email: string): Promise<void> {
        await apiFetch<void>("/api/auth/forgot-password", {
            method: "POST",
            json: {email},
        });
    },

    async resetPassword(token: string, newPassword: string): Promise<void> {
        await apiFetch<void>("/api/auth/reset-password", {
            method: "POST",
            json: {token, newPassword},
        });
    },

    logout() {
        // Revocation serveur best-effort du refresh token (endpoint idempotent),
        // puis purge locale quoi qu'il arrive (réseau coupé, token déjà expiré…).
        const rt = tokenStorage.getRefresh();
        if (rt) {
            void apiFetch<void>("/api/auth/logout", {
                method: "POST",
                json: {refreshToken: rt},
            }).catch(() => undefined);
        }
        tokenStorage.clear();
    },
};

export const accountApi = {
    /** Supprime le compte de l'utilisateur courant (anonymisation côté serveur).
     * Le backend identifie le user via le Bearer — aucun paramètre. */
    async deleteAccount(): Promise<import("./types").AccountDeletionResponse> {
        return apiFetch<import("./types").AccountDeletionResponse>("/api/account", {
            method: "DELETE",
            auth: true,
        });
    },

    /** Met à jour l'identité (prénom / nom). `PATCH /api/me/profile`. */
    updateProfile(firstName: string, lastName: string): Promise<void> {
        return apiFetch<void>("/api/me/profile", {
            method: "PATCH",
            json: {firstName, lastName},
            auth: true,
        });
    },

    /** Change le mot de passe (compte LOCAL). `POST /api/me/change-password`. */
    changePassword(currentPassword: string, newPassword: string): Promise<void> {
        return apiFetch<void>("/api/me/change-password", {
            method: "POST",
            json: {currentPassword, newPassword},
            auth: true,
        });
    },

    /** Demande un changement d'email : un lien de vérification est envoyé au
     *  nouvel email, l'ancien reste actif tant qu'il n'est pas confirmé.
     *  `POST /api/me/change-email-request`. */
    requestEmailChange(newEmail: string, currentPassword: string): Promise<void> {
        return apiFetch<void>("/api/me/change-email-request", {
            method: "POST",
            json: {newEmail, currentPassword},
            auth: true,
        });
    },
};

// ============================================================================
// Endpoints Themes
// ============================================================================

export const themeApi = {
    list(module: ModuleEnum): Promise<ThemeUserResponse[]> {
        return apiFetch<ThemeUserResponse[]>(`/api/themes?module=${module}`, {
            auth: true,
        });
    },
};

// ============================================================================
// Endpoints Billing (Stripe Payment Links)
// ============================================================================

/**
 * Périodicité d'un abonnement récurrent. Le {@link planCodeFor} en dérive
 * le `planCode` à passer à {@link billingApi.getPaymentLink}.
 */
export type PlanPeriodicity = "monthly" | "quarterly" | "yearly";

/** Module visé pour un paywall : civique seul ou intégral (civique + TCF). */
export type PlanModuleTarget = "CIVIQUE" | "INTEGRAL";

/**
 * Dérive le `planCode` backend à partir d'un module + d'une périodicité.
 * Doit rester synchronisé avec la table `plans` (migration V106 :
 * CIVIQUE_MONTHLY / CIVIQUE_QUARTERLY / CIVIQUE_YEARLY + idem INTEGRAL_*).
 */
export function planCodeFor(
    module: PlanModuleTarget,
    periodicity: PlanPeriodicity,
): string {
    const suffix = periodicity.toUpperCase();
    return `${module}_${suffix}`;
}

/**
 * Mappe un `billingCycle` backend vers une {@link PlanPeriodicity} du toggle UI.
 * Le seul cycle servant à l'achat est récurrent : MONTHLY/THREE_MONTHS/YEARLY.
 * Renvoie {@code null} pour les autres (NONE, SIX_MONTHS).
 */
export function periodicityFromCycle(
    cycle: string | null | undefined,
): PlanPeriodicity | null {
    switch (cycle) {
        case "MONTHLY": return "monthly";
        case "THREE_MONTHS": return "quarterly";
        case "YEARLY": return "yearly";
        default: return null;
    }
}

export const billingApi = {
    /**
     * Récupère l'URL d'une Stripe Checkout Session (mode SUBSCRIPTION) pour
     * le plan demandé. Le backend ajoute déjà `client_reference_id=<user_id>`
     * à l'URL ; le front n'a plus qu'à rediriger vers cette URL.
     *
     * @param planCode code du Plan en base (ex: `INTEGRAL_MONTHLY`). Voir
     *                 {@link planCodeFor} pour le dériver depuis le toggle UI.
     */
    getPaymentLink(planCode: string): Promise<{ url: string }> {
        return apiFetch<{ url: string }>(
            `/api/billing/payment-link?planCode=${encodeURIComponent(planCode)}`,
            {auth: true}
        );
    },

    /**
     * Liste publique des plans actifs (FREE + payants), avec prix actuel et prix
     * d'origine (offre de lancement). Utilisé par la section Tarifs de la landing
     * pour ne pas hardcoder les montants côté front.
     *
     * Mis en cache ISR 30 min : la landing reste statique et performante, mais
     * les prix changeront automatiquement dans la demi-heure suivant une mise
     * à jour côté admin (table `plans`).
     */
    listPlans(): Promise<PlanPublicResponse[]> {
        return apiFetch<PlanPublicResponse[]>(`/api/billing/plans`, {
            auth: false,
            next: {revalidate: 1800},
        });
    },

    /**
     * Statut Premium agrégé toutes sources (Stripe + Apple + Google). À
     * appeler pour afficher des détails plus précis que `AuthenticatedUser`
     * (source, productId, autoRenew, status fin). Le statut booléen `isPremium`
     * reste lu via `useAuth().user`.
     */
    getSubscriptionStatus(): Promise<import("./types").SubscriptionStatusResponse> {
        return apiFetch<import("./types").SubscriptionStatusResponse>(
            `/api/billing/subscription-status`,
            {auth: true}
        );
    },

    /**
     * Résilie l'abonnement Premium en cours. Le backend route selon la source :
     * - Stripe : annulation à la fin de période, réponse `action=DONE`.
     * - Apple/Google : réponse `action=REDIRECT` avec l'URL de gestion du store
     *   (les stores n'autorisent pas l'annulation serveur).
     */
    cancel(): Promise<import("./types").CancelSubscriptionResponse> {
        return apiFetch<import("./types").CancelSubscriptionResponse>(
            `/api/billing/cancel`,
            {auth: true, method: "POST"}
        );
    },
};

// ============================================================================
// Endpoints Newsletter (publique)
// ============================================================================

export interface NewsletterSubscribeResponse {
    email: string;
    alreadySubscribed: boolean;
}

export const newsletterApi = {
    // POST /api/newsletter/subscribe — à implémenter côté Java.
    // Tant que l'endpoint n'existe pas, le 404 est renvoyé au caller qui affiche
    // un message "service bientôt disponible". Même pattern que billingApi.
    subscribe(
        email: string,
        source?: string
    ): Promise<NewsletterSubscribeResponse> {
        return apiFetch<NewsletterSubscribeResponse>("/api/newsletter/subscribe", {
            method: "POST",
            auth: false,
            json: {email, source},
        });
    },
};

// ============================================================================
// Endpoints Contact (publique)
// ============================================================================

export interface ContactSubmitRequest {
    /** Miroir du DTO backend `ContactRequest.name` (@NotBlank). */
    name: string;
    email: string;
    subject: string;
    message: string;
    consent: boolean;
    /** Honeypot anti-bot — toujours "" pour un humain. */
    website: string;
}

export interface ContactSubmitResponse {
    ticketId: string;
}

export const contactApi = {
    // POST /api/contact — à implémenter côté Java.
    // Tant que l'endpoint n'existe pas, le 404 est renvoyé au caller qui affiche
    // un message inline "service bientôt disponible". Même pattern que
    // newsletterApi / billingApi.
    submit(body: ContactSubmitRequest): Promise<ContactSubmitResponse> {
        return apiFetch<ContactSubmitResponse>("/api/contact", {
            method: "POST",
            auth: false,
            json: body,
        });
    },
};

// ============================================================================
// Endpoints Examens blancs (vitrine publique)
// ============================================================================

export const examApi = {
    list(module?: ModuleEnum): Promise<ExamTemplateSummary[]> {
        const qs = module ? `?module=${module}` : "";
        return apiFetch<ExamTemplateSummary[]>(`/api/exams${qs}`, {auth: false});
    },

    getBySlug(slug: string): Promise<ExamTemplateSummary> {
        return apiFetch<ExamTemplateSummary>(`/api/exams/${slug}`, {auth: false});
    },
};

// ============================================================================
// Lots (découpage déterministe d'un thème/épreuve en séries)
// ============================================================================

export const lotApi = {
    /** Lots civiques d'un thème (themeId obligatoire côté backend pour CIVIQUE). */
    listCivique(themeId: string): Promise<LotDto[]> {
        return apiFetch<LotDto[]>(
            `/api/lots?module=CIVIQUE&themeId=${encodeURIComponent(themeId)}`,
            { auth: true },
        );
    },
    /** Lots TCF d'une épreuve QCM (CO/CE/STRUCTURE) à un niveau (A2/B1/B2 obligatoire). */
    listTcf(questionType: QuestionType, difficulty: Difficulty): Promise<LotDto[]> {
        return apiFetch<LotDto[]>(
            `/api/lots?module=TCF&questionType=${questionType}&difficulty=${difficulty}`,
            { auth: true },
        );
    },
};

/**
 * Variante guest de `lotApi` : même découpage de séries sans les derniers
 * scores. La série 1 est jouable sans compte via `publicAttemptApi.startDemo`
 * (TRAINING + lotNumero=1), les séries 2+ ouvrent la GuestGateSheet.
 */
export const publicLotApi = {
    listCivique(themeId: string): Promise<LotDto[]> {
        return apiFetch<LotDto[]>(
            `/api/public/lots?module=CIVIQUE&themeId=${encodeURIComponent(themeId)}`,
        );
    },
    listTcf(questionType: QuestionType, difficulty: Difficulty): Promise<LotDto[]> {
        return apiFetch<LotDto[]>(
            `/api/public/lots?module=TCF&questionType=${questionType}&difficulty=${difficulty}`,
        );
    },
};

// ============================================================================
// Endpoints User content (favoris, questions ratées, stats, target path)
// ============================================================================

export const userContentApi = {
    favorites(module?: ModuleEnum): Promise<QuestionReviewResponse[]> {
        const qs = module ? `?module=${module}` : "";
        return apiFetch<QuestionReviewResponse[]>(
            `/api/me/questions/favorites${qs}`,
            {auth: true},
        );
    },

    addFavorite(questionId: string): Promise<void> {
        return apiFetch<void>(`/api/me/questions/${questionId}/favorite`, {
            method: "POST",
            auth: true,
        });
    },

    removeFavorite(questionId: string): Promise<void> {
        return apiFetch<void>(`/api/me/questions/${questionId}/favorite`, {
            method: "DELETE",
            auth: true,
        });
    },

    wrong(
        module?: ModuleEnum,
        opts: { questionType?: QuestionType; themeId?: string } = {},
    ): Promise<QuestionReviewResponse[]> {
        const p = new URLSearchParams();
        if (module) p.set("module", module);
        if (opts.questionType) p.set("questionType", opts.questionType);
        if (opts.themeId) p.set("themeId", opts.themeId);
        const qs = p.toString() ? `?${p.toString()}` : "";
        return apiFetch<QuestionReviewResponse[]>(
            `/api/me/questions/wrong${qs}`,
            {auth: true},
        );
    },

    /**
     * Version détaillée d'une question pour la révision : choix résolus + explanation.
     * Backend exige que l'utilisateur ait déjà tenté ou favorisé la question.
     */
    reviewQuestion(questionId: string): Promise<QuestionReviewResponse> {
        return apiFetch<QuestionReviewResponse>(
            `/api/me/questions/${questionId}/review`,
            {auth: true},
        );
    },

    /**
     * Définit / met à jour le parcours administratif visé (CSP/CR/NAT).
     * Le backend dérive ensuite automatiquement la difficulté.
     */
    updateTargetPath(procedure: TargetProcedure): Promise<void> {
        return apiFetch<void>(`/api/me/target-path`, {
            method: "PUT",
            json: {targetProcedure: procedure},
            auth: true,
        });
    },

    /**
     * La date d'examen déclarée (`10_` §3.2, question 3). Format `YYYY-MM-DD`.
     *
     * 🛑 **Une date, pas un instant** : une convocation porte un JOUR. Envoyer
     * un horodatage ferait basculer la date d'un fuseau à l'autre.
     *
     * 🛑 **Route séparée de `target-path`**, et ce n'est pas cosmétique : loger
     * la date dans la mise à jour de la démarche l'effacerait à chaque
     * changement de procédure. `null` efface volontairement — « pas encore de
     * date » est une réponse, pas une absence de réponse.
     *
     * C'est cette date qui alimente le compte à rebours et le pass recommandé
     * du paywall (L5) : sans elle, `passRecommande` ne peut rien proposer.
     */
    /**
     * **Où en sont les deux préparations** — l'état UNIQUE.
     *
     * 🛑 L'Accueil, le Plan et les Examens lisent **cet** appel. Ne jamais
     * dériver l'étape d'un module ailleurs : trois déductions finiraient par
     * proposer trois choses différentes au même candidat.
     */
    preparation(): Promise<PreparationDto> {
        return apiFetch<PreparationDto>("/api/me/preparation", {auth: true});
    },

    updateExamDate(examDate: string | null): Promise<void> {
        return apiFetch<void>(`/api/me/exam-date`, {
            method: "PUT",
            json: {examDate},
            auth: true,
        });
    },
};

// ============================================================================
// Endpoints Stats
// ============================================================================

export const statsApi = {
    get(module: ModuleEnum): Promise<UserStatsResponse> {
        return apiFetch<UserStatsResponse>(`/api/me/stats?module=${module}`, {
            auth: true,
        });
    },
};

// ============================================================================
// Endpoint Dashboard (agrégat unique : streak + stats + catégories)
// ============================================================================

function fetchDashboardSummary(): Promise<DashboardSummaryResponse> {
    return apiFetch<DashboardSummaryResponse>("/api/me/dashboard", {auth: true});
}

// Mémo 30 s : la sidebar (streak) et la page dashboard consomment le même
// agrégat — un seul appel réseau quand les deux montent en même temps.
let dashboardMemo: {at: number; promise: Promise<DashboardSummaryResponse>} | null = null;

export const dashboardApi = {
    summary: fetchDashboardSummary,
    summaryCached(): Promise<DashboardSummaryResponse> {
        if (dashboardMemo && Date.now() - dashboardMemo.at < 30_000) {
            return dashboardMemo.promise;
        }
        const promise = fetchDashboardSummary().catch((e) => {
            dashboardMemo = null;
            throw e;
        });
        dashboardMemo = {at: Date.now(), promise};
        return promise;
    },
};

// ============================================================================
// Diagnostic TCF rapide + Plan personnalisé
// ============================================================================

function afterDiagnosticRead(response: DiagnosticResponse): DiagnosticResponse {
    // Le pipeline peut faire évoluer le diagnostic sans écriture de cet onglet.
    // Invalider l'entrée pendant que son loader est encore en vol détache le
    // snapshot du cache sans rejeter la promesse : les appels simultanés restent
    // mutualisés, mais le prochain lecteur relit toujours l'état serveur.
    if (requiresDiagnosticRevalidation(response)) {
        invalidateCache(DIAGNOSTIC_CACHE_PREFIX);
    }
    // À la fin de l'analyse, le Plan vient d'être construit côté serveur.
    if (response.status === "COMPLETED" || response.status === "FAILED") {
        invalidateCache(LEARNING_PLAN_CACHE_PREFIX);
    }
    return response;
}

function fetchCurrentDiagnostic(): Promise<DiagnosticResponse> {
    return apiFetch<DiagnosticResponse>("/api/diagnostics/current", {auth: true}).then(
        afterDiagnosticRead,
    );
}

const LEARNING_PLAN_CACHE_KEY = `${LEARNING_PLAN_CACHE_PREFIX}current`;

/**
 * Toute lecture du Plan **range son résultat** sous la clé de cache, y compris
 * la lecture directe de `/plan` : l'écran d'une compétence ouverte depuis le
 * Plan y relit le périmètre de l'étape (`stepPromptIds`) **sans redemander le
 * Plan au serveur**. Le comportement de `/plan` ne change pas pour autant — il
 * continue d'appeler l'API à chaque montage, une analyse asynchrone ne doit
 * jamais rester figée.
 */
function fetchLearningPlan(): Promise<LearningPlanDto> {
    return apiFetch<LearningPlanDto>("/api/me/plan", {auth: true}).then((plan) => {
        primeCached(LEARNING_PLAN_CACHE_KEY, plan);
        return plan;
    });
}

/**
 * Le diagnostic TCF **4 épreuves** (L4).
 *
 * 🛑 Distinct de `diagnosticApi`, qui porte le diagnostic **initial** (une
 * production écrite + une orale). Deux objets produit différents.
 *
 * La **passation** n'est pas ici : les sections QCM répondent par `attemptApi`
 * et les productions par `productionApi`, exactement comme l'examen complet.
 */
export const tcfDiagnosticApi = {
    /**
     * Ouvre le diagnostic, ou rend celui en cours. **Idempotent** côté serveur :
     * un double appui ne crée pas deux diagnostics — ce qui compte, le premier
     * étant le seul gratuit.
     */
    open(): Promise<TcfDiagnosticDto> {
        return apiFetch<TcfDiagnosticDto>("/api/tcf-diagnostics", {
            method: "POST",
            auth: true,
        });
    },

    /**
     * Le diagnostic courant, ou `null` si le candidat n'en a jamais ouvert
     * (**204** côté serveur).
     *
     * 🛑 Une lecture n'ouvre jamais de diagnostic par effet de bord : ne pas
     * remplacer cet appel par `open()` pour « simplifier » un écran.
     */
    async current(): Promise<TcfDiagnosticDto | null> {
        const res = await apiFetch<TcfDiagnosticDto | null>(
            "/api/tcf-diagnostics/current", {auth: true},
        );
        return res ?? null;
    },

    get(sessionId: string): Promise<TcfDiagnosticDto> {
        return apiFetch<TcfDiagnosticDto>(`/api/tcf-diagnostics/${sessionId}`, {auth: true});
    },

    /**
     * Pose l'ancre du chrono d'une section. À appeler **avant** d'ouvrir le
     * runner : sans elle la section n'a aucune échéance. Idempotent — rappelée,
     * elle rend le temps réellement restant.
     */
    startSection(sessionId: string, epreuve: EpreuveType): Promise<TcfDiagnosticDto> {
        return apiFetch<TcfDiagnosticDto>(
            `/api/tcf-diagnostics/${sessionId}/sections/${epreuve}/start`,
            {method: "POST", auth: true},
        );
    },

    /** Calcule le résultat et clôture. N'exige pas les 4 sections. */
    result(sessionId: string): Promise<TcfDiagnosticResultDto> {
        return apiFetch<TcfDiagnosticResultDto>(
            `/api/tcf-diagnostics/${sessionId}/result`,
            {method: "POST", auth: true},
        );
    },

    /** Relit un résultat sans rien reclôturer. */
    readResult(sessionId: string): Promise<TcfDiagnosticResultDto> {
        return apiFetch<TcfDiagnosticResultDto>(
            `/api/tcf-diagnostics/${sessionId}/result`, {auth: true},
        );
    },

    /**
     * **Peut-il relancer, et sinon pourquoi ?** (L7)
     *
     * 🛑 C'est la seule façon correcte de le savoir. Ne jamais le déduire d'un
     * `completedAt` ni recompter les 14 jours ici : la règle a une seule
     * autorité, et elle est serveur.
     *
     * Jamais 204 — un candidat sans aucun diagnostic reçoit
     * `{first: true, canStart: true}`.
     */
    eligibility(): Promise<TcfReassessmentEligibilityDto> {
        return apiFetch<TcfReassessmentEligibilityDto>(
            "/api/tcf-diagnostics/eligibility", {auth: true},
        );
    },
};

/**
 * Le diagnostic CIVIQUE (L9, `20_` §4).
 *
 * 🛑 **Distinct de l'examen blanc civique** : même format (40 questions),
 * couverture équilibrée contre représentative, il CRÉE le plan là où l'examen
 * blanc VÉRIFIE la préparation.
 *
 * 🛑 **La passation ne passe pas par ici** : les réponses vont sur
 * `/api/attempts/{id}/answers`, exactement comme n'importe quelle série. Aucun
 * runner n'est dupliqué.
 *
 * 🛑 **Aucun appel LLM** : le civique est du QCM déterministe.
 */
export const civicDiagnosticApi = {
    /** Ouvre, ou rend celui en cours. **Idempotent** : pas deux tirages. */
    open(): Promise<CivicDiagnosticDto> {
        return apiFetch<CivicDiagnosticDto>("/api/civic-diagnostics", {
            method: "POST",
            auth: true,
        });
    },

    /**
     * Le diagnostic courant, ou `null` (**204**).
     *
     * 🛑 Une lecture n'ouvre jamais de diagnostic par effet de bord : ne pas
     * remplacer cet appel par `open()` pour « simplifier » un écran — l'ouvrir
     * consomme l'unique diagnostic gratuit.
     */
    async current(): Promise<CivicDiagnosticDto | null> {
        const res = await apiFetch<CivicDiagnosticDto | null>(
            "/api/civic-diagnostics/current", {auth: true},
        );
        return res ?? null;
    },

    /** Calcule le résultat et clôture. */
    result(sessionId: string): Promise<CivicDiagnosticResultDto> {
        return apiFetch<CivicDiagnosticResultDto>(
            `/api/civic-diagnostics/${sessionId}/result`,
            {method: "POST", auth: true},
        );
    },

    /** Relit un résultat sans rien reclôturer. */
    readResult(sessionId: string): Promise<CivicDiagnosticResultDto> {
        return apiFetch<CivicDiagnosticResultDto>(
            `/api/civic-diagnostics/${sessionId}/result`, {auth: true},
        );
    },

    /**
     * **Adopte** un diagnostic passé sans compte (V053).
     *
     * 🛑 Rien n'est rejoué : ce sont les mêmes questions, déjà corrigées. Le
     * serveur ne fait que poser le porteur. Idempotent — un double appel
     * pendant l'inscription rend la même session.
     */
    adopt(sessionId: string): Promise<CivicDiagnosticDto> {
        return apiFetch<CivicDiagnosticDto>(
            `/api/civic-diagnostics/${sessionId}/adopt`,
            {method: "POST", auth: true},
        );
    },
};

/**
 * **Le plan civique** (L10, `20_` §6).
 *
 * 🛑 **Il n'y a pas de « recompute ».** Le plan est un dérivé relu à chaque
 * appel côté serveur : recalculer, c'est relire. Aucune table de progression
 * n'existe, et c'est ce qui rend le tagging rétroactif.
 */
export const civicPlanApi = {
    /**
     * Le plan.
     *
     * 🛑 **Jamais `null`** : sans diagnostic terminé, la réponse porte
     * `disponible: false`. L'écran a besoin de savoir *pourquoi* il n'a rien à
     * montrer pour ouvrir la porte qui débloque.
     */
    get(): Promise<CivicPlanDto> {
        return apiFetch<CivicPlanDto>("/api/me/civic-plan", {auth: true});
    },

    /**
     * Ouvre la **série ciblée** d'une cible du plan.
     *
     * C'est un `TRAINING` ordinaire : le résultat s'ouvre dans
     * `/sessions/{attemptId}`. 🛑 **403 sans abonnement** — même règle que le
     * `locked` servi, cette fois opposable : à router vers l'offre par
     * `handleStartFailure`, jamais à afficher en erreur technique.
     */
    serie(cibleId: string, grain: CivicPlanGrain): Promise<AttemptResponse> {
        return apiFetch<AttemptResponse>(
            `/api/me/civic-plan/cibles/${cibleId}/serie?grain=${grain}`,
            {method: "POST", auth: true},
        );
    },
};

/**
 * Le diagnostic civique **avant le compte** (`V053`).
 *
 * 🛑 **Aucune route de résultat ici, et c'est délibéré** : le résultat est ce
 * qu'on échange contre le compte (arbitrage du propriétaire, 2026-09-10). La
 * passation, elle, passe par `publicAttemptApi` — le même runner que la démo,
 * aucun écran de passation n'est dupliqué.
 */
export const publicCivicDiagnosticApi = {
    /** Tire les 40 questions et ouvre la session du visiteur. */
    open(procedure: TargetProcedure): Promise<CivicDiagnosticDto> {
        return apiFetch<CivicDiagnosticDto>(
            `/api/public/civic-diagnostics?procedure=${procedure}`,
            {method: "POST"},
        );
    },

    /** L'avancement de la session du visiteur. **404 dès qu'un compte l'a adoptée.** */
    get(sessionId: string): Promise<CivicDiagnosticDto> {
        return apiFetch<CivicDiagnosticDto>(`/api/public/civic-diagnostics/${sessionId}`);
    },
};

export const diagnosticApi = {
    current: fetchCurrentDiagnostic,

    /**
     * Sujets du diagnostic pour un **visiteur non connecté**. Aucune session
     * n'est créée : le serveur n'a rien à rattacher tant qu'il n'y a pas de
     * compte. Les deux sujets suffisent pour produire ; l'écrit et l'oral sont
     * gardés sur l'appareil jusqu'à l'inscription.
     */
    publicCurrent(): Promise<PublicDiagnosticResponse> {
        return apiFetch<PublicDiagnosticResponse>("/api/public/diagnostics/current", {
            auth: false,
        });
    },

    currentCached(): Promise<DiagnosticResponse> {
        return cached(`${DIAGNOSTIC_CACHE_PREFIX}current`, fetchCurrentDiagnostic);
    },

    /**
     * Ouvre la session, ou rend celle déjà commencée. **Idempotent.**
     *
     * `writtenTaskId` est le sujet que le candidat a réellement lu et traité
     * (L3). Il est **facultatif** et **vérifié serveur** : un identifiant
     * inconnu retombe sur un tirage plutôt que de bloquer un candidat dont le
     * sujet a été désactivé entre-temps.
     */
    start(writtenTaskId?: string): Promise<DiagnosticResponse> {
        invalidateDiagnosticAndPlan();
        const query = writtenTaskId
            ? `?writtenTaskId=${encodeURIComponent(writtenTaskId)}`
            : "";
        return apiFetch<DiagnosticResponse>(`/api/diagnostics${query}`, {
            method: "POST",
            auth: true,
        }).then(afterDiagnosticRead);
    },

    get(sessionId: string): Promise<DiagnosticResponse> {
        return apiFetch<DiagnosticResponse>(`/api/diagnostics/${sessionId}`, {
            auth: true,
        }).then(afterDiagnosticRead);
    },

    retryAnalysis(sessionId: string): Promise<DiagnosticResponse> {
        invalidateDiagnosticAndPlan();
        return apiFetch<DiagnosticResponse>(
            `/api/diagnostics/${sessionId}/retry-analysis`,
            {method: "POST", auth: true},
        ).then(afterDiagnosticRead);
    },
};

export const learningPlanApi = {
    get: fetchLearningPlan,

    getCached(): Promise<LearningPlanDto> {
        return cached(LEARNING_PLAN_CACHE_KEY, fetchLearningPlan);
    },

    /** La clé sous laquelle le Plan est rangé, pour un écran qui veut le
     *  brancher sur `useCachedData` : peint ce qui est déjà connu, et ne
     *  déclenche l'appel que si le cache est **froid**. */
    cacheKey: LEARNING_PLAN_CACHE_KEY,

    /** Le Plan **déjà chargé**, sans aucun appel. `undefined` quand rien n'a
     *  encore été lu (lien profond, rechargement de page).
     *
     *  ⚠️ À réserver aux **conforts d'affichage** qu'on accepte de perdre. Dès
     *  que l'absence du Plan change la **nature** de l'écran — c'était le cas
     *  de l'étape (`?etape=1`), qui retombait sur la fiche des 15 sujets et
     *  renvoyait le candidat dans `/entrainement` après un simple F5 —, on passe
     *  par `cacheKey` + `getCached()` : l'appel n'a lieu qu'à froid. */
    peekCached(): LearningPlanDto | undefined {
        return peekCached<LearningPlanDto>(LEARNING_PLAN_CACHE_KEY);
    },
};

// ============================================================================
// Endpoints Funnel (étapes purement navigateur)
// ============================================================================

/** Étapes du funnel que seul le navigateur peut constater. Le reste (compte
 *  créé, diagnostic commencé/terminé, paiement) est déduit serveur des vraies
 *  tables : ne rien émettre pour ces étapes-là. */
export type FunnelEvent = "PAYWALL_VIEWED" | "SUBSCRIBE_CLICKED";

export const funnelApi = {
    /** 204. Idempotent côté serveur (première occurrence par compte). */
    record(event: FunnelEvent): Promise<void> {
        return apiFetch<void>("/api/me/funnel-events", {
            method: "POST",
            json: {event},
            auth: true,
        });
    },
};

// ============================================================================
// Endpoints Attempts
// ============================================================================

export const attemptApi = {
    start(body: StartAttemptRequest, opts: { auth?: boolean } = {}): Promise<AttemptResponse> {
        // Pour les visiteurs anonymes, utiliser `publicAttemptApi.startDemo` qui
        // pointe sur /api/public/attempts/demo (gating IP + quota mensuel).
        return apiFetch<AttemptResponse>("/api/attempts", {
            method: "POST",
            json: body,
            auth: opts.auth ?? true,
        });
    },

    /**
     * Démarre une **série ciblée** sur une compétence de COMPRÉHENSION (CO/CE) —
     * l'exercice que le Plan désigne sous `PlanExerciseKind.TARGETED_QCM_SERIES`.
     *
     * 🛑 **Seul le `skillId` part.** L'épreuve, le palier et le nombre de
     * questions se dérivent du référentiel côté serveur : un couple
     * (`questionType`, `difficulty`) envoyé d'ici aurait pu contredire la
     * compétence affichée et faire progresser une **autre** compétence.
     *
     * Erreurs : `403` compétence verrouillée (freemium, opposable serveur) ·
     * `422` compétence d'expression · `404` compétence inconnue.
     *
     * ⚠️ Ne **jamais** appeler `GET /api/skills/progress?section=CO|CE` pour
     * préparer cet écran : le serveur répond **422** volontairement — il n'y a
     * pas de choix de tâche en compréhension.
     */
    startTargetedSeries(skillId: string): Promise<AttemptResponse> {
        return apiFetch<AttemptResponse>("/api/attempts", {
            method: "POST",
            json: {type: "TRAINING", module: "TCF", skillId} satisfies StartAttemptRequest,
            auth: true,
        });
    },

    get(id: string): Promise<AttemptResponse> {
        return apiFetch<AttemptResponse>(`/api/attempts/${id}`, {auth: true});
    },

    submitAnswer(
        attemptId: string,
        body: SubmitAnswerRequest,
    ): Promise<AnswerResultResponse> {
        return apiFetch<AnswerResultResponse>(`/api/attempts/${attemptId}/answers`, {
            method: "POST",
            json: body,
            auth: true,
        });
    },

    finish(attemptId: string): Promise<AttemptResponse> {
        return apiFetch<AttemptResponse>(`/api/attempts/${attemptId}/finish`, {
            method: "POST",
            auth: true,
        });
    },

    /**
     * Historique des sessions de l'utilisateur. Sans les questions imbriquées,
     * juste les méta — utilisé par /historique pour la liste paginée.
     */
    listMine(opts: {
        type?: AttemptType;
        module?: ModuleEnum;
        themeId?: string;
        moduleExamQuestionType?: QuestionType;
        limit?: number;
    } = {}): Promise<AttemptSummaryResponse[]> {
        const qs = new URLSearchParams();
        if (opts.type) qs.set("type", opts.type);
        if (opts.module) qs.set("module", opts.module);
        if (opts.themeId) qs.set("themeId", opts.themeId);
        if (opts.moduleExamQuestionType)
            qs.set("moduleExamQuestionType", opts.moduleExamQuestionType);
        if (opts.limit !== undefined) qs.set("limit", String(opts.limit));
        const suffix = qs.toString() ? `?${qs.toString()}` : "";
        return apiFetch<AttemptSummaryResponse[]>(`/api/me/attempts${suffix}`, {
            auth: true,
        });
    },
};

// ============================================================================
// Endpoints Production écrite / orale (TCF_EE / TCF_EO — évaluation IA)
// ============================================================================
// Tout est authentifié : le backend protège ces routes via
// `.anyRequest().authenticated()` (le catalogue de tâches/exemples n'est PAS
// sous /api/public/**). Après un POST, on poll getSubmission jusqu'à statut
// EVALUATED / FAILED (le pipeline IA tourne en arrière-plan).

/** Nom de fichier audio dérivé du type MIME du blob (Safari = mp4, Chrome/FF =
 *  webm) pour que le backend/Whisper détecte le bon format. */
function audioFilename(type: string): string {
    if (type.includes("mp4") || type.includes("m4a")) return "audio.mp4";
    if (type.includes("ogg")) return "audio.ogg";
    if (type.includes("wav")) return "audio.wav";
    if (type.includes("mpeg")) return "audio.mp3";
    return "audio.webm";
}

export const productionApi = {
    /** Crée un attempt vide dédié à une épreuve productive (EE/EO/COMPLET). */
    startAttempt(body: ProductionAttemptStartRequest): Promise<AttemptResponse> {
        return apiFetch<AttemptResponse>("/api/attempts/production", {
            method: "POST",
            json: body,
            auth: true,
        });
    },

    /** Catalogue de tâches filtré. niveau / tacheNumero optionnels. */
    listTasks(opts: {
        epreuve: EpreuveType;
        niveau?: string;
        tacheNumero?: number;
    }): Promise<ProductionTaskDto[]> {
        const qs = new URLSearchParams({epreuve: opts.epreuve});
        if (opts.niveau) qs.set("niveau", opts.niveau);
        if (opts.tacheNumero !== undefined) qs.set("tacheNumero", String(opts.tacheNumero));
        return apiFetch<ProductionTaskDto[]>(`/api/production-tasks?${qs.toString()}`, {
            auth: true,
        });
    },

    getTask(id: string): Promise<ProductionTaskDto> {
        return apiFetch<ProductionTaskDto>(`/api/production-tasks/${id}`, {auth: true});
    },

    /** Composition déterministe d'un examen blanc production : exactement 3
     *  tâches ordonnées T1, T2, T3 pour le slot de l'attempt. 400 sur un
     *  entraînement libre. Couvre aussi les sous-attempts EE/EO d'un examen
     *  TCF complet. */
    getExamTasks(attemptId: string): Promise<ProductionTaskDto[]> {
        return apiFetch<ProductionTaskDto[]>(
            `/api/attempts/${attemptId}/production-exam-tasks`,
            {auth: true},
        );
    },

    /** Réponses-modèles d'une (épreuve, tâche) — onglet « Exemples ». */
    listExamples(epreuve: EpreuveType, tacheNumero: number): Promise<ProductionExampleDto[]> {
        return apiFetch<ProductionExampleDto[]>(
            `/api/production-examples?epreuve=${epreuve}&tacheNumero=${tacheNumero}`,
            {auth: true},
        );
    },

    /** Soumet un texte EE. Renvoie la submission en statut SUBMITTED. */
    submitText(body: SubmitProductionTextRequest): Promise<ProductionSubmissionDto> {
        return apiFetch<ProductionSubmissionDto>("/api/production-submissions", {
            method: "POST",
            json: body,
            auth: true,
        }).then(afterProductionWrite);
    },

    /** Soumet un audio EO (multipart). productionTaskId / attemptId en query
     *  (côté backend `@RequestParam`), l'audio en part `audio`. Content-Type
     *  multipart posé automatiquement par le navigateur. */
    submitAudio(
        productionTaskId: string,
        attemptId: string,
        audio: Blob,
        filename?: string,
        clientSubmissionId?: string,
    ): Promise<ProductionSubmissionDto> {
        const fd = new FormData();
        fd.append("audio", audio, filename ?? audioFilename(audio.type));
        const qs = new URLSearchParams({productionTaskId, attemptId});
        // Idempotence : renvoyer la même clé rend la même soumission, sans
        // repayer Whisper puis le correcteur.
        if (clientSubmissionId) qs.set("clientSubmissionId", clientSubmissionId);
        return apiFetch<ProductionSubmissionDto>(
            `/api/production-submissions?${qs.toString()}`,
            {method: "POST", body: fd, auth: true},
        ).then(afterProductionWrite);
    },

    /** Récupère une submission (polling de l'évaluation IA). */
    getSubmission(id: string): Promise<ProductionSubmissionDto> {
        return apiFetch<ProductionSubmissionDto>(`/api/production-submissions/${id}`, {
            auth: true,
        }).then(afterProductionRead);
    },

    /** Relance l'évaluation d'une submission FAILED (3 essais max). */
    retrySubmission(id: string): Promise<ProductionSubmissionDto> {
        return apiFetch<ProductionSubmissionDto>(
            `/api/production-submissions/${id}/retry`,
            {method: "POST", auth: true},
        ).then(afterProductionWrite);
    },

    /** Historique des soumissions de l'utilisateur (optionnellement par épreuve). */
    listMine(opts: { epreuve?: EpreuveType; limit?: number } = {}): Promise<ProductionSubmissionDto[]> {
        const qs = new URLSearchParams();
        if (opts.epreuve) qs.set("epreuve", opts.epreuve);
        if (opts.limit !== undefined) qs.set("limit", String(opts.limit));
        const suffix = qs.toString() ? `?${qs.toString()}` : "";
        return apiFetch<ProductionSubmissionDto[]>(
            `/api/users/me/production-submissions${suffix}`,
            {auth: true},
        );
    },

    /** Dernière submission par tâche pour un (épreuve, niveau) — badges du hub. */
    lastPerTask(epreuve: EpreuveType, niveau: string): Promise<ProductionSubmissionDto[]> {
        return apiFetch<ProductionSubmissionDto[]>(
            `/api/users/me/production-submissions/last-per-task?epreuve=${epreuve}&niveau=${niveau}`,
            {auth: true},
        );
    },

    /** Bilan d'épreuve (moyenne /20 + niveau global en examen blanc seulement). */
    getBilan(attemptId: string): Promise<ProductionBilanResponse> {
        return apiFetch<ProductionBilanResponse>(
            `/api/attempts/${attemptId}/production-bilan`,
            {auth: true},
        );
    },
};

// ============================================================================
// COMPÉTENCES TCF — micro-exercices ciblés (voie parallèle aux productions)
// Toutes les routes sont authentifiées : il n'existe aucun endpoint public.
// ============================================================================

export const skillApi = {
    /** Résumé par tâche (3 entrées) pour l'écran de choix de tâche. */
    progress(section: SkillSection): Promise<SkillTaskProgressDto[]> {
        return apiFetch<SkillTaskProgressDto[]>(
            `/api/skills/progress?section=${section}`,
            {auth: true},
        );
    },

    /** Les 8 compétences actives d'une tâche + progression du user courant.
     *  Ne plus appeler directement depuis un écran : passer par
     *  `loadSectionSkills` (`lib/skill-catalog.ts`), qui charge l'épreuve
     *  entière en une fois et se sert de ceci comme repli. */
    listSkills(taskCode: string): Promise<SkillDto[]> {
        return apiFetch<SkillDto[]>(`/api/skills?taskCode=${taskCode}`, {auth: true});
    },

    /** Les 24 compétences d'une épreuve entière (3 tâches × 8), triées
     *  `taskCode` puis `displayOrder`. C'est l'appel unique qui rend les
     *  pastilles T1/T2/T3 instantanées : elles filtrent, elles ne rechargent pas. */
    listSkillsBySection(section: SkillSection): Promise<SkillDto[]> {
        return apiFetch<SkillDto[]>(`/api/skills?section=${section}`, {auth: true});
    },

    /** Compétence + ses 15 petits sujets avec leur statut. */
    getSkill(skillId: string): Promise<SkillDetailDto> {
        return apiFetch<SkillDetailDto>(`/api/skills/${skillId}`, {auth: true});
    },

    /** Sujet complet (sans les références — elles ont leur propre appel). */
    getPrompt(promptId: string): Promise<SkillPromptDto> {
        return apiFetch<SkillPromptDto>(`/api/skill-prompts/${promptId}`, {auth: true});
    },

    /** Les 3 références. 403 tant que le user n'a aucune tentative sur ce sujet
     *  — c'est le garde serveur de la règle « pas de modèle avant de produire ». */
    listReferences(promptId: string): Promise<SkillReferenceDto[]> {
        return apiFetch<SkillReferenceDto[]>(
            `/api/skill-prompts/${promptId}/references`,
            {auth: true},
        );
    },

    /** Soumet une production écrite (section EE). */
    submitText(body: SubmitSkillTextRequest): Promise<SkillAttemptDto> {
        return apiFetch<SkillAttemptDto>("/api/skill-attempts", {
            method: "POST",
            json: body,
            auth: true,
        }).then(afterSkillAttempt);
    },

    /** Soumet une production orale (section EO, multipart). Les identifiants
     *  passent en query (`@RequestParam` côté backend) : poser `json` écraserait
     *  le boundary du FormData. */
    submitAudio(opts: {
        skillPromptId: string;
        audio: Blob;
        durationSec: number;
        selfEvaluation?: SkillSelfEvaluation | null;
        requestAnalysis: boolean;
        filename?: string;
        clientSubmissionId?: string;
    }): Promise<SkillAttemptDto> {
        const fd = new FormData();
        fd.append("audio", opts.audio, opts.filename ?? audioFilename(opts.audio.type));
        const qs = new URLSearchParams({
            skillPromptId: opts.skillPromptId,
            durationSec: String(opts.durationSec),
            requestAnalysis: String(opts.requestAnalysis),
        });
        if (opts.selfEvaluation) qs.set("selfEvaluation", opts.selfEvaluation);
        if (opts.clientSubmissionId) qs.set("clientSubmissionId", opts.clientSubmissionId);
        return apiFetch<SkillAttemptDto>(`/api/skill-attempts?${qs.toString()}`, {
            method: "POST",
            body: fd,
            auth: true,
        }).then(afterSkillAttempt);
    },

    /** Polling du résultat. 404 (pas 403) si la tentative n'est pas au user. */
    getAttempt(id: string): Promise<SkillAttemptDto> {
        return apiFetch<SkillAttemptDto>(`/api/skill-attempts/${id}`, {auth: true}).then(
            afterSkillAttempt,
        );
    },

    /** Historique des tentatives sur un sujet, plus récente d'abord. */
    listAttempts(promptId: string, limit = 5): Promise<SkillAttemptDto[]> {
        return apiFetch<SkillAttemptDto[]>(
            `/api/skill-prompts/${promptId}/attempts?limit=${limit}`,
            {auth: true},
        );
    },

    /** Analyses IA restantes. `remaining === -1` = illimité (jamais affiché tel quel). */
    analysisQuota(): Promise<SkillAnalysisQuotaDto> {
        return apiFetch<SkillAnalysisQuotaDto>("/api/skills/analysis-quota", {auth: true});
    },

    /** Demande l'analyse IA d'une tentative déjà `RECORDED` (produite sans IA).
     *  Sert au candidat qui produit d'abord et s'abonne ensuite : la production
     *  est déjà en base, seule l'analyse manque. Consomme un quota. */
    requestAnalysis(id: string): Promise<SkillAttemptDto> {
        return apiFetch<SkillAttemptDto>(`/api/skill-attempts/${id}/analyse`, {
            method: "POST",
            auth: true,
        }).then(afterSkillAttempt);
    },

    /** Relance l'analyse d'une tentative FAILED. Ne re-consomme pas le quota. */
    retryAnalysis(id: string): Promise<SkillAttemptDto> {
        return apiFetch<SkillAttemptDto>(`/api/skill-attempts/${id}/retry`, {
            method: "POST",
            auth: true,
        }).then(afterSkillAttempt);
    },
};

// ============================================================================
// Expression orale TEMPS RÉEL (examinateur IA, T1/T2 — schéma A : token éphémère)
// ============================================================================
// Le backend émet un token éphémère (persona verrouillée serveur), le client
// ouvre lui-même le WebSocket vers Gemini (cf. lib/realtime/geminiLive.ts) et
// relaie les fragments de transcript ici. La notation réutilise le pipeline EO
// existant (submission créée à la clôture). Quota épuisé / non éligible →
// `mode: "ASYNC_FALLBACK"` : on bascule en enregistrement classique.

export const realtimeApi = {
    /** Sessions temps réel restantes (compteur du modal de lancement). */
    getQuota(): Promise<import("./types").RealtimeQuotaResponse> {
        return apiFetch<import("./types").RealtimeQuotaResponse>(
            "/api/realtime/eo/quota",
            {auth: true},
        );
    },

    /** Démarre une session : descripteur REALTIME (token + WS) ou ASYNC_FALLBACK. */
    startSession(
        body: import("./types").StartRealtimeSessionRequest,
    ): Promise<import("./types").RealtimeSessionDescriptor> {
        return apiFetch<import("./types").RealtimeSessionDescriptor>(
            "/api/realtime/eo/sessions",
            {method: "POST", json: body, auth: true},
        );
    },

    /** Reprend une session dont le WebSocket est tombé : NOUVEAU token, MÊME
     *  conversation, MÊME transcript, et surtout AUCUN slot de simulation
     *  re-débité. Ne JAMAIS rappeler `startSession` après une coupure : cela
     *  créerait une seconde session et débiterait un second slot au candidat.
     *  Peut répondre `ASYNC_FALLBACK` ; 422 si la session est terminée, si le
     *  plafond de reprises est atteint ou si la reprise est désactivée. */
    resumeSession(
        sessionId: string,
        resumptionHandle: string | null,
    ): Promise<import("./types").RealtimeSessionDescriptor> {
        return apiFetch<import("./types").RealtimeSessionDescriptor>(
            `/api/realtime/eo/sessions/${sessionId}/resume`,
            {method: "POST", json: {resumptionHandle}, auth: true},
        );
    },

    /** Relaie un fragment de transcript (candidat ou examinateur). 204.
     *
     *  `turnIndex` rend l'appel IDEMPOTENT : le serveur ignore un index déjà
     *  appliqué, donc un réessai après coupure réseau ne duplique plus un tour.
     *  Il doit être strictement croissant sur la session et CONSERVÉ d'un essai
     *  à l'autre. `resumptionHandle` voyage ici plutôt que dans un appel dédié :
     *  le client POSTe déjà toutes les 1,2 s, le serveur reste à jour sans un
     *  aller-retour de plus. */
    appendTranscript(
        sessionId: string,
        speaker: import("./types").RealtimeSpeaker,
        text: string,
        turnIndex?: number,
        resumptionHandle?: string | null,
    ): Promise<void> {
        return apiFetch<void>(
            `/api/realtime/eo/sessions/${sessionId}/transcript`,
            {
                method: "POST",
                json: {
                    speaker,
                    text,
                    ...(turnIndex === undefined ? {} : {turnIndex}),
                    ...(resumptionHandle ? {resumptionHandle} : {}),
                },
                auth: true,
            },
        );
    },

    /** Clôture la session : crée la submission + lance la notation côté backend. */
    finishSession(
        sessionId: string,
    ): Promise<import("./types").RealtimeSessionStateResponse> {
        return apiFetch<import("./types").RealtimeSessionStateResponse>(
            `/api/realtime/eo/sessions/${sessionId}/finish`,
            {method: "POST", auth: true},
        );
    },
};

// ============================================================================
// Endpoints Examen blanc TCF complet (TCF_COMPLET — CO → CE → EE → EO)
// ============================================================================
// Le backend crée le parent + 4 sous-attempts en une transaction (start) et
// agrège le statut (IN_PROGRESS / PENDING_EVALUATIONS / COMPLETED). Les
// productions EE/EO sont soumises via productionApi puis évaluées en arrière-
// plan ; `markSubDone` débloque la suite sans attendre l'IA. Premium TCF requis.

export const fullTcfExamApi = {
    /** Démarre un examen complet (crée parent TCF_COMPLET + 4 sous-attempts). */
    start(slotNumber?: number): Promise<FullTcfExamResponse> {
        const qs = slotNumber != null ? `?slotNumber=${slotNumber}` : "";
        return apiFetch<FullTcfExamResponse>(`/api/full-tcf-exams${qs}`, {
            method: "POST",
            auth: true,
        });
    },

    /** État courant (polling du bilan / refresh du hub de progression). */
    get(id: string): Promise<FullTcfExamResponse> {
        return apiFetch<FullTcfExamResponse>(`/api/full-tcf-exams/${id}`, {auth: true});
    },

    /** Historique des examens complets de l'utilisateur (grille de slots). */
    listMine(limit = 20): Promise<FullTcfExamSummaryResponse[]> {
        return apiFetch<FullTcfExamSummaryResponse[]>(
            `/api/me/full-tcf-exams?limit=${limit}`,
            {auth: true},
        );
    },

    /** Démarre le chrono PROPRE d'une épreuve au moment où le candidat la
     *  lance, AVANT d'ouvrir l'écran de l'épreuve. **Obligatoire sur les 4** :
     *  tant qu'il n'est pas appelé, l'épreuve n'a aucune échéance et son
     *  `deadlineAt` reste null. Il n'y a plus de chrono global — le temps d'une
     *  épreuve ne se reporte jamais sur la suivante. Idempotent : une reprise
     *  ne remet rien à zéro et rend le temps réellement restant. */
    begin(id: string, epreuve: string): Promise<FullTcfExamResponse> {
        return apiFetch<FullTcfExamResponse>(
            `/api/full-tcf-exams/${id}/begin?epreuve=${encodeURIComponent(epreuve)}`,
            {
                method: "POST",
                auth: true,
            },
        );
    },

    /** Finalise l'examen (idempotent ; exige les 4 sous-attempts terminés). */
    finish(id: string): Promise<FullTcfExamResponse> {
        return apiFetch<FullTcfExamResponse>(`/api/full-tcf-exams/${id}/finish`, {
            method: "POST",
            auth: true,
        });
    },

    /** Marque une sous-épreuve de production (EE/EO) terminée après la T3,
     *  sans attendre l'évaluation IA — débloque l'épreuve suivante au hub. */
    markSubDone(id: string, epreuve: EpreuveType): Promise<FullTcfExamResponse> {
        return apiFetch<FullTcfExamResponse>(
            `/api/full-tcf-exams/${id}/sub-done?epreuve=${epreuve}`,
            {method: "POST", auth: true},
        );
    },
};

// ============================================================================
// Endpoints PUBLICS (démo guest, sans auth)
// ============================================================================
// La démo est illimitée et déterministe : chaque lancement renvoie la même
// série de questions pour un module donné. Le client_ip est toujours posée
// côté serveur (pour audit) mais aucun quota n'est appliqué.

export const publicThemeApi = {
    list(module: ModuleEnum): Promise<ThemeUserResponse[]> {
        return apiFetch<ThemeUserResponse[]>(
            `/api/public/themes?module=${module}`,
            {auth: false},
        );
    },
};

export const publicExamApi = {
    list(module?: ModuleEnum): Promise<ExamTemplateSummary[]> {
        const qs = module ? `?module=${module}` : "";
        return apiFetch<ExamTemplateSummary[]>(`/api/public/exams${qs}`, {
            auth: false,
        });
    },

    getBySlug(slug: string): Promise<ExamTemplateSummary> {
        return apiFetch<ExamTemplateSummary>(`/api/public/exams/${slug}`, {
            auth: false,
        });
    },
};

export const publicAttemptApi = {
    startDemo(body: StartAttemptRequest): Promise<AttemptResponse> {
        return apiFetch<AttemptResponse>("/api/public/attempts/demo", {
            method: "POST",
            json: body,
            auth: false,
        });
    },

    getById(id: string): Promise<AttemptResponse> {
        return apiFetch<AttemptResponse>(`/api/public/attempts/${id}`, {
            auth: false,
        });
    },

    submitAnswer(
        attemptId: string,
        body: SubmitAnswerRequest,
    ): Promise<AnswerResultResponse> {
        return apiFetch<AnswerResultResponse>(
            `/api/public/attempts/${attemptId}/answers`,
            {method: "POST", json: body, auth: false},
        );
    },

    finish(attemptId: string): Promise<AttemptResponse> {
        return apiFetch<AttemptResponse>(
            `/api/public/attempts/${attemptId}/finish`,
            {method: "POST", auth: false},
        );
    },
};
