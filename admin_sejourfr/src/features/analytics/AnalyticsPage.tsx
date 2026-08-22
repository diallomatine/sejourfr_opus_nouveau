import { useEffect, useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { analyticsApi } from "../../api/analyticsApi";
import type { AnalyticsFilters, AnalyticsRange } from "../../types/api";
import { Spinner } from "../../components/ui/Spinner";
import styles from "./analytics.module.css";
import { EmptyBlock } from "./components/Card";
import { Menu, Segmented } from "./components/Controls";
import { Drawer } from "./components/Drawer";
import { Icon } from "./components/Icon";
import { StepDetail } from "./components/StepDetail";
import { formatRange, formatShortRange, parisToday } from "./dates";
import { hasAnyData } from "./derive";
import { PLATFORM_OPTIONS, STEP_LABELS, TABS, type TabId } from "./labels";
import { PERIOD_PRESETS, choiceId, resolveRange, type PeriodChoice } from "./period";
import { AcquisitionTab } from "./tabs/AcquisitionTab";
import { ConversionTab } from "./tabs/ConversionTab";
import { DiagnosticTab } from "./tabs/DiagnosticTab";
import { OverviewTab } from "./tabs/OverviewTab";
import { UsersTab } from "./tabs/UsersTab";
import { EMPTY_FILTERS, readState, writeState } from "./storage";
import type { DetailTarget, TabProps } from "./types";

interface Option {
  id: string;
  label: string;
}

/**
 * Les listes de filtres se lisent sur la reponse NON FILTREE de la meme
 * periode : des qu'un filtre est pose, la reponse filtree ne contient plus que
 * sa propre valeur, et le menu se viderait apres le premier choix.
 *
 * Sans filtre actif, cette requete porte exactement la meme cle que la
 * principale : TanStack la sert depuis le cache, donc zero appel de plus. Le
 * seul aller-retour supplementaire arrive quand un filtre est pose — le moment
 * ou l'on a justement besoin de la liste complete.
 */
function useDimensionOptions(filters: AnalyticsFilters, range: AnalyticsRange) {
  const unfiltered = useQuery({
    queryKey: ["analytics", range, EMPTY_FILTERS],
    queryFn: ({ signal }) => analyticsApi.get(range, EMPTY_FILTERS, signal),
    staleTime: 60_000,
  });

  return useMemo(() => {
    const data = unfiltered.data;
    const withSelected = (options: Option[], selected: string | null): Option[] => {
      if (!selected || options.some((option) => option.id === selected)) {
        return options;
      }
      return [...options, { id: selected, label: selected }];
    };

    return {
      sources: withSelected(
        data?.sources.map((source) => ({ id: source.id, label: source.label })) ?? [],
        filters.source,
      ),
      countries: withSelected(
        data?.countries.map((country) => ({
          id: country.id,
          label: country.label,
        })) ?? [],
        filters.country,
      ),
      devices: withSelected(
        data?.devices.map((device) => ({ id: device.id, label: device.label })) ?? [],
        filters.device,
      ),
    };
  }, [unfiltered.data, filters.source, filters.country, filters.device]);
}

export function AnalyticsPage() {
  const initial = useMemo(() => readState(), []);
  const [tab, setTab] = useState<TabId>(initial.tab);
  const [period, setPeriod] = useState<PeriodChoice>(initial.period);
  const [compare, setCompare] = useState(initial.compare);
  const [filters, setFilters] = useState<AnalyticsFilters>(initial.filters);
  const [detail, setDetail] = useState<DetailTarget | null>(null);
  const [customFrom, setCustomFrom] = useState(
    period.kind === "custom" ? period.from : parisToday(),
  );
  const [customTo, setCustomTo] = useState(
    period.kind === "custom" ? period.to : parisToday(),
  );

  useEffect(() => {
    writeState({ tab, period, compare, filters });
  }, [tab, period, compare, filters]);

  const range = useMemo(() => resolveRange(period), [period]);

  const query = useQuery({
    queryKey: ["analytics", range, filters],
    queryFn: ({ signal }) => analyticsApi.get(range, filters, signal),
    staleTime: 60_000,
  });

  const data = query.data;
  const options = useDimensionOptions(filters, range);

  /* Un device implique deja sa plateforme : cumuler les deux rendrait des
     resultats vides sans que l'ecran dise pourquoi. */
  const setFilter = (key: keyof AnalyticsFilters, value: string | null) => {
    setFilters((current) => ({
      ...current,
      [key]: value,
      ...(key === "device" && value ? { platform: null } : {}),
      ...(key === "platform" && value ? { device: null } : {}),
    }));
  };

  const activeFilters = Object.values(filters).filter(Boolean).length;
  const selectedSource = data?.sources.find(
    (source) => source.id === filters.source,
  );

  const tabProps: TabProps | null = data
    ? {
        data,
        prev: compare ? data.prev : null,
        compare,
        filters,
        setFilter,
        go: setTab,
        openDetail: setDetail,
      }
    : null;

  return (
    <div className={styles.root}>
      <header className={styles.top}>
        <div className={styles.topRow}>
          <h1 className={styles.title}>
            Analytics <em className={styles.titleEm}>acquisition</em>
          </h1>
          <div className={styles.spacer} />
          <div className={styles.filters}>
            <Segmented
              ariaLabel="Période"
              options={PERIOD_PRESETS.map((preset) => ({
                id: preset.id,
                label: preset.label,
              }))}
              value={choiceId(period)}
              onChange={(id) => {
                const preset = PERIOD_PRESETS.find((entry) => entry.id === id);
                if (preset) setPeriod(preset.choice);
              }}
            />
            <span className={styles.dateFields}>
              <input
                type="date"
                aria-label="Début de la période"
                value={customFrom}
                max={customTo}
                onChange={(event) => {
                  setCustomFrom(event.target.value);
                  if (event.target.value && customTo) {
                    setPeriod({
                      kind: "custom",
                      from: event.target.value,
                      to: customTo,
                    });
                  }
                }}
              />
              <span>→</span>
              <input
                type="date"
                aria-label="Fin de la période"
                value={customTo}
                min={customFrom}
                onChange={(event) => {
                  setCustomTo(event.target.value);
                  if (customFrom && event.target.value) {
                    setPeriod({
                      kind: "custom",
                      from: customFrom,
                      to: event.target.value,
                    });
                  }
                }}
              />
            </span>
            <button
              type="button"
              className={`${styles.chip} ${compare ? styles.chipOn : ""}`}
              aria-pressed={compare}
              onClick={() => setCompare(!compare)}
            >
              Période précédente
            </button>
          </div>
        </div>

        <div className={styles.topRow}>
          <span className={styles.rangeLine}>
            <span className={styles.rangeIcon}>
              <Icon name="calendar" size={15} />
            </span>
            {data ? formatRange(data.from, data.to) : "Période en cours de calcul"}
          </span>
          {compare && data?.prevFrom && data.prevTo && (
            <span className={styles.rangeCompare}>
              comparé au {formatShortRange(data.prevFrom, data.prevTo)}
            </span>
          )}
          <div className={styles.spacer} />
          <div className={styles.filters}>
            <span className={styles.filtersIcon}>
              <Icon name="filter" size={14} />
            </span>
            <Menu
              label="Source"
              allLabel="Toutes les sources"
              value={filters.source}
              options={options.sources}
              onChange={(value) => setFilter("source", value)}
            />
            <Menu
              label="Pays"
              allLabel="Tous les pays"
              value={filters.country}
              options={options.countries}
              onChange={(value) => setFilter("country", value)}
            />
            <Menu
              label="Device"
              allLabel="Tous les devices"
              value={filters.device}
              options={options.devices}
              onChange={(value) => setFilter("device", value)}
            />
            <Segmented
              small
              ariaLabel="Plateforme"
              options={PLATFORM_OPTIONS}
              value={filters.platform ?? "all"}
              onChange={(value) =>
                setFilter("platform", value === "all" ? null : value)
              }
            />
            {activeFilters > 0 && (
              <button
                type="button"
                className={`${styles.chip} ${styles.chipQuiet}`}
                onClick={() => setFilters(EMPTY_FILTERS)}
              >
                Réinitialiser
                <Icon name="close" size={12} />
              </button>
            )}
          </div>
        </div>

        <div className={styles.tabs} role="tablist">
          {TABS.map((entry) => (
            <button
              key={entry.id}
              type="button"
              role="tab"
              className={styles.tab}
              aria-selected={tab === entry.id}
              disabled={entry.soon}
              onClick={() => !entry.soon && setTab(entry.id)}
            >
              {entry.label}
              {entry.soon && <span className={styles.tabSoon}>bientôt</span>}
            </button>
          ))}
        </div>
      </header>

      <main className={styles.page}>
        {query.isLoading && <Spinner label="Chargement des mesures..." />}

        {query.isError && (
          <EmptyBlock error title="Les mesures n'ont pas pu être chargées.">
            {(query.error as Error).message}
          </EmptyBlock>
        )}

        {data && tabProps && (
          <>
            {filters.source && (
              <div className={styles.filteredBanner}>
                <span className={styles.lbl}>Vue filtrée</span>
                <span className={styles.filteredText}>
                  Tous les chiffres ci-dessous ne concernent que{" "}
                  <b>{selectedSource?.label ?? filters.source}</b>.
                </span>
                <button
                  type="button"
                  className={styles.chip}
                  onClick={() => setFilter("source", null)}
                >
                  Retirer le filtre
                  <Icon name="close" size={12} />
                </button>
              </div>
            )}

            {!hasAnyData(data.total) ? (
              <EmptyBlock>
                Aucun visiteur, aucune inscription et aucun paiement n'ont été
                mesurés {formatRange(data.from, data.to)}
                {activeFilters > 0 ? " avec ces filtres" : ""}. Élargissez la
                période plutôt que de lire des zéros comme des mesures.
              </EmptyBlock>
            ) : (
              <>
                {tab === "overview" && <OverviewTab {...tabProps} />}
                {tab === "acquisition" && <AcquisitionTab {...tabProps} />}
                {tab === "diagnostic" && <DiagnosticTab {...tabProps} />}
                {tab === "conversion" && <ConversionTab {...tabProps} />}
                {tab === "users" && <UsersTab {...tabProps} />}
              </>
            )}
          </>
        )}
      </main>

      {detail && data && (
        <Drawer
          title={STEP_LABELS[detail.stepKey] ?? detail.label ?? "Détail"}
          sub={`${formatRange(data.from, data.to)}${
            selectedSource ? ` · ${selectedSource.label}` : ""
          }`}
          onClose={() => setDetail(null)}
        >
          <StepDetail
            stepKey={detail.stepKey}
            data={data}
            prev={compare ? data.prev : null}
            compare={compare}
          />
        </Drawer>
      )}
    </div>
  );
}
