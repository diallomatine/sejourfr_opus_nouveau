import type {EpreuveType} from "@/lib/types";

/**
 * Config d'une épreuve productive (Expression écrite / orale). Pilote les
 * composants génériques `Production*` : même flux (hub → tâches → input →
 * feedback IA → examen blanc 3 tâches → historique), seul l'input change
 * (rédaction texte vs enregistrement audio).
 */
export interface ProductionConfig {
  epreuve: Extract<EpreuveType, "TCF_EE" | "TCF_EO">;
  /** Racine des routes, ex: `/entrainement/tcf/ee`. */
  base: string;
  label: string; // "Expression écrite" / "Expression orale"
  shortLabel: string; // "Écrit" / "Oral"
  mode: "text" | "audio";
  accent: "blue" | "red";
  /** Segment de la route de saisie : "redaction" (EE) / "enregistrement" (EO). */
  inputSegment: string;
  /** Chrono de l'épreuve en examen blanc, tel qu'appliqué par le backend
   *  (`AttemptService.PRODUCTION_E{E,O}_EXAM_SECONDS`). */
  examMinutes: string;
  /** Phrase de présentation du format de l'examen blanc. */
  examIntro: string;
}

export const EE_CONFIG: ProductionConfig = {
  epreuve: "TCF_EE",
  base: "/entrainement/tcf/ee",
  label: "Expression écrite",
  shortLabel: "Écrit",
  mode: "text",
  accent: "blue",
  inputSegment: "redaction",
  examMinutes: "30 min",
  examIntro:
    "Vous rédigez les 3 productions écrites (message, récit, point de vue argumenté). À la fin, l'IA évalue chaque tâche et vous attribue un niveau CECRL global (le plancher des 3 tâches).",
};

export const EO_CONFIG: ProductionConfig = {
  epreuve: "TCF_EO",
  base: "/entrainement/tcf/eo",
  label: "Expression orale",
  shortLabel: "Oral",
  mode: "audio",
  accent: "red",
  inputSegment: "enregistrement",
  examMinutes: "15 min",
  examIntro:
    "Vous enregistrez les 3 tâches orales (entretien dirigé, point de vue, jeu de rôle). À la fin, l'IA transcrit puis évalue chaque tâche et vous attribue un niveau CECRL global (le plancher des 3 tâches).",
};
