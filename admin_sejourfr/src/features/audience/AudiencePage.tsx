import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { audienceApi } from "../../api/audienceApi";
import { PageHeader } from "../../components/ui/PageHeader";
import { Spinner } from "../../components/ui/Spinner";
import type { FunnelStatsResponse } from "../../types/api";
import { AnonymousAudience } from "./components/AnonymousAudience";
import { Collapsible } from "./components/Collapsible";
import { FunnelDaily } from "./components/FunnelDaily";
import { FunnelSteps } from "./components/FunnelSteps";
import { HeadlineBoard } from "./components/HeadlineBoard";
import { IntegrityCheck } from "./components/IntegrityCheck";
import { PeriodFilter } from "./components/PeriodFilter";
import { PlatformBreakdown } from "./components/PlatformBreakdown";
import { SourceRanking } from "./components/SourceRanking";
import panels from "./components/panels.module.css";
import { formatDate, formatRange } from "./dates";
import { buildInsights } from "./insights";
import { DEFAULT_PERIOD, resolveRange, type PeriodChoice } from "./period";
import styles from "./AudiencePage.module.css";

/**
 * Deux natures de données sur un seul écran, et un seul filtre de période pour
 * les deux : un filtre par section ferait comparer deux fenêtres sans le voir.
 * Ce qui se lit en trois secondes est en haut (chiffres clés, entonnoir,
 * classement des provenances) ; le reste est replié, jamais supprimé.
 */
export function AudiencePage() {
  const [period, setPeriod] = useState<PeriodChoice>(DEFAULT_PERIOD);
  const [path, setPath] = useState("/reussir");

  const range = resolveRange(period);

  const funnelQuery = useQuery({
    queryKey: ["audienceFunnel", range],
    queryFn: () => audienceApi.funnel(range),
  });

  const pathsQuery = useQuery({
    queryKey: ["pageViews", "paths"],
    queryFn: () => audienceApi.trackedPaths(),
  });

  const statsQuery = useQuery({
    queryKey: ["pageViews", { path, range }],
    queryFn: () => audienceApi.landing(path, range),
  });

  const funnel = funnelQuery.data;
  const stats = statsQuery.data;

  /* La période affichée vient des bornes RENVOYÉES par le serveur, jamais de ce
     que le client croit avoir demandé : c'est ce qui rend l'écran vérifiable. */
  const applied = funnel
    ? formatRange(funnel.cohortFrom, funnel.cohortTo)
    : stats
      ? formatRange(stats.from, stats.to)
      : null;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow="§ 01 — Acquisition"
        title="Funnel et"
        emphasis="audience"
      />

      <div className={styles.filterBar}>
        <PeriodFilter choice={period} onChange={setPeriod} />
        <p className={styles.applied}>
          {applied ? (
            <>
              Période affichée : <strong>{applied}</strong>
              <span className={styles.appliedHint}>
                {" "}
                — bornes renvoyées par le serveur, fuseau Europe/Paris
              </span>
            </>
          ) : (
            "Période en cours de chargement…"
          )}
        </p>
      </div>

      {funnelQuery.isPending && <Spinner label="Chargement du funnel…" />}

      {funnelQuery.isError && (
        <p className={`${panels.state} ${panels.stateError}`}>
          <strong className={panels.stateTitle}>Funnel indisponible</strong>
          {(funnelQuery.error as Error).message}
        </p>
      )}

      {funnel && <FunnelView stats={funnel} />}

      <Collapsible
        title="Audience des landings"
        hint="vues de pages, sans cookie ni identifiant"
        nature="anon"
      >
        <p className={panels.note}>
          Compteur de <strong>vues de pages</strong> : deux passages de la même
          personne comptent deux fois, et rien ici n&apos;est rattachable à un
          compte. Ces nombres <strong>ne se comparent pas</strong> à ceux du
          funnel ci-dessus, qui compte des comptes.
        </p>
        <AnonymousAudience
          paths={pathsQuery.data ?? [path]}
          path={path}
          onPathChange={setPath}
          stats={stats}
          isPending={statsQuery.isPending}
          error={statsQuery.isError ? (statsQuery.error as Error) : null}
        />
      </Collapsible>
    </div>
  );
}

function FunnelView({ stats }: { stats: FunnelStatsResponse }) {
  const insights = buildInsights(stats);
  const integrityAlert =
    stats.integrity.accountsWithMultipleDiagnosticSessions > 0;

  if (insights.signups === 0) {
    return (
      <>
        <p className={panels.state}>
          <strong className={panels.stateTitle}>
            Aucun compte créé sur cette période
          </strong>
          Rien n&apos;a été enregistré entre le {formatDate(stats.cohortFrom)} et
          le {formatDate(stats.cohortTo)} : il n&apos;y a pas de cohorte à
          suivre. Élargissez la période — l&apos;écran suit les comptes{" "}
          <strong>créés</strong> dans la fenêtre, pas ceux qui y étaient actifs.
        </p>

        <div className={styles.backstage}>
          <h2 className={styles.backstageTitle}>Vérifications</h2>
          <Collapsible
            title="Un seul diagnostic par compte"
            hint="contrôle d'intégrité, sur toute la base"
            nature="exact"
            defaultOpen={integrityAlert}
          >
            <IntegrityCheck integrity={stats.integrity} />
          </Collapsible>
        </div>
      </>
    );
  }

  return (
    <>
      <HeadlineBoard insights={insights} />

      <div className={panels.panel}>
        <div className={styles.funnelHead}>
          <span className={`${panels.nature} ${panels.natureExact}`}>
            exact · par compte
          </span>
          <h2 className={styles.funnelTitle}>Du réseau social au paiement</h2>
        </div>
        <p className={styles.funnelIntro}>
          Population suivie : les comptes <strong>créés</strong> pendant la
          période. Un compte n&apos;est compté qu&apos;une fois par étape, et
          chaque barre vaut une part des inscrits — les largeurs se comparent
          donc entre elles.
        </p>
        <FunnelSteps
          stats={stats}
          signups={insights.signups}
          leak={insights.leak}
        />
      </div>

      <SourceRanking
        ranking={insights.ranking}
        bestSource={insights.bestSource}
      />

      <div className={styles.backstage}>
        <h2 className={styles.backstageTitle}>Détail et vérifications</h2>

        <Collapsible
          title="Par plateforme"
          hint="où le compte a été créé, puis ce qu'il y a fait"
          nature="exact"
        >
          <PlatformBreakdown platforms={stats.byPlatform} />
        </Collapsible>

        <Collapsible
          title="Jour par jour"
          hint="chaque compte est compté au jour de son inscription"
          nature="exact"
        >
          <FunnelDaily
            daily={stats.daily}
            from={stats.cohortFrom}
            to={stats.cohortTo}
          />
        </Collapsible>

        <Collapsible
          title="Un seul diagnostic par compte"
          hint="contrôle d'intégrité, sur toute la base"
          nature="exact"
          defaultOpen={integrityAlert}
        >
          <IntegrityCheck integrity={stats.integrity} />
        </Collapsible>
      </div>
    </>
  );
}
