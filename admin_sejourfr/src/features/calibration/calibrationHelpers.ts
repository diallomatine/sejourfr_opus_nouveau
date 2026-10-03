import { formatDecimal } from "../../lib/evaluation";

export type HealthTone = "good" | "watch" | "bad";

export interface BiasReading {
  tone: HealthTone;
  /** Phrase complète, lisible par un non-statisticien. */
  sentence: string;
}

/**
 * Le backend calcule `ecart = note humaine − note IA`. Un écart moyen NÉGATIF
 * signifie donc que l'IA a mis plus de points que le correcteur : elle est trop
 * indulgente. C'est l'inverse de la lecture spontanée, d'où la phrase explicite.
 */
export function readBias(ecartMoyen: number, seuilHorsCible: number): BiasReading {
  const amplitude = Math.abs(ecartMoyen);
  const negligeable = seuilHorsCible / 12;
  const marque = seuilHorsCible / 3;

  if (amplitude < negligeable) {
    return {
      tone: "good",
      sentence:
        "Aucun biais net : l'IA ne penche globalement ni vers l'indulgence ni vers la sévérité.",
    };
  }

  const points = `${formatDecimal(amplitude)} point${amplitude >= 2 ? "s" : ""}`;
  const tone: HealthTone = amplitude >= marque ? "bad" : "watch";

  return ecartMoyen < 0
    ? {
        tone,
        sentence: `L'IA note en moyenne ${points} AU-DESSUS du correcteur : elle est trop indulgente.`,
      }
    : {
        tone,
        sentence: `L'IA note en moyenne ${points} EN DESSOUS du correcteur : elle est trop sévère.`,
      };
}

/** Même convention de signe, mais sur une seule production. */
export function readGap(ecart: number, seuilHorsCible: number): BiasReading {
  const amplitude = Math.abs(ecart);
  if (amplitude < 0.05) {
    return {
      tone: "good",
      sentence: "L'IA et le correcteur donnent exactement la même note.",
    };
  }

  const points = `${formatDecimal(amplitude)} point${amplitude >= 2 ? "s" : ""}`;
  const tone: HealthTone =
    amplitude > seuilHorsCible ? "bad" : amplitude >= seuilHorsCible / 2 ? "watch" : "good";

  return ecart < 0
    ? {
        tone,
        sentence: `L'IA a mis ${points} de plus que le correcteur : trop indulgente sur cette production.`,
      }
    : {
        tone,
        sentence: `L'IA a mis ${points} de moins que le correcteur : trop sévère sur cette production.`,
      };
}

export function readDispersion(
  ecartMoyenAbsolu: number,
  seuilHorsCible: number,
): HealthTone {
  if (ecartMoyenAbsolu >= seuilHorsCible / 2) return "bad";
  if (ecartMoyenAbsolu >= seuilHorsCible / 4) return "watch";
  return "good";
}
