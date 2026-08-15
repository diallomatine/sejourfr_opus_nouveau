import {PRODUCTION_INPUT_SEGMENT} from "@/lib/production-catalog";
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
 *
 * ⚠️ **Plus d'`accent`** (décision client 2026-08-09) : l'expression orale
 * était rouge, elle est bleue comme l'écrit. Le rouge redevient réservé aux CTA
 * critiques et aux signaux d'urgence (`docs/identite-visuelle.md`). Ce qui
 * distingue les deux épreuves : `label`, `mode` (donc le pictogramme stylo /
 * micro), `actionVerb` et `epreuveMeta`. Miroir mobile : `TcfProductionModule`.
 */
export interface ProductionConfig {
  epreuve: Extract<EpreuveType, "TCF_EE" | "TCF_EO">;
  /** Préfixe des routes de l'épreuve, ex: `/entrainement/tcf/ee`. Servi seul,
   *  il redirige vers `productionEntryHref(base)`. */
  base: string;
  label: string; // "Expression écrite" / "Expression orale"
  shortLabel: string; // "Écrit" / "Oral"
  mode: "text" | "audio";
  /** Sous-titre d'épreuve de l'en-tête du parcours. Écrit ici et nulle part
   *  ailleurs — trois écrans le composaient. */
  epreuveMeta: string;
  /** Verbe de production (« Rédiger » / « Enregistrer ») : avec le pictogramme
   *  et la durée, c'est ce qui distingue l'écrit de l'oral depuis que les deux
   *  épreuves sont bleues. */
  actionVerb: string;
  /** Segment de la route de saisie : "redaction" (EE) / "enregistrement" (EO).
   *  Déclaré dans `lib/production-catalog.ts` — le Plan y route sa vérification
   *  en situation, les deux doivent viser la même adresse. */
  inputSegment: string;
  /** Ce qui borne le temps en examen blanc, tel qu'appliqué par le backend :
   *  un chrono d'épreuve à l'écrit (30 min sur les 3 tâches), **rien** à l'oral
   *  — l'EO se chronomètre tâche par tâche, et le décompte ne part qu'au
   *  lancement de la tâche. Jamais une durée d'épreuve inventée pour l'oral.
   *  `short` complète « 3 tâches · … », `factLabel`/`factValue` alimentent la
   *  fiche de lancement. */
  examTiming: { short: string; factLabel: string; factValue: string };
  /** Phrase de présentation du format de l'examen blanc. */
  examIntro: string;
}

export const EE_CONFIG: ProductionConfig = {
  epreuve: "TCF_EE",
  base: "/entrainement/tcf/ee",
  label: "Expression écrite",
  shortLabel: "Écrit",
  mode: "text",
  epreuveMeta: "TCF IRN · 3 tâches · 30 min",
  actionVerb: "Rédiger",
  inputSegment: PRODUCTION_INPUT_SEGMENT.EE,
  examTiming: { short: "30 min", factLabel: "sur les 3 tâches", factValue: "30 min" },
  examIntro:
    "Vous rédigez les 3 productions écrites (message, récit, point de vue argumenté). Le chrono de 30 minutes porte sur les 3 tâches ensemble ; un temps conseillé s'affiche sur chacune, à titre indicatif. À la fin, l'IA évalue chaque tâche et vous attribue un niveau CECRL global (le plancher des 3 tâches).",
};

export const EO_CONFIG: ProductionConfig = {
  epreuve: "TCF_EO",
  base: "/entrainement/tcf/eo",
  label: "Expression orale",
  shortLabel: "Oral",
  mode: "audio",
  epreuveMeta: "TCF IRN · 3 tâches · chronométrées par tâche",
  actionVerb: "Enregistrer",
  inputSegment: PRODUCTION_INPUT_SEGMENT.EO,
  examTiming: {
    short: "chronométrées une par une",
    factLabel: "chronométrée à part",
    factValue: "chaque tâche",
  },
  examIntro:
    "Vous enregistrez les 3 tâches orales (entretien dirigé, point de vue, jeu de rôle). Chaque tâche est chronométrée à part : la consigne s'affiche sans décompte, et le temps ne part qu'au moment où vous lancez la tâche. À la fin, l'IA transcrit puis évalue chaque tâche et vous attribue un niveau CECRL global (le plancher des 3 tâches).",
};
