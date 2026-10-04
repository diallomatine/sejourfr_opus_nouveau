import { HttpError, httpErrorMessage } from "../../api/http";
import type { AdminUserAuthProvider } from "../../types/api";

/** Bornes miroirs des DTO serveur (`UpdateProfileRequest`, `ChangePasswordRequest`, `ChangeEmailRequest`). */
export const NAME_MAX = 120;
export const PASSWORD_MIN = 8;
export const PASSWORD_MAX = 128;
export const EMAIL_MAX = 255;

/** Même forme minimale que le web (`web_sejoufr/lib/compte.ts`) ; le serveur reste juge (`@Email`). */
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export type IdentityErrors = { firstName?: string; lastName?: string };
export type EmailErrors = { newEmail?: string; password?: string };
export type PasswordErrors = { current?: string; next?: string; confirm?: string };

const CURRENT_PASSWORD_REQUIRED = "Indiquez votre mot de passe actuel.";

function nameError(value: string, required: string): string | undefined {
  const v = value.trim();
  if (!v) return required;
  if (v.length > NAME_MAX) return `${NAME_MAX} caractères maximum.`;
  return undefined;
}

export function validateIdentity(firstName: string, lastName: string): IdentityErrors {
  const errors: IdentityErrors = {};
  const fn = nameError(firstName, "Indiquez votre prénom.");
  const ln = nameError(lastName, "Indiquez votre nom.");
  if (fn) errors.firstName = fn;
  if (ln) errors.lastName = ln;
  return errors;
}

export function validateEmailChange(newEmail: string, password: string, currentEmail: string): EmailErrors {
  const errors: EmailErrors = {};
  const email = newEmail.trim();
  if (!email) errors.newEmail = "Indiquez la nouvelle adresse e-mail.";
  else if (email.length > EMAIL_MAX) errors.newEmail = `${EMAIL_MAX} caractères maximum.`;
  else if (!EMAIL_PATTERN.test(email)) errors.newEmail = "Cette adresse e-mail n'est pas valide.";
  else if (email.toLowerCase() === currentEmail.trim().toLowerCase())
    errors.newEmail = "C'est déjà votre adresse actuelle.";
  if (!password) errors.password = CURRENT_PASSWORD_REQUIRED;
  return errors;
}

export function validatePasswordChange(current: string, next: string, confirm: string): PasswordErrors {
  const errors: PasswordErrors = {};
  if (!current) errors.current = CURRENT_PASSWORD_REQUIRED;
  if (next.length < PASSWORD_MIN) errors.next = `Au moins ${PASSWORD_MIN} caractères.`;
  else if (next.length > PASSWORD_MAX) errors.next = `${PASSWORD_MAX} caractères maximum.`;
  else if (current && next === current) errors.next = "Le nouveau mot de passe doit être différent de l'actuel.";
  if (!errors.next && next !== confirm) errors.confirm = "Les deux mots de passe ne correspondent pas.";
  return errors;
}

export function hasErrors(errors: Record<string, string | undefined>): boolean {
  return Object.values(errors).some(Boolean);
}

export interface ServerErrors<K extends string> {
  fields: Partial<Record<K, string>>;
  /** Message sans champ rattaché (ex. « Mot de passe actuel incorrect. »), affiché en alerte. */
  alert: string | null;
}

/**
 * Répartit une erreur serveur : chaque `fieldErrors[].field` connu va sous son champ
 * (`fieldMap` : nom du champ du DTO → clé du formulaire), le reste en alerte.
 */
export function serverErrors<K extends string>(error: unknown, fieldMap: Record<string, K>): ServerErrors<K> {
  const fields: Partial<Record<K, string>> = {};
  const unmapped: string[] = [];
  const fieldErrors = error instanceof HttpError ? (error.payload?.fieldErrors ?? []) : [];
  for (const fe of fieldErrors) {
    const key = fieldMap[fe.field];
    if (key && !fields[key]) fields[key] = fe.message;
    else if (!key) unmapped.push(fe.message);
  }
  if (fieldErrors.length > 0) {
    return { fields, alert: unmapped.length > 0 ? unmapped.join(" ") : null };
  }
  return { fields, alert: httpErrorMessage(error) };
}

export function providerLabel(provider: AdminUserAuthProvider): string {
  if (provider === "GOOGLE") return "Google";
  if (provider === "APPLE") return "Apple";
  return "E-mail et mot de passe";
}
