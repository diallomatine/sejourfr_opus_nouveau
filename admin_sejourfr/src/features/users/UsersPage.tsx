import { useCallback } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { Link, useLocation } from "react-router-dom";
import { httpErrorMessage } from "../../api/http";
import { usersApi } from "../../api/usersApi";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Form";
import { PageHeader } from "../../components/ui/PageHeader";
import { Pagination } from "../../components/ui/Pagination";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { useClampPage, useUrlSearchInput } from "../../hooks/useUrlListState";
import { formatParisDate, formatParisDateTime } from "../../lib/dates";
import tableStyles from "../../components/ui/DataTable.module.css";
import { AccessStatusBadge } from "./components/AccessStatusBadge";
import { PAGE_SIZE_OPTIONS, USER_FILTERS, useUserListParams } from "./useUserListParams";
import styles from "./UsersPage.module.css";

const NUMBER_FORMAT = new Intl.NumberFormat("fr-FR");

/**
 * Console « Utilisateurs » (spec admin utilisateurs V2 §4) : retrouver un
 * compte et lire son accès en un coup d'œil. Tout ce qui s'affiche — statuts,
 * produit effectif, modules ouverts, prochaine fin — est servi par
 * `GET /api/admin/users` ; l'écran ne le recalcule jamais.
 */
export function UsersPage() {
  const { filters, hasActiveFilter, setFilter, setPage, setSize, resetFilters } = useUserListParams();
  const location = useLocation();

  const commitSearch = useCallback(
    (value: string | undefined) => setFilter("q", value, { replace: true }),
    [setFilter],
  );
  const [searchInput, setSearchInput] = useUrlSearchInput(filters.q ?? "", commitSearch);

  const usersQuery = useQuery({
    queryKey: ["adminUsers", "list", filters],
    queryFn: () => usersApi.list(filters),
    placeholderData: keepPreviousData,
  });

  const data = usersQuery.data;
  const isStale = usersQuery.isPlaceholderData;
  useClampPage(data?.totalPages, isStale, filters.page, setPage);

  const activeFilter = filters.filter ?? "ALL";

  const handleReset = () => {
    setSearchInput("");
    resetFilters();
  };

  return (
    <>
      <PageHeader eyebrow="§ 01 — Support" title="Utilis" emphasis="ateurs" />

      <Panel noPadding>
        <div className={styles.toolbar}>
          <label className={styles.filterLabel} htmlFor="users-search">
            Recherche (email, nom ou identifiant)
          </label>
          <Input
            id="users-search"
            type="search"
            placeholder="jean@exemple.fr, Dupont ou identifiant complet"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
          />
        </div>
        <div className={styles.chips} role="group" aria-label="Filtrer par accès">
          {USER_FILTERS.map((f) => (
            <button
              key={f.value}
              type="button"
              className={`${styles.chip} ${activeFilter === f.value ? styles.chipActive : ""}`}
              aria-pressed={activeFilter === f.value}
              onClick={() => setFilter("filter", f.value === "ALL" ? undefined : f.value)}
            >
              {f.label}
            </button>
          ))}
        </div>
      </Panel>

      {usersQuery.isPending && <Spinner label="Chargement..." />}

      {usersQuery.isError && !data && (
        <Panel>
          <div className={styles.error}>
            <span>Impossible de charger les utilisateurs : {httpErrorMessage(usersQuery.error)}</span>
            <Button variant="ghost" size="sm" onClick={() => usersQuery.refetch()}>
              Réessayer
            </Button>
          </div>
        </Panel>
      )}

      {data && (
        <Panel
          title="Comptes"
          sub={`${NUMBER_FORMAT.format(data.totalElements)} résultat${data.totalElements > 1 ? "s" : ""}`}
          actions={
            usersQuery.isFetching ? (
              <span className={styles.refreshing} role="status">
                Mise à jour…
              </span>
            ) : undefined
          }
          noPadding
        >
          {usersQuery.isError && (
            <div className={styles.inlineError} role="alert">
              <span>Actualisation impossible : {httpErrorMessage(usersQuery.error)}</span>
              <Button variant="ghost" size="sm" onClick={() => usersQuery.refetch()}>
                Réessayer
              </Button>
            </div>
          )}

          {data.totalElements === 0 ? (
            hasActiveFilter ? (
              <div className={styles.emptyWithAction}>
                <EmptyState
                  title="Aucun utilisateur ne correspond"
                  description="Modifiez la recherche ou le filtre."
                />
                <Button variant="ghost" size="sm" onClick={handleReset}>
                  Réinitialiser
                </Button>
              </div>
            ) : (
              <EmptyState title="Aucun utilisateur" />
            )
          ) : (
            <div className={`${tableStyles.tableWrap} ${isStale ? styles.stale : ""}`} aria-busy={isStale}>
              <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
                <thead>
                  <tr>
                    <th>Utilisateur</th>
                    <th>Accès</th>
                    <th>Produit effectif</th>
                    <th>Prochaine fin</th>
                    <th>Dernière activité</th>
                    <th>Inscription</th>
                    <th>Compte</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {data.content.map((u) => (
                    <tr key={u.id}>
                      <td>
                        <Link
                          to={`/users/${u.id}`}
                          state={{ listSearch: location.search }}
                          className={styles.userLink}
                        >
                          <strong>{u.displayName ?? u.email}</strong>
                          {u.displayName && <span className={styles.subLine}>{u.email}</span>}
                        </Link>
                      </td>
                      <td data-label="Accès">
                        <div className={styles.badges}>
                          {u.accesses.map((a) => (
                            <AccessStatusBadge
                              key={a.product}
                              status={a.status}
                              label={`${a.productLabel} · ${a.statusLabel}`}
                            />
                          ))}
                        </div>
                      </td>
                      <td data-label="Produit effectif">
                        <div>
                          <strong>{u.effectiveAccess.effectiveProductLabel}</strong>
                          <div className={styles.subLine}>
                            Modules : {u.effectiveAccess.openModulesLabel}
                          </div>
                        </div>
                      </td>
                      <td data-label="Prochaine fin" className={styles.dateCell}>
                        {u.nextEndLabel ?? "—"}
                      </td>
                      <td data-label="Dernière activité" className={styles.dateCell}>
                        {formatParisDateTime(u.lastActivityAt)}
                      </td>
                      <td data-label="Inscription" className={styles.dateCell}>
                        {formatParisDate(u.createdAt)}
                      </td>
                      <td data-label="Compte">
                        <div className={styles.accountCell}>
                          <span className={u.accountStatus === "DELETED" ? styles.deleted : ""}>
                            {u.accountStatusLabel}
                          </span>
                          {u.manualAccess && <span className={styles.manual}>Accès manuel</span>}
                        </div>
                      </td>
                      <td>
                        <div className={tableStyles.rowActions}>
                          <Link
                            to={`/users/${u.id}`}
                            state={{ listSearch: location.search }}
                            className={tableStyles.iconBtn}
                          >
                            Ouvrir →
                          </Link>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <Pagination
            page={data.page}
            size={data.size}
            totalElements={data.totalElements}
            totalPages={data.totalPages}
            onPageChange={(p) => setPage(p)}
            onSizeChange={setSize}
            sizeOptions={PAGE_SIZE_OPTIONS}
            busy={usersQuery.isFetching}
            itemLabel="utilisateurs"
          />
        </Panel>
      )}
    </>
  );
}
