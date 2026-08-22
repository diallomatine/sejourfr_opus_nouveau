import { useState } from "react";
import type { AnalyticsMetricKey } from "../../../types/api";
import { sparkValues } from "../derive";
import { barWidth, int, money, pct, rate } from "../format";
import { CHART_METRICS } from "../labels";
import type { TabProps } from "../types";
import styles from "../analytics.module.css";
import { Card, EmptyState, Note, SectionHead } from "../components/Card";
import { Segmented } from "../components/Controls";
import { Heat } from "../components/DataTable";
import { Delta } from "../components/Delta";
import { Funnel } from "../components/Funnel";
import { Icon } from "../components/Icon";
import { Insights } from "../components/Insight";
import { Kpi } from "../components/Kpi";
import { LineChart } from "../components/LineChart";

interface DerivedRate {
  label: string;
  current: number | null;
  previous: number | null;
  money?: boolean;
}

export function OverviewTab({
  data,
  prev,
  compare,
  setFilter,
  go,
  openDetail,
}: TabProps) {
  const [metric, setMetric] = useState<AnalyticsMetricKey>("v");
  const total = data.total;
  const days = Math.max(1, data.period.days);

  const previousOf = (key: AnalyticsMetricKey) =>
    compare && prev ? prev[key] : null;

  const derived: DerivedRate[] = [
    {
      label: "Visiteur → clic diagnostic",
      current: rate(total.cta, total.v),
      previous: prev ? rate(prev.cta, prev.v) : null,
    },
    {
      label: "Diagnostic commencé → terminé",
      current: rate(total.rep, total.start),
      previous: prev ? rate(prev.rep, prev.start) : null,
    },
    {
      label: "Diagnostic terminé → inscription",
      current: rate(total.sig, total.rep),
      previous: prev ? rate(prev.sig, prev.rep) : null,
    },
    {
      label: "Diagnostic terminé → clic Premium",
      current: rate(total.prem, total.rep),
      previous: prev ? rate(prev.prem, prev.rep) : null,
    },
    {
      label: "Clic Premium → checkout",
      current: rate(total.ck, total.prem),
      previous: prev ? rate(prev.ck, prev.prem) : null,
    },
    {
      label: "Checkout → paiement",
      current: rate(total.pay, total.ck),
      previous: prev ? rate(prev.pay, prev.ck) : null,
    },
    {
      label: "Inscription → paiement",
      current: rate(total.pay, total.sig),
      previous: prev ? rate(prev.pay, prev.sig) : null,
    },
    {
      label: "Visiteur → paiement",
      current: rate(total.pay, total.v),
      previous: prev ? rate(prev.pay, prev.v) : null,
    },
    {
      label: "Revenu par visiteur",
      current: rate(total.revEurCents, total.v),
      previous: prev ? rate(prev.revEurCents, prev.v) : null,
      money: true,
    },
    {
      label: "Revenu par nouvel inscrit",
      current: rate(total.revEurCents, total.sig),
      previous: prev ? rate(prev.revEurCents, prev.sig) : null,
      money: true,
    },
  ];

  const topSources = [...data.sources].sort((a, b) => b.m.v - a.m.v).slice(0, 5);
  const maxSource = Math.max(...topSources.map((source) => source.m.v), 1);
  const refPay = rate(total.pay, total.v);

  const premiumRows = [
    { label: "Rapports diagnostic affichés", value: total.rep, conv: null },
    { label: "Clics Premium", value: total.prem, conv: rate(total.prem, total.rep) },
    { label: "Checkouts", value: total.ck, conv: rate(total.ck, total.prem) },
    { label: "Paiements", value: total.pay, conv: rate(total.pay, total.ck) },
  ];

  return (
    <>
      {data.partial && (
        <Note>
          Journée en cours — les chiffres s'arrêtent à <strong>{data.hourNow} h</strong>{" "}
          et la comparaison porte sur la même plage horaire hier. Les paiements
          étant rares à cette échelle, lisez plutôt les volumes hauts de parcours.
        </Note>
      )}

      <section className={`${styles.card} ${styles.cardClipped}`}>
        <div className={styles.kpis}>
          <Kpi
            label="Visiteurs"
            value={int(total.v)}
            current={total.v}
            previous={previousOf("v")}
            sub={
              data.partial
                ? `journée en cours, arrêtée à ${data.hourNow} h`
                : `${int(total.v / days)} / jour en moyenne`
            }
            spark={sparkValues(data.series, "v")}
            onClick={() => openDetail({ kind: "step", stepKey: "v" })}
          />
          <Kpi
            label="Nouvelles inscriptions"
            value={int(total.sig)}
            current={total.sig}
            previous={previousOf("sig")}
            sub={`${pct(rate(total.sig, total.v))} des visiteurs`}
            spark={sparkValues(data.series, "sig")}
            onClick={() => openDetail({ kind: "step", stepKey: "sig" })}
          />
          <Kpi
            label="Diagnostics terminés"
            value={int(total.rep)}
            current={total.rep}
            previous={previousOf("rep")}
            sub={`${pct(rate(total.rep, total.start))} des diagnostics commencés`}
            spark={sparkValues(data.series, "rep")}
            onClick={() => go("diagnostic")}
          />
          <Kpi
            label="Nouveaux abonnés payants"
            value={int(total.pay)}
            current={total.pay}
            previous={previousOf("pay")}
            sub={
              total.pay === 0
                ? "aucun paiement sur cette période"
                : `${pct(rate(total.pay, total.v), 2)} des visiteurs`
            }
            spark={sparkValues(data.series, "pay")}
            onClick={() => go("conversion")}
          />

          <Kpi
            mini
            label="Clics « Faire mon diagnostic »"
            value={int(total.cta)}
            current={total.cta}
            previous={previousOf("cta")}
            sub={`${pct(rate(total.cta, total.v))} des visiteurs`}
          />
          <Kpi
            mini
            label="Diagnostics commencés"
            value={int(total.start)}
            current={total.start}
            previous={previousOf("start")}
            sub={`${pct(rate(total.start, total.cta))} des clics`}
          />
          <Kpi
            mini
            label="Clics « Débloquer mon plan »"
            value={int(total.prem)}
            current={total.prem}
            previous={previousOf("prem")}
            sub={`${pct(rate(total.prem, total.rep))} des rapports`}
          />
          <Kpi
            mini
            label="Checkouts commencés"
            value={int(total.ck)}
            current={total.ck}
            previous={previousOf("ck")}
            sub={`${pct(rate(total.ck, total.prem))} des clics Premium`}
          />
          <Kpi
            mini
            label="Chiffre d'affaires"
            value={money(total.revEurCents)}
            current={total.revEurCents}
            previous={previousOf("revEurCents")}
            sub={`${int(total.pay)} ${total.pay > 1 ? "paiements" : "paiement"} encaissés`}
          />
          <Kpi
            mini
            label="Revenu par visiteur"
            value={money(rate(total.revEurCents, total.v))}
            current={total.v ? total.revEurCents / total.v : 0}
            previous={
              compare && prev && prev.v ? prev.revEurCents / prev.v : null
            }
            sub="ARPV"
          />
          <Kpi
            mini
            label="Visiteur → paiement"
            value={pct(rate(total.pay, total.v), 2)}
            current={total.v ? total.pay / total.v : 0}
            previous={compare && prev && prev.v ? prev.pay / prev.v : null}
            sub="conversion de bout en bout"
          />
          <Kpi
            mini
            label="Utilisateurs inscrits au total"
            value={int(data.totalUsers)}
            sub="cumul, hors période"
          />
        </div>
      </section>

      <div className={styles.sec}>
        <SectionHead
          title="Du visiteur au paiement"
          sub="Où est-ce que je perds mes utilisateurs ? Cliquez sur une étape pour voir sa répartition par source."
        />
        <div className={`${styles.grid} ${styles.g84}`}>
          <Card>
            {data.funnel.length === 0 ? (
              <EmptyState />
            ) : (
              <Funnel
                steps={data.funnel}
                worstFrom={2}
                onStep={(step) =>
                  openDetail({ kind: "step", stepKey: step.k, label: step.label })
                }
              />
            )}
          </Card>
          <Card title="Conversions clés" question="est-ce que ça monte ou ça baisse ?">
            <div className={styles.rateList}>
              {derived.map((row) => (
                <div className={styles.rateRow} key={row.label}>
                  <span className={styles.rateLabel}>{row.label}</span>
                  <span className={`${styles.mono} ${styles.rateValue}`}>
                    {row.money ? money(row.current) : pct(row.current)}
                  </span>
                  <span className={styles.rateDelta}>
                    {compare && row.current != null && (
                      <Delta
                        current={row.current}
                        previous={row.previous}
                        showFlat={false}
                      />
                    )}
                  </span>
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>

      {data.insights.length > 0 && (
        <div className={styles.sec}>
          <SectionHead
            title="À retenir"
            sub="Constats calculés sur la période sélectionnée, jamais sur un volume trop faible pour conclure."
          />
          <Insights insights={data.insights} />
        </div>
      )}

      <div className={styles.sec}>
        <SectionHead
          title="Évolution dans le temps"
          sub={
            data.period.grain === "HOUR"
              ? "Par heure — journée en cours."
              : data.period.grain === "WEEK"
                ? "Par semaine."
                : "Par jour, avec les repères produit et marketing posés sur la courbe."
          }
          right={
            <Segmented
              small
              ariaLabel="Mesure affichée"
              options={CHART_METRICS}
              value={metric}
              onChange={setMetric}
            />
          }
        />
        <Card>
          <LineChart
            series={data.series}
            prevSeries={compare ? data.prevSeries : null}
            metric={metric}
            annotations={data.annotations}
            height={272}
          />
        </Card>
      </div>

      <div className={`${styles.grid} ${styles.g3}`}>
        <Card
          title="Sources"
          question="d'où viennent les bons utilisateurs ?"
          actions={
            <button
              type="button"
              className={styles.chip}
              onClick={() => go("acquisition")}
            >
              Détail
              <Icon name="right" size={13} />
            </button>
          }
        >
          {topSources.length === 0 ? (
            <EmptyState>Aucune provenance mesurée sur cette période.</EmptyState>
          ) : (
            <>
              <div className={styles.barList}>
                {topSources.map((source) => (
                  <button
                    key={source.id}
                    type="button"
                    className={`${styles.barRow} ${styles.barRowClickable}`}
                    onClick={() => setFilter("source", source.id)}
                  >
                    <div className={styles.barRowTop}>
                      <span>{source.label}</span>
                    </div>
                    <div className={styles.barRowVal}>
                      {int(source.m.v)}
                      <span className={styles.barRowRight}>
                        <Heat value={rate(source.m.pay, source.m.v)} base={refPay} />
                      </span>
                    </div>
                    <div className={styles.barTrack}>
                      <i style={{ width: barWidth(source.m.v, maxSource, 2) }} />
                    </div>
                  </button>
                ))}
              </div>
              <div className={styles.barNote}>
                Volume de visiteurs · conversion visiteur → payant
              </div>
            </>
          )}
        </Card>

        <Card
          title="Diagnostic"
          question="est-ce qu'ils terminent l'expérience ?"
          actions={
            <button
              type="button"
              className={styles.chip}
              onClick={() => go("diagnostic")}
            >
              Détail
              <Icon name="right" size={13} />
            </button>
          }
        >
          {data.diagTypes.length === 0 ? (
            <EmptyState>Aucun diagnostic commencé sur cette période.</EmptyState>
          ) : (
            <div className={styles.stackedBlock}>
              {data.diagTypes.map((type, index) => (
                <div className={styles.diagRow} key={type.id}>
                  <div className={styles.diagRowHead}>
                    <span className={styles.diagRowTitle}>{type.label}</span>
                    <span className={styles.diagRowSub}>{type.sub}</span>
                    <span className={`${styles.mono} ${styles.diagRowRate}`}>
                      {pct(rate(type.done, type.start), 0)}
                    </span>
                  </div>
                  <div className={styles.barTrack} style={{ height: 8 }}>
                    <i
                      style={{
                        width: barWidth(type.done, type.start, 2),
                        background:
                          index === 0
                            ? "var(--blue)"
                            : "color-mix(in srgb, var(--blue) 55%, var(--paper))",
                      }}
                    />
                  </div>
                  <div className={styles.miniRowMeta}>
                    {int(type.start)} commencés · {int(type.done)} terminés ·{" "}
                    {int(type.prem)} clics Premium · {int(type.pay)} paiements
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>

        <Card
          title="Conversion Premium"
          question="veulent-ils acheter, et où abandonnent-ils ?"
          actions={
            <button
              type="button"
              className={styles.chip}
              onClick={() => go("conversion")}
            >
              Détail
              <Icon name="right" size={13} />
            </button>
          }
        >
          <div className={styles.stackedBlock}>
            {premiumRows.map((row) => (
              <div className={styles.summaryRow} key={row.label}>
                <span className={styles.num}>{int(row.value)}</span>
                <span className={styles.summaryLabel}>{row.label}</span>
                {row.conv != null && (
                  <span
                    className={`${styles.mono} ${styles.summaryRate} ${
                      row.conv < 0.25 ? styles.summaryRateLow : ""
                    }`}
                  >
                    {pct(row.conv, 0)}
                  </span>
                )}
              </div>
            ))}
            <div className={styles.miniRowMeta}>
              {money(total.revEurCents)} encaissés sur la période
            </div>
          </div>
        </Card>
      </div>
    </>
  );
}
