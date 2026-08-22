import { useState } from "react";
import type { AnalyticsCtaStat, AnalyticsMetricKey } from "../../../types/api";
import { buildSteps } from "../derive";
import { int, money, pct, rate } from "../format";
import type { TabProps } from "../types";
import styles from "../analytics.module.css";
import { BarList } from "../components/BarList";
import { Card, EmptyBlock, EmptyState, SectionHead } from "../components/Card";
import { Segmented } from "../components/Controls";
import { DataTable, Heat, TBar, type Column } from "../components/DataTable";
import { Funnel } from "../components/Funnel";
import { Kpi } from "../components/Kpi";
import { LineChart } from "../components/LineChart";

const STEP_DEFS = [
  { k: "rep" as const, label: "Rapport diagnostic affiché" },
  { k: "prem" as const, label: "CTA abonnement cliqué" },
  { k: "ck" as const, label: "Checkout affiché" },
  { k: "pay" as const, label: "Paiement réussi" },
];

/**
 * OBJECTIFS produit, poses a la main — ce ne sont pas des mesures. Ils servent
 * uniquement a ordonner « sur quoi agir en premier » : la porte la plus loin de
 * son objectif remonte en tete. Les changer ne change aucun chiffre affiche.
 */
const GATES = [
  {
    id: "diag",
    label: "Le diagnostic",
    objective: 0.55,
    why: "trop peu de rapports produits : le problème est en amont du paywall.",
  },
  {
    id: "paywall",
    label: "Le paywall",
    objective: 0.22,
    why: "le rapport ne donne pas envie de débloquer le plan.",
  },
  {
    id: "checkout",
    label: "Le checkout",
    objective: 0.28,
    why: "l'intention existe mais le paiement ne se termine pas.",
  },
  {
    id: "price",
    label: "Le prix",
    objective: 0.45,
    why: "beaucoup de clics, peu de checkouts : hésitation au moment du tarif.",
  },
];

const CHART_OPTIONS: { id: AnalyticsMetricKey; label: string }[] = [
  { id: "pay", label: "Paiements" },
  { id: "revEurCents", label: "Revenus" },
  { id: "prem", label: "Clics Premium" },
];

export function ConversionTab({
  data,
  prev,
  compare,
  setFilter,
  openDetail,
}: TabProps) {
  const [metric, setMetric] = useState<AnalyticsMetricKey>("pay");
  const total = data.total;
  const steps = buildSteps(total, STEP_DEFS);

  const ctas = data.ctas.filter((cta) => cta.prem > 0);
  const maxPrem = Math.max(...ctas.map((cta) => cta.prem), 1);
  const refCk = rate(total.ck, total.prem);
  const refPay = rate(total.pay, total.prem);

  const ctaCols: Column<AnalyticsCtaStat>[] = [
    {
      key: "cta",
      label: "CTA",
      cell: "key",
      render: (row) => (
        <span className={styles.cellWithBar}>
          <TBar value={row.prem} max={maxPrem} />
          <span className={styles.cellTwoLines}>
            <span>{row.label}</span>
            <span className={styles.cellMeta}>{row.where}</span>
          </span>
        </span>
      ),
    },
    { key: "prem", label: "Clics", cell: "strong", render: (row) => int(row.prem) },
    { key: "ck", label: "Checkout", render: (row) => int(row.ck) },
    {
      key: "cck",
      label: "Clic → checkout",
      hideSmall: true,
      render: (row) => <Heat value={rate(row.ck, row.prem)} base={refCk} digits={0} />,
    },
    { key: "pay", label: "Paiements", cell: "strong", render: (row) => int(row.pay) },
    {
      key: "conv",
      label: "Clic → paiement",
      render: (row) => (
        <Heat value={rate(row.pay, row.prem)} base={refPay} digits={1} />
      ),
    },
    { key: "rev", label: "Revenu", render: (row) => money(row.revEurCents) },
  ];

  const measured = [
    { id: "diag", value: rate(total.rep, total.start) },
    { id: "paywall", value: rate(total.prem, total.rep) },
    { id: "checkout", value: rate(total.pay, total.ck) },
    { id: "price", value: rate(total.ck, total.prem) },
  ];

  /* Une porte sans mesure n'est pas « la pire » : elle sort du classement. */
  const gates = GATES.map((gate) => {
    const value = measured.find((entry) => entry.id === gate.id)?.value ?? null;
    return { ...gate, value, ratio: value == null ? null : value / gate.objective };
  })
    .filter((gate) => gate.ratio != null)
    .sort((a, b) => (a.ratio as number) - (b.ratio as number));

  const bySource = [...data.sources].sort(
    (a, b) => b.m.revEurCents - a.m.revEurCents,
  );

  return (
    <>
      <div className={styles.sec}>
        <SectionHead
          title="Du rapport au paiement"
          sub="Quatre étapes seulement — c'est là que se joue le chiffre d'affaires."
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
            <div className={styles.inlineStats}>
              <span>
                Rapport → paiement{" "}
                <b className={styles.mono}>{pct(rate(total.pay, total.rep), 2)}</b>
              </span>
              <span>
                Inscription → paiement{" "}
                <b className={styles.mono}>{pct(rate(total.pay, total.sig), 2)}</b>
              </span>
              <span>
                Visiteur → paiement{" "}
                <b className={styles.mono}>{pct(rate(total.pay, total.v), 2)}</b>
              </span>
            </div>
          </Card>

          <div className={styles.stack}>
            <Card title="Revenus">
              <div className={`${styles.kpis} ${styles.kpisHalf}`}>
                <Kpi
                  label="Chiffre d'affaires"
                  value={money(total.revEurCents)}
                  current={total.revEurCents}
                  previous={compare && prev ? prev.revEurCents : null}
                />
                <Kpi
                  label="Abonnés payants"
                  value={int(total.pay)}
                  current={total.pay}
                  previous={compare && prev ? prev.pay : null}
                />
                <Kpi
                  mini
                  label="Prix moyen du pass"
                  value={money(rate(total.revEurCents, total.pay))}
                  sub="encaissé, pas un tarif catalogue"
                />
                <Kpi
                  mini
                  label="Revenu / visiteur"
                  value={money(rate(total.revEurCents, total.v))}
                  current={total.v ? total.revEurCents / total.v : 0}
                  previous={
                    compare && prev && prev.v ? prev.revEurCents / prev.v : null
                  }
                />
                <Kpi
                  mini
                  label="Revenu / nouvel inscrit"
                  value={money(rate(total.revEurCents, total.sig))}
                  current={total.sig ? total.revEurCents / total.sig : 0}
                  previous={
                    compare && prev && prev.sig ? prev.revEurCents / prev.sig : null
                  }
                />
                <Kpi
                  mini
                  label="Rapports sans clic Premium"
                  value={int(Math.max(0, total.rep - total.prem))}
                  sub="lus, jamais convertis"
                />
              </div>
            </Card>

            <Card title="Où est le problème ?" question="sur quoi agir en priorité ?">
              {gates.length === 0 ? (
                <EmptyState>
                  Aucune des quatre portes n'a de mesure sur cette période.
                </EmptyState>
              ) : (
                <div className={styles.stackedBlock}>
                  {gates.map((gate, index) => (
                    <div className={styles.gateRow} key={gate.id}>
                      <span
                        className={`${styles.dot} ${styles.gateDot} ${
                          index === 0
                            ? styles.dotBad
                            : index === 1
                              ? styles.dotWarn
                              : styles.dotQuiet
                        }`}
                      />
                      <span className={styles.gateLabel}>{gate.label}</span>
                      <span
                        className={`${styles.mono} ${styles.gateValue} ${
                          index === 0 ? styles.gateValueWorst : ""
                        }`}
                      >
                        {pct(gate.value, 0)}
                      </span>
                      <span className={styles.gateWhy}>
                        {index === 0
                          ? gate.why
                          : `objectif ${pct(gate.objective, 0)}`}
                      </span>
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
          title="Quel écran déclenche l'achat ?"
          sub="Plusieurs points d'entrée mènent au paiement — tous ne se valent pas."
        />
        {ctas.length === 0 ? (
          <EmptyBlock title="Aucun clic Premium sur cette période.">
            Le tableau des CTA apparaît dès qu'un écran Premium est cliqué.
          </EmptyBlock>
        ) : (
          <Card>
            <DataTable
              cols={ctaCols}
              rows={ctas}
              keyOf={(row) => row.id}
              foot={{
                cta: "Total",
                prem: int(total.prem),
                ck: int(total.ck),
                pay: int(total.pay),
                conv: pct(rate(total.pay, total.prem), 1),
                rev: money(total.revEurCents),
              }}
            />
          </Card>
        )}
      </div>

      <div className={`${styles.grid} ${styles.g75}`}>
        <Card
          title="Évolution"
          question="les paiements suivent-ils le trafic ?"
          actions={
            <Segmented
              small
              ariaLabel="Mesure affichée"
              options={CHART_OPTIONS}
              value={metric}
              onChange={setMetric}
            />
          }
        >
          <LineChart
            series={data.series}
            prevSeries={compare ? data.prevSeries : null}
            metric={metric}
            annotations={data.annotations}
            height={236}
          />
        </Card>

        <Card title="Revenu par source" question="qui finance réellement le produit ?">
          {bySource.length === 0 ? (
            <EmptyState />
          ) : (
            <>
              <BarList
                rows={bySource.map((source) => ({
                  id: source.id,
                  label: source.label,
                  value: source.m.revEurCents,
                  sub: `${int(source.m.pay)} payants`,
                  right: pct(rate(source.m.pay, source.m.v), 2),
                }))}
                format={money}
                onRow={(row) => setFilter("source", row.id)}
              />
              <div className={styles.barNote}>
                Revenu encaissé · conversion visiteur → payant à droite
              </div>
            </>
          )}
        </Card>
      </div>
    </>
  );
}
