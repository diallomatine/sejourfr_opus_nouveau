import { useEffect, useMemo, useState } from "react";
import { useQuery, keepPreviousData } from "@tanstack/react-query";
import { subscriptionsApi } from "../../api/subscriptionsApi";
import { Button } from "../../components/ui/Button";
import { Input, Select } from "../../components/ui/Form";
import { Modal } from "../../components/ui/Modal";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import type {
  AdminSubscriptionDto,
  AdminSubscriptionFilters,
  ModuleAccess,
  SubscriptionSource,
  SubscriptionStatus,
} from "../../types/api";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./SubscriptionsPage.module.css";

const PAGE_SIZE = 25;

const SOURCE_LABEL: Record<SubscriptionSource, string> = {
  STRIPE: "Stripe (web)",
  APPLE: "Apple (iOS)",
  GOOGLE: "Google (Android)",
};

const STATUS_LABEL: Record<SubscriptionStatus, string> = {
  ACTIVE: "Actif",
  TRIAL: "Essai",
  IN_GRACE: "Grâce",
  PENDING: "En attente",
  CANCELED: "Annulé",
  EXPIRED: "Expiré",
  REFUNDED: "Remboursé",
};

const STATUS_TONE: Record<SubscriptionStatus, "active" | "premium" | "muted" | "csp"> = {
  ACTIVE: "active",
  TRIAL: "csp",
  IN_GRACE: "premium",
  PENDING: "csp",
  CANCELED: "muted",
  EXPIRED: "muted",
  REFUNDED: "premium",
};

const SOURCE_TONE: Record<SubscriptionSource, "csp" | "premium" | "co"> = {
  STRIPE: "csp",
  APPLE: "co",
  GOOGLE: "premium",
};

const MODULE_LABEL: Record<ModuleAccess, string> = {
  NONE: "Aucun",
  CIVIQUE: "Civique",
  TCF: "TCF",
  INTEGRAL: "Intégral",
};

function formatDate(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleString("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatPrice(n: number | null | undefined): string {
  if (n === null || n === undefined) return "—";
  return new Intl.NumberFormat("fr-FR", {
    style: "currency",
    currency: "EUR",
  }).format(n);
}

function fullName(sub: AdminSubscriptionDto): string {
  const parts = [sub.userFirstName, sub.userLastName].filter(Boolean);
  return parts.length > 0 ? parts.join(" ") : "—";
}

export function SubscriptionsPage() {
  const [source, setSource] = useState<SubscriptionSource | "">("");
  const [status, setStatus] = useState<SubscriptionStatus | "">("");
  const [moduleAccess, setModuleAccess] = useState<ModuleAccess | "">("");
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(0);
  const [detail, setDetail] = useState<AdminSubscriptionDto | null>(null);

  // Debounce de la recherche (300ms) pour éviter de spammer le backend.
  useEffect(() => {
    const t = setTimeout(() => {
      setSearch(searchInput.trim());
      setPage(0);
    }, 300);
    return () => clearTimeout(t);
  }, [searchInput]);

  // Reset à la page 0 quand on change un filtre.
  useEffect(() => {
    setPage(0);
  }, [source, status, moduleAccess]);

  const filters = useMemo<AdminSubscriptionFilters>(
    () => ({
      source: source || undefined,
      status: status || undefined,
      moduleAccess: moduleAccess || undefined,
      search: search || undefined,
      page,
      size: PAGE_SIZE,
    }),
    [source, status, moduleAccess, search, page],
  );

  const subscriptionsQuery = useQuery({
    queryKey: ["adminSubscriptions", filters],
    queryFn: () => subscriptionsApi.list(filters),
    placeholderData: keepPreviousData,
  });

  const totalPages = subscriptionsQuery.data
    ? Math.max(1, Math.ceil(subscriptionsQuery.data.total / PAGE_SIZE))
    : 1;

  return (
    <>
      <PageHeader
        eyebrow="§ 06 — Commerce"
        title="Abonn"
        emphasis="ements"
      />

      <Panel noPadding>
        <div className={styles.filtersBar}>
          <div className={styles.filterGroup}>
            <label className={styles.filterLabel}>Source</label>
            <Select
              value={source}
              onChange={(e) => setSource(e.target.value as SubscriptionSource | "")}
            >
              <option value="">Toutes</option>
              <option value="STRIPE">Stripe (web)</option>
              <option value="APPLE">Apple (iOS)</option>
              <option value="GOOGLE">Google (Android)</option>
            </Select>
          </div>

          <div className={styles.filterGroup}>
            <label className={styles.filterLabel}>Statut</label>
            <Select
              value={status}
              onChange={(e) => setStatus(e.target.value as SubscriptionStatus | "")}
            >
              <option value="">Tous</option>
              {(Object.keys(STATUS_LABEL) as SubscriptionStatus[]).map((s) => (
                <option key={s} value={s}>
                  {STATUS_LABEL[s]}
                </option>
              ))}
            </Select>
          </div>

          <div className={styles.filterGroup}>
            <label className={styles.filterLabel}>Module</label>
            <Select
              value={moduleAccess}
              onChange={(e) => setModuleAccess(e.target.value as ModuleAccess | "")}
            >
              <option value="">Tous</option>
              <option value="CIVIQUE">Civique</option>
              <option value="INTEGRAL">Intégral</option>
            </Select>
          </div>

          <div className={`${styles.filterGroup} ${styles.searchGroup}`}>
            <label className={styles.filterLabel}>Recherche (email ou nom)</label>
            <Input
              type="search"
              placeholder="user@exemple.fr"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
            />
          </div>
        </div>
      </Panel>

      {subscriptionsQuery.isLoading && <Spinner label="Chargement..." />}

      {subscriptionsQuery.isError && (
        <Panel>
          <div style={{ padding: 24, color: "var(--red)" }}>
            Erreur : {(subscriptionsQuery.error as Error).message}
          </div>
        </Panel>
      )}

      {subscriptionsQuery.data && (
        <Panel
          title="Souscriptions"
          sub={`${subscriptionsQuery.data.total} résultats · page ${page + 1} / ${totalPages}`}
          noPadding
        >
          {subscriptionsQuery.data.items.length === 0 ? (
            <EmptyState
              title="Aucune souscription"
              description="Essayez d'autres filtres ou supprimez la recherche."
            />
          ) : (
            <table className={tableStyles.table}>
              <thead>
                <tr>
                  <th>Utilisateur</th>
                  <th>Plan</th>
                  <th>Source</th>
                  <th>Statut</th>
                  <th>Échéance</th>
                  <th>Maj</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {subscriptionsQuery.data.items.map((sub) => (
                  <tr key={sub.id}>
                    <td>
                      <strong>{sub.userEmail}</strong>
                      <div className={styles.subLine}>{fullName(sub)}</div>
                    </td>
                    <td>
                      <strong>{sub.planName ?? sub.productId ?? "—"}</strong>
                      {sub.moduleAccess && (
                        <div className={styles.subLine}>
                          <Tag
                            tone={sub.moduleAccess === "CIVIQUE" ? "csp" : "premium"}
                          >
                            {MODULE_LABEL[sub.moduleAccess]}
                          </Tag>
                        </div>
                      )}
                    </td>
                    <td>
                      <Tag tone={SOURCE_TONE[sub.source]}>{sub.source}</Tag>
                    </td>
                    <td>
                      <Tag tone={STATUS_TONE[sub.status]}>
                        {STATUS_LABEL[sub.status]}
                      </Tag>
                      {!sub.autoRenew && sub.status === "ACTIVE" && (
                        <div className={styles.cancelHint}>auto-renew off</div>
                      )}
                    </td>
                    <td>{formatDate(sub.endsAt)}</td>
                    <td className={styles.dateCell}>{formatDateTime(sub.updatedAt)}</td>
                    <td>
                      <div className={tableStyles.rowActions}>
                        <button
                          type="button"
                          className={tableStyles.iconBtn}
                          onClick={() => setDetail(sub)}
                        >
                          Détails
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          <div className={styles.pagination}>
            <Button
              variant="ghost"
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={page === 0 || subscriptionsQuery.isFetching}
            >
              ← Précédent
            </Button>
            <span className={styles.paginationInfo}>
              Page {page + 1} / {totalPages}
            </span>
            <Button
              variant="ghost"
              onClick={() => setPage((p) => p + 1)}
              disabled={page + 1 >= totalPages || subscriptionsQuery.isFetching}
            >
              Suivant →
            </Button>
          </div>
        </Panel>
      )}

      <SubscriptionDetailModal
        sub={detail}
        onClose={() => setDetail(null)}
      />
    </>
  );
}

// ============================================================================
// DETAIL MODAL
// ============================================================================

function SubscriptionDetailModal({
  sub,
  onClose,
}: {
  sub: AdminSubscriptionDto | null;
  onClose: () => void;
}) {
  if (!sub) return null;

  return (
    <Modal
      open={true}
      onClose={onClose}
      title="Détail de la souscription"
      eyebrow={sub.planCode ?? "—"}
      footer={
        <Button variant="ghost" onClick={onClose}>
          Fermer
        </Button>
      }
    >
      <div className={styles.detailGrid}>
        <DetailRow label="Utilisateur">
          <strong>{sub.userEmail}</strong>
          {fullName(sub) !== "—" && <div className={styles.detailSub}>{fullName(sub)}</div>}
        </DetailRow>

        <DetailRow label="Plan">
          <strong>{sub.planName ?? sub.productId ?? "—"}</strong>
          {sub.moduleAccess && (
            <div className={styles.detailSub}>
              {MODULE_LABEL[sub.moduleAccess]} · {formatPrice(sub.planPrice)}
            </div>
          )}
        </DetailRow>

        <DetailRow label="Source">
          {SOURCE_LABEL[sub.source]}
        </DetailRow>

        <DetailRow label="Statut">
          <Tag tone={STATUS_TONE[sub.status]}>{STATUS_LABEL[sub.status]}</Tag>
          <span className={styles.detailSub}>
            {sub.autoRenew ? "Auto-renouvellement actif" : "Pas de renouvellement"}
          </span>
        </DetailRow>

        <DetailRow label="Début">
          {formatDateTime(sub.startsAt)}
        </DetailRow>

        <DetailRow label="Échéance">
          {formatDateTime(sub.endsAt)}
        </DetailRow>

        <DetailRow label="Dernière mise à jour">
          {formatDateTime(sub.updatedAt)}
        </DetailRow>

        <DetailRow label="Original transaction ID">
          <code className={styles.code}>{sub.originalTransactionId}</code>
          <span className={styles.detailSub}>
            Clé stable de réconciliation des renouvellements
          </span>
        </DetailRow>

        <DetailRow label="External transaction ID (dernière éval)">
          <code className={styles.code}>{sub.externalTransactionId ?? "—"}</code>
        </DetailRow>

        <DetailRow label="Product ID (store)">
          <code className={styles.code}>{sub.productId ?? "—"}</code>
        </DetailRow>
      </div>
    </Modal>
  );
}

function DetailRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className={styles.detailRow}>
      <div className={styles.detailLabel}>{label}</div>
      <div className={styles.detailValue}>{children}</div>
    </div>
  );
}
