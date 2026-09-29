"use client";

import { useState } from "react";
import { accountApi, ApiException } from "@/lib/api";
import {
  COMPTE_BACK_INFO,
  COMPTE_BACK_TO_INFO,
  COMPTE_CONFIRM_PASSWORD_LABEL,
  COMPTE_CURRENT_PASSWORD_LABEL,
  COMPTE_INFORMATIONS_HREF,
  COMPTE_MOT_DE_PASSE_HREF,
  COMPTE_NEW_PASSWORD_HINT,
  COMPTE_NEW_PASSWORD_LABEL,
  COMPTE_PASSWORD_FAILED,
  COMPTE_PASSWORD_LEAD,
  COMPTE_PASSWORD_SUBMIT,
  COMPTE_PASSWORD_SUBMITTING,
  COMPTE_PASSWORD_SUCCESS_BODY,
  COMPTE_PASSWORD_SUCCESS_TITLE,
  COMPTE_PASSWORD_TITLE,
  compteIsLocal,
  comptePasswordProviderNote,
  hasErrors,
  validatePasswordChange,
} from "@/lib/compte";
import type { PasswordErrors } from "@/lib/compte";
import {
  CompteAlert,
  CompteAuth,
  CompteDone,
  CompteField,
  CompteForm,
  CompteProviderNote,
  CompteShell,
  CompteSubmit,
} from "./CompteParts";

/** « Mot de passe » (`/profil/informations/mot-de-passe`) — `POST /api/me/change-password`. */
export function MotDePasseForm() {
  return (
    <CompteAuth next={COMPTE_MOT_DE_PASSE_HREF}>
      {(user) => (
        <CompteShell
          backHref={COMPTE_INFORMATIONS_HREF}
          backLabel={COMPTE_BACK_INFO}
          title={COMPTE_PASSWORD_TITLE}
          lead={compteIsLocal(user.authProvider) ? COMPTE_PASSWORD_LEAD : undefined}
        >
          {compteIsLocal(user.authProvider) ? (
            <PasswordFields />
          ) : (
            <CompteProviderNote
              note={comptePasswordProviderNote(user.authProvider)}
              actionHref={COMPTE_INFORMATIONS_HREF}
              actionLabel={COMPTE_BACK_TO_INFO}
            />
          )}
        </CompteShell>
      )}
    </CompteAuth>
  );
}

function PasswordFields() {
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [errors, setErrors] = useState<PasswordErrors>({});
  const [submitted, setSubmitted] = useState(false);
  const [saving, setSaving] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  function changed(c: string, n: string, k: string) {
    setServerError(null);
    if (submitted) setErrors(validatePasswordChange(c, n, k));
  }

  async function submit() {
    setSubmitted(true);
    const found = validatePasswordChange(current, next, confirm);
    setErrors(found);
    if (hasErrors(found)) return;
    setSaving(true);
    setServerError(null);
    try {
      await accountApi.changePassword(current, next);
      setDone(true);
    } catch (e) {
      setServerError(e instanceof ApiException && e.message ? e.message : COMPTE_PASSWORD_FAILED);
    } finally {
      setSaving(false);
    }
  }

  if (done) {
    return (
      <CompteDone
        title={COMPTE_PASSWORD_SUCCESS_TITLE}
        body={COMPTE_PASSWORD_SUCCESS_BODY}
        actionHref={COMPTE_INFORMATIONS_HREF}
        actionLabel={COMPTE_BACK_TO_INFO}
      />
    );
  }

  return (
    <CompteForm onSubmit={submit}>
      <CompteField
        id="compte-current-password"
        label={COMPTE_CURRENT_PASSWORD_LABEL}
        type="password"
        value={current}
        onChange={(v) => {
          setCurrent(v);
          changed(v, next, confirm);
        }}
        error={errors.current}
        autoComplete="current-password"
        disabled={saving}
      />
      <CompteField
        id="compte-new-password"
        label={COMPTE_NEW_PASSWORD_LABEL}
        type="password"
        value={next}
        onChange={(v) => {
          setNext(v);
          changed(current, v, confirm);
        }}
        error={errors.next}
        hint={COMPTE_NEW_PASSWORD_HINT}
        autoComplete="new-password"
        disabled={saving}
      />
      <CompteField
        id="compte-confirm-password"
        label={COMPTE_CONFIRM_PASSWORD_LABEL}
        type="password"
        value={confirm}
        onChange={(v) => {
          setConfirm(v);
          changed(current, next, v);
        }}
        error={errors.confirm}
        autoComplete="new-password"
        disabled={saving}
      />
      {serverError ? <CompteAlert tone="error">{serverError}</CompteAlert> : null}
      <CompteSubmit loading={saving} label={COMPTE_PASSWORD_SUBMIT} loadingLabel={COMPTE_PASSWORD_SUBMITTING} />
    </CompteForm>
  );
}
