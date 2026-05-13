import { apiRequest } from "./http";
import type { AuthenticatedUser, TokenResponse } from "../types/api";

export const authApi = {
  login(email: string, password: string) {
    return apiRequest<TokenResponse>("/api/auth/login", {
      method: "POST",
      body: { email, password },
      skipRefresh: true,
    });
  },

  me() {
    return apiRequest<AuthenticatedUser>("/api/auth/me");
  },
};
