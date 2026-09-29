import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { aiCostsApi } from "../../api/aiCostsApi";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import type { AiCostLigne } from "../../types/api";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./AiCostsPage.module.css";

const PERIODES = [7, 30, 90, 365] as const;

/**
 * **Ce que l'IA coûte** (lot L12, `00_` §8.4).
 *
 * Tout vient de la vue `v_ai_usage`, qui **lit** les quatre endroits où le
 * backend écrit déjà ce coût. Cet écran n'en dérive aucun : il met en forme.
 *
 * 🛑 **Les deux unités ne se mélangent jamais.** Millionièmes de dollar
 * (colonne vivante) et centimes d'euro (colonne ancienne, plus jamais écrite)
 * ont chacune leur colonne, et il n'existe nulle part un total qui les
 * additionne.
 *
 * 🛑 **Un coût inconnu s'affiche « — », jamais « 0,00 $ ».** Et le nombre
 * d'appels sans coût est montré à côté de chaque total : sans lui, un montant
 * bas se lit « l'IA ne coûte presque rien » alors qu'il se lit « on ne sait pas
 * ce qu'elle a coûté ».
 */
export function AiCostsPage() {
  const [days, setDays] = useState<number>(30);
  const { data, isLoading, error } = useQuery({
    queryKey: ["ai-costs", days],
    queryFn: ({ signal }) => aiCostsApi.get(days, signal),
  });

  return (
    <>
      <PageHeader
        eyebrow="Supervision"
        title="Coût de l'"
        emphasis="IA"
        actions={
          <div className={styles.periodes}>
            {PERIODES.map((p) => (
              <button
                key={p}
                type="button"
                className={p === days ? styles.periodeActive : styles.periode}
                onClick={() => setDays(p)}
              >
                {p} j
              </button>
            ))}
          </div>
        }
      />

      {isLoading && <Spinner />}
      {error && (
        <EmptyState title="Le coût IA n'a pas pu être lu." />
      )}

      {data && (
        <>
          <Panel
            title="Total de la période"
            sub={`Du ${data.from} au ${data.to}, bornes appliquées par le serveur.`}
          >
            <div className={styles.totaux}>
              <Chiffre label="Appels" valeur={String(data.total.appels)} />
              <Chiffre label="Coût (micro-USD)" valeur={usd(data.total.coutMicroUsd)} />
              <Chiffre
                label="Ancien coût (centimes €)"
                valeur={centimes(data.total.coutLegacyCentimes)}
              />
              {/* 🛑 Le chiffre qui empêche de mal lire les trois autres. */}
              <Chiffre
                label="Appels au coût inconnu"
                valeur={String(data.total.lignesSansCout)}
                alerte={data.total.lignesSansCout > 0}
              />
            </div>
            <p className={styles.note}>
              Les deux colonnes de coût sont dans des unités et des devises
              différentes : elles ne s'additionnent pas.
            </p>
          </Panel>

          <Panel
            title="Coût moyen d'un diagnostic mené à terme"
            sub="Rapport de deux totaux de fenêtre, pas une moyenne par session."
          >
            <div className={styles.totaux}>
              <Chiffre
                label="Diagnostics clos"
                valeur={String(data.diagnosticComplet.sessions)}
              />
              <Chiffre
                label="Coût moyen (micro-USD)"
                valeur={usd(data.diagnosticComplet.moyenneMicroUsd)}
              />
              <Chiffre
                label="Coût total diagnostic"
                valeur={usd(data.diagnosticComplet.totalMicroUsd)}
              />
            </div>
          </Panel>

          <Tableau titre="Par nature d'appel" lignes={data.parFamille} />
          <Tableau titre="Par source" lignes={data.parSource} />
          <Tableau titre="Par modèle" lignes={data.parModele} />
        </>
      )}
    </>
  );
}

function Tableau({ titre, lignes }: { titre: string; lignes: AiCostLigne[] }) {
  if (lignes.length === 0) {
    return (
      <Panel title={titre}>
        <EmptyState title="Aucun appel sur cette période." />
      </Panel>
    );
  }
  return (
    <Panel title={titre} noPadding>
      <table className={tableStyles.table}>
        <thead>
          <tr>
            <th>Clé</th>
            <th>Appels</th>
            <th>Sans coût</th>
            <th>Tokens in</th>
            <th>Tokens out</th>
            <th>Cache</th>
            <th>micro-USD</th>
            <th>centimes €</th>
          </tr>
        </thead>
        <tbody>
          {lignes.map((ligne) => (
            <tr key={ligne.cle ?? "total"}>
              <td>{ligne.cle ?? "—"}</td>
              <td>{ligne.appels}</td>
              <td className={ligne.lignesSansCout > 0 ? styles.alerte : undefined}>
                {ligne.lignesSansCout}
              </td>
              <td>{nombre(ligne.tokensInput)}</td>
              <td>{nombre(ligne.tokensOutput)}</td>
              <td>{nombre(ligne.tokensInputCacheHit)}</td>
              <td>{usd(ligne.coutMicroUsd)}</td>
              <td>{centimes(ligne.coutLegacyCentimes)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </Panel>
  );
}

function Chiffre({
  label,
  valeur,
  alerte,
}: {
  label: string;
  valeur: string;
  alerte?: boolean;
}) {
  return (
    <div className={styles.chiffre}>
      <span className={styles.chiffreLabel}>{label}</span>
      <strong className={alerte ? styles.alerte : undefined}>{valeur}</strong>
    </div>
  );
}

/**
 * 🛑 `null` s'affiche « — », jamais « 0 ». Un coût inconnu n'est pas un coût
 * nul, et c'est toute la différence entre « gratuit » et « on ne sait pas ».
 */
function nombre(value: number | null): string {
  return value === null ? "—" : value.toLocaleString("fr-FR");
}

/** Millionièmes de dollar → dollars, 4 décimales : les appels sont minuscules. */
function usd(microUsd: number | null): string {
  if (microUsd === null) return "—";
  return `${(microUsd / 1_000_000).toLocaleString("fr-FR", {
    minimumFractionDigits: 4,
    maximumFractionDigits: 4,
  })} $`;
}

/** Centimes d'euro → euros. Colonne **ancienne** : plus rien ne l'alimente. */
function centimes(value: number | null): string {
  if (value === null) return "—";
  return `${(value / 100).toLocaleString("fr-FR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })} €`;
}
