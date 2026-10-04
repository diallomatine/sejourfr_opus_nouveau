import { apiRequest } from "./http";

/** Compte de l'administrateur connecté : les mêmes routes `/api/me/*` que le web et le mobile. */
export const accountApi = {
  updateProfile(firstName: string, lastName: string) {
    return apiRequest<void>("/api/me/profile", {
      method: "PATCH",
      body: { firstName, lastName },
    });
  },

  changePassword(currentPassword: string, newPassword: string) {
    return apiRequest<void>("/api/me/change-password", {
      method: "POST",
      body: { currentPassword, newPassword },
    });
  },

  /** L'adresse ne change qu'au clic sur le lien envoyé à la nouvelle adresse. */
  requestEmailChange(newEmail: string, currentPassword: string) {
    return apiRequest<void>("/api/me/change-email-request", {
      method: "POST",
      body: { newEmail, currentPassword },
    });
  },
};
