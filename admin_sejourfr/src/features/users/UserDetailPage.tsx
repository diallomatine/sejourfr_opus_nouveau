import { useState } from "react";
import type { ReactNode } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link, useLocation, useParams } from "react-router-dom";
import { HttpError, httpErrorMessage } from "../../api/http";
import { usersApi } from "../../api/usersApi";
import { Button } from "../../components/ui/Button";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { formatParisDate, formatParisDateTime } from "../../lib/dates";
import tableStyles from "../../components/ui/DataTable.module.css";
import type {
  AdminAccessOperationType,
  AdminUserAccessDto,
  AdminUserDetailDto,
  AdminUserProgressionDto,
  AdminUserPurchaseDto,
} from "../../types/api";
import { AccessOperationModal } from "./components/AccessOperationModal";
import type { AccessOperationIntent } from "./components/AccessOperationModal";
import { AccessStatusBadge } from "./components/AccessStatusBadge";
import styles from "./UserDetailPage.module.css";

/** Ton du bouton selon l'opération servie (le serveur décide lesquelles existent). */
const OPERATION_VARIANT: Record<AdminAccessOperationType, "primary" | "default" | "danger" | "ghost"> = {
  EXTEND: "primary",
  REACTIVATE: "primary",
  SHORTEN: "default",
  CORRECT_PRODUCT: "default",
  GRANT: "ghost",
  END: "danger",
};

function money(cents: number | null, currency: string | null): string {
  if (cents == null) return "—";
  return new Intl.NumberFormat("fr-FR", { style: "currency", currency: currency ?? "EUR" }).format(cents / 100);
}

/**
 * Fiche d'un utilisateur (spec §5), dans l'ordre : résumé lisible en 5 s,
 * accès par produit, achats (lecture seule), progression, compte, historique
 * admin. Tout est servi par `GET /api/admin/users/{id}` : statuts, dates
 * incluses, libellés, actions proposées (`availableOperations`).
 */
export function UserDetailPage() {
  const { id = "" } = useParams<{ id: string }>();
  const location = useLocation();
  const listSearch = (location.state as { listSearch?: string } | null)?.listSearch ?? "";
  const [intent, setIntent] = useState<AccessOperationIntent | null>(null);

  const detailQuery = useQuery({
    queryKey: ["adminUsers", "detail", id],
    queryFn: () => usersApi.detail(id),
    enabled: id !== "",
  });

  const back = (
    <Link to={`/users${listSearch}`} className={styles.back}>
      ← Utilisateurs
    </Link>
  );

  if (detailQuery.isPending) {
    return (
      <>
        {back}
        <Spinner label="Chargement de la fiche..." />
      </>
    );
  }

  if (detailQuery.isError) {
    const notFound = detailQuery.error instanceof HttpError && detailQuery.error.status === 404;
    return (
      <>
        {back}
        <Panel>
          {notFound ? (
            <EmptyState title="Utilisateur introuvable" description="Ce compte n'existe pas." />
          ) : (
            <div className={styles.error}>
              <span>Impossible de charger la fiche : {httpErrorMessage(detailQuery.error)}</span>
              <Button variant="ghost" size="sm" onClick={() => detailQuery.refetch()}>
                Réessayer
              </Button>
            </div>
          )}
        </Panel>
      </>
    );
  }

  const d = detailQuery.data;
  const name = d.account.displayName ?? d.account.email;

  return (
    <>
      {back}

      <header className={styles.hero}>
        <div className={styles.heroMain}>
          <div className={styles.eyebrow}>Fiche utilisateur</div>
          <h1 className={styles.name}>{name}</h1>
          {d.account.displayName && <div className={styles.email}>{d.account.email}</div>}
          <div className={styles.heroTags}>
            <span className={d.account.accountStatus === "DELETED" ? styles.tagDanger : styles.tag}>
              Compte {d.account.accountStatusLabel.toLowerCase()}
            </span>
            {d.account.role === "ADMIN" && <span className={styles.tag}>Administrateur</span>}
            {d.account.internal && <span className={styles.tag}>Compte interne</span>}
          </div>
        </div>
        <div className={styles.heroActions}>
          <Button variant="primary" onClick={() => setIntent({ operation: "GRANT", product: null, label: "Donner un accès" })}>
            + Donner un accès
          </Button>
          {detailQuery.isFetching && <span className={styles.refreshing}>Mise à jour…</span>}
        </div>
      </header>

      <Summary detail={d} />

      <Panel title="Accès" sub="Droit réellement appliqué dans l'application, par produit vendu">
        <div className={styles.accessGrid}>
          {d.accesses.map((a) => (
            <AccessCard key={a.product} access={a} onAction={setIntent} />
          ))}
        </div>
      </Panel>

      <Panel title="Achats" sub="Historique commercial réel — lecture seule" noPadding>
        <Purchases purchases={d.purchases} />
      </Panel>

      <Panel title="Progression" sub="Données déjà enregistrées, lues sans effet de bord">
        <div className={styles.progressGrid}>
          {d.progression.map((p) => (
            <ProgressionCard key={p.module} progression={p} />
          ))}
        </div>
      </Panel>

      <Panel title="Compte" sub="Lecture seule">
        <dl className={styles.infoGrid}>
          <Info label="Identifiant">
            <code className={styles.code}>{d.account.id}</code>
          </Info>
          <Info label="Email">{d.account.email}</Info>
          <Info label="Prénom / nom">
            {[d.account.firstName, d.account.lastName].filter(Boolean).join(" ") || "—"}
          </Info>
          <Info label="Inscription">{formatParisDateTime(d.account.createdAt)}</Info>
          <Info label="Dernière connexion">{formatParisDateTime(d.account.lastLoginAt)}</Info>
          <Info label="Statut">{d.account.accountStatusLabel}</Info>
          <Info label="Connexion via">{d.account.authProvider}</Info>
          <Info label="Démarche / niveau visés">
            {[d.account.targetProcedure, d.account.targetLevel].filter(Boolean).join(" · ") || "—"}
          </Info>
        </dl>
      </Panel>

      <Panel title="Historique administratif" sub="Une entrée par action admin, avec son motif">
        <History detail={d} />
      </Panel>

      {intent && (
        <AccessOperationModal
          key={`${intent.operation}-${intent.product ?? "any"}`}
          userId={d.account.id}
          userLabel={d.account.email}
          accessVersion={d.accessVersion}
          accesses={d.accesses}
          intent={intent}
          onClose={() => setIntent(null)}
        />
      )}
    </>
  );
}

function Summary({ detail: d }: { detail: AdminUserDetailDto }) {
  return (
    <section className={styles.summary} aria-label="Résumé">
      <p className={styles.summaryMeta}>
        Inscrit le {formatParisDate(d.account.createdAt)} · Dernière activité :{" "}
        {d.lastActivityAt ? formatParisDateTime(d.lastActivityAt) : "aucune"}
      </p>
      <p className={styles.summaryEffective}>
        Produit effectif : <strong>{d.effectiveAccess.effectiveProductLabel}</strong>
        <span className={styles.sep}>·</span>
        Modules ouverts : <strong>{d.effectiveAccess.openModulesLabel}</strong>
      </p>
      <ul className={styles.summaryLines}>
        {d.accesses.map((a) => (
          <li key={a.product}>
            <strong>{a.productLabel}</strong> : {a.summary}
            {a.originLabel && <span className={styles.origin}> ({a.originLabel})</span>}
          </li>
        ))}
      </ul>
    </section>
  );
}

function AccessCard({
  access: a,
  onAction,
}: {
  access: AdminUserAccessDto;
  onAction: (intent: AccessOperationIntent) => void;
}) {
  return (
    <article className={`${styles.accessCard} ${a.status === "ACTIVE" ? styles.accessCardActive : ""}`}>
      <div className={styles.accessTop}>
        <div>
          <div className={styles.accessLabel}>Produit</div>
          <div className={styles.accessProduct}>{a.productLabel}</div>
        </div>
        <AccessStatusBadge status={a.status} label={a.statusLabel} />
      </div>
      <p className={styles.accessSummary}>{a.summary}</p>
      <dl className={styles.accessFacts}>
        <div>
          <dt>Début</dt>
          <dd>{formatParisDate(a.startsAt)}</dd>
        </div>
        <div>
          <dt>Fin incluse</dt>
          <dd>{a.endLabel ?? "—"}</dd>
        </div>
        <div>
          <dt>Origine</dt>
          <dd>{a.originLabel ?? "—"}</dd>
        </div>
      </dl>
      {a.alerts.length > 0 && (
        <ul className={styles.alerts}>
          {a.alerts.map((al) => (
            <li key={al.code}>{al.label}</li>
          ))}
        </ul>
      )}
      {a.availableOperations.length > 0 && (
        <div className={styles.accessActions}>
          {a.availableOperations.map((op) => (
            <Button
              key={op.code}
              size="sm"
              variant={OPERATION_VARIANT[op.code]}
              onClick={() => onAction({ operation: op.code, product: a.product, label: op.label })}
            >
              {op.label}
            </Button>
          ))}
        </div>
      )}
    </article>
  );
}

function Purchases({ purchases }: { purchases: AdminUserPurchaseDto[] }) {
  if (purchases.length === 0) {
    return <EmptyState title="Aucun achat" description="Ce compte n'a jamais payé." />;
  }
  return (
    <div className={tableStyles.tableWrap}>
      <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
        <thead>
          <tr>
            <th>Produit</th>
            <th>Montant</th>
            <th>Date</th>
            <th>Plateforme</th>
            <th>Statut</th>
            <th>Fin</th>
            <th>Référence</th>
          </tr>
        </thead>
        <tbody>
          {purchases.map((p) => (
            <tr key={p.id}>
              <td>
                <strong>{p.productLabel ?? "—"}</strong>
                <div className={styles.subLine}>{p.planName ?? p.planCode ?? ""}</div>
                {p.recurring && <div className={styles.recurring}>Abonnement récurrent</div>}
              </td>
              <td data-label="Montant">{money(p.amountCents, p.currency)}</td>
              <td data-label="Date" className={styles.mono}>
                {formatParisDateTime(p.purchasedAt ?? p.startsAt)}
              </td>
              <td data-label="Plateforme">{p.sourceLabel}</td>
              <td data-label="Statut">
                <div>
                  {p.statusLabel}
                  {p.paymentStatusLabel && <div className={styles.subLine}>{p.paymentStatusLabel}</div>}
                </div>
              </td>
              <td data-label="Fin" className={styles.mono}>
                {p.endLabel ?? "—"}
              </td>
              <td data-label="Référence">
                <code className={styles.code}>{p.externalReference ?? "—"}</code>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ProgressionCard({ progression: p }: { progression: AdminUserProgressionDto }) {
  const c = p.currentCycle;
  return (
    <article className={styles.progressCard}>
      <h3 className={styles.progressTitle}>{p.moduleLabel}</h3>
      <dl className={styles.infoGrid}>
        <Info label="Diagnostic">
          {p.diagnosticDone ? `Fait le ${formatParisDate(p.diagnosticCompletedAt)}` : "Non fait"}
        </Info>
        <Info label="Cycle en cours">
          {c ? `Depuis le ${formatParisDate(c.startedAt)}` : "Aucun cycle"}
        </Info>
        {c && (
          <>
            <Info label="Niveau d'entrée">{c.entryLevel ?? "—"}</Info>
            <Info label="Objectif">{[c.targetProcedure, c.targetLevel].filter(Boolean).join(" · ") || "—"}</Info>
            <Info label="Étapes closes">
              {c.stepsClosed} / {c.stepsTotal}
            </Info>
          </>
        )}
        <Info label="Cycles historisés">{p.historisedCycles}</Info>
      </dl>
    </article>
  );
}

function History({ detail: d }: { detail: AdminUserDetailDto }) {
  if (d.history.length === 0) {
    return <p className={styles.muted}>Aucune action administrative sur ce compte.</p>;
  }
  return (
    <ol className={styles.timeline}>
      {d.history.map((h) => (
        <li key={h.operationId} className={styles.timelineItem}>
          <div className={styles.timelineHead}>
            <span className={styles.mono}>{formatParisDateTime(h.createdAt)}</span>
            <span className={styles.muted}> — {h.adminEmail ?? h.adminId}</span>
          </div>
          <div className={styles.timelineTitle}>
            {h.operationLabel} :{" "}
            {h.fromProductLabel ? `${h.fromProductLabel} → ${h.productLabel}` : h.productLabel}
          </div>
          {h.changes.length > 0 && (
            <ul className={styles.timelineChanges}>
              {h.changes.map((c) => (
                <li key={c}>{c}</li>
              ))}
            </ul>
          )}
          <div className={styles.timelineReason}>Motif : {h.reason}</div>
        </li>
      ))}
    </ol>
  );
}

function Info({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className={styles.info}>
      <dt>{label}</dt>
      <dd>{children}</dd>
    </div>
  );
}
