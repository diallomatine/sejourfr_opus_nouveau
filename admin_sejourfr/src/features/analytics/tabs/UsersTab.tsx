import { Fragment } from "react";
import type {
  AnalyticsCountryStat,
  AnalyticsDeviceStat,
} from "../../../types/api";
import { barWidth, int, money, pct, rate } from "../format";
import type { TabProps } from "../types";
import styles from "../analytics.module.css";
import { BarList } from "../components/BarList";
import { Card, EmptyBlock, EmptyState, Note, SectionHead } from "../components/Card";
import { DataTable, Heat, TBar, type Column } from "../components/DataTable";

export function UsersTab({ data, filters, setFilter }: TabProps) {
  const total = data.total;
  const refPay = rate(total.pay, total.v);
  const refSig = rate(total.sig, total.v);
  const refSigToPay = rate(total.pay, total.sig);

  const countries = data.countries;
  const maxCountry = Math.max(...countries.map((country) => country.v), 1);

  const countryCols: Column<AnalyticsCountryStat>[] = [
    {
      key: "country",
      label: "Pays",
      cell: "key",
      render: (row) => (
        <span className={styles.cellWithBar}>
          <TBar value={row.v} max={maxCountry} />
          {row.label}
        </span>
      ),
    },
    { key: "v", label: "Visiteurs", cell: "strong", render: (row) => int(row.v) },
    {
      key: "share",
      label: "Part",
      hideSmall: true,
      render: (row) => pct(rate(row.v, total.v), 0),
    },
    { key: "sig", label: "Inscrits", render: (row) => int(row.sig) },
    {
      key: "csig",
      label: "Conv. inscr.",
      hideSmall: true,
      render: (row) => <Heat value={rate(row.sig, row.v)} base={refSig} digits={1} />,
    },
    { key: "pay", label: "Payants", cell: "strong", render: (row) => int(row.pay) },
    {
      key: "cpay",
      label: "Inscrit → payant",
      render: (row) => (
        <Heat value={rate(row.pay, row.sig)} base={refSigToPay} digits={1} />
      ),
    },
    { key: "rev", label: "Revenu", render: (row) => money(row.revEurCents) },
  ];

  const deviceCols: Column<AnalyticsDeviceStat>[] = [
    { key: "device", label: "Plateforme", cell: "key", render: (row) => row.label },
    { key: "v", label: "Visiteurs", cell: "strong", render: (row) => int(row.v) },
    { key: "rep", label: "Diag. terminés", render: (row) => int(row.rep) },
    {
      key: "csig",
      label: "Conv. inscription",
      render: (row) => <Heat value={rate(row.sig, row.v)} base={refSig} digits={1} />,
    },
    {
      key: "cpay",
      label: "Conv. paiement",
      render: (row) => <Heat value={rate(row.pay, row.v)} base={refPay} />,
    },
    { key: "pay", label: "Payants", render: (row) => int(row.pay) },
  ];

  const signupsBySource = [...data.sources].sort((a, b) => b.m.sig - a.m.sig);

  const biggestCountry = countries[0] ?? null;
  const bestCountry = [...countries]
    .filter((country) => country.sig > 0 && country.pay > 0)
    .sort(
      (a, b) => (rate(b.pay, b.sig) ?? 0) - (rate(a.pay, a.sig) ?? 0),
    )[0] ?? null;

  const worstDevice = [...data.devices]
    .filter((device) => device.v > 0)
    .sort((a, b) => (rate(a.pay, a.v) ?? 0) - (rate(b.pay, b.v) ?? 0))[0] ?? null;

  return (
    <>
      <div className={styles.sec}>
        <SectionHead
          title="Nouvelles inscriptions"
          sub={`${int(total.sig)} ${total.sig > 1 ? "comptes créés" : "compte créé"} sur la période · ${int(data.totalUsers)} utilisateurs inscrits au total.`}
        />
        <div className={`${styles.grid} ${styles.g75}`}>
          <Card title="Par source" question="d'où viennent les comptes ?">
            {signupsBySource.length === 0 ? (
              <EmptyState>Aucune inscription sur cette période.</EmptyState>
            ) : (
              <BarList
                rows={signupsBySource.map((source) => ({
                  id: source.id,
                  label: source.label,
                  value: source.m.sig,
                  sub: pct(rate(source.m.sig, total.sig), 0),
                  right: `${int(source.m.pay)} payants`,
                }))}
                onRow={(row) => setFilter("source", row.id)}
              />
            )}
          </Card>

          <Card title="Par étape déclencheuse" question="quel moment crée le compte ?">
            {data.triggers.length === 0 ? (
              <EmptyState>
                Aucun contexte d'inscription mesuré sur cette période.
              </EmptyState>
            ) : (
              <div className={styles.barList}>
                {data.triggers.map((trigger) => (
                  <div className={styles.barRow} key={trigger.id}>
                    <div className={styles.barRowTop}>
                      <span>{trigger.label}</span>
                    </div>
                    <div className={styles.barRowVal}>
                      {int(trigger.sig)}
                      <span className={styles.barRowRight}>
                        {pct(trigger.share, 0)}
                      </span>
                    </div>
                    <div className={styles.miniRowMeta}>{trigger.hint}</div>
                    <div className={styles.barTrack}>
                      <i
                        style={{
                          width: barWidth(
                            trigger.share,
                            data.triggers[0].share || 1,
                            2,
                          ),
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

      <div className={styles.sec}>
        <SectionHead
          title="Parcours principaux avant inscription"
          sub="Les chemins les plus fréquents, en part des comptes créés."
        />
        {data.paths.length === 0 ? (
          <EmptyBlock title="Aucun parcours reconstitué sur cette période.">
            Un parcours se reconstitue dès qu'un visiteur enchaîne plusieurs
            écrans avant de créer son compte.
          </EmptyBlock>
        ) : (
          <Card>
            {data.paths.map((path, index) => (
              <div className={styles.path} key={path.chain.join(">")}>
                <div className={styles.pathChain}>
                  <span className={`${styles.lbl} ${styles.pathRank}`}>
                    #{index + 1}
                  </span>
                  {path.chain.map((node, position) => (
                    <Fragment key={`${node}-${position}`}>
                      {position > 0 && <em className={styles.pathArrow}>→</em>}
                      <b>{node}</b>
                    </Fragment>
                  ))}
                </div>
                <div className={styles.pathMeta}>
                  <span className={`${styles.mono} ${styles.pathShare}`}>
                    {pct(path.share, 0)}
                  </span>
                  <div className={styles.barTrack}>
                    <i
                      style={{
                        width: barWidth(path.share, data.paths[0].share || 1, 2),
                      }}
                    />
                  </div>
                  <span className={styles.pathCount}>
                    {int(path.sig)}{" "}
                    {path.sig > 1 ? "inscriptions" : "inscription"}
                  </span>
                </div>
              </div>
            ))}
          </Card>
        )}
      </div>

      <div className={styles.sec}>
        <SectionHead
          title="Audience"
          sub="Le volume d'audience et la valeur commerciale ne se superposent pas : la colonne « inscrit → payant » tranche."
        />
        {countries.length === 0 ? (
          <EmptyBlock>
            Aucun pays mesuré sur cette période.
          </EmptyBlock>
        ) : (
          <>
            <Card>
              <DataTable
                cols={countryCols}
                rows={countries}
                keyOf={(row) => row.id}
                onRow={(row) =>
                  setFilter("country", filters.country === row.id ? null : row.id)
                }
                foot={{
                  country: "Total",
                  v: int(total.v),
                  sig: int(total.sig),
                  pay: int(total.pay),
                  cpay: pct(refSigToPay, 1),
                  rev: money(total.revEurCents),
                }}
              />
            </Card>
            {biggestCountry && bestCountry && biggestCountry.id !== bestCountry.id && (
              <Note>
                <strong>{biggestCountry.label}</strong> pèse{" "}
                {pct(rate(biggestCountry.v, total.v), 0)} de l'audience pour{" "}
                {int(biggestCountry.pay)}{" "}
                {biggestCountry.pay > 1 ? "paiements" : "paiement"}, quand{" "}
                <strong>{bestCountry.label}</strong> transforme{" "}
                {pct(rate(bestCountry.pay, bestCountry.sig), 1)} de ses inscrits en
                abonnés. Deux audiences, deux stratégies : volume d'un côté,
                revenu de l'autre.
              </Note>
            )}
          </>
        )}
      </div>

      <div className={`${styles.grid} ${styles.g75}`}>
        <Card
          title="Device & plateforme"
          question="un canal technique bloque-t-il la conversion ?"
        >
          {data.devices.length === 0 ? (
            <EmptyState />
          ) : (
            <>
              <DataTable
                cols={deviceCols}
                rows={data.devices}
                keyOf={(row) => row.id}
                onRow={(row) =>
                  setFilter("device", filters.device === row.id ? null : row.id)
                }
              />
              {worstDevice && total.pay > 0 && data.devices.length > 1 && (
                <div className={styles.padded}>
                  <Note>
                    <strong>{worstDevice.label}</strong> concentre{" "}
                    {pct(rate(worstDevice.v, total.v), 0)} du trafic mais convertit
                    à {pct(rate(worstDevice.pay, worstDevice.v), 2)} — le plus
                    faible de tous les supports.
                  </Note>
                </div>
              )}
            </>
          )}
        </Card>

        <Card title="Rétention" question="prévu pour la suite">
          <RetentionPlaceholder />
        </Card>
      </div>
    </>
  );
}

/** Le meme bloc sert la carte d'Utilisateurs et l'onglet Retention desactive. */
export function RetentionPlaceholder() {
  return (
    <div className={styles.soon}>
      <span className={styles.lbl}>Bientôt</span>
      <p>
        Cet emplacement accueillera la rétention des abonnés : activité D1 / D7 /
        D30, renouvellement, désabonnement, exercices réalisés et examens blancs
        passés.
      </p>
      <div className={styles.soonTags}>
        {[
          "D1 / D7 / D30",
          "Renouvellement",
          "Désabonnement",
          "Exercices",
          "Examens blancs",
        ].map((tag) => (
          <span className={styles.soonTag} key={tag}>
            {tag}
          </span>
        ))}
      </div>
    </div>
  );
}
