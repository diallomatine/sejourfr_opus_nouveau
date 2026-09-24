"use client";

import { useState } from "react";
import { accountApi, ApiException } from "@/lib/api";
import {
  COMPTE_BACK_INFO,
  COMPTE_BACK_TO_INFO,
  COMPTE_CURRENT_PASSWORD_LABEL,
  COMPTE_EMAIL_CURRENT_LABEL,
  COMPTE_EMAIL_FAILED,
  COMPTE_EMAIL_HREF,
  COMPTE_EMAIL_LEAD,
  COMPTE_EMAIL_NEW_LABEL,
  COMPTE_EMAIL_PLACEHOLDER,
  COMPTE_EMAIL_SUBMIT,
  COMPTE_EMAIL_SUBMITTING,
  COMPTE_EMAIL_SUCCESS_TITLE,
  COMPTE_EMAIL_TITLE,
  COMPTE_INFORMATIONS_HREF,
  compteEmailProviderNote,
  compteEmailSuccessBody,
  compteIsLocal,
  hasErrors,
  validateEmailChange,
} from "@/lib/compte";
import type { EmailErrors } from "@/lib/compte";
import {
  CompteAlert,
  CompteAuth,
  CompteDone,
  CompteField,
  CompteForm,
  CompteProviderNote,
  CompteReadonly,
  CompteShell,
  CompteSubmit,
} from "./CompteParts";

/**
 * « Adresse e-mail » (`/profil/informations/email`) —
 * `POST /api/me/change-email-request`. L'adresse ne change qu'au clic sur le
 * lien reçu : l'écran le dit avant l'envoi, puis le confirme.
 */
export function EmailForm() {
  return (
    <CompteAuth next={COMPTE_EMAIL_HREF}>
      {(user) => (
        <CompteShell
          backHref={COMPTE_INFORMATIONS_HREF}
          backLabel={COMPTE_BACK_INFO}
          title={COMPTE_EMAIL_TITLE}
          lead={compteIsLocal(user.authProvider) ? COMPTE_EMAIL_LEAD : undefined}
        >
          {compteIsLocal(user.authProvider) ? (
            <EmailFields currentEmail={user.email} />
          ) : (
            <CompteProviderNote
              note={compteEmailProviderNote(user.authProvider)}
              actionHref={COMPTE_INFORMATIONS_HREF}
              actionLabel={COMPTE_BACK_TO_INFO}
            />
          )}
        </CompteShell>
      )}
    </CompteAuth>
  );
}

function EmailFields({ currentEmail }: { currentEmail: string }) {
  const [newEmail, setNewEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<EmailErrors>({});
  const [submitted, setSubmitted] = useState(false);
  const [sending, setSending] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);
  const [sentTo, setSentTo] = useState<string | null>(null);

  function changed(email: string, pwd: string) {
    setServerError(null);
    if (submitted) setErrors(validateEmailChange(email, pwd, currentEmail));
  }

  async function submit() {
    setSubmitted(true);
    const found = validateEmailChange(newEmail, password, currentEmail);
    setErrors(found);
    if (hasErrors(found)) return;
    const email = newEmail.trim();
    setSending(true);
    setServerError(null);
    try {
      await accountApi.requestEmailChange(email, password);
      setSentTo(email);
    } catch (e) {
      setServerError(e instanceof ApiException && e.message ? e.message : COMPTE_EMAIL_FAILED);
    } finally {
      setSending(false);
    }
  }

  if (sentTo) {
    return (
      <CompteDone
        title={COMPTE_EMAIL_SUCCESS_TITLE}
        body={compteEmailSuccessBody(sentTo, currentEmail)}
        actionHref={COMPTE_INFORMATIONS_HREF}
        actionLabel={COMPTE_BACK_TO_INFO}
      />
    );
  }

  return (
    <CompteForm onSubmit={submit}>
      <CompteReadonly label={COMPTE_EMAIL_CURRENT_LABEL} value={currentEmail} />
      <CompteField
        id="compte-new-email"
        label={COMPTE_EMAIL_NEW_LABEL}
        type="email"
        value={newEmail}
        onChange={(v) => {
          setNewEmail(v);
          changed(v, password);
        }}
        error={errors.newEmail}
        placeholder={COMPTE_EMAIL_PLACEHOLDER}
        autoComplete="email"
        disabled={sending}
      />
      <CompteField
        id="compte-email-password"
        label={COMPTE_CURRENT_PASSWORD_LABEL}
        type="password"
        value={password}
        onChange={(v) => {
          setPassword(v);
          changed(newEmail, v);
        }}
        error={errors.password}
        autoComplete="current-password"
        disabled={sending}
      />
      {serverError ? <CompteAlert tone="error">{serverError}</CompteAlert> : null}
      <CompteSubmit loading={sending} label={COMPTE_EMAIL_SUBMIT} loadingLabel={COMPTE_EMAIL_SUBMITTING} />
    </CompteForm>
  );
}
