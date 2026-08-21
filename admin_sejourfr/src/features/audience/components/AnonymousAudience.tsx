import type {
  PageViewDailyStat,
  PageViewSourceStat,
  PageViewStatsResponse,
} from "../../../types/api";
import { Spinner } from "../../../components/ui/Spinner";
import { fillDays } from "../dates";
import { barWidth, count, percent, ratio } from "../insights";
import { EVENT_LABELS, EVENT_ORDER, sourceLabel } from "../labels";
import { DailyChart } from "./DailyChart";
import panels from "./panels.module.css";
import styles from "./AnonymousAudience.module.css";

/**
 * Compteur de VUES de pages, sans cookie ni identifiant : ces nombres ne se
 * comparent pas à ceux du funnel, qui compte des comptes. L'écran garde donc
 * les deux natures séparées et étiquetées.
 */
export function AnonymousAudience({
  paths,
  path,
  onPathChange,
  stats,
  isPending,
  error,
}: {
  paths: string[];
  path: string;
  onPathChange: (path: string) => void;
  stats: PageViewStatsResponse | undefined;
  isPending: boolean;
  error: Error | null;
}) {
  return (
    <div className={styles.wrap}>
      {paths.length > 1 && (
        <div className={styles.controls}>
          <span className={styles.controlLabel}>Page suivie</span>
          <select
            className={styles.select}
            value={path}
            onChange={(e) => onPathChange(e.target.value)}
          >
            {paths.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </div>
      )}

      {isPending && <Spinner label="Chargement de l'audience…" />}

      {error && (
        <p className={`${panels.state} ${panels.stateError}`}>
          <strong className={panels.stateTitle}>
            Audience anonyme indisponible
          </strong>
          {error.message}
        </p>
      )}

      {stats && <PageStats stats={stats} />}

      <p className={panels.note}>
        La provenance vient du paramètre <code>?utm_source=</code> du lien
        partagé, avec le référent en repli. Aucun cookie, aucun stockage local,
        aucune adresse IP : c&apos;est ce qui permet de se passer de bandeau de
        consentement, au prix de ne mesurer que des vues.
      </p>
    </div>
  );
}

function PageStats({ stats }: { stats: PageViewStatsResponse }) {
  const totalEvents = Object.values(stats.events).reduce(
    (total, occurrences) => total + (occurrences ?? 0),
    0,
  );

  if (totalEvents === 0) {
    return (
      <p className={panels.state}>
        <strong className={panels.stateTitle}>Aucune vue enregistrée</strong>
        Rien n&apos;a été compté sur <code>{stats.path}</code> pendant la période
        retenue. Soit la page n&apos;a pas été ouverte, soit la mesure y est plus
        récente que la période choisie — élargissez la fenêtre pour trancher.
      </p>
    );
  }

  return (
    <>
      <div className={styles.tiles}>
        <Tile label="Vues" value={count(stats.views)} />
        <Tile label="Clics sur le CTA" value={count(stats.ctaClicks)} />
        <Tile
          label="Taux de clic"
          value={percent(ratio(stats.ctaClicks, stats.views))}
        />
      </div>

      <div className={`${panels.panel} ${panels.quiet}`}>
        <div className={panels.head}>
          <h4 className={`${panels.title} ${panels.titleQuiet}`}>
            Événements de page
          </h4>
        </div>
        <ul className={styles.events}>
          {EVENT_ORDER.filter((event) => (stats.events[event] ?? 0) > 0).map(
            (event) => (
              <li key={event}>
                <span>{EVENT_LABELS[event]}</span>
                <strong>{count(stats.events[event] ?? 0)}</strong>
              </li>
            ),
          )}
        </ul>
      </div>

      <div className={`${panels.panel} ${panels.quiet}`}>
        <div className={panels.head}>
          <h4 className={`${panels.title} ${panels.titleQuiet}`}>
            Par provenance
          </h4>
        </div>
        <SourceList sources={stats.sources} />
      </div>

      <div className={`${panels.panel} ${panels.quiet}`}>
        <div className={panels.head}>
          <h4 className={`${panels.title} ${panels.titleQuiet}`}>Jour par jour</h4>
        </div>
        <PageViewsDaily stats={stats} />
      </div>
    </>
  );
}

function Tile({ label, value }: { label: string; value: string }) {
  return (
    <div className={styles.tile}>
      <span className={styles.tileLabel}>{label}</span>
      <span className={styles.tileValue}>{value}</span>
    </div>
  );
}

function SourceList({ sources }: { sources: PageViewSourceStat[] }) {
  if (sources.length === 0) {
    return (
      <p className={panels.note}>
        Aucune provenance identifiée : les vues comptées viennent de liens sans{" "}
        <code>?utm_source=</code> ni référent exploitable.
      </p>
    );
  }

  const max = sources.reduce((m, s) => Math.max(m, s.views), 0);

  return (
    <ul className={styles.sources}>
      {sources.map((source) => (
        <li key={source.source} className={styles.source}>
          <span className={styles.sourceName}>{sourceLabel(source.source)}</span>
          <span className={styles.sourceBar}>
            <i style={{ width: barWidth(source.views, max) }} />
          </span>
          <span className={styles.sourceViews}>{count(source.views)}</span>
          <span className={styles.sourceCta}>
            {count(source.ctaClicks)} clic{source.ctaClicks > 1 ? "s" : ""}
            {source.ctaRate !== null && <em> · {percent(source.ctaRate)}</em>}
          </span>
        </li>
      ))}
    </ul>
  );
}

function PageViewsDaily({ stats }: { stats: PageViewStatsResponse }) {
  const series: PageViewDailyStat[] = fillDays(
    stats.daily,
    stats.from,
    stats.to,
    (day) => ({ day, views: 0, ctaClicks: 0 }),
  );

  return (
    <DailyChart
      days={series.map((d) => d.day)}
      series={[
        {
          key: "views",
          label: "Vues",
          tone: "soft",
          values: series.map((d) => d.views),
        },
        {
          key: "ctaClicks",
          label: "Clics CTA",
          tone: "strong",
          values: series.map((d) => d.ctaClicks),
        },
      ]}
    />
  );
}
