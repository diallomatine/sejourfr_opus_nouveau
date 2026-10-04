"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { authApi, isDefinitiveAuthFailure, tokenStorage } from "./api";
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
 *   - "guest"          : pas de session, ou serveur injoignable.
 *
 * 🛑 **La session tient tant que le refresh token est valable** (30 j). Un
 * access expiré au retour sur le site n'est pas une déconnexion : `/me` prend
 * un 401, `apiFetch` rafraîchit et rejoue. Les jetons ne sont vidés que sur un
 * refus DÉFINITIF (`isDefinitiveAuthFailure`) — jamais sur une coupure réseau
 * ou un 5xx, après lesquels on retente au retour de l'onglet ou du réseau.
 */
export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<Status>("loading");
  const [user, setUser] = useState<AuthenticatedUser | null>(null);

  const refreshUser = useCallback(async () => {
    if (typeof window === "undefined") {
      setStatus("guest");
      return;
    }
    if (!tokenStorage.getAccess() && !tokenStorage.getRefresh()) {
      setUser(null);
      setStatus("guest");
      return;
    }
    try {
      // Access absent mais refresh présent : on rafraîchit d'abord, plutôt
      // que de déclarer le visiteur déconnecté.
      if (!tokenStorage.getAccess() && !(await authApi.refresh())) {
        setUser(null);
        setStatus("guest");
        return;
      }
      const me = await authApi.me();
      tokenStorage.markSession();
      setUser(me);
      setStatus("authenticated");
    } catch (err) {
      if (isDefinitiveAuthFailure(err)) tokenStorage.clear();
      setUser(null);
      setStatus("guest");
    }
  }, []);

  useEffect(() => {
    void refreshUser();
  }, [refreshUser]);

  // Une hydratation tombée sur une panne (réseau, 5xx) a laissé les jetons en
  // place : on retente quand l'onglet revient au premier plan ou que le
  // réseau revient.
  useEffect(() => {
    if (status !== "guest") return;
    const retry = () => {
      if (document.visibilityState !== "visible") return;
      if (tokenStorage.getRefresh()) void refreshUser();
    };
    document.addEventListener("visibilitychange", retry);
    window.addEventListener("online", retry);
    return () => {
      document.removeEventListener("visibilitychange", retry);
      window.removeEventListener("online", retry);
    };
  }, [status, refreshUser]);

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
