import { InlineError } from "../../../components/ui/InlineError";
import { StatTile } from "../../../components/ui/StatTile";
import { httpErrorMessage } from "../../../api/http";
import { DASH, int } from "../../../lib/format";
import type { AdminProductionStatsDto } from "../../../types/api";
import styles from "./ProductionStats.module.css";

interface ProductionStatsProps {
  data: AdminProductionStatsDto | undefined;
  error: unknown;
  stale: boolean;
  onRetry: () => void;
}

/**
 * Encart au-dessus de la liste (DI-35) : la période choisie et les comptes
 * internes, rien d'autre. Toutes les valeurs sont servies par
 * `GET /api/admin/productions/stats` ; aucune somme, aucun pourcentage ici.
 */
export function ProductionStats({ data, error, stale, onRetry }: ProductionStatsProps) {
  if (error && !data) {
    return (
      <InlineError onRetry={onRetry}>
        Impossible de charger la vue d’ensemble : {httpErrorMessage(error)}
      </InlineError>
    );
  }
  const c = data?.compteurs;
  const value = (n: number | undefined) => (n === undefined ? DASH : int(n));

  return (
    <section
      className={`${styles.grid} ${stale ? styles.stale : ""}`}
      aria-label="Vue d’ensemble de la période"
      aria-busy={stale || !data}
    >
      <StatTile
        label="Productions soumises"
        value={value(c?.total)}
        trend={c ? `EE ${int(c.ee)} · EO ${int(c.eo)}` : DASH}
        neutral
      />
      <StatTile
        label="Candidats"
        value={value(data?.candidats)}
        trend="comptes distincts"
        neutral
      />
      <StatTile
        label="Avec examinateur IA"
        value={value(c?.avecExaminateur)}
        trend="EO en temps réel"
        neutral
      />
      <StatTile
        label="Évaluées"
        value={value(c?.evaluees)}
        trend={c ? `en cours : ${int(c.enCours)}` : DASH}
        neutral
      />
      <StatTile
        label="Non évaluables"
        value={value(c?.nonEvaluables)}
        trend="écartées avant correction"
        neutral
      />
      <StatTile label="En échec" value={value(c?.enEchec)} trend="traitement interrompu" neutral />
      <StatTile
        label="Signalées"
        value={value(c?.signalees)}
        trend="à vérifier"
        neutral
      />
    </section>
  );
}
