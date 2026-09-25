import { ApiException } from "./api";
import {
  COMPTE_EMAIL_INVALID,
  COMPTE_FIRST_NAME_REQUIRED,
  COMPTE_LAST_NAME_REQUIRED,
  COMPTE_PASSWORD_MIN,
  EMAIL_PATTERN,
} from "./compte";

/**
 * Validation locale des formulaires de connexion et d'inscription. Elle ne
 * double que les contraintes de `LoginRequest` / `RegisterRequest` côté
 * serveur (`@NotBlank`, `@Email`, `@Size(min = 8)` sur le mot de passe) : rien
 * de plus strict, le serveur reste l'autorité et ses `fieldErrors` sont
 * affichés sous le champ concerné.
 */

export const AUTH_PASSWORD_MIN = COMPTE_PASSWORD_MIN;
export const AUTH_PASSWORD_RULE = `${AUTH_PASSWORD_MIN} caractères minimum`;

const EMAIL_REQUIRED = "Indiquez votre adresse e-mail.";
const PASSWORD_REQUIRED = "Indiquez votre mot de passe.";
const PASSWORD_TOO_SHORT = `Le mot de passe doit contenir au moins ${AUTH_PASSWORD_MIN} caractères.`;
const CONSENT_REQUIRED =
  "Acceptez les Conditions générales et la Politique de confidentialité pour créer votre compte.";

export type AuthFieldName = "firstName" | "lastName" | "email" | "password" | "consent";
export type AuthFieldErrors = Partial<Record<AuthFieldName, string>>;

function emailError(email: string): string | undefined {
  const v = email.trim();
  if (!v) return EMAIL_REQUIRED;
  if (!EMAIL_PATTERN.test(v)) return COMPTE_EMAIL_INVALID;
  return undefined;
}

function compact(errors: AuthFieldErrors): AuthFieldErrors {
  return Object.fromEntries(Object.entries(errors).filter(([, v]) => Boolean(v))) as AuthFieldErrors;
}

export function validateLogin(input: { email: string; password: string }): AuthFieldErrors {
  return compact({
    email: emailError(input.email),
    password: input.password ? undefined : PASSWORD_REQUIRED,
  });
}

export function validateRegister(input: {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  consent: boolean;
}): AuthFieldErrors {
  return compact({
    firstName: input.firstName.trim() ? undefined : COMPTE_FIRST_NAME_REQUIRED,
    lastName: input.lastName.trim() ? undefined : COMPTE_LAST_NAME_REQUIRED,
    email: emailError(input.email),
    password: !input.password
      ? PASSWORD_REQUIRED
      : input.password.length < AUTH_PASSWORD_MIN
        ? PASSWORD_TOO_SHORT
        : undefined,
    consent: input.consent ? undefined : CONSENT_REQUIRED,
  });
}

const KNOWN_FIELDS: readonly AuthFieldName[] = ["firstName", "lastName", "email", "password"];

/**
 * Répartit une erreur serveur : les `fieldErrors` d'un champ du formulaire vont
 * sous ce champ, tout le reste (champ inconnu, message global) dans le bandeau.
 */
export function splitServerErrors(err: ApiException): {
  fields: AuthFieldErrors;
  global: string | null;
} {
  const raw = err.payload?.fieldErrors;
  if (!raw) return { fields: {}, global: err.message };
  const fields: AuthFieldErrors = {};
  const others: string[] = [];
  for (const [key, message] of Object.entries(raw)) {
    if ((KNOWN_FIELDS as readonly string[]).includes(key)) fields[key as AuthFieldName] = message;
    else others.push(message);
  }
  return { fields, global: others.length > 0 ? others.join(" · ") : null };
}
