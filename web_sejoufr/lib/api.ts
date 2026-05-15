// Client HTTP minimal vers le backend Spring Boot.
// Compatible Server Components et Client Components (Next 16 / App Router).

import type {
  AnswerResultResponse,
  ApiError,
  AttemptResponse,
  AuthenticatedUser,
  ExamTemplateSummary,
  LoginRequest,
  RegisterRequest,
  StartAttemptRequest,
  SubmitAnswerRequest,
  ThemeUserResponse,
  TokenResponse,
  Module as ModuleEnum,
} from "./types";

// Base URL configurable via .env.local : NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8080";

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
        json: { refreshToken: rt },
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
  const { auth, json, headers, skipRefresh: _skip, ...rest } = opts;

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

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...rest,
    headers: finalHeaders,
    body: json !== undefined ? JSON.stringify(json) : rest.body,
    cache: "no-store",
  });

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

async function apiFetch<T>(path: string, opts: FetchOptions = {}): Promise<T> {
  try {
    return await rawFetch<T>(path, opts);
  } catch (err) {
    // Tentative unique de refresh sur un 401, sauf pour /auth/refresh lui-même.
    if (
      err instanceof ApiException &&
      err.status === 401 &&
      !opts.skipRefresh &&
      typeof window !== "undefined" &&
      tokenStorage.getRefresh()
    ) {
      const newToken = await refreshAccessToken();
      if (newToken) {
        return rawFetch<T>(path, opts);
      }
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

  async me(): Promise<AuthenticatedUser> {
    return apiFetch<AuthenticatedUser>("/api/auth/me", { auth: true });
  },

  async refresh(): Promise<string | null> {
    return refreshAccessToken();
  },

  async forgotPassword(email: string): Promise<void> {
    await apiFetch<void>("/api/auth/forgot-password", {
      method: "POST",
      json: { email },
    });
  },

  async resetPassword(token: string, newPassword: string): Promise<void> {
    await apiFetch<void>("/api/auth/reset-password", {
      method: "POST",
      json: { token, newPassword },
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
// Endpoints Billing (Stripe Checkout)
// ============================================================================

export type BillingPlan = "MENSUEL" | "ANNUEL";

export const billingApi = {
  /**
   * Crée une Stripe Checkout Session côté backend et renvoie l'URL vers
   * laquelle rediriger l'utilisateur (page Stripe hosted).
   */
  createCheckoutSession(plan: BillingPlan): Promise<{ url: string }> {
    return apiFetch<{ url: string }>("/api/billing/create-checkout-session", {
      method: "POST",
      json: { plan },
      auth: true,
    });
  },

  /**
   * Ouvre une session Stripe Customer Portal (gestion carte, factures,
   * annulation). 404 si l'user n'a pas encore d'abonnement Stripe.
   */
  createPortalSession(): Promise<{ url: string }> {
    return apiFetch<{ url: string }>("/api/billing/portal-session", {
      method: "POST",
      auth: true,
    });
  },
};

// ============================================================================
// Endpoints Examens blancs (vitrine publique)
// ============================================================================

export const examApi = {
  list(module?: ModuleEnum): Promise<ExamTemplateSummary[]> {
    const qs = module ? `?module=${module}` : "";
    return apiFetch<ExamTemplateSummary[]>(`/api/exams${qs}`, { auth: false });
  },

  getBySlug(slug: string): Promise<ExamTemplateSummary> {
    return apiFetch<ExamTemplateSummary>(`/api/exams/${slug}`, { auth: false });
  },
};

// ============================================================================
// Endpoints Attempts
// ============================================================================

export const attemptApi = {
  start(body: StartAttemptRequest, opts: { auth?: boolean } = {}): Promise<AttemptResponse> {
    // L'examen blanc démo permet de lancer un attempt sans être connecté
    // (le backend a un endpoint public /api/attempts/demo pour ça si besoin).
    // Sinon, l'endpoint /api/attempts exige un Bearer.
    return apiFetch<AttemptResponse>("/api/attempts", {
      method: "POST",
      json: body,
      auth: opts.auth ?? true,
    });
  },

  get(id: string): Promise<AttemptResponse> {
    return apiFetch<AttemptResponse>(`/api/attempts/${id}`, { auth: true });
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
};
