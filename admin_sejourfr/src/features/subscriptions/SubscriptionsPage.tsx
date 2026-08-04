import { useEffect, useMemo, useState } from "react";
import {
  useMutation,
  useQuery,
  useQueryClient,
  keepPreviousData,
} from "@tanstack/react-query";
import { HttpError } from "../../api/http";
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
  CancelSubscriptionResponse,
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
          <div className={styles.error}>
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
            <div className={tableStyles.tableWrap}>
              <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
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
                      <td data-label="Client">
                        <div>
                          <strong>{sub.userEmail}</strong>
                          <div className={styles.subLine}>{fullName(sub)}</div>
                        </div>
                      </td>
                      <td data-label="Plan">
                        <div>
                          <strong>{sub.planName ?? sub.productId ?? "—"}</strong>
                          {sub.moduleAccess && (
                            <div className={styles.subLine}>
                              <Tag
                                tone={sub.moduleAccess === "CIVIQUE" ? "csp" : "premium"}
                              >
                                {MODULE_LABEL[sub.moduleAccess] ?? sub.moduleAccess}
                              </Tag>
                            </div>
                          )}
                        </div>
                      </td>
                      <td data-label="Source">
                        <Tag tone={SOURCE_TONE[sub.source] ?? "muted"}>{sub.source}</Tag>
                      </td>
                      <td data-label="Statut">
                        <div>
                          <Tag tone={STATUS_TONE[sub.status] ?? "muted"}>
                            {STATUS_LABEL[sub.status] ?? sub.status}
                          </Tag>
                          {!sub.autoRenew && sub.status === "ACTIVE" && (
                            <div className={styles.cancelHint}>auto-renew off</div>
                          )}
                        </div>
                      </td>
                      <td data-label="Échéance">{formatDate(sub.endsAt)}</td>
                      <td data-label="Maj" className={styles.dateCell}>
                        {formatDateTime(sub.updatedAt)}
                      </td>
                      <td data-label="Action">
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
            </div>
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
  const queryClient = useQueryClient();
  const [lastResult, setLastResult] = useState<CancelSubscriptionResponse | null>(
    null,
  );
  const [rtInput, setRtInput] = useState("");
  const [rtSaved, setRtSaved] = useState<number | null>(null);

  // Reset l'état de feedback quand on bascule sur un autre abo (ou qu'on
  // referme/rouvre la modal sur le même).
  useEffect(() => {
    setLastResult(null);
    setRtSaved(null);
    setRtInput(sub ? String(sub.realtimeEoSessionsRemaining) : "");
  }, [sub]);

  const cancelMutation = useMutation({
    mutationFn: (id: string) => subscriptionsApi.cancel(id),
    onSuccess: (res) => {
      setLastResult(res);
      queryClient.invalidateQueries({ queryKey: ["adminSubscriptions"] });
    },
  });

  const setRealtimeMutation = useMutation({
    mutationFn: (remaining: number) =>
      subscriptionsApi.setRealtimeSessions(sub!.id, remaining),
    onSuccess: (dto) => {
      setRtSaved(dto.realtimeEoSessionsRemaining);
      setRtInput(String(dto.realtimeEoSessionsRemaining));
      queryClient.invalidateQueries({ queryKey: ["adminSubscriptions"] });
    },
  });

  if (!sub) return null;

  const isCancellable =
    sub.status === "ACTIVE" || sub.status === "TRIAL" || sub.status === "IN_GRACE";
  const isDone = lastResult?.action === "DONE";

  const handleCancel = () => {
    const msg =
      sub.source === "STRIPE"
        ? `Résilier l'abonnement Stripe de ${sub.userEmail} ?\n\n` +
          `Stripe sera appelée pour poser cancel_at_period_end=true. ` +
          `L'accès Premium restera ouvert jusqu'à l'échéance.`
        : `Tenter la résiliation de l'abonnement ${sub.source} de ${sub.userEmail} ?\n\n` +
          `${sub.source === "APPLE" ? "Apple" : "Google"} n'autorise pas ` +
          `l'annulation côté serveur — l'API renverra l'URL de gestion du ` +
          `store à transmettre au client.`;
    if (!window.confirm(msg)) return;
    cancelMutation.mutate(sub.id);
  };

  // `sub` est l'instantané pris au clic sur « Détails » : après un
  // enregistrement, le solde de référence est celui renvoyé par le PATCH,
  // sinon le bouton resterait actif sur une valeur déjà posée.
  const rtCurrent = rtSaved ?? sub.realtimeEoSessionsRemaining;
  const rtParsed = Number.parseInt(rtInput, 10);
  const rtValid = Number.isFinite(rtParsed) && rtParsed >= 0;
  const rtChanged = rtValid && rtParsed !== rtCurrent;
  const handleSaveRealtime = () => {
    if (rtValid) setRealtimeMutation.mutate(rtParsed);
  };

  const copyRedirect = async (url: string) => {
    try {
      await navigator.clipboard.writeText(url);
    } catch {
      // Pas de toast UI ici — l'URL reste visible dans le bandeau.
    }
  };

  return (
    <Modal
      open={true}
      onClose={onClose}
      title="Détail de la souscription"
      eyebrow={sub.planCode ?? "—"}
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Fermer
          </Button>
          {!isDone && (
            <Button
              variant="danger"
              onClick={handleCancel}
              disabled={!isCancellable || cancelMutation.isPending}
            >
              {cancelMutation.isPending
                ? "Résiliation…"
                : isCancellable
                  ? "Résilier l'abonnement"
                  : "Non résiliable"}
            </Button>
          )}
        </>
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

        <DetailRow label="Sessions temps réel (EO)">
          <div className={styles.rtEditor}>
            <Input
              type="number"
              min={0}
              value={rtInput}
              onChange={(e) => setRtInput(e.target.value)}
              className={styles.rtInput}
            />
            <Button
              variant="primary"
              size="sm"
              onClick={handleSaveRealtime}
              disabled={!rtChanged || setRealtimeMutation.isPending}
            >
              {setRealtimeMutation.isPending ? "…" : "Enregistrer"}
            </Button>
          </div>
          <span className={styles.detailSub}>
            Solde de sessions examinateur vocal du pass — débité à chaque
            session, cumulé à la prolongation. Ajustable ici (support).
          </span>
          {rtSaved !== null && (
            <span className={`${styles.detailSub} ${styles.rtOk}`}>
              Solde mis à jour : {rtSaved}
            </span>
          )}
          {setRealtimeMutation.isError && (
            <span className={`${styles.detailSub} ${styles.rtError}`}>
              {setRealtimeMutation.error instanceof HttpError
                ? setRealtimeMutation.error.payload?.message ??
                  setRealtimeMutation.error.message
                : (setRealtimeMutation.error as Error).message}
            </span>
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

      {cancelMutation.isError && (
        <div className={`${styles.cancelFeedback} ${styles.cancelFeedbackError}`}>
          <strong>Erreur :</strong>{" "}
          {cancelMutation.error instanceof HttpError
            ? cancelMutation.error.payload?.message ?? cancelMutation.error.message
            : (cancelMutation.error as Error).message}
        </div>
      )}

      {lastResult?.action === "DONE" && (
        <div className={`${styles.cancelFeedback} ${styles.cancelFeedbackDone}`}>
          <strong>Résiliation enregistrée.</strong>
          <span>{lastResult.message}</span>
        </div>
      )}

      {lastResult?.action === "REDIRECT" && lastResult.redirectUrl && (
        <div className={`${styles.cancelFeedback} ${styles.cancelFeedbackRedirect}`}>
          <strong>Action requise côté client.</strong>
          <span>{lastResult.message}</span>
          <div className={styles.cancelFeedbackUrl}>
            <code className={styles.code}>{lastResult.redirectUrl}</code>
            <Button
              variant="ghost"
              onClick={() => copyRedirect(lastResult.redirectUrl!)}
            >
              Copier
            </Button>
          </div>
        </div>
      )}
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
