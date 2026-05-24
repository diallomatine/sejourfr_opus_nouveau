// Client HTTP minimal vers le backend Spring Boot.
// Compatible Server Components et Client Components (Next 16 / App Router).

import type {
  AnswerResultResponse,
  ApiError,
  AttemptResponse,
  AttemptSummaryResponse,
  AttemptType,
  AuthenticatedUser,
  ExamTemplateSummary,
  GoogleSignInRequest,
  LoginRequest,
  Module as ModuleEnum,
  PlanPublicResponse,
  QuestionReviewResponse,
  RegisterRequest,
  StartAttemptRequest,
  SubmitAnswerRequest,
  TargetProcedure,
  ThemeUserResponse,
  TokenResponse,
  UserStatsResponse,
} from "./types";

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
        document.cookie = `${ACCESS_TOKEN_KEY}=${tokens.accessToken}; path=/; max-age=${tokens.expiresInSeconds}; SameSite=Lax`;
    },
    clear() {
        if (typeof window === "undefined") return;
        localStorage.removeItem(ACCESS_TOKEN_KEY);
        localStorage.removeItem(REFRESH_TOKEN_KEY);
        document.cookie = `${ACCESS_TOKEN_KEY}=; path=/; max-age=0`;
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

async function rawFetch<T>(path: string, opts: FetchOptions = {}): Promise<T> {
    const {auth, json, headers, skipRefresh: _skip, cache, next, ...rest} = opts;

    const finalHeaders: Record<string, string> = {
        Accept: "application/json",
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
        tokenStorage.clear();
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
    fullName: string;
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

    wrong(module?: ModuleEnum): Promise<QuestionReviewResponse[]> {
        const qs = module ? `?module=${module}` : "";
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
        limit?: number;
    } = {}): Promise<AttemptSummaryResponse[]> {
        const qs = new URLSearchParams();
        if (opts.type) qs.set("type", opts.type);
        if (opts.module) qs.set("module", opts.module);
        if (opts.limit !== undefined) qs.set("limit", String(opts.limit));
        const suffix = qs.toString() ? `?${qs.toString()}` : "";
        return apiFetch<AttemptSummaryResponse[]>(`/api/me/attempts${suffix}`, {
            auth: true,
        });
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
