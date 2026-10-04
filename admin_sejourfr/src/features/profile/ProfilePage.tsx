import { useQuery } from "@tanstack/react-query";
import { authApi } from "../../api/authApi";
import { httpErrorMessage } from "../../api/http";
import { Avatar } from "../../components/ui/Avatar";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import type { AuthenticatedUser } from "../../types/api";
import { EmailChangeForm } from "./components/EmailChangeForm";
import { IdentityForm } from "./components/IdentityForm";
import { PasswordChangeForm } from "./components/PasswordChangeForm";
import { providerLabel } from "./profileForm";
import styles from "./ProfilePage.module.css";

/** `/profil` — le compte de l'administrateur connecté, ouvert depuis la carte de la barre latérale. */
export function ProfilePage() {
  const meQuery = useQuery({ queryKey: ["me"], queryFn: () => authApi.me() });

  return (
    <>
      <PageHeader eyebrow="Compte" title="Mon" emphasis="profil" description="Vos informations de connexion à la console." />
      {meQuery.isPending ? (
        <Panel>
          <Spinner label="Chargement du profil…" />
        </Panel>
      ) : meQuery.isError ? (
        <Panel>
          <EmptyState title="Profil indisponible" description={httpErrorMessage(meQuery.error)} />
        </Panel>
      ) : (
        <ProfileContent me={meQuery.data} />
      )}
    </>
  );
}

function ProfileContent({ me }: { me: AuthenticatedUser }) {
  const fullName = [me.firstName, me.lastName].filter(Boolean).join(" ").trim();
  return (
    <div className={styles.layout}>
      <aside className={styles.summary} aria-label="Informations du compte">
        <div className={styles.hero}>
          <Avatar name={fullName || null} email={me.email} size="lg" />
          <div className={styles.heroText}>
            <strong>{fullName || "Sans nom"}</strong>
            <span>{me.email}</span>
          </div>
        </div>
        <dl className={styles.facts}>
          <div>
            <dt>Prénom</dt>
            <dd>{me.firstName || "—"}</dd>
          </div>
          <div>
            <dt>Nom</dt>
            <dd>{me.lastName || "—"}</dd>
          </div>
          <div>
            <dt>E-mail</dt>
            <dd className={styles.email}>{me.email}</dd>
          </div>
          <div>
            <dt>Rôle</dt>
            <dd>
              <Tag tone="info" dot>
                {me.role === "ADMIN" ? "Administrateur" : "Utilisateur"}
              </Tag>
            </dd>
          </div>
          <div>
            <dt>Connexion</dt>
            <dd>{providerLabel(me.authProvider)}</dd>
          </div>
        </dl>
      </aside>
      <div className={styles.forms}>
        <IdentityForm key={`${me.firstName}|${me.lastName}`} me={me} />
        <EmailChangeForm me={me} />
        <PasswordChangeForm me={me} />
      </div>
    </div>
  );
}
