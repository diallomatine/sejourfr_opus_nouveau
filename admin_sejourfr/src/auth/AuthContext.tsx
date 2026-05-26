import type {ReactNode} from "react";
import {createContext, useCallback, useContext, useEffect, useMemo, useState} from "react";
import {authApi} from "../api/authApi";
import type {AuthenticatedUser} from "../types/api";
import {tokenStorage} from "./tokenStorage";

interface AuthContextValue {
    user: AuthenticatedUser | null;
    isAuthenticated: boolean;
    login: (email: string, password: string) => Promise<AuthenticatedUser>;
    logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({children}: { children: ReactNode }) {
    const [user, setUser] = useState<AuthenticatedUser | null>(() =>
        tokenStorage.getUser(),
    );

    // Synchroniser entre onglets : si l'utilisateur se deconnecte ailleurs, on suit.
    useEffect(() => {
        const onStorage = (e: StorageEvent) => {
            if (e.key === "sejourfr.user" || e.key === "sejourfr.accessToken") {
                setUser(tokenStorage.getUser());
            }
        };
        window.addEventListener("storage", onStorage);
        return () => window.removeEventListener("storage", onStorage);
    }, []);

    const login = useCallback(async (email: string, password: string) => {
        const tokens = await authApi.login(email, password);
        if (tokens.user.role !== "ADMIN") {
            tokenStorage.clear();
            throw new Error("Accès reservé aux administrateurs.");
            s
        }
        tokenStorage.set(tokens.accessToken, tokens.refreshToken, tokens.user);
        setUser(tokens.user);
        return tokens.user;
    }, []);

    const logout = useCallback(() => {
        tokenStorage.clear();
        setUser(null);
    }, []);

    const value = useMemo<AuthContextValue>(
        () => ({
            user,
            isAuthenticated: !!user,
            login,
            logout,
        }),
        [user, login, logout],
    );

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
    const ctx = useContext(AuthContext);
    if (!ctx) {
        throw new Error("useAuth doit être utilisé dans un AuthProvider");
    }
    return ctx;
}
