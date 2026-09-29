import { Spinner } from "../../components/ui/Spinner";
import { ActivityCard } from "./components/ActivityCard";
import { ByTypeCard } from "./components/ByTypeCard";
import { FunnelCard } from "./components/FunnelCard";
import { KpiGrid } from "./components/KpiGrid";
import { RatiosCard } from "./components/RatiosCard";
import { RevenueCard } from "./components/RevenueCard";
import { SignupsCard } from "./components/SignupsCard";
import { SourcesCard } from "./components/SourcesCard";
import { SuiviFilters } from "./components/SuiviFilters";
import { formatRange } from "./dates";
import { useSuivi } from "./useSuivi";
import { useSuiviParams } from "./useSuiviParams";
import styles from "./suivi.module.css";

/**
 * Ecran « Suivi » (route `/dashboard`), template
 * docs/admin/sejourfr-suivi-dashboard.html. Un seul appel nourrit tout
 * l'ecran ; les bornes affichees sont celles SERVIES.
 */
export function SuiviPage() {
  const { period, from, to, query, update } = useSuiviParams();
  const { data, error, isPending, isPlaceholderData } = useSuivi(query);

  return (
    <div className={styles.root}>
      <div className={styles.topbar}>
        <div>
          <h1 className={styles.title}>Suivi</h1>
          <p className={styles.subtitle}>
            Comprendre rapidement ce qui attire, convertit et fait travailler les candidats.
          </p>
          {data && (
            <p className={styles.period}>
              {formatRange(data.window.from, data.window.to)} · heure de Paris
            </p>
          )}
        </div>
        <SuiviFilters
          period={period}
          from={from}
          to={to}
          type={query.type}
          platform={query.platform}
          source={query.source}
          includeInternal={query.includeInternal}
          availableSources={data?.filters.availableSources ?? []}
          servedFrom={data?.window.from ?? null}
          servedTo={data?.window.to ?? null}
          onChange={update}
        />
      </div>

      {error && (
        <div className={styles.error} role="alert">
          Impossible de charger le suivi : {error.message}
        </div>
      )}

      {isPending && !data && <Spinner label="Chargement du suivi…" />}

      {data && (
        <div className={isPlaceholderData ? styles.stale : ""}>
          <KpiGrid data={data} />

          <section className={styles.layout}>
            <FunnelCard data={data} />
            <RevenueCard data={data} />
          </section>

          <RatiosCard data={data} />

          <section className={styles.twoCol}>
            <ByTypeCard data={data} />
            <SignupsCard data={data} />
          </section>

          <section className={styles.twoCol}>
            <ActivityCard data={data} />
            <SourcesCard data={data} />
          </section>
        </div>
      )}
    </div>
  );
}
