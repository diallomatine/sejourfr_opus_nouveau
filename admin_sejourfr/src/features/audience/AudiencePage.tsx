import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { pageViewsApi } from "../../api/pageViewsApi";
import type { PageViewSourceStat, PageViewStatsResponse } from "../../types/api";
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
      <header className={styles.header}>
        <div>
          <h1 className="page-title">Audience des landings</h1>
          <p className={styles.subtitle}>
            Nombre de consultations et de clics sur l&apos;appel à l&apos;action, par
            réseau de provenance.
          </p>
        </div>

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
      </header>

      {statsQuery.isPending && <p className={styles.state}>Chargement…</p>}
      {statsQuery.isError && (
        <p className={styles.state}>Impossible de charger l&apos;audience.</p>
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
  const empty = stats.views === 0 && stats.ctaClicks === 0;
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
        <h2 className="panel-title">Par provenance</h2>
        <SourceTable sources={stats.sources} maxViews={maxViews(stats.sources)} />
      </section>

      <section className={styles.panel}>
        <h2 className="panel-title">Jour par jour</h2>
        <DailyChart stats={stats} />
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
            <i style={{ width: max > 0 ? `${(s.views * 100) / max}%` : 0 }} />
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

/** Barres verticales maison — pas de librairie de graphes dans ce projet. */
function DailyChart({ stats }: { stats: PageViewStatsResponse }) {
  const max = stats.daily.reduce((m, d) => Math.max(m, d.views), 0);
  return (
    <div className={styles.chart}>
      {stats.daily.map((d) => (
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
  );
}
