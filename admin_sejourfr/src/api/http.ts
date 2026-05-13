import type { ApiError, TokenResponse } from "../types/api";
import { tokenStorage } from "../auth/tokenStorage";

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8080";

export class HttpError extends Error {
  status: number;
  payload: ApiError | null;

  constructor(status: number, message: string, payload: ApiError | null) {
    super(message);
    this.status = status;
    this.payload = payload;
  }
}

interface RequestOptions {
  method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined | null>;
  /** Pour les uploads multipart. */
  formData?: FormData;
  /** Si true, n'essaie pas de refresher (utilise par /auth/refresh lui-meme). */
  skipRefresh?: boolean;
  signal?: AbortSignal;
}

// File d'attente pour eviter plusieurs refresh paralleles
let refreshPromise: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    const refreshToken = tokenStorage.getRefresh();
    if (!refreshToken) return null;

    try {
      const res = await fetch(`${API_BASE}/api/auth/refresh`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken }),
      });
      if (!res.ok) {
        tokenStorage.clear();
        return null;
      }
      const data = (await res.json()) as TokenResponse;
      tokenStorage.set(data.accessToken, data.refreshToken, data.user);
      return data.accessToken;
    } catch {
      tokenStorage.clear();
      return null;
    } finally {
      // Petit delai pour qu'une eventuelle requete parallele recupere bien le token
      setTimeout(() => {
        refreshPromise = null;
      }, 0);
    }
  })();

  return refreshPromise;
}

function buildQuery(query: RequestOptions["query"]): string {
  if (!query) return "";
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null || value === "") continue;
    params.append(key, String(value));
  }
  const str = params.toString();
  return str ? `?${str}` : "";
}

async function rawRequest<T>(
  path: string,
  options: RequestOptions = {},
  accessToken: string | null,
): Promise<T> {
  const headers: Record<string, string> = {};
  if (accessToken) headers["Authorization"] = `Bearer ${accessToken}`;

  let body: BodyInit | undefined;
  if (options.formData) {
    body = options.formData;
  } else if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
    body = JSON.stringify(options.body);
  }

  const url = `${API_BASE}${path}${buildQuery(options.query)}`;

  const res = await fetch(url, {
    method: options.method ?? "GET",
    headers,
    body,
    signal: options.signal,
  });

  if (res.status === 204) {
    return undefined as T;
  }

  const contentType = res.headers.get("content-type") ?? "";
  const isJson = contentType.includes("application/json");
  const payload = isJson ? await res.json().catch(() => null) : null;

  if (!res.ok) {
    const apiError = (payload as ApiError | null) ?? null;
    const msg = apiError?.message ?? `Erreur HTTP ${res.status}`;
    throw new HttpError(res.status, msg, apiError);
  }

  return payload as T;
}

export async function apiRequest<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  let token = tokenStorage.getAccess();

  try {
    return await rawRequest<T>(path, options, token);
  } catch (err) {
    if (
      err instanceof HttpError &&
      err.status === 401 &&
      !options.skipRefresh &&
      tokenStorage.getRefresh()
    ) {
      const newToken = await refreshAccessToken();
      if (newToken) {
        token = newToken;
        return rawRequest<T>(path, options, token);
      }
      // Refresh KO : on laisse l'erreur 401 remonter, le ProtectedRoute redirigera
    }
    throw err;
  }
}

export function apiBaseUrl(): string {
  return API_BASE;
}
