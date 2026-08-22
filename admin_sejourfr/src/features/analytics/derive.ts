import type {
  AnalyticsFunnelStep,
  AnalyticsMetricKey,
  AnalyticsMetrics,
  AnalyticsSeriesPoint,
} from "../../types/api";

/**
 * Les onglets Diagnostic et Conversion isolent une SOUS-SEQUENCE du parcours
 * (« du rapport au paiement », « clic → EE → EO → rapport »). Le serveur ne
 * sert que l'entonnoir complet ; ces marches-la se derivent donc du vecteur
 * `total`, qui est deja arrondi a somme conservee. On ne recalcule jamais un
 * pourcentage que le serveur a deja rendu — seulement des rapports entre deux
 * de ses mesures.
 */
export function buildSteps(
  total: AnalyticsMetrics,
  defs: { k: AnalyticsMetricKey; label: string; q?: string }[],
): AnalyticsFunnelStep[] {
  return defs.map((def, index) => {
    const previous = index ? total[defs[index - 1].k] : null;
    const value = total[def.k];
    const conv = previous ? value / previous : null;
    return {
      k: def.k,
      label: def.label,
      q: def.q ?? "",
      value,
      conv,
      lost: previous ? previous - value : 0,
      lostShare: conv == null ? 0 : 1 - conv,
    };
  });
}

/** Valeurs mesurees d'une metrique, pour une micro-courbe. */
export function sparkValues(
  series: AnalyticsSeriesPoint[],
  metric: AnalyticsMetricKey,
): number[] {
  return series.filter((point) => !point.empty).map((point) => point.m[metric]);
}

/**
 * La periode porte-t-elle assez de matiere pour etre lue ? En dessous, l'ecran
 * le DIT au lieu d'afficher des zeros qu'on prendrait pour des mesures.
 */
export function hasAnyData(total: AnalyticsMetrics): boolean {
  return total.v > 0 || total.sig > 0 || total.pay > 0 || total.start > 0;
}
