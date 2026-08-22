import type { AnalyticsCampaignStat, AnalyticsSourceStat } from "../../../types/api";
import { int, money, pct, rate } from "../format";
import type { TabProps } from "../types";
import styles from "../analytics.module.css";
import { BarList } from "../components/BarList";
import { Card, EmptyBlock, EmptyState, Note, SectionHead } from "../components/Card";
import { DataTable, Heat, TBar, type Column } from "../components/DataTable";
import { Delta } from "../components/Delta";
import { Funnel } from "../components/Funnel";
import { QualityMap } from "../components/QualityMap";

export function AcquisitionTab({
  data,
  compare,
  filters,
  setFilter,
  openDetail,
}: TabProps) {
  const total = data.total;
  const refPay = rate(total.pay, total.v);
  const refSig = rate(total.sig, total.v);

  const sources = [...data.sources].sort((a, b) => b.m.v - a.m.v);
  const maxV = Math.max(...sources.map((source) => source.m.v), 1);
  const previousOf = (id: string) =>
    compare ? data.prevSources.find((source) => source.id === id)?.m ?? null : null;

  const cols: Column<AnalyticsSourceStat>[] = [
    {
      key: "src",
      label: "Source",
      cell: "key",
      render: (row) => (
        <span className={styles.cellWithBar}>
          <TBar value={row.m.v} max={maxV} />
          {row.label}
        </span>
      ),
    },
    { key: "v", label: "Visiteurs", cell: "strong", render: (row) => int(row.m.v) },
    {
      key: "dv",
      label: "vs préc.",
      hideSmall: true,
      render: (row) => (
        <Delta current={row.m.v} previous={previousOf(row.id)?.v} showFlat={false} />
      ),
    },
    { key: "sig", label: "Inscrits", render: (row) => int(row.m.sig) },
    {
      key: "csig",
      label: "Conv. inscr.",
      hideSmall: true,
      render: (row) => (
        <Heat value={rate(row.m.sig, row.m.v)} base={refSig} digits={1} />
      ),
    },
    {
      key: "rep",
      label: "Diag. terminés",
      hideSmall: true,
      render: (row) => int(row.m.rep),
    },
    {
      key: "prem",
      label: "Clics Premium",
      hideSmall: true,
      render: (row) => int(row.m.prem),
    },
    { key: "pay", label: "Payants", cell: "strong", render: (row) => int(row.m.pay) },
    {
      key: "cpay",
      label: "Conv. payante",
      render: (row) => <Heat value={rate(row.m.pay, row.m.v)} base={refPay} />,
    },
    { key: "rev", label: "Revenu", render: (row) => money(row.m.revEurCents) },
    {
      key: "arpv",
      label: "Rev./visiteur",
      hideSmall: true,
      render: (row) => money(rate(row.m.revEurCents, row.m.v)),
    },
  ];

  const foot = {
    src: "Total",
    v: int(total.v),
    sig: int(total.sig),
    rep: int(total.rep),
    prem: int(total.prem),
    pay: int(total.pay),
    cpay: pct(refPay, 2),
    rev: money(total.revEurCents),
    arpv: money(rate(total.revEurCents, total.v)),
  };

  const campaigns = data.campaigns.filter((campaign) => campaign.v > 0).slice(0, 12);
  const maxCampaign = Math.max(...campaigns.map((campaign) => campaign.v), 1);
  const campaignCols: Column<AnalyticsCampaignStat>[] = [
    {
      key: "name",
      label: "Campagne / contenu",
      cell: "key",
      render: (row) => (
        <span className={styles.cellWithBar}>
          <TBar value={row.v} max={maxCampaign} />
          <span className={styles.cellTwoLines}>
            <span>{row.name}</span>
            <span className={styles.cellMeta}>
              utm_source={row.sourceId}
              {row.medium ? ` · utm_medium=${row.medium}` : ""}
              {row.content ? ` · ${row.content}` : ""}
            </span>
          </span>
        </span>
      ),
    },
    { key: "v", label: "Visites", cell: "strong", render: (row) => int(row.v) },
    {
      key: "start",
      label: "Diagnostics",
      hideSmall: true,
      render: (row) => int(row.start),
    },
    { key: "sig", label: "Inscriptions", render: (row) => int(row.sig) },
    {
      key: "prem",
      label: "Clics Premium",
      hideSmall: true,
      render: (row) => int(row.prem),
    },
    { key: "pay", label: "Abonnés", cell: "strong", render: (row) => int(row.pay) },
    {
      key: "cpay",
      label: "Conv. payante",
      render: (row) => <Heat value={rate(row.pay, row.v)} base={refPay} />,
    },
  ];

  const top = sources[0];

  return (
    <>
      {filters.source && (
        <div className={styles.sec}>
          <SectionHead
            title={`Parcours ${top ? top.label : ""}`}
            sub="Le tableau de bord entier est filtré sur cette source — chaque étape ne compte que ses utilisateurs."
          />
          <Card>
            <Funnel
              steps={data.funnel}
              compact
              onStep={(step) =>
                openDetail({ kind: "step", stepKey: step.k, label: step.label })
              }
            />
          </Card>
        </div>
      )}

      <div className={styles.sec}>
        <SectionHead
          title="Sources"
          sub="Volume acquis et qualité côte à côte : une source qui amène beaucoup d'inscrits sans paiement se voit immédiatement. Cliquez sur une ligne pour filtrer tout le tableau de bord."
        />
        {sources.length === 0 ? (
          <EmptyBlock>
            Aucune provenance n'a été mesurée sur cette période.
          </EmptyBlock>
        ) : (
          <Card>
            <DataTable
              cols={cols}
              rows={sources}
              keyOf={(row) => row.id}
              foot={foot}
              onRow={(row) =>
                setFilter("source", filters.source === row.id ? null : row.id)
              }
            />
          </Card>
        )}
      </div>

      <div className={`${styles.grid} ${styles.g75}`}>
        <Card
          title="Volume × qualité"
          question="quelle source amène les utilisateurs qui paient ?"
        >
          <QualityMap
            rows={sources.map((source) => ({
              id: source.id,
              label: source.label,
              v: source.m.v,
              rate: rate(source.m.pay, source.m.v),
              revEurCents: source.m.revEurCents,
            }))}
            avg={refPay}
            onPick={(id) => setFilter("source", id)}
          />
        </Card>

        <Card title="Part de chaque source" question="ma dépendance est-elle saine ?">
          {sources.length === 0 ? (
            <EmptyState />
          ) : (
            <>
              <BarList
                rows={sources.map((source) => ({
                  id: source.id,
                  label: source.label,
                  value: source.m.v,
                  sub: pct(rate(source.m.v, total.v), 0),
                  right: `${int(source.m.pay)} payants`,
                }))}
                onRow={(row) => setFilter("source", row.id)}
              />
              {top && (
                <div className={styles.padded}>
                  <Note>
                    <strong>{top.label}</strong> représente{" "}
                    {pct(rate(top.m.v, total.v), 0)} du trafic et{" "}
                    {pct(rate(top.m.pay, total.pay), 0)} des paiements.{" "}
                    {total.pay > 0 &&
                    (rate(top.m.pay, total.pay) ?? 0) < (rate(top.m.v, total.v) ?? 0)
                      ? "Le volume ne se transforme pas au même rythme."
                      : total.pay > 0
                        ? "La qualité suit le volume."
                        : "Aucun paiement sur la période : la qualité reste indéterminée."}
                  </Note>
                </div>
              )}
            </>
          )}
        </Card>
      </div>

      <div className={styles.sec}>
        <SectionHead
          title="Campagnes & contenus"
          sub="Quel contenu marketing génère réellement du revenu — pas seulement des vues."
        />
        {campaigns.length === 0 ? (
          <EmptyBlock title="Aucune campagne identifiée sur cette période.">
            Les campagnes apparaissent dès qu'un lien porte des paramètres{" "}
            <code>utm_*</code>.
          </EmptyBlock>
        ) : (
          <Card>
            <DataTable
              cols={campaignCols}
              rows={campaigns}
              keyOf={(row) => row.id}
              onRow={(row) => setFilter("source", row.sourceId)}
            />
          </Card>
        )}
      </div>
    </>
  );
}
