// Client HTTP minimal vers le backend Spring Boot.
// Compatible Server Components et Client Components (Next 16 / App Router).

import type {
  AnswerResultResponse,
  ApiError,
  AttemptResponse,
  AuthenticatedUser,
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

const ACCESS_TOKEN_KEY = "sejourfr.accessToken";
const REFRESH_TOKEN_KEY = "sejourfr.refreshToken";

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
}

async function apiFetch<T>(path: string, opts: FetchOptions = {}): Promise<T> {
  const { auth, json, headers, ...rest } = opts;

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

  // Si pas de contenu (204), retourner undefined
  if (res.status === 204) return undefined as T;

  return (await res.json()) as T;
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
