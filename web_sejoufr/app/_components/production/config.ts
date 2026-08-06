import type {EpreuveType} from "@/lib/types";

/** Écran parent des deux épreuves productives : le hub TCF. C'est là que
 *  remonte tout lien de retour qui sort d'une épreuve — l'épreuve n'a plus
 *  d'écran d'accueil propre (cf. `PRODUCTION_ENTRY_SUFFIX`). */
export const TCF_HUB_HREF = "/entrainement?module=TCF";
export const TCF_HUB_LABEL = "TCF IRN";

/**
 * Entrée dans une épreuve productive : le mode « Compétences » de la tâche 1.
 *
 * Il n'y a **pas** d'écran d'accueil d'épreuve : on ouvre directement l'espace
 * de travail, et on change de tâche par les pastilles T1/T2/T3, de mode par la
 * barre Compétences · Sujets · Examens. Les routes `${base}` restent servies —
 * en **redirection** vers cette destination — parce qu'elles sont référencées
 * (hub TCF, tableau de bord, landing `/reussir`, `?back=`).
 */
export const PRODUCTION_ENTRY_SUFFIX = "/tache/1/competences";

/** Destination d'entrée d'une épreuve, depuis n'importe quel appelant. */
export function productionEntryHref(base: string): string {
  return `${base}${PRODUCTION_ENTRY_SUFFIX}`;
}

/**
 * Les trois tâches d'une épreuve, à prérendre (`generateStaticParams`).
 *
 * Une épreuve n'a jamais eu que trois tâches : laisser ces routes en rendu à la
 * demande faisait payer un aller-retour serveur à chaque bascule de mode
 * (Compétences · Sujets · Examens), alors que la page est une coquille cliente
 * identique pour les trois. Prérendues, elles sont préchargées par les liens de
 * la barre de modes et servies depuis le cache de routage.
 *
 * Les autres valeurs de `n` restent servies à la demande (l'écran affiche
 * « Tâche inconnue ») : on prérend le vrai parcours, on ne ferme rien.
 */
export const PRODUCTION_TASK_PARAMS = [{n: "1"}, {n: "2"}, {n: "3"}] as const;

/**
 * Voix employée par le **chrome** d'un formulaire de production (libellés,
 * aides, messages d'état et d'erreur).
 *
 * Décision client : le candidat est **tutoyé** dans le module « Compétences ».
 * Les écrans de production TCF (sujets complets, session d'examen blanc)
 * vouvoient encore — d'où une valeur par défaut qui ne change rien. Le drapeau
 * ne touche **jamais** le texte des sujets, qui vient de la base et reproduit
 * une situation d'examen où l'énoncé vouvoie.
 */
export type ProductionVoice = "vouvoiement" | "tutoiement";

/**
 * Config d'une épreuve productive (Expression écrite / orale). Pilote les
 * composants génériques `Production*` : même flux (compétences ⇄ sujets ⇄
 * examens → input → feedback IA → examen blanc 3 tâches → historique), seul
 * l'input change (rédaction texte vs enregistrement audio).
 */
export interface ProductionConfig {
  epreuve: Extract<EpreuveType, "TCF_EE" | "TCF_EO">;
  /** Préfixe des routes de l'épreuve, ex: `/entrainement/tcf/ee`. Servi seul,
   *  il redirige vers `productionEntryHref(base)`. */
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
