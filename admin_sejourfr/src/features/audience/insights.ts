import type {
  FunnelSourceStat,
  FunnelStage,
  FunnelStatsResponse,
} from "../../types/api";
import { STAGE_LABELS, UNKNOWN_SOURCE, sourceLabel } from "./labels";

/* ------------------------------------------------------------------ *
 * HONNÊTETÉ STATISTIQUE — les trois seuils qui autorisent à conclure.
 *
 * Sur un petit volume, « TikTok convertit le mieux » n'est pas une
 * observation, c'est du bruit : un seul paiement de plus renverse le
 * classement. La phrase de synthèse REFUSE donc de conclure sous ces
 * seuils — elle énonce alors les chiffres et dit pourquoi elle s'arrête
 * là. Les chiffres, eux, restent tous affichés : on masque une
 * conclusion, jamais une donnée.
 * ------------------------------------------------------------------ */

/** En dessous, aucune marche du parcours n'est désignée comme « celle qui fuit ». */
export const MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE = 10;

/** En dessous, aucune provenance n'est désignée comme « celle qui convertit le mieux ». */
export const MIN_SIGNUPS_POUR_COMPARER_LES_RESEAUX = 20;

/** Un réseau ne se compare pas à 3 inscrits, même si le total de la période est élevé. */
export const MIN_SIGNUPS_PAR_RESEAU = 5;

/** Une marche du parcours : ce qu'on perd entre deux étapes consécutives. */
export interface FunnelLeak {
  from: FunnelStage;
  to: FunnelStage;
  /** Index de l'étape d'ARRIVÉE dans `stages` — celle qu'on met en évidence. */
  toIndex: number;
  lost: number;
}

export interface SourceScore extends FunnelSourceStat {
  /** Payants ÷ inscrits, en %. Null si la provenance n'a aucun inscrit. */
  conversion: number | null;
}

export type SummaryTone = "fact" | "caveat";

export interface SummaryPart {
  tone: SummaryTone;
  text: string;
}

export interface AudienceInsights {
  signups: number;
  diagnosticsCompleted: number;
  purchases: number;
  /** Payants ÷ inscrits, en %. Null si aucun inscrit. */
  conversion: number | null;
  /** La marche qui perd le plus de comptes. Null si le parcours ne perd personne. */
  leak: FunnelLeak | null;
  /** Provenance désignée par la synthèse. Null si le volume interdit de conclure. */
  bestSource: SourceScore | null;
  /** Toutes les provenances, classées (cf. `compareSources`). */
  ranking: SourceScore[];
  summary: SummaryPart[];
}

export function buildInsights(stats: FunnelStatsResponse): AudienceInsights {
  const stages = stats.stages;
  const signups = stageCount(stages, "SIGNUP");
  const diagnosticsCompleted = stageCount(stages, "DIAGNOSTIC_COMPLETED");
  const purchases = stageCount(stages, "PURCHASE");
  const conversion = ratio(purchases, signups);

  const leak = biggestLeak(stats);
  const ranking = rankSources(stats.bySource);
  const candidate = bestConvertingSource(ranking);
  const canCompareSources =
    signups >= MIN_SIGNUPS_POUR_COMPARER_LES_RESEAUX && candidate !== null;

  return {
    signups,
    diagnosticsCompleted,
    purchases,
    conversion,
    leak,
    bestSource: canCompareSources ? candidate : null,
    ranking,
    summary: buildSummary({
      signups,
      purchases,
      conversion,
      leak,
      candidate,
      canCompareSources,
    }),
  };
}

/**
 * La marche qui perd le plus de COMPTES, en valeur absolue : c'est ce qui coûte
 * réellement des paiements. À égalité, la plus précoce l'emporte — une fuite
 * haute ampute mécaniquement tout ce qui suit.
 */
function biggestLeak(stats: FunnelStatsResponse): FunnelLeak | null {
  let worst: FunnelLeak | null = null;

  for (let i = 1; i < stats.stages.length; i += 1) {
    const previous = stats.stages[i - 1];
    const current = stats.stages[i];
    const lost = previous.count - current.count;

    if (lost > 0 && (worst === null || lost > worst.lost)) {
      worst = {
        from: previous.stage,
        to: current.stage,
        toIndex: i,
        lost,
      };
    }
  }

  return worst;
}

/**
 * Classement affiché : d'abord le VOLUME DE PAYANTS, ensuite seulement le taux.
 * Trier sur le taux seul hisserait en tête une provenance à 1 inscrit et
 * 1 payant (100 %), qui n'a rien démontré. La provenance inconnue (comptes
 * antérieurs à la mesure) reste toujours en dernier : ce n'est pas un canal
 * sur lequel on peut investir.
 */
export function compareSources(a: SourceScore, b: SourceScore): number {
  if (a.source === UNKNOWN_SOURCE) return 1;
  if (b.source === UNKNOWN_SOURCE) return -1;
  if (b.purchases !== a.purchases) return b.purchases - a.purchases;
  if ((b.conversion ?? 0) !== (a.conversion ?? 0)) {
    return (b.conversion ?? 0) - (a.conversion ?? 0);
  }
  if (b.signups !== a.signups) return b.signups - a.signups;
  return a.source.localeCompare(b.source, "fr");
}

function rankSources(sources: FunnelSourceStat[]): SourceScore[] {
  return sources
    .map((source) => ({
      ...source,
      conversion: ratio(source.purchases, source.signups),
    }))
    .sort(compareSources);
}

/** Meilleur taux parmi les provenances qui ont assez d'inscrits ET au moins un payant. */
function bestConvertingSource(ranking: SourceScore[]): SourceScore | null {
  const eligible = ranking.filter(
    (source) =>
      source.source !== UNKNOWN_SOURCE &&
      source.signups >= MIN_SIGNUPS_PAR_RESEAU &&
      source.purchases > 0,
  );

  return eligible.reduce<SourceScore | null>((best, source) => {
    if (best === null) return source;
    if ((source.conversion ?? 0) > (best.conversion ?? 0)) return source;
    return best;
  }, null);
}

function buildSummary({
  signups,
  purchases,
  conversion,
  leak,
  candidate,
  canCompareSources,
}: {
  signups: number;
  purchases: number;
  conversion: number | null;
  leak: FunnelLeak | null;
  candidate: SourceScore | null;
  canCompareSources: boolean;
}): SummaryPart[] {
  const parts: SummaryPart[] = [];

  parts.push({
    tone: "fact",
    text:
      purchases === 0
        ? `Sur cette période, ${count(signups)} ${plural(signups, "inscrit", "inscrits")} et aucun paiement.`
        : `Sur cette période, ${count(signups)} ${plural(signups, "inscrit", "inscrits")} et ${count(purchases)} ${plural(purchases, "payant", "payants")}${conversion === null ? "" : ` (${percent(conversion)})`}.`,
  });

  if (signups < MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE) {
    parts.push({
      tone: "caveat",
      text: `Sous ${MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE} inscrits, aucune étape n'est désignée comme celle qui fuit : l'écart tiendrait au hasard.`,
    });
  } else if (leak === null) {
    parts.push({
      tone: "fact",
      text: "Aucune étape ne perd de compte : tout le monde va au bout.",
    });
  } else {
    parts.push({
      tone: "fact",
      text: `La plus grosse perte est entre « ${STAGE_LABELS[leak.from]} » et « ${STAGE_LABELS[leak.to]} » (−${count(leak.lost)} ${plural(leak.lost, "compte", "comptes")}).`,
    });
  }

  if (canCompareSources && candidate !== null) {
    parts.push({
      tone: "fact",
      text: `${sourceLabel(candidate.source)} convertit le mieux : ${count(candidate.purchases)} ${plural(candidate.purchases, "payant", "payants")} sur ${count(candidate.signups)} ${plural(candidate.signups, "inscrit", "inscrits")}${candidate.conversion === null ? "" : ` (${percent(candidate.conversion)})`}.`,
    });
  } else if (signups < MIN_SIGNUPS_POUR_COMPARER_LES_RESEAUX) {
    parts.push({
      tone: "caveat",
      text: `Il faut au moins ${MIN_SIGNUPS_POUR_COMPARER_LES_RESEAUX} inscrits pour comparer les provenances entre elles : le classement reste affiché, il ne conclut rien.`,
    });
  } else {
    parts.push({
      tone: "caveat",
      text: `Aucune provenance n'atteint encore ${MIN_SIGNUPS_PAR_RESEAU} inscrits avec au moins un paiement : rien à départager.`,
    });
  }

  return parts;
}

function stageCount(
  stages: FunnelStatsResponse["stages"],
  stage: FunnelStage,
): number {
  return stages.find((s) => s.stage === stage)?.count ?? 0;
}

/* ---------- Formatage partagé par toute la feature ---------- */

export function ratio(count: number, base: number): number | null {
  if (base <= 0) return null;
  return (count * 100) / base;
}

export function count(value: number): string {
  return value.toLocaleString("fr-FR");
}

export function percent(value: number | null): string {
  if (value === null) return "—";
  return `${value.toFixed(1).replace(".", ",")} %`;
}

export function percentOf(value: number, base: number): string {
  return percent(ratio(value, base));
}

export function plural(value: number, one: string, many: string): string {
  return value > 1 ? many : one;
}

/** Largeur de barre bornée à 100 %, en pourcentage d'une base. */
export function barWidth(value: number, base: number): string {
  if (base <= 0) return "0%";
  return `${Math.min(100, Math.max(0, (value * 100) / base))}%`;
}
