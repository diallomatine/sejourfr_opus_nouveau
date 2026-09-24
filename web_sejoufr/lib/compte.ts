/**
 * Les écrans du compte : « Mes informations » et ses trois pages d'édition
 * (nom et prénom, adresse e-mail, mot de passe).
 *
 * 🛑 **Miroir mot pour mot** de
 * `mobile_sejourfr/lib/screens/profile/account_labels.dart` : libellés,
 * messages de validation et règles de saisie. Un texte qui bouge ici bouge
 * là-bas dans la même passe.
 *
 * Les bornes recopient les contraintes du backend (`UpdateProfileRequest`,
 * `ChangePasswordRequest`) : un refus serveur ne doit jamais être la première
 * nouvelle d'une saisie invalide. Aucun endpoint n'est déclaré ici — les
 * écrans appellent `accountApi` (`lib/api.ts`).
 */

import type { AuthProvider } from "./types";

// ── Adresses ────────────────────────────────────────────────────────────
export const COMPTE_INFORMATIONS_HREF = "/profil/informations";
export const COMPTE_IDENTITE_HREF = "/profil/informations/identite";
export const COMPTE_EMAIL_HREF = "/profil/informations/email";
export const COMPTE_MOT_DE_PASSE_HREF = "/profil/informations/mot-de-passe";
export const COMPTE_PROFIL_HREF = "/profil";

// ── Bornes (miroirs du backend) ─────────────────────────────────────────
export const COMPTE_NAME_MAX = 120;
export const COMPTE_PASSWORD_MIN = 8;
export const COMPTE_PASSWORD_MAX = 128;

// ── « Mes informations » ────────────────────────────────────────────────
export const COMPTE_INFO_TITLE = "Mes informations";
export const COMPTE_INFO_LEAD = "Votre identité, votre adresse e-mail et votre mot de passe.";
export const COMPTE_BACK_PROFIL = "Mon profil";
export const COMPTE_BACK_INFO = "Mes informations";
export const COMPTE_ROW_IDENTITY = "Nom et prénom";
export const COMPTE_ROW_EMAIL = "Adresse e-mail";
export const COMPTE_ROW_PASSWORD = "Mot de passe";
export const COMPTE_PASSWORD_MASK = "••••••••••";
export const COMPTE_IDENTITY_EMPTY = "Non renseigné";

export function compteProviderName(provider: AuthProvider | null | undefined): string {
  return provider === "GOOGLE" ? "Google" : provider === "APPLE" ? "Apple" : "e-mail";
}

export function compteIsLocal(provider: AuthProvider | null | undefined): boolean {
  return !provider || provider === "LOCAL";
}

/** Sous-titre d'une donnée tenue par le fournisseur (Google / Apple). */
export function compteProviderManaged(provider: AuthProvider | null | undefined): string {
  return `Géré par votre compte ${compteProviderName(provider)}`;
}

/** Compte Google / Apple : l'adresse e-mail est celle du fournisseur. */
export function compteEmailProviderNote(provider: AuthProvider | null | undefined): string {
  const name = compteProviderName(provider);
  return `Connexion via ${name} — l'adresse e-mail se gère depuis votre compte ${name}.`;
}

/** Compte Google / Apple : aucun mot de passe SejourFR n'existe. */
export function comptePasswordProviderNote(provider: AuthProvider | null | undefined): string {
  return `Connexion via ${compteProviderName(provider)} — votre compte n'a pas de mot de passe SejourFR.`;
}

// ── Nom et prénom ───────────────────────────────────────────────────────
export const COMPTE_IDENTITY_TITLE = "Nom et prénom";
export const COMPTE_IDENTITY_LEAD = "Ce nom s'affiche sur votre profil.";
export const COMPTE_FIRST_NAME_LABEL = "Prénom";
export const COMPTE_LAST_NAME_LABEL = "Nom";
export const COMPTE_FIRST_NAME_REQUIRED = "Indiquez votre prénom.";
export const COMPTE_LAST_NAME_REQUIRED = "Indiquez votre nom.";
export const COMPTE_NAME_TOO_LONG = `${COMPTE_NAME_MAX} caractères maximum.`;
export const COMPTE_IDENTITY_SUBMIT = "Enregistrer";
export const COMPTE_IDENTITY_SUBMITTING = "Enregistrement…";
export const COMPTE_IDENTITY_SUCCESS = "Vos informations sont à jour.";
export const COMPTE_IDENTITY_FAILED = "La mise à jour a échoué. Réessayez.";

// ── Adresse e-mail ──────────────────────────────────────────────────────
export const COMPTE_EMAIL_TITLE = "Adresse e-mail";
export const COMPTE_EMAIL_LEAD =
  "Nous envoyons un lien de vérification à la nouvelle adresse. Votre adresse actuelle reste active tant que vous n'avez pas cliqué dessus.";
export const COMPTE_EMAIL_CURRENT_LABEL = "Adresse actuelle";
export const COMPTE_EMAIL_NEW_LABEL = "Nouvelle adresse e-mail";
export const COMPTE_EMAIL_PLACEHOLDER = "nouvelle@adresse.fr";
export const COMPTE_CURRENT_PASSWORD_LABEL = "Mot de passe actuel";
export const COMPTE_EMAIL_REQUIRED = "Indiquez votre nouvelle adresse e-mail.";
export const COMPTE_EMAIL_INVALID = "Cette adresse e-mail n'est pas valide.";
export const COMPTE_EMAIL_SAME = "C'est déjà votre adresse actuelle.";
export const COMPTE_CURRENT_PASSWORD_REQUIRED = "Indiquez votre mot de passe actuel.";
export const COMPTE_EMAIL_SUBMIT = "Envoyer le lien de vérification";
export const COMPTE_EMAIL_SUBMITTING = "Envoi…";
export const COMPTE_EMAIL_SUCCESS_TITLE = "Vérifiez votre boîte de réception";
export const COMPTE_EMAIL_FAILED = "La demande a échoué. Réessayez.";

export function compteEmailSuccessBody(newEmail: string, currentEmail: string): string {
  return `Un lien de vérification a été envoyé à ${newEmail}. Cliquez dessus pour confirmer le changement. D'ici là, vous vous connectez toujours avec ${currentEmail}.`;
}

// ── Mot de passe ────────────────────────────────────────────────────────
export const COMPTE_PASSWORD_TITLE = "Mot de passe";
export const COMPTE_PASSWORD_LEAD =
  "Saisissez votre mot de passe actuel, puis choisissez-en un nouveau.";
export const COMPTE_NEW_PASSWORD_LABEL = "Nouveau mot de passe";
export const COMPTE_CONFIRM_PASSWORD_LABEL = "Confirmer le nouveau mot de passe";
export const COMPTE_NEW_PASSWORD_HINT = `${COMPTE_PASSWORD_MIN} caractères minimum.`;
export const COMPTE_NEW_PASSWORD_TOO_SHORT = `Le nouveau mot de passe doit contenir au moins ${COMPTE_PASSWORD_MIN} caractères.`;
export const COMPTE_NEW_PASSWORD_TOO_LONG = `${COMPTE_PASSWORD_MAX} caractères maximum.`;
export const COMPTE_NEW_PASSWORD_SAME = "Le nouveau mot de passe doit être différent de l'actuel.";
export const COMPTE_CONFIRM_MISMATCH = "Les deux mots de passe ne correspondent pas.";
export const COMPTE_PASSWORD_SUBMIT = "Mettre à jour le mot de passe";
export const COMPTE_PASSWORD_SUBMITTING = "Mise à jour…";
export const COMPTE_PASSWORD_SUCCESS_TITLE = "Mot de passe modifié";
export const COMPTE_PASSWORD_SUCCESS_BODY = "Utilisez-le dès votre prochaine connexion.";
export const COMPTE_PASSWORD_FAILED = "La modification a échoué. Réessayez.";
export const COMPTE_PASSWORD_SHOW = "Afficher le mot de passe";
export const COMPTE_PASSWORD_HIDE = "Masquer le mot de passe";

// ── Commun ──────────────────────────────────────────────────────────────
export const COMPTE_BACK_TO_INFO = "Retour à mes informations";
export const COMPTE_GATE_TEXT = "Connectez-vous pour gérer votre compte.";
export const COMPTE_GATE_CTA = "Se connecter";

// ── Validation (pure) ───────────────────────────────────────────────────
export type IdentityErrors = { firstName?: string; lastName?: string };
export type EmailErrors = { newEmail?: string; password?: string };
export type PasswordErrors = { current?: string; next?: string; confirm?: string };

function nameError(value: string, required: string): string | undefined {
  const v = value.trim();
  if (!v) return required;
  if (v.length > COMPTE_NAME_MAX) return COMPTE_NAME_TOO_LONG;
  return undefined;
}

export function validateIdentity(firstName: string, lastName: string): IdentityErrors {
  const errors: IdentityErrors = {};
  const fn = nameError(firstName, COMPTE_FIRST_NAME_REQUIRED);
  const ln = nameError(lastName, COMPTE_LAST_NAME_REQUIRED);
  if (fn) errors.firstName = fn;
  if (ln) errors.lastName = ln;
  return errors;
}

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateEmailChange(
  newEmail: string,
  password: string,
  currentEmail: string,
): EmailErrors {
  const errors: EmailErrors = {};
  const email = newEmail.trim();
  if (!email) errors.newEmail = COMPTE_EMAIL_REQUIRED;
  else if (!EMAIL_PATTERN.test(email)) errors.newEmail = COMPTE_EMAIL_INVALID;
  else if (email.toLowerCase() === currentEmail.trim().toLowerCase()) errors.newEmail = COMPTE_EMAIL_SAME;
  if (!password) errors.password = COMPTE_CURRENT_PASSWORD_REQUIRED;
  return errors;
}

export function validatePasswordChange(
  current: string,
  next: string,
  confirm: string,
): PasswordErrors {
  const errors: PasswordErrors = {};
  if (!current) errors.current = COMPTE_CURRENT_PASSWORD_REQUIRED;
  if (next.length < COMPTE_PASSWORD_MIN) errors.next = COMPTE_NEW_PASSWORD_TOO_SHORT;
  else if (next.length > COMPTE_PASSWORD_MAX) errors.next = COMPTE_NEW_PASSWORD_TOO_LONG;
  else if (current && next === current) errors.next = COMPTE_NEW_PASSWORD_SAME;
  if (!errors.next && next !== confirm) errors.confirm = COMPTE_CONFIRM_MISMATCH;
  return errors;
}

export function hasErrors(errors: Record<string, string | undefined>): boolean {
  return Object.values(errors).some(Boolean);
}
