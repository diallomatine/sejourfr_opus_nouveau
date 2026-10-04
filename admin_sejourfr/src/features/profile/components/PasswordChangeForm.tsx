import { useState } from "react";
import type { FormEvent } from "react";
import { useMutation } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { accountApi } from "../../../api/accountApi";
import { useAuth } from "../../../auth/AuthContext";
import { Button } from "../../../components/ui/Button";
import { Panel } from "../../../components/ui/Panel";
import type { AuthenticatedUser } from "../../../types/api";
import {
  hasErrors,
  PASSWORD_MAX,
  PASSWORD_MIN,
  providerLabel,
  serverErrors,
  validatePasswordChange,
} from "../profileForm";
import type { PasswordErrors } from "../profileForm";
import { PasswordField } from "./PasswordField";
import styles from "./ProfileForm.module.css";

const FIELD_MAP = { currentPassword: "current", newPassword: "next" } as const;

/**
 * Mot de passe — `POST /api/me/change-password`. Le serveur vérifie l'ancien, hache le
 * nouveau et révoque toutes les sessions du compte, celle-ci comprise.
 */
export function PasswordChangeForm({ me }: { me: AuthenticatedUser }) {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [errors, setErrors] = useState<PasswordErrors>({});
  const [alert, setAlert] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  const mutation = useMutation({
    mutationFn: () => accountApi.changePassword(current, next),
    onSuccess: () => {
      setDone(true);
      setCurrent("");
      setNext("");
      setConfirm("");
    },
    onError: (error) => {
      const found = serverErrors(error, FIELD_MAP);
      setErrors(found.fields);
      setAlert(found.alert);
    },
  });

  if (me.authProvider !== "LOCAL") {
    return (
      <Panel title="Mot de passe">
        <p className={styles.note}>
          Connexion via {providerLabel(me.authProvider)} — ce compte n'a pas de mot de passe SejourFR.
        </p>
      </Panel>
    );
  }

  if (done) {
    return (
      <Panel title="Mot de passe">
        <div className={styles.success} role="status">
          <strong>Mot de passe modifié</strong>
          <p>
            Par sécurité, toutes les sessions du compte ont été fermées. Celle-ci reste ouverte au plus
            une heure, puis il faudra vous reconnecter avec le nouveau mot de passe.
          </p>
          <div className={styles.actions}>
            <Button
              type="button"
              variant="primary"
              onClick={() => {
                logout();
                navigate("/login", { replace: true });
              }}
            >
              Se reconnecter maintenant
            </Button>
          </div>
        </div>
      </Panel>
    );
  }

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const found = validatePasswordChange(current, next, confirm);
    setErrors(found);
    setAlert(null);
    if (hasErrors(found)) return;
    mutation.mutate();
  };

  return (
    <Panel title="Mot de passe">
      <form className={styles.form} onSubmit={submit} noValidate>
        <PasswordField
          id="profile-current-password"
          label="Mot de passe actuel"
          value={current}
          onChange={setCurrent}
          autoComplete="current-password"
          error={errors.current}
          disabled={mutation.isPending}
        />
        <PasswordField
          id="profile-new-password"
          label="Nouveau mot de passe"
          value={next}
          onChange={setNext}
          autoComplete="new-password"
          error={errors.next}
          hint={`${PASSWORD_MIN} à ${PASSWORD_MAX} caractères, différent de l'actuel.`}
          disabled={mutation.isPending}
        />
        <PasswordField
          id="profile-confirm-password"
          label="Confirmer le nouveau mot de passe"
          value={confirm}
          onChange={setConfirm}
          autoComplete="new-password"
          error={errors.confirm}
          disabled={mutation.isPending}
        />
        {alert && (
          <div className={styles.alert} role="alert">
            {alert}
          </div>
        )}
        <div className={styles.actions}>
          <Button type="submit" variant="primary" disabled={mutation.isPending}>
            {mutation.isPending ? "Mise à jour…" : "Mettre à jour le mot de passe"}
          </Button>
        </div>
      </form>
    </Panel>
  );
}
