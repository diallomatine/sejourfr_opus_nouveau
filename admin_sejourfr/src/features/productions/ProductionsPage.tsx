import { useCallback } from "react";
import type { MouseEvent, ReactNode } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { httpErrorMessage } from "../../api/http";
import { productionsApi } from "../../api/productionsApi";
import { Button } from "../../components/ui/Button";
import { Select } from "../../components/ui/Form";
import { Icon } from "../../components/ui/Icon";
import { PageHeader } from "../../components/ui/PageHeader";
import { Pagination } from "../../components/ui/Pagination";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useClampPage, useUrlSearchInput } from "../../hooks/useUrlListState";
import { formatParisDate, formatParisTime, parisToday } from "../../lib/dates";
import { NIVEAU_LABEL } from "../../lib/evaluation";
import tableStyles from "../../components/ui/DataTable.module.css";
import type { AdminProductionListItemDto } from "../../types/api";
import {
  ANNOTATION_OPTIONS,
  EPREUVE_OPTIONS,
  EPREUVE_SIGLE,
  NIVEAU_OPTIONS,
  PERIODE_OPTIONS,
  SIGNALEMENT_OPTIONS,
  SIGNALEMENT_TONE,
  SORT_OPTIONS,
  STATUT_OPTIONS,
  STATUT_TONE,
  TACHE_OPTIONS,
  shortId,
} from "./productionLabels";
import type { Option } from "./productionLabels";
import { PAGE_SIZE_OPTIONS, useProductionListParams } from "./useProductionListParams";
import styles from "./ProductionsPage.module.css";

const NUMBER_FORMAT = new Intl.NumberFormat("fr-FR");

/**
 * Console « Productions IA » : repérer une production EE/EO corrigée par IA,
 * l'ouvrir, comprendre son niveau, la signaler. Tout ce qui s'affiche est
 * servi par `GET /api/admin/productions` (pagination, filtres et tri serveur).
 */
export function ProductionsPage() {
  const {
    filters,
    period,
    hasActiveFilter,
    setFilter,
    setPeriod,
    setRange,
    setPage,
    setSize,
    resetFilters,
  } = useProductionListParams();
  const location = useLocation();
  const navigate = useNavigate();

  const commitSearch = useCallback(
    (value: string | undefined) => setFilter("q", value, { replace: true }),
    [setFilter],
  );
  const [searchInput, setSearchInput] = useUrlSearchInput(filters.q ?? "", commitSearch);

  const listQuery = useQuery({
    queryKey: ["adminProductions", "list", filters],
    queryFn: () => productionsApi.list(filters),
    placeholderData: keepPreviousData,
  });

  const data = listQuery.data;
  const isStale = listQuery.isPlaceholderData;
  useClampPage(data?.totalPages, isStale, filters.page, setPage);

  const listState = { listSearch: location.search };
  const today = parisToday();

  const handleReset = () => {
    setSearchInput("");
    resetFilters();
  };

  const openRow = (id: string) => (e: MouseEvent<HTMLTableRowElement>) => {
    if (e.target instanceof Element && e.target.closest("a, button")) return;
    navigate(`/productions-ia/${id}`, { state: listState });
  };

  const count = data
    ? `${NUMBER_FORMAT.format(data.totalElements)} production${data.totalElements > 1 ? "s" : ""}`
    : undefined;

  return (
    <>
      <PageHeader
        title="Productions IA"
        description="Contrôler les productions écrites et orales corrigées par IA, comprendre le niveau observé et signaler une évaluation incohérente. Consulter une production ne déclenche aucune évaluation."
      />

      <Panel
        title="Productions"
        sub={count}
        actions={
          listQuery.isFetching && data ? (
            <span className={styles.refreshing} role="status">
              Mise à jour…
            </span>
          ) : undefined
        }
        noPadding
      >
        <div className={styles.toolbar}>
          <label className={styles.search}>
            <span className="visually-hidden">
              Rechercher une production (email, identifiant utilisateur ou de production)
            </span>
            <Icon name="search" size={17} className={styles.searchIcon} />
            <input
              type="search"
              className={styles.searchInput}
              placeholder="Email, ID utilisateur ou ID production (complet)…"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
            />
          </label>
        </div>

        <div className={styles.filters}>
          <FilterSelect
            id="prod-epreuve"
            label="Épreuve"
            allLabel="Toutes"
            options={EPREUVE_OPTIONS}
            value={filters.epreuve ?? ""}
            onChange={(v) => setFilter("epreuve", v)}
          />
          <FilterSelect
            id="prod-tache"
            label="Tâche"
            allLabel="Toutes"
            options={TACHE_OPTIONS}
            value={filters.tache ? String(filters.tache) : ""}
            onChange={(v) => setFilter("tache", v)}
          />
          <FilterSelect
            id="prod-niveau"
            label="Niveau observé"
            allLabel="Tous"
            options={NIVEAU_OPTIONS}
            value={filters.niveau ?? ""}
            onChange={(v) => setFilter("niveau", v)}
          />
          <FilterSelect
            id="prod-statut"
            label="Statut IA"
            allLabel="Tous"
            options={STATUT_OPTIONS}
            value={filters.statut ?? ""}
            onChange={(v) => setFilter("statut", v)}
          />
          <FilterSelect
            id="prod-signalement"
            label="Signalement"
            allLabel="Toutes"
            options={SIGNALEMENT_OPTIONS}
            value={filters.signalement ?? ""}
            onChange={(v) => setFilter("signalement", v)}
          />
          <FilterSelect
            id="prod-annotation"
            label="Annotation humaine"
            allLabel="Toutes"
            options={ANNOTATION_OPTIONS}
            value={filters.annotation ?? ""}
            onChange={(v) => setFilter("annotation", v)}
          />
          <FilterSelect
            id="prod-periode"
            label="Période"
            allLabel="Toutes"
            options={PERIODE_OPTIONS}
            value={period}
            onChange={(v) => setPeriod(v ?? "", today)}
          />
          <FilterSelect
            id="prod-sort"
            label="Trier par"
            options={SORT_OPTIONS}
            value={filters.sort}
            onChange={(v) => setFilter("sort", v === "DATE_DESC" ? undefined : v)}
          />
        </div>

        <div className={styles.filtersFoot}>
          {period === "CUSTOM" && filters.from && filters.to && (
            <div className={styles.range}>
              <label className={styles.rangeLabel}>
                Du
                <input
                  type="date"
                  className={styles.dateInput}
                  value={filters.from}
                  max={filters.to}
                  onChange={(e) => {
                    const value = e.target.value;
                    if (value && filters.to && value <= filters.to) setRange(value, filters.to);
                  }}
                />
              </label>
              <label className={styles.rangeLabel}>
                au
                <input
                  type="date"
                  className={styles.dateInput}
                  value={filters.to}
                  min={filters.from}
                  max={today}
                  onChange={(e) => {
                    const value = e.target.value;
                    if (value && filters.from && value >= filters.from) setRange(filters.from, value);
                  }}
                />
              </label>
            </div>
          )}
          <label className={styles.checkbox}>
            <input
              type="checkbox"
              checked={filters.includeInternal === true}
              onChange={(e) => setFilter("internes", e.target.checked ? "1" : undefined)}
            />
            Inclure les comptes internes
          </label>
          {hasActiveFilter && (
            <Button variant="ghost" size="sm" onClick={handleReset}>
              Réinitialiser les filtres
            </Button>
          )}
        </div>

        {listQuery.isPending && (
          <div className={styles.loading}>
            <Spinner label="Chargement des productions…" />
          </div>
        )}

        {listQuery.isError && (
          <div className={styles.inlineError} role="alert">
            <span>
              {data ? "Actualisation impossible" : "Impossible de charger les productions"} :{" "}
              {httpErrorMessage(listQuery.error)}
            </span>
            <Button variant="default" size="sm" onClick={() => listQuery.refetch()}>
              Réessayer
            </Button>
          </div>
        )}

        {data &&
          (data.totalElements === 0 ? (
            hasActiveFilter ? (
              <div className={styles.emptyWithAction}>
                <EmptyState
                  title="Aucune production ne correspond"
                  description="Modifiez la recherche ou les filtres. La recherche par identifiant attend un UUID complet."
                />
                <Button variant="default" size="sm" onClick={handleReset}>
                  Réinitialiser
                </Button>
              </div>
            ) : (
              <EmptyState
                title="Aucune production"
                description="Aucune production EE/EO corrigée par IA (comptes internes exclus)."
              />
            )
          ) : (
            <div className={`${tableStyles.tableWrap} ${isStale ? styles.stale : ""}`} aria-busy={isStale}>
              <table className={`${tableStyles.table} ${tableStyles.cardTable} ${styles.table}`}>
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Candidat</th>
                    <th>Épreuve</th>
                    <th>Tâche</th>
                    <th>Niveau observé</th>
                    <th>Statut IA</th>
                    <th>Signalement</th>
                    <th>
                      <span className="visually-hidden">Ouvrir</span>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.content.map((row) => (
                    <ProductionRow
                      key={row.id}
                      row={row}
                      listState={listState}
                      onClick={openRow(row.id)}
                    />
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
            busy={listQuery.isFetching}
            itemLabel="productions"
          />
        )}
      </Panel>
    </>
  );
}

function ProductionRow({
  row,
  listState,
  onClick,
}: {
  row: AdminProductionListItemDto;
  listState: { listSearch: string };
  onClick: (e: MouseEvent<HTMLTableRowElement>) => void;
}) {
  const href = `/productions-ia/${row.id}`;
  return (
    <tr className={styles.row} onClick={onClick}>
      <td>
        <Link to={href} state={listState} className={styles.mainLink}>
          {formatParisDate(row.submittedAt)}
        </Link>
        <span className={styles.subLine}>
          {formatParisTime(row.submittedAt)} · <span className={styles.mono}>{shortId(row.id)}</span>
        </span>
      </td>
      <td data-label="Candidat">
        <div className={styles.candidate}>
          <span className={styles.email}>{row.userEmail}</span>
          <span className={`${styles.subLine} ${styles.mono}`}>{shortId(row.userId)}</span>
          {row.userInternal && (
            <span className={styles.inlineTag}>
              <Tag tone="neutral">Compte interne</Tag>
            </span>
          )}
        </div>
      </td>
      <td data-label="Épreuve">
        <Tag tone="info">{EPREUVE_SIGLE[row.epreuve] ?? row.epreuve}</Tag>
        {row.source === "REALTIME" && <span className={styles.subLine}>Temps réel</span>}
      </td>
      <td data-label="Tâche">
        <Cell main={`Tâche ${row.tache}`} sub={row.contexteLabel} />
      </td>
      <td data-label="Niveau observé">
        {row.niveauObserve ? (
          <span className={styles.level}>{NIVEAU_LABEL[row.niveauObserve]}</span>
        ) : (
          <span className={styles.dash} title="Aucun niveau (en cours, échec ou non évaluable)">
            —
          </span>
        )}
      </td>
      <td data-label="Statut IA">
        <Tag tone={STATUT_TONE[row.statutIa]} dot>
          {row.statutIaLabel}
        </Tag>
        {row.annotee && <span className={styles.subLine}>Annotée</span>}
      </td>
      <td data-label="Signalement">
        {row.etatSignalement === "AUCUN" ? (
          <span className={styles.dash} title={row.etatSignalementLabel}>
            —
          </span>
        ) : (
          <Tag tone={SIGNALEMENT_TONE[row.etatSignalement]} dot>
            {row.etatSignalementLabel}
          </Tag>
        )}
      </td>
      <td className={styles.actionCell}>
        <Link
          to={href}
          state={listState}
          className={styles.rowAction}
          aria-label={`Ouvrir la production ${shortId(row.id)}`}
        >
          <span className={styles.rowActionText}>Ouvrir la production</span>
          <Icon name="chevronRight" size={16} />
        </Link>
      </td>
    </tr>
  );
}

function Cell({ main, sub }: { main: ReactNode; sub?: ReactNode }) {
  return (
    <div className={styles.cell}>
      <span>{main}</span>
      {sub && <span className={styles.subLine}>{sub}</span>}
    </div>
  );
}

function FilterSelect<T extends string>({
  id,
  label,
  allLabel,
  options,
  value,
  onChange,
}: {
  id: string;
  label: string;
  /** Absent : pas d'option « toutes » (le tri a toujours une valeur). */
  allLabel?: string;
  options: readonly Option<T>[];
  value: T | "";
  onChange: (value: T | undefined) => void;
}) {
  return (
    <div className={`${styles.filterGroup} ${value && allLabel ? styles.filterOn : ""}`}>
      <label className={styles.filterLabel} htmlFor={id}>
        {label}
      </label>
      <Select
        id={id}
        value={value}
        onChange={(e) => {
          const next = options.find((o) => o.value === e.target.value);
          onChange(next?.value);
        }}
      >
        {allLabel && <option value="">{allLabel}</option>}
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </Select>
    </div>
  );
}
