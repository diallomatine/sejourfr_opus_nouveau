"use client";

import { UserRound } from "lucide-react";
import { useState } from "react";
import { accountApi, ApiException, userContentApi } from "@/lib/api";
import {
  splitServerErrors,
  validateProfileCompletion,
  type AuthFieldErrors,
} from "@/lib/auth-form";
import { useAuth } from "@/lib/auth-context";
import type { AuthenticatedUser, TargetProcedure } from "@/lib/types";
import { AuthField } from "./AuthField";
import { AuthAlert, AuthSubmit, focusFirstError } from "./AuthForm";
import { DemarcheField } from "./DemarcheField";
import styles from "./auth.module.css";

const FIELD_ORDER = ["firstName", "lastName", "targetProcedure"] as const;

/**
 * Les questions de l'inscription qu'un compte n'a pas encore reçues — compte
 * né d'une connexion Google, compte ancien sans démarche. **Mêmes champs, mêmes
 * libellés, même validation** que `RegisterForm` (`AuthField`, `DemarcheField`,
 * `lib/auth-form.ts`) : c'est la même question, posée plus tard.
 *
 * 🛑 **Ce qui est demandé est SERVI** (`user.missingProfileFields`) : le
 * formulaire ne déduit rien d'un `null`. Les routes d'écriture sont celles du
 * profil, déjà existantes — `PATCH /api/me/profile` (prénom + nom, les deux
 * requis : un nom déjà connu est prérempli) puis `PUT /api/me/target-path`.
 * Le profil est ensuite **relu** (`refreshUser`) : c'est le serveur qui dit
 * s'il est complet.
 */
export function ProfileCompletionForm({
  user,
  onCompleted,
}: {
  user: AuthenticatedUser;
  onCompleted: () => void;
}) {
  const { refreshUser } = useAuth();
  const missing = user.missingProfileFields ?? [];
  const askNames = missing.includes("FIRST_NAME") || missing.includes("LAST_NAME");
  const askDemarche = missing.includes("TARGET_PROCEDURE");

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<AuthFieldErrors>({});
  const [mention, setMention] = useState<TargetProcedure | null>(null);

  const clearField = (name: keyof AuthFieldErrors) =>
    setFieldErrors((prev) => (prev[name] ? { ...prev, [name]: undefined } : prev));

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    const fd = new FormData(e.currentTarget);
    const firstName = askNames ? String(fd.get("firstName") ?? "") : undefined;
    const lastName = askNames ? String(fd.get("lastName") ?? "") : undefined;

    const invalid = validateProfileCompletion({
      firstName,
      lastName,
      targetProcedure: askDemarche ? mention : undefined,
    });
    setFieldErrors(invalid);
    if (Object.keys(invalid).length > 0) {
      focusFirstError(FIELD_ORDER, invalid);
      return;
    }

    setSubmitting(true);
    try {
      if (firstName !== undefined && lastName !== undefined) {
        await accountApi.updateProfile(firstName.trim(), lastName.trim());
      }
      if (askDemarche && mention) {
        await userContentApi.updateTargetPath(mention);
      }
    } catch (err) {
      if (err instanceof ApiException) {
        const { fields, global } = splitServerErrors(err);
        setFieldErrors(fields);
        setError(global);
        focusFirstError(FIELD_ORDER, fields);
      } else {
        setError("Impossible d'enregistrer vos réponses. Réessayez dans un instant.");
      }
      setSubmitting(false);
      return;
    }
    await refreshUser();
    setSubmitting(false);
    onCompleted();
  }

  return (
    <form onSubmit={handleSubmit} className={styles.form} noValidate suppressHydrationWarning>
      {error ? <AuthAlert>{error}</AuthAlert> : null}

      {askNames ? (
        <div className={styles.row2}>
          <AuthField
            id="firstName"
            name="firstName"
            label="Prénom"
            icon={UserRound}
            autoComplete="given-name"
            defaultValue={user.firstName ?? ""}
            disabled={submitting}
            error={fieldErrors.firstName}
            onChange={() => clearField("firstName")}
          />
          <AuthField
            id="lastName"
            name="lastName"
            label="Nom"
            autoComplete="family-name"
            defaultValue={user.lastName ?? ""}
            disabled={submitting}
            error={fieldErrors.lastName}
            onChange={() => clearField("lastName")}
          />
        </div>
      ) : null}

      {askDemarche ? (
        <DemarcheField
          value={mention}
          disabled={submitting}
          error={fieldErrors.targetProcedure}
          onChange={(v) => {
            setMention(v);
            clearField("targetProcedure");
          }}
        />
      ) : null}

      <AuthSubmit loading={submitting} label="Continuer" loadingLabel="Enregistrement…" />
    </form>
  );
}
