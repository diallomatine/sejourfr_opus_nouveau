import { useState } from "react";
import type { FormEvent } from "react";
import { useMutation } from "@tanstack/react-query";
import { accountApi } from "../../../api/accountApi";
import { Button } from "../../../components/ui/Button";
import { FormRow, Input } from "../../../components/ui/Form";
import { Panel } from "../../../components/ui/Panel";
import type { AuthenticatedUser } from "../../../types/api";
import { EMAIL_MAX, hasErrors, providerLabel, serverErrors, validateEmailChange } from "../profileForm";
import type { EmailErrors } from "../profileForm";
import { PasswordField } from "./PasswordField";
import styles from "./ProfileForm.module.css";

const FIELD_MAP = { newEmail: "newEmail", currentPassword: "password" } as const;

/**
 * Adresse e-mail — `POST /api/me/change-email-request`. Rien ne change ici : le serveur
 * envoie un lien à la nouvelle adresse et ne bascule le compte qu'au clic.
 */
export function EmailChangeForm({ me }: { me: AuthenticatedUser }) {
  const [newEmail, setNewEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<EmailErrors>({});
  const [alert, setAlert] = useState<string | null>(null);
  const [sentTo, setSentTo] = useState<string | null>(null);

  const mutation = useMutation({
    mutationFn: (email: string) => accountApi.requestEmailChange(email, password),
    onSuccess: (_, email) => {
      setSentTo(email);
      setNewEmail("");
      setPassword("");
    },
    onError: (error) => {
      const found = serverErrors(error, FIELD_MAP);
      setErrors(found.fields);
      setAlert(found.alert);
    },
  });

  if (me.authProvider !== "LOCAL") {
    const name = providerLabel(me.authProvider);
    return (
      <Panel title="Adresse e-mail">
        <p className={styles.note}>
          Connexion via {name} — l'adresse e-mail se gère depuis votre compte {name}.
        </p>
      </Panel>
    );
  }

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const found = validateEmailChange(newEmail, password, me.email);
    setErrors(found);
    setAlert(null);
    if (hasErrors(found)) return;
    mutation.mutate(newEmail.trim().toLowerCase());
  };

  if (sentTo) {
    return (
      <Panel title="Adresse e-mail">
        <div className={styles.success} role="status">
          <strong>Vérifiez la boîte de réception</strong>
          <p>
            Un lien de confirmation a été envoyé à <b>{sentTo}</b>. Il expire dans une heure. D'ici là,
            vous vous connectez toujours avec {me.email}.
          </p>
          <p>
            Une fois le lien ouvert, toutes vos sessions sont fermées : reconnectez-vous avec la nouvelle
            adresse.
          </p>
          <div className={styles.actions}>
            <Button type="button" onClick={() => setSentTo(null)}>
              Saisir une autre adresse
            </Button>
          </div>
        </div>
      </Panel>
    );
  }

  return (
    <Panel title="Adresse e-mail" sub={`Adresse actuelle : ${me.email}`}>
      <form className={styles.form} onSubmit={submit} noValidate>
        <p className={styles.lead}>
          Un lien de vérification part vers la nouvelle adresse. L'adresse actuelle reste active tant
          qu'il n'a pas été ouvert.
        </p>
        <FormRow label="Nouvelle adresse e-mail" htmlFor="profile-new-email" error={errors.newEmail}>
          <Input
            id="profile-new-email"
            type="email"
            inputMode="email"
            value={newEmail}
            onChange={(e) => setNewEmail(e.target.value)}
            autoComplete="email"
            maxLength={EMAIL_MAX}
            placeholder="nouvelle@adresse.fr"
            aria-invalid={errors.newEmail ? true : undefined}
            disabled={mutation.isPending}
          />
        </FormRow>
        <PasswordField
          id="profile-email-password"
          label="Mot de passe actuel"
          value={password}
          onChange={setPassword}
          autoComplete="current-password"
          error={errors.password}
          disabled={mutation.isPending}
        />
        {alert && (
          <div className={styles.alert} role="alert">
            {alert}
          </div>
        )}
        <div className={styles.actions}>
          <Button type="submit" variant="primary" disabled={mutation.isPending}>
            {mutation.isPending ? "Envoi…" : "Envoyer le lien de confirmation"}
          </Button>
        </div>
      </form>
    </Panel>
  );
}
