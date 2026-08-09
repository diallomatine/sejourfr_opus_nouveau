import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { pageViewsApi } from "../../api/pageViewsApi";
import { PageHeader } from "../../components/ui/PageHeader";
import type {
  PageViewDailyStat,
  PageViewEvent,
  PageViewSourceStat,
  PageViewStatsResponse,
} from "../../types/api";
import styles from "./AudiencePage.module.css";

const WINDOWS = [7, 30, 90] as const;

/** Libellés lisibles des sources normalisées côté backend. */
const SOURCE_LABELS: Record<string, string> = {
  tiktok: "TikTok",
  instagram: "Instagram",
  whatsapp: "WhatsApp",
  facebook: "Facebook",
  youtube: "YouTube",
  direct: "Accès direct",
  autre: "Autre",
};

const EVENT_LABELS: Record<PageViewEvent, string> = {
  VIEW: "Page vue",
  CTA: "CTA historique cliqué",
  DIAGNOSTIC_VIEWED: "Diagnostic vu",
  DIAGNOSTIC_STARTED: "Diagnostic démarré",
  DIAGNOSTIC_WRITTEN_COMPLETED: "Écrit terminé",
  DIAGNOSTIC_ORAL_COMPLETED: "Oral terminé",
  DIAGNOSTIC_COMPLETED: "Diagnostic analysé",
  DIAGNOSTIC_RESULT_VIEWED: "Résultat consulté",
  PLAN_OPENED: "Plan ouvert",
  PLAN_RECOMMENDED_EXERCISE_STARTED: "Exercice recommandé démarré",
  SOCIAL_LANDING_DIAGNOSTIC_CLICKED: "CTA diagnostic social cliqué",
  DIAGNOSTIC_TO_PREMIUM_CLICKED: "CTA Premium depuis diagnostic",
};

const EVENT_ORDER = Object.keys(EVENT_LABELS) as PageViewEvent[];

export function AudiencePage() {
  const [days, setDays] = useState<number>(30);
  const [path, setPath] = useState("/reussir");

  const pathsQuery = useQuery({
    queryKey: ["pageViews", "paths"],
    queryFn: () => pageViewsApi.trackedPaths(),
  });

  const statsQuery = useQuery({
    queryKey: ["pageViews", { path, days }],
    queryFn: () => pageViewsApi.stats(path, days),
  });

  const paths = pathsQuery.data ?? [path];
  const stats = statsQuery.data;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow="§ 01 — Vue d'ensemble"
        title="Audience des"
        emphasis="landings"
        actions={
          <div className={styles.filters}>
            {paths.length > 1 && (
              <select
                className={styles.select}
                value={path}
                onChange={(e) => setPath(e.target.value)}
              >
                {paths.map((p) => (
                  <option key={p} value={p}>
                    {p}
                  </option>
                ))}
              </select>
            )}
            <div className={styles.windows}>
              {WINDOWS.map((w) => (
                <button
                  key={w}
                  type="button"
                  className={`${styles.window} ${w === days ? styles.windowActive : ""}`}
                  onClick={() => setDays(w)}
                >
                  {w} j
                </button>
              ))}
            </div>
          </div>
        }
      />

      <p className={styles.subtitle}>
        Nombre de consultations et de clics sur l&apos;appel à l&apos;action, par
        réseau de provenance.
      </p>

      {statsQuery.isPending && <p className={styles.state}>Chargement…</p>}
      {statsQuery.isError && (
        <p className={styles.state}>
          Impossible de charger l&apos;audience :{" "}
          {(statsQuery.error as Error).message}
        </p>
      )}

      {stats && <StatsView stats={stats} />}

      <p className={styles.note}>
        Ce compteur mesure des <strong>vues</strong>, pas des visiteurs uniques :
        aucun cookie ni identifiant n&apos;est déposé sur le terminal du visiteur,
        donc deux passages de la même personne comptent deux fois. La provenance
        vient du paramètre <code>?utm_source=</code> du lien partagé, avec le
        référent en repli.
      </p>
    </div>
  );
}

function StatsView({ stats }: { stats: PageViewStatsResponse }) {
  const totalEvents = Object.values(stats.events).reduce(
    (total, count) => total + (count ?? 0),
    0,
  );
  const empty = totalEvents === 0;
  const globalRate = stats.views > 0 ? (stats.ctaClicks * 100) / stats.views : null;

  if (empty) {
    return (
      <p className={styles.state}>
        Aucune consultation enregistrée sur <code>{stats.path}</code> ces{" "}
        {stats.days} derniers jours.
      </p>
    );
  }

  return (
    <>
      <div className={styles.tiles}>
        <Tile label="Vues" value={stats.views.toLocaleString("fr-FR")} />
        <Tile label="Clics sur le CTA" value={stats.ctaClicks.toLocaleString("fr-FR")} />
        <Tile
          label="Taux de clic"
          value={globalRate === null ? "—" : `${globalRate.toFixed(1).replace(".", ",")} %`}
        />
      </div>

      <section className={styles.panel}>
        <h2 className={styles.panelTitle}>Étapes du funnel</h2>
        <ul className={styles.events}>
          {EVENT_ORDER.filter((event) => (stats.events[event] ?? 0) > 0).map(
            (event) => (
              <li key={event}>
                <span>{EVENT_LABELS[event]}</span>
                <strong>{(stats.events[event] ?? 0).toLocaleString("fr-FR")}</strong>
              </li>
            ),
          )}
        </ul>
      </section>

      <section className={styles.panel}>
        <h2 className={styles.panelTitle}>Par provenance</h2>
        <SourceTable sources={stats.sources} maxViews={maxViews(stats.sources)} />
      </section>

      <section className={styles.panel}>
        <h2 className={styles.panelTitle}>Jour par jour</h2>
        <DailyChart daily={continuousDaily(stats)} />
      </section>
    </>
  );
}

function maxViews(sources: PageViewSourceStat[]): number {
  return sources.reduce((max, s) => Math.max(max, s.views), 0);
}

function Tile({ label, value }: { label: string; value: string }) {
  return (
    <div className={styles.tile}>
      <span className={styles.tileLabel}>{label}</span>
      <span className={styles.tileValue}>{value}</span>
    </div>
  );
}

function SourceTable({
  sources,
  maxViews: max,
}: {
  sources: PageViewSourceStat[];
  maxViews: number;
}) {
  return (
    <ul className={styles.sources}>
      {sources.map((s) => (
        <li key={s.source} className={styles.source}>
          <span className={styles.sourceName}>
            {SOURCE_LABELS[s.source] ?? s.source}
          </span>
          <span className={styles.sourceBar}>
            <i style={{ width: max > 0 ? `${(s.views * 100) / max}%` : "0%" }} />
          </span>
          <span className={styles.sourceViews}>
            {s.views.toLocaleString("fr-FR")}
          </span>
          <span className={styles.sourceCta}>
            {s.ctaClicks.toLocaleString("fr-FR")} clic
            {s.ctaClicks > 1 ? "s" : ""}
            {s.ctaRate !== null && (
              <em> · {s.ctaRate.toFixed(1).replace(".", ",")} %</em>
            )}
          </span>
        </li>
      ))}
    </ul>
  );
}

/** Jour courant à Paris (yyyy-MM-dd), même référentiel que le backend. */
function parisToday(): string {
  return new Intl.DateTimeFormat("fr-CA", { timeZone: "Europe/Paris" }).format(
    new Date(),
  );
}

function addDays(day: string, delta: number): string {
  const [year, month, date] = day.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, date + delta))
    .toISOString()
    .slice(0, 10);
}

/**
 * Le backend ne renvoie que les jours ayant au moins un événement. Sans les
 * jours vides, deux points espacés d'un mois seraient dessinés côte à côte et
 * la largeur des barres ne voudrait rien dire : on rétablit la série continue
 * sur toute la fenêtre.
 */
function continuousDaily(stats: PageViewStatsResponse): PageViewDailyStat[] {
  const byDay = new Map(stats.daily.map((d) => [d.day, d]));
  const observed = stats.daily.map((d) => d.day);
  const end = [parisToday(), ...observed].reduce((a, b) => (a > b ? a : b));

  const series: PageViewDailyStat[] = [];
  for (let offset = 1 - stats.days; offset <= 0; offset += 1) {
    const day = addDays(end, offset);
    series.push(byDay.get(day) ?? { day, views: 0, ctaClicks: 0 });
  }
  return series;
}

function formatDay(day: string): string {
  const [year, month, date] = day.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, date)).toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "short",
    timeZone: "UTC",
  });
}

/** Barres verticales maison — pas de librairie de graphes dans ce projet. */
function DailyChart({ daily }: { daily: PageViewDailyStat[] }) {
  const max = daily.reduce((m, d) => Math.max(m, d.views), 0);
  const first = daily[0];
  const last = daily[daily.length - 1];

  return (
    <>
      <div className={styles.chart}>
        {daily.map((d) => (
          <span
            key={d.day}
            className={styles.chartCol}
            title={`${d.day} — ${d.views} vue${d.views > 1 ? "s" : ""}, ${d.ctaClicks} clic${d.ctaClicks > 1 ? "s" : ""}`}
          >
            <i
              className={styles.chartViews}
              style={{ height: max > 0 ? `${(d.views * 100) / max}%` : "0%" }}
            />
            <i
              className={styles.chartCta}
              style={{ height: max > 0 ? `${(d.ctaClicks * 100) / max}%` : "0%" }}
            />
          </span>
        ))}
      </div>
      {first && last && (
        <div className={styles.chartAxis}>
          <span>{formatDay(first.day)}</span>
          <span>{formatDay(last.day)}</span>
        </div>
      )}
    </>
  );
}
