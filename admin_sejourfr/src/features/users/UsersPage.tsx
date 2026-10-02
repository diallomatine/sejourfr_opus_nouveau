import { useCallback } from "react";
import type { MouseEvent } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { httpErrorMessage } from "../../api/http";
import { usersApi } from "../../api/usersApi";
import { Avatar } from "../../components/ui/Avatar";
import { Button } from "../../components/ui/Button";
import { Chips } from "../../components/ui/Chips";
import { Icon } from "../../components/ui/Icon";
import { PageHeader } from "../../components/ui/PageHeader";
import { Pagination } from "../../components/ui/Pagination";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useClampPage, useUrlSearchInput } from "../../hooks/useUrlListState";
import { formatParisDate, formatParisDateTime } from "../../lib/dates";
import tableStyles from "../../components/ui/DataTable.module.css";
import type { AdminUserFilter } from "../../types/api";
import { ACCESS_STATUS_TONE } from "./accessTones";
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
  const navigate = useNavigate();

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

  const activeFilter: AdminUserFilter = filters.filter ?? "ALL";
  const listState = { listSearch: location.search };

  const handleReset = () => {
    setSearchInput("");
    resetFilters();
  };

  const openRow = (id: string) => (e: MouseEvent<HTMLTableRowElement>) => {
    if (e.target instanceof Element && e.target.closest("a, button")) return;
    navigate(`/users/${id}`, { state: listState });
  };

  const count = data
    ? `${NUMBER_FORMAT.format(data.totalElements)} utilisateur${data.totalElements > 1 ? "s" : ""}`
    : undefined;

  return (
    <>
      <PageHeader
        title="Gestion des utilisateurs"
        description="Retrouver un compte, comprendre son accès effectif (produits Civique et Intégral) et le dépanner. Les achats restent en lecture seule."
      />

      <Panel
        title="Utilisateurs"
        sub={count}
        actions={
          usersQuery.isFetching && data ? (
            <span className={styles.refreshing} role="status">
              Mise à jour…
            </span>
          ) : undefined
        }
        noPadding
      >
        <div className={styles.toolbar}>
          <label className={styles.search}>
            <span className="visually-hidden">Rechercher un utilisateur (email, nom ou identifiant)</span>
            <Icon name="search" size={17} className={styles.searchIcon} />
            <input
              type="search"
              className={styles.searchInput}
              placeholder="Email, nom ou identifiant complet…"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
            />
          </label>
        </div>

        <div className={styles.filters}>
          <Chips
            label="Filtrer par accès"
            options={USER_FILTERS}
            value={activeFilter}
            onChange={(value) => setFilter("filter", value === "ALL" ? undefined : value)}
          />
        </div>

        {usersQuery.isPending && (
          <div className={styles.loading}>
            <Spinner label="Chargement des utilisateurs…" />
          </div>
        )}

        {usersQuery.isError && (
          <div className={styles.inlineError} role="alert">
            <span>
              {data ? "Actualisation impossible" : "Impossible de charger les utilisateurs"} :{" "}
              {httpErrorMessage(usersQuery.error)}
            </span>
            <Button variant="default" size="sm" onClick={() => usersQuery.refetch()}>
              Réessayer
            </Button>
          </div>
        )}

        {data &&
          (data.totalElements === 0 ? (
            hasActiveFilter ? (
              <div className={styles.emptyWithAction}>
                <EmptyState title="Aucun utilisateur ne correspond" description="Modifiez la recherche ou le filtre." />
                <Button variant="default" size="sm" onClick={handleReset}>
                  Réinitialiser
                </Button>
              </div>
            ) : (
              <EmptyState title="Aucun utilisateur" />
            )
          ) : (
            <div className={`${tableStyles.tableWrap} ${isStale ? styles.stale : ""}`} aria-busy={isStale}>
              <table className={`${tableStyles.table} ${tableStyles.cardTable} ${styles.table}`}>
                <thead>
                  <tr>
                    <th>Utilisateur</th>
                    <th>Accès</th>
                    <th>Produit effectif</th>
                    <th>Prochaine fin</th>
                    <th>Dernière activité</th>
                    <th className={styles.signupCol}>Inscription</th>
                    <th>
                      <span className="visually-hidden">Ouvrir</span>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.content.map((u) => (
                    <tr key={u.id} className={styles.row} onClick={openRow(u.id)}>
                      <td>
                        <div className={styles.userCell}>
                          <Avatar name={u.displayName} email={u.email} size="sm" />
                          <div className={styles.userMain}>
                            <Link to={`/users/${u.id}`} state={listState} className={styles.userLink}>
                              {u.displayName ?? u.email}
                            </Link>
                            {u.displayName && <span className={styles.subLine}>{u.email}</span>}
                            <span className={`${styles.subLine} ${styles.signupInline}`}>
                              Inscrit le {formatParisDate(u.createdAt)}
                            </span>
                            {u.accountStatus !== "ACTIVE" && (
                              <span className={styles.accountTag}>
                                <Tag tone="danger">Compte {u.accountStatusLabel.toLowerCase()}</Tag>
                              </span>
                            )}
                          </div>
                        </div>
                      </td>
                      <td data-label="Accès">
                        <div className={styles.badges}>
                          {u.accesses.map((a) => (
                            <Tag key={a.product} tone={ACCESS_STATUS_TONE[a.status]} dot>
                              {a.productLabel} · {a.statusLabel}
                            </Tag>
                          ))}
                        </div>
                      </td>
                      <td data-label="Produit effectif">
                        <div className={styles.effective}>
                          <strong>{u.effectiveAccess.effectiveProductLabel}</strong>
                          <span className={styles.subLine}>Modules : {u.effectiveAccess.openModulesLabel}</span>
                          {u.manualAccess && (
                            <span className={styles.manual}>
                              <Tag tone="info" dot>
                                Accès manuel
                              </Tag>
                            </span>
                          )}
                        </div>
                      </td>
                      <td data-label="Prochaine fin" className={styles.muted}>
                        {u.nextEndLabel ?? "—"}
                      </td>
                      <td data-label="Dernière activité" className={styles.muted}>
                        {formatParisDateTime(u.lastActivityAt)}
                      </td>
                      <td data-label="Inscription" className={`${styles.muted} ${styles.signupCol}`}>
                        {formatParisDate(u.createdAt)}
                      </td>
                      <td className={styles.actionCell}>
                        <Link
                          to={`/users/${u.id}`}
                          state={listState}
                          className={styles.rowAction}
                          aria-label={`Ouvrir la fiche de ${u.displayName ?? u.email}`}
                        >
                          <span className={styles.rowActionText}>Ouvrir la fiche</span>
                          <Icon name="chevronRight" size={16} />
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}

        {data && (
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
        )}
      </Panel>
    </>
  );
}
