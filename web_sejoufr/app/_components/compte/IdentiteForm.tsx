"use client";

import { useState } from "react";
import { useAuth } from "@/lib/auth-context";
import { accountApi, ApiException } from "@/lib/api";
import {
  COMPTE_BACK_INFO,
  COMPTE_FIRST_NAME_LABEL,
  COMPTE_IDENTITE_HREF,
  COMPTE_IDENTITY_FAILED,
  COMPTE_IDENTITY_LEAD,
  COMPTE_IDENTITY_SUBMIT,
  COMPTE_IDENTITY_SUBMITTING,
  COMPTE_IDENTITY_SUCCESS,
  COMPTE_IDENTITY_TITLE,
  COMPTE_INFORMATIONS_HREF,
  COMPTE_LAST_NAME_LABEL,
  hasErrors,
  validateIdentity,
} from "@/lib/compte";
import type { IdentityErrors } from "@/lib/compte";
import type { AuthenticatedUser } from "@/lib/types";
import {
  CompteAlert,
  CompteAuth,
  CompteField,
  CompteForm,
  CompteShell,
  CompteSubmit,
} from "./CompteParts";

/** « Nom et prénom » (`/profil/informations/identite`) — `PATCH /api/me/profile`. */
export function IdentiteForm() {
  return (
    <CompteAuth next={COMPTE_IDENTITE_HREF}>
      {(user) => (
        <CompteShell
          backHref={COMPTE_INFORMATIONS_HREF}
          backLabel={COMPTE_BACK_INFO}
          title={COMPTE_IDENTITY_TITLE}
          lead={COMPTE_IDENTITY_LEAD}
        >
          <IdentiteFields user={user} />
        </CompteShell>
      )}
    </CompteAuth>
  );
}

function IdentiteFields({ user }: { user: AuthenticatedUser }) {
  const { refreshUser } = useAuth();
  const [firstName, setFirstName] = useState(user.firstName ?? "");
  const [lastName, setLastName] = useState(user.lastName ?? "");
  const [errors, setErrors] = useState<IdentityErrors>({});
  const [submitted, setSubmitted] = useState(false);
  const [saving, setSaving] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  /** Une saisie efface les messages ; après un premier envoi, elle revalide. */
  function changed(fn: string, ln: string) {
    setSaved(false);
    setServerError(null);
    if (submitted) setErrors(validateIdentity(fn, ln));
  }

  async function submit() {
    setSubmitted(true);
    const found = validateIdentity(firstName, lastName);
    setErrors(found);
    if (hasErrors(found)) return;
    setSaving(true);
    setServerError(null);
    setSaved(false);
    try {
      await accountApi.updateProfile(firstName.trim(), lastName.trim());
      await refreshUser();
      setSaved(true);
    } catch (e) {
      setServerError(e instanceof ApiException && e.message ? e.message : COMPTE_IDENTITY_FAILED);
    } finally {
      setSaving(false);
    }
  }

  return (
    <CompteForm onSubmit={submit}>
      <CompteField
        id="compte-first-name"
        label={COMPTE_FIRST_NAME_LABEL}
        value={firstName}
        onChange={(v) => {
          setFirstName(v);
          changed(v, lastName);
        }}
        error={errors.firstName}
        autoComplete="given-name"
        disabled={saving}
      />
      <CompteField
        id="compte-last-name"
        label={COMPTE_LAST_NAME_LABEL}
        value={lastName}
        onChange={(v) => {
          setLastName(v);
          changed(firstName, v);
        }}
        error={errors.lastName}
        autoComplete="family-name"
        disabled={saving}
      />
      {serverError ? <CompteAlert tone="error">{serverError}</CompteAlert> : null}
      {saved ? <CompteAlert tone="ok">{COMPTE_IDENTITY_SUCCESS}</CompteAlert> : null}
      <CompteSubmit
        loading={saving}
        label={COMPTE_IDENTITY_SUBMIT}
        loadingLabel={COMPTE_IDENTITY_SUBMITTING}
      />
    </CompteForm>
  );
}
