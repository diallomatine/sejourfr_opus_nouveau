import type { AnalyticsSourceStat } from "../../../types/api";
import { buildSteps } from "../derive";
import { barWidth, blueStep, int, pct, rate } from "../format";
import type { TabProps } from "../types";
import styles from "../analytics.module.css";
import { Card, EmptyBlock, EmptyState, Note, SectionHead } from "../components/Card";
import { DataTable, Heat, TBar, type Column } from "../components/DataTable";
import { Funnel } from "../components/Funnel";
import { MiniSteps } from "../components/MiniSteps";

const STEP_DEFS = [
  { k: "cta" as const, label: "Clic « Faire mon diagnostic »" },
  { k: "start" as const, label: "Diagnostic démarré" },
  { k: "ee1" as const, label: "EE démarrée" },
  { k: "ee2" as const, label: "EE terminée" },
  { k: "eo1" as const, label: "EO démarrée" },
  { k: "eo2" as const, label: "EO terminée" },
  { k: "rep" as const, label: "Rapport affiché" },
  { k: "prem" as const, label: "CTA Premium cliqué" },
  { k: "ck" as const, label: "Checkout commencé" },
  { k: "pay" as const, label: "Paiement" },
];

export function DiagnosticTab({ data, filters, setFilter, openDetail }: TabProps) {
  const total = data.total;
  const steps = buildSteps(total, STEP_DEFS);

  const bySource = [...data.sources].sort((a, b) => b.m.start - a.m.start);
  const maxStart = Math.max(...bySource.map((source) => source.m.start), 1);
  const refComp = rate(total.rep, total.start);
  const refPrem = rate(total.prem, total.rep);

  const sourceCols: Column<AnalyticsSourceStat>[] = [
    {
      key: "src",
      label: "Source",
      cell: "key",
      render: (row) => (
        <span className={styles.cellWithBar}>
          <TBar value={row.m.start} max={maxStart} />
          {row.label}
        </span>
      ),
    },
    {
      key: "start",
      label: "Commencés",
      cell: "strong",
      render: (row) => int(row.m.start),
    },
    {
      key: "ee2",
      label: "EE terminée",
      hideSmall: true,
      render: (row) => int(row.m.ee2),
    },
    {
      key: "eo2",
      label: "EO terminée",
      hideSmall: true,
      render: (row) => int(row.m.eo2),
    },
    { key: "rep", label: "Terminés", render: (row) => int(row.m.rep) },
    {
      key: "comp",
      label: "Complétion",
      render: (row) => (
        <Heat value={rate(row.m.rep, row.m.start)} base={refComp} digits={0} />
      ),
    },
    {
      key: "prem",
      label: "Clics Premium",
      hideSmall: true,
      render: (row) => int(row.m.prem),
    },
    {
      key: "cprem",
      label: "Rapport → Premium",
      render: (row) => (
        <Heat value={rate(row.m.prem, row.m.rep)} base={refPrem} digits={0} />
      ),
    },
  ];

  const maxDeviceRep = Math.max(...data.devices.map((device) => device.rep), 1);
  const [fast, complete] = data.diagTypes;

  return (
    <>
      <div className={styles.sec}>
        <SectionHead
          title="Parcours diagnostic"
          sub="Étape par étape, du clic sur la landing jusqu'au paiement. L'étape la plus coûteuse est signalée."
        />
        <div className={`${styles.grid} ${styles.g84}`}>
          <Card>
            <Funnel
              steps={steps}
              compact
              onStep={(step) =>
                openDetail({ kind: "step", stepKey: step.k, label: step.label })
              }
            />
          </Card>
          <div className={styles.stack}>
            <Card
              title="Abandon du diagnostic"
              question="où décrochent-ils exactement ?"
            >
              {data.abandon.length === 0 ? (
                <EmptyState>
                  Aucun diagnostic commencé : il n'y a pas encore d'abandon à
                  situer.
                </EmptyState>
              ) : (
                <div className={styles.stackedBlock}>
                  {data.abandon.map((row) => (
                    <div className={styles.abandonRow} key={row.id}>
                      <span
                        className={`${styles.abandonLabel} ${row.worst ? styles.abandonWorst : ""}`}
                      >
                        {row.label}
                      </span>
                      <span
                        className={`${styles.mono} ${styles.abandonValue} ${row.worst ? styles.abandonWorst : ""}`}
                      >
                        {pct(row.v, 0)}
                      </span>
                      <span className={styles.abandonMeta}>
                        {row.sub} ·{" "}
                        {row.base === "rep"
                          ? "des rapports affichés"
                          : "des diagnostics commencés"}
                      </span>
                      <div className={`${styles.barTrack} ${styles.miniRowBar}`}>
                        <i
                          style={{
                            width: barWidth(row.v, 1),
                            background: row.worst
                              ? "var(--red)"
                              : "color-mix(in srgb, var(--blue) 45%, var(--paper))",
                          }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          </div>
        </div>
      </div>

      <div className={styles.sec}>
        <SectionHead
          title="Diagnostic rapide ou diagnostic complet ?"
          sub="Le format court complète mieux ; reste à savoir lequel amène réellement des abonnés."
        />
        {data.diagTypes.length === 0 ? (
          <EmptyBlock>
            Aucun diagnostic n'a été commencé sur cette période.
          </EmptyBlock>
        ) : (
          <>
            <div className={`${styles.grid} ${styles.g2}`}>
              {data.diagTypes.map((type, index) => (
                <Card key={type.id} title={type.label} question={type.sub}>
                  <div className={styles.stackedBlockWide}>
                    <div className={styles.metricGrid}>
                      {[
                        { label: "Commencés", value: int(type.start) },
                        { label: "Terminés", value: int(type.done) },
                        {
                          label: "Complétion",
                          value: pct(rate(type.done, type.start), 0),
                        },
                        { label: "Paiements", value: int(type.pay) },
                      ].map((metric) => (
                        <div className={styles.metricCell} key={metric.label}>
                          <span className={styles.num}>{metric.value}</span>
                          <span className={styles.metricCellLabel}>
                            {metric.label}
                          </span>
                        </div>
                      ))}
                    </div>
                    <MiniSteps
                      rows={type.chain}
                      tone={blueStep(index, data.diagTypes.length)}
                    />
                    <div className={styles.miniRowMeta}>
                      {type.steps} épreuve{type.steps > 1 ? "s" : ""} dans ce format.
                    </div>
                    <div className={styles.cardFooter}>
                      <span>
                        <b className={styles.mono}>{int(type.prem)}</b> clics
                        Premium · {pct(rate(type.prem, type.done), 0)} des rapports
                      </span>
                      <span>
                        <b className={styles.mono}>
                          {pct(rate(type.pay, type.start), 2)}
                        </b>{" "}
                        commencé → payant
                      </span>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
            {fast && complete && (
              <DiagComparison fast={fast} complete={complete} />
            )}
          </>
        )}
      </div>

      <div className={`${styles.grid} ${styles.g75}`}>
        <Card
          title="Complétion par source"
          question="certaines audiences terminent-elles moins ?"
        >
          {bySource.length === 0 ? (
            <EmptyState />
          ) : (
            <DataTable
              cols={sourceCols}
              rows={bySource}
              keyOf={(row) => row.id}
              onRow={(row) =>
                setFilter("source", filters.source === row.id ? null : row.id)
              }
            />
          )}
        </Card>

        <Card title="Complétion par plateforme" question="un écran pose-t-il problème ?">
          {data.devices.length === 0 ? (
            <EmptyState />
          ) : (
            <div className={styles.stackedBlock}>
              {data.devices.map((device) => (
                <div className={styles.miniRow} key={device.id}>
                  <span className={styles.miniRowLabel}>{device.label}</span>
                  <span className={`${styles.mono} ${styles.miniRowValue}`}>
                    {int(device.rep)} terminés
                  </span>
                  <div className={`${styles.barTrack} ${styles.miniRowBar}`}>
                    <i style={{ width: barWidth(device.rep, maxDeviceRep) }} />
                  </div>
                  <span className={styles.miniRowMeta}>
                    {int(device.v)} visiteurs · diagnostic terminé{" "}
                    {pct(rate(device.rep, device.v), 1)} · payant{" "}
                    {pct(rate(device.pay, device.v), 2)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </>
  );
}

/**
 * La phrase ne CONCLUT que si les deux formats ont produit des paiements. Sur
 * zero, on enonce la complétion et on s'arrete la — designer un gagnant sur du
 * bruit serait une conclusion inventee.
 */
function DiagComparison({
  fast,
  complete,
}: {
  fast: TabProps["data"]["diagTypes"][number];
  complete: TabProps["data"]["diagTypes"][number];
}) {
  const fastRate = rate(fast.pay, fast.start);
  const completeRate = rate(complete.pay, complete.start);

  if (fastRate == null || completeRate == null || fast.pay + complete.pay === 0) {
    return (
      <Note>
        Complétion de {pct(rate(fast.done, fast.start), 0)} pour le{" "}
        {fast.label.toLowerCase()} contre{" "}
        {pct(rate(complete.done, complete.start), 0)} pour le{" "}
        {complete.label.toLowerCase()}. Aucun des deux formats n'a encore produit
        d'abonné : rien à départager sur la conversion.
      </Note>
    );
  }

  const better = completeRate > fastRate ? complete : fast;
  const worse = completeRate > fastRate ? fast : complete;
  const ratio = Math.max(fastRate, completeRate) / Math.min(fastRate, completeRate);

  return (
    <Note>
      Le <strong>{better.label.toLowerCase()}</strong> convertit{" "}
      {isFinite(ratio) && ratio > 1
        ? `${ratio.toFixed(1).replace(".", ",")}×`
        : "mieux"}{" "}
      en abonnés que le {worse.label.toLowerCase()}, avec une complétion de{" "}
      {pct(rate(better.done, better.start), 0)} contre{" "}
      {pct(rate(worse.done, worse.start), 0)}.
    </Note>
  );
}
