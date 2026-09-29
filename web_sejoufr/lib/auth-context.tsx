"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { authApi, tokenStorage } from "./api";
import type { AuthenticatedUser, LoginRequest, RegisterRequest } from "./types";

type Status = "loading" | "authenticated" | "guest";

interface AuthContextValue {
  status: Status;
  user: AuthenticatedUser | null;
  login: (req: LoginRequest) => Promise<void>;
  register: (req: RegisterRequest) => Promise<void>;
  loginWithGoogle: (idToken: string) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

/**
 * Provider racine qui hydrate l'état utilisateur au mount via /api/auth/me,
 * et synchronise tous les composants qui consomment `useAuth()`.
 *
 * Trois statuts possibles :
 *   - "loading"        : on attend la réponse initiale (utile pour éviter
 *                        un flash "déconnecté" sur les pages protégées).
 *   - "authenticated"  : user défini.
 *   - "guest"          : pas de token ou /me a échoué.
 */
export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<Status>("loading");
  const [user, setUser] = useState<AuthenticatedUser | null>(null);

  const refreshUser = useCallback(async () => {
    if (typeof window === "undefined") {
      setStatus("guest");
      return;
    }
    const token = tokenStorage.getAccess();
    if (!token) {
      setUser(null);
      setStatus("guest");
      return;
    }
    try {
      const me = await authApi.me();
      setUser(me);
      setStatus("authenticated");
    } catch {
      // Token périmé / invalide : on tombe en guest, le middleware ou
      // les pages protégées feront leur travail.
      tokenStorage.clear();
      setUser(null);
      setStatus("guest");
    }
  }, []);

  useEffect(() => {
    void refreshUser();
  }, [refreshUser]);

  const login = useCallback(
    async (req: LoginRequest) => {
      await authApi.login(req);
      await refreshUser();
    },
    [refreshUser],
  );

  const register = useCallback(
    async (req: RegisterRequest) => {
      await authApi.register(req);
      await refreshUser();
    },
    [refreshUser],
  );

  const loginWithGoogle = useCallback(
    async (idToken: string) => {
      await authApi.google({ idToken });
      await refreshUser();
    },
    [refreshUser],
  );

  const logout = useCallback(() => {
    authApi.logout();
    setUser(null);
    setStatus("guest");
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({ status, user, login, register, loginWithGoogle, logout, refreshUser }),
    [status, user, login, register, loginWithGoogle, logout, refreshUser],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used inside <AuthProvider>");
  }
  return ctx;
}
