import { useState } from "react";
import type { FormEvent } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { accountApi } from "../../../api/accountApi";
import { authApi } from "../../../api/authApi";
import { useAuth } from "../../../auth/AuthContext";
import { Button } from "../../../components/ui/Button";
import { FormRow, Input } from "../../../components/ui/Form";
import { Panel } from "../../../components/ui/Panel";
import { useToast } from "../../../components/ui/Toast";
import type { AuthenticatedUser } from "../../../types/api";
import { hasErrors, NAME_MAX, serverErrors, validateIdentity } from "../profileForm";
import type { IdentityErrors } from "../profileForm";
import styles from "./ProfileForm.module.css";

const FIELD_MAP = { firstName: "firstName", lastName: "lastName" } as const;

/** Prénom et nom — `PATCH /api/me/profile`, puis relecture de `/api/auth/me` pour la barre latérale. */
export function IdentityForm({ me }: { me: AuthenticatedUser }) {
  const queryClient = useQueryClient();
  const { updateUser } = useAuth();
  const toast = useToast();
  const [firstName, setFirstName] = useState(me.firstName ?? "");
  const [lastName, setLastName] = useState(me.lastName ?? "");
  const [errors, setErrors] = useState<IdentityErrors>({});
  const [alert, setAlert] = useState<string | null>(null);

  const mutation = useMutation({
    mutationFn: async () => {
      await accountApi.updateProfile(firstName.trim(), lastName.trim());
      return authApi.me();
    },
    onSuccess: (fresh) => {
      queryClient.setQueryData(["me"], fresh);
      updateUser(fresh);
      toast.show("Profil enregistré", "success");
    },
    onError: (error) => {
      const found = serverErrors(error, FIELD_MAP);
      setErrors(found.fields);
      setAlert(found.alert);
    },
  });

  const unchanged = firstName.trim() === (me.firstName ?? "") && lastName.trim() === (me.lastName ?? "");

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const found = validateIdentity(firstName, lastName);
    setErrors(found);
    setAlert(null);
    if (hasErrors(found)) return;
    mutation.mutate();
  };

  return (
    <Panel title="Identité" sub="Le nom affiché dans la console.">
      <form className={styles.form} onSubmit={submit} noValidate>
        <FormRow label="Prénom" htmlFor="profile-first-name" error={errors.firstName}>
          <Input
            id="profile-first-name"
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            autoComplete="given-name"
            maxLength={NAME_MAX}
            aria-invalid={errors.firstName ? true : undefined}
            disabled={mutation.isPending}
          />
        </FormRow>
        <FormRow label="Nom" htmlFor="profile-last-name" error={errors.lastName}>
          <Input
            id="profile-last-name"
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            autoComplete="family-name"
            maxLength={NAME_MAX}
            aria-invalid={errors.lastName ? true : undefined}
            disabled={mutation.isPending}
          />
        </FormRow>
        {alert && (
          <div className={styles.alert} role="alert">
            {alert}
          </div>
        )}
        <div className={styles.actions}>
          <Button type="submit" variant="primary" disabled={mutation.isPending || unchanged}>
            {mutation.isPending ? "Enregistrement…" : "Enregistrer"}
          </Button>
        </div>
      </form>
    </Panel>
  );
}
