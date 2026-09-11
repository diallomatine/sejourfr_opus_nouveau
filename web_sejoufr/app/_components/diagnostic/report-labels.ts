/**
 * **Les phrases du résultat du diagnostic RAPIDE TCF.**
 *
 * Le serveur sert des **faits** — un niveau estimé, un paragraphe d'analyse,
 * des points forts, des priorités. Les titres, les kickers et les phrases de
 * mise en perspective vivent ici.
 *
 * 🛑 **Elles ne sont plus la propriété de l'écran de rapport.** La porte
 * d'entrée du Plan rappelle la même estimation quand le diagnostic complet
 * manque encore : deux écrans, une seule formulation. Recopier « Niveau estimé
 * sur cet exercice » dans le second aurait fait exactement ce que le dépôt
 * paie le plus cher — deux copies d'une même règle d'affichage.
 *
 * Miroir mot pour mot de
 * `mobile_sejourfr/lib/screens/diagnostic/widgets/diagnostic_report_labels.dart`.
 */
import {BookOpen, Headphones, Mic, PenLine, type LucideIcon} from "lucide-react";
import type {DiagnosticResultDto} from "@/lib/types";

/* ------------------------------------------------------------- l'en-tête */

export const DIAGNOSTIC_REPORT_BACK_HREF = "/dashboard";
export const DIAGNOSTIC_REPORT_KICKER = "Diagnostic rapide terminé";
/** 🛑 « Votre estimation », pas « Votre niveau TCF ». */
export const DIAGNOSTIC_REPORT_TITLE = "Votre estimation";

/* ---------------------------------------------------------- la carte hero */

/**
 * 🛑 **Wording imposé** : « Niveau estimé **sur cet exercice** », jamais « votre
 * niveau TCF ». Trois épreuves sur quatre n'ont pas été mesurées.
 */
export const DIAGNOSTIC_LEVEL_EYEBROW = "Niveau estimé sur cet exercice";
export const DIAGNOSTIC_GOAL_PREFIX = "Votre objectif :";
/** 🛑 L'objectif est **nullable** : aucun front n'invente « B2 » pour un
 *  candidat qui n'a déclaré ni démarche ni palier. */
export const DIAGNOSTIC_OBJECTIVE_UNKNOWN = "à définir";
/** Ce qu'on affiche à la place d'un niveau qui n'existe pas. */
export const DIAGNOSTIC_LEVEL_UNKNOWN = "—";

/** 🛑 « Rendue, rien à observer » ≠ « faible ». La phrase ne juge pas la
 *  production : elle dit ce qui manque pour conclure. */
export const DIAGNOSTIC_INCOMPLETE_TEXT =
  "Nous n'avons pas reçu suffisamment de contenu pour estimer votre niveau."
  + " Une nouvelle production de deux minutes suffit.";

/* --------------------------------------------- ce que nous avons observé */

export const DIAGNOSTIC_OBSERVE_TITLE = "Ce que nous avons observé";
export const DIAGNOSTIC_OBSERVE_POSITIVE = "Positive";
export const DIAGNOSTIC_OBSERVE_AMELIORER = "À améliorer";
/** Plafond d'AFFICHAGE, arbitré produit : deux points à améliorer, pas une
 *  liste. Le serveur en sert jusqu'à trois ; on n'en montre que deux. */
export const DIAGNOSTIC_OBSERVE_MAX_AMELIORER = 2;

export interface ObservationLine {
  tone: "ok" | "up";
  kicker: string;
  title: string;
  text: string | null;
}

/**
 * Une ligne positive, puis deux à améliorer — dans cet ordre.
 *
 * 🛑 **Rien n'est dérivé.** Le point fort est une observation que le serveur a
 * marquée `SOLID` ; les points à améliorer sont les priorités qu'il a classées.
 * Le front choisit dans une liste servie, il ne juge pas.
 *
 * ⚠️ Le repli sur `strengths` existe parce que le serveur sert deux formes du
 * même fait : des observations nommées (titre + explication) et, quand il n'en
 * a aucune, des phrases nues. On n'invente pas de ligne pour remplir le bloc —
 * ni l'une ni l'autre ⇒ pas de ligne positive.
 */
export function observationLines(result: DiagnosticResultDto | null): ObservationLine[] {
  const solide = (result?.written?.skills ?? []).find(
    (skill) => skill.observed && skill.status === "SOLID",
  );
  const positive: ObservationLine[] = solide
    ? [{
        tone: "ok",
        kicker: DIAGNOSTIC_OBSERVE_POSITIVE,
        title: solide.skillTitle,
        text: solide.explanation,
      }]
    : (result?.strengths ?? []).slice(0, 1).map((phrase) => ({
        tone: "ok" as const,
        kicker: DIAGNOSTIC_OBSERVE_POSITIVE,
        title: phrase,
        text: null,
      }));

  return [
    ...positive,
    ...(result?.priorities ?? [])
      .slice(0, DIAGNOSTIC_OBSERVE_MAX_AMELIORER)
      .map((skill) => ({
        tone: "up" as const,
        kicker: DIAGNOSTIC_OBSERVE_AMELIORER,
        title: skill.skillTitle,
        text: skill.explanation,
      })),
  ];
}

/* ------------------------------------------------------- la mise au point */

/**
 * 🛑 **Le bloc de transition n'est pas décoratif, c'est une obligation
 * d'honnêteté.** Le diagnostic rapide n'observe qu'une production ÉCRITE.
 */
export const DIAGNOSTIC_TRANSITION_TITLE = "Ce n'est qu'une première estimation";
export const DIAGNOSTIC_TRANSITION_TEXT =
  "Cet exercice analyse votre manière de vous exprimer à l'écrit. "
  + "Au TCF, votre niveau dépend aussi de votre expression orale, de votre "
  + "compréhension orale et de votre compréhension écrite.";
export const DIAGNOSTIC_TRANSITION_EMPHASIS =
  "Votre niveau peut donc être différent selon les épreuves.";

/* ------------------------------------------------- le diagnostic complet */

export const DIAGNOSTIC_COMPLET_TITLE = "Découvrez où vous en êtes vraiment au TCF";

/** Les quatre épreuves du diagnostic complet, dans l'ordre de la maquette.
 *  Aucun niveau n'y figure : elles ne sont pas encore mesurées. */
export const DIAGNOSTIC_COMPLET_EPREUVES: ReadonlyArray<{icon: LucideIcon; label: string}> = [
  {icon: Headphones, label: "Compréhension orale"},
  {icon: BookOpen, label: "Compréhension écrite"},
  {icon: PenLine, label: "Expression écrite"},
  {icon: Mic, label: "Expression orale"},
];

export const DIAGNOSTIC_COMPLET_PROMISE = "À la fin, vous connaîtrez :";
export const DIAGNOSTIC_COMPLET_BENEFITS = [
  "votre niveau par épreuve",
  "les tâches qui vous limitent actuellement",
  "vos priorités pour atteindre votre objectif",
];
export const DIAGNOSTIC_COMPLET_CTA = "Faire mon diagnostic complet";
export const DIAGNOSTIC_COMPLET_NOTE = "Examen blanc complet dans les conditions du TCF.";
