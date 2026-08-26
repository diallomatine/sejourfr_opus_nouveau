"use client";

import Link from "next/link";
import {useCallback, useEffect, useMemo, useState, type ReactNode} from "react";
import {ArrowRight, Check, ChevronDown, Info, Lock, Play, RotateCcw, Sparkles} from "lucide-react";
import {learningPlanApi} from "@/lib/api";
import {track} from "@/lib/analytics";
import {PlanBlur, PlanDomainIcon, PlanLevelRail} from "@/app/_components/plan/PlanBits";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {usePlanAssessment, usePlanExercise} from "@/app/_components/plan/use-plan-exercise";
import {RowChevron, SectionHead} from "@/app/_components/skill-ui/SkillLayout";
import {
  findAssessment,
  findDomain,
  isComprehension,
  PLAN_DOMAIN_SECTION,
  PLAN_SKILLS_HREF,
  PLAN_SKILLS_TITLE,
  planDomainLabel,
  planSkillHref,
  type PlanDomainEpreuve,
} from "@/lib/plan-domain";
import {LEARNING_PLAN_SKILL_STATUS_LABEL} from "@/lib/diagnostic";
import {useTrafficSourceHref} from "@/lib/use-traffic-source";
import {
  niveauCecrlShort,
  type DiagnosticResultDto,
  type LearningPlanDto,
  type NiveauCecrl,
  type PlanDomainAssessmentDto,
  type PlanDomainDto,
  type PlanDomainSkillDto,
  type TargetLevel,
} from "@/lib/types";
import styles from "./diagnostic.module.css";

/* ============================================================================
   « Mon diagnostic » — le niveau ÉPREUVE PAR ÉPREUVE, et les compétences qui
   l'expliquent.
   ----------------------------------------------------------------------------
   Géométrie de la maquette `WEB_mon_diagnostic.jsx`, couleurs et fontes de
   l'application (même méthode que `skill-ui/`). Ordre des sections **figé et
   identique au mobile** : héros global → « Mes 4 épreuves » → prochaine étape
   (ou l'offre) → mention d'estimation.

   🛑 **Le serveur ne sert AUCUNE phrase.** Il expose des faits — un niveau, des
   compteurs, des compétences, un verrou — et toutes les formulations vivent ici,
   déclarées une seule fois, **miroirs du mobile**.

   ⚠️ **Vouvoiement.** La maquette tutoie ; elle ne donne que la direction
   visuelle. Le registre reste celui de l'application.
   ============================================================================ */

/* ------------------------------------------------------------- les libellés */

const REPORT_TITLE = "Diagnostic";
const REPORT_SUB_PREMIUM = "Rapport complet";
const REPORT_SUB_FREE = "Estimation d'entraînement Séjour";

/** ⚠️ Le libellé du niveau estimé contient **toujours** le mot « estimé »
 *  (règle du dépôt). Miroir de `kDiagnosticLevelEyebrow` côté mobile. */
const HERO_EYEBROW = "Niveau estimé";
const HERO_OBJECTIVE = "Objectif";
/** 🛑 `objectiveLevel` est **nullable** : aucun front n'invente « B2 » quand le
 *  candidat n'a déclaré ni démarche ni palier. */
const HERO_OBJECTIVE_UNKNOWN = "à définir";
const HERO_COMPLETE = "Diagnostic complet";
const LEVEL_CAPTION = "Estimé";
/** Ce qu'on affiche à la place d'un niveau qui n'existe pas. *null = inconnu,
 *  jamais mauvais* : on ne descend pas au plus bas palier faute de mesure. */
const LEVEL_UNKNOWN = "—";

/** « 2 / 4 épreuves évaluées ». Le dénominateur vient du serveur
 *  (`cycle.domainsExpected`) : on ne l'écrit jamais en dur. */
function heroProgress(done: number, total: number): string {
  return `${done} / ${total} épreuve${total > 1 ? "s" : ""} évaluée${total > 1 ? "s" : ""}`;
}

/** Ce que vaut une estimation partielle — dite sans reproche : les épreuves
 *  manquantes ne sont pas ratées, elles ne sont pas mesurées. */
function heroPartial(done: number, total: number): string {
  return `Estimation basée sur ${done} épreuve${done > 1 ? "s" : ""} sur ${total}.`
    + " Elle se précisera dès que les autres seront évaluées.";
}

const EPREUVES_TITLE = "Mes 4 épreuves";
const EPREUVES_TEXT =
  "Votre niveau épreuve par épreuve, et les compétences qui l'expliquent";

const STATE_TO_EVALUATE = "À évaluer";
const STATE_INCOMPLETE = "Évaluation incomplète";

function toEvaluateText(label: string): string {
  return `Cette épreuve n'a pas encore été évaluée : aucun niveau n'est estimé en ${label.toLowerCase()}.`;
}

/** 🛑 « Rendue, rien à observer » ≠ « pas encore analysée » ≠ « faible ». La
 *  phrase ne juge pas la production : elle dit ce qui manque pour conclure. */
const INCOMPLETE_TEXT =
  "Nous n'avons pas reçu suffisamment de contenu pour estimer votre niveau."
  + " Une nouvelle production de deux minutes suffit.";

/** « mon expression écrite » / « ma compréhension orale ». Le français ne
 *  s'accorde pas sur le domaine mais sur son nom : *expression* est féminin mais
 *  commence par une voyelle, donc « mon ». */
function toEvaluateCta(epreuve: PlanDomainEpreuve): string {
  const possessif = isComprehension(PLAN_DOMAIN_SECTION[epreuve]) ? "ma" : "mon";
  return `Évaluer ${possessif} ${planDomainLabel(epreuve).toLowerCase()}`;
}

function redoCta(label: string): string {
  return `Refaire l'${label.toLowerCase()}`;
}

const GROUP_PRIORITY = "Priorité";
const GROUP_REINFORCE = "À renforcer";
const GROUP_ACQUIRE = "À acquérir";
const GROUP_SOLID = "Déjà solide";
const GROUP_PRIORITIES = "Priorités";
/** Un compte sans accès ne voit qu'**une** ligne de travail : elle se nomme
 *  « Priorité principale » quand c'en est une, jamais sinon. */
const GROUP_FREE_MAIN = "Priorité principale";
const GROUP_FREE_MAIN_ALT = "À travailler en premier";

/** 🛑 « À acquérir » ne se dit **jamais** « à renforcer » : renforcer suppose un
 *  constat négatif, et sur une compétence jamais travaillée il n'y en a aucun. */
function acquireNote(level: string | null): string {
  return level
    ? `Compétences du palier ${level} que votre plan va commencer à enseigner.`
    : "Compétences que votre plan va commencer à enseigner.";
}

function notObservedLine(count: number): string {
  return `${count} compétence${count > 1 ? "s" : ""} : pas encore assez de données pour se prononcer.`;
}

function moreToWork(count: number): string {
  return `+ ${count} autre${count > 1 ? "s" : ""} compétence${count > 1 ? "s" : ""} à travailler`;
}

function freeCounter(visible: number, total: number): string {
  return `${visible} sur ${total}`;
}

/**
 * **Les seuils d'affichage, déclarés UNE fois.**
 *
 * Miroirs du mobile (`_kFreeWorkVisible` / `_kFreeSolidVisible` /
 * `_kCollapsedWorkVisible`) : ce sont des plafonds d'**affichage**, jamais des
 * règles d'accès — le verrou réel vit sur `PlanDomainSkillDto.locked`, posé par
 * le serveur.
 */
const FREE_WORK_VISIBLE = 1;
const FREE_SOLID_VISIBLE = 1;
const COLLAPSED_WORK_VISIBLE = 2;

/** « + 3 compétences détectées · 2 déjà solides ». 🛑 Les deux nombres sont
 *  **vrais** — ils viennent des compteurs du domaine, jamais d'une constante. */
function lockCount(work: number, solid: number): string {
  return [
    work > 0 && `+ ${work} compétence${work > 1 ? "s" : ""} détectée${work > 1 ? "s" : ""}`,
    solid > 0 && `${solid} déjà solide${solid > 1 ? "s" : ""}`,
  ]
    .filter(Boolean)
    .join(" · ");
}

/** Le repli du titre flouté quand le serveur n'a plus de ligne à laisser
 *  deviner. Jamais une compétence inventée : une formule qui n'affirme rien. */
const LOCK_FALLBACK = "Compétence détectée";
const LOCK_CTA = "Débloquer";
/** L'attente d'un démarrage, dite une seule fois. */
const STARTING = "Démarrage…";
/** L'information NETTE que porte le bloc flouté, pour un lecteur d'écran : le
 *  flou est retiré de l'arbre d'accessibilité, il ne peut rien annoncer. */
const LOCK_SR = "Compétences réservées à l'abonnement.";

const FOOT_CTA_EXPRESSION = "Travailler mes priorités";

function footCtaComprehension(label: string): string {
  return `Travailler la ${label.toLowerCase()}`;
}

function footNext(title: string): string {
  return `Prochaine étape : ${title.toLowerCase()}.`;
}

const NEXT_TITLE = "Prochaine étape";

function nextText(objective: string | null): string {
  return objective
    ? `Votre plan traite ces priorités une par une, dans l'ordre qui vous fait progresser le plus vite vers le ${objective}.`
    : "Votre plan traite ces priorités une par une, dans l'ordre qui vous fait progresser le plus vite.";
}

const OFFER_TITLE = "Votre analyse complète est prête";

function offerText(objective: string | null): string {
  return objective
    ? `Découvrez toutes vos priorités, tous vos points forts et votre plan personnalisé pour progresser vers le ${objective}.`
    : "Découvrez toutes vos priorités, tous vos points forts et votre plan personnalisé pour progresser.";
}

/**
 * Ce que l'abonnement ouvre, dit du point de vue du candidat qui vient de lire
 * son diagnostic.
 *
 * 🛑 **Le premier bénéfice porte un compte RÉEL** — la somme des compétences à
 * travailler réellement détectées sur les épreuves évaluées. `0` ⇒ **aucun
 * nombre** : on ne vend jamais un compteur inventé.
 */
function offerBenefits(toWork: number): string[] {
  return [
    ...(toWork > 0
      ? [
          `Les ${toWork} compétence${toWork > 1 ? "s" : ""} à travailler`
          + ` détectée${toWork > 1 ? "s" : ""} sur vos épreuves`,
        ]
      : []),
    "Toutes vos compétences déjà solides",
    "Votre plan et vos entraînements ciblés",
  ];
}

const OFFER_CTA = "Débloquer mon diagnostic complet";
const OFFER_GHOST = "Voir les formules";
/** Le libellé de la barre collante mobile. Même mot que partout ailleurs : un
 *  candidat ne doit pas lire deux formulations pour la même action. */
const CTA_PLAN = "Voir mon plan";

/** La seule phrase de l'écran qui dise ce que vaut l'estimation. Gardée en pied
 *  de rapport, pour tout le monde. */
const ESTIMATION_NOTE =
  "Votre niveau est une estimation d'entraînement Séjour, pas un score officiel du TCF.";

/**
 * **Le résumé d'une épreuve**, une phrase par (épreuve × palier).
 *
 * ⚠️ **Miroirs mot pour mot du mobile** (`_kDiagnosticResume`) : ces chaînes ne
 * transitent pas par le réseau, chaque front en tient sa copie. Un libellé qui
 * bouge, ce sont deux fichiers à changer dans la même passe.
 *
 * 🛑 Elle dit ce que le niveau **veut dire** et ce qui sépare de la marche
 * suivante — jamais un jugement sur la personne, jamais un mot de manque quand
 * rien n'a été observé.
 */
const EPREUVE_SUMMARY: Record<PlanDomainEpreuve, Record<TargetLevel | "A1_NON_ATTEINT" | "A1", string>> = {
  TCF_EE: {
    A1_NON_ATTEINT:
      "Votre texte reste très court : les compétences attendues au A2 sont encore à construire.",
    A1: "Vous écrivez des phrases simples ; les compétences attendues au A2 restent à installer.",
    A2: "Vos productions sont compréhensibles, mais certaines compétences attendues au B1 restent à consolider.",
    B1: "Vos textes tiennent le B1. Ce qui manque pour le B2 : des arguments développés et nuancés.",
    B2: "Vos productions atteignent le niveau attendu : il s'agit maintenant de le conserver.",
  },
  TCF_EO: {
    A1_NON_ATTEINT:
      "Votre enregistrement reste très bref : les compétences attendues au A2 sont encore à construire.",
    A1: "Vous répondez par des phrases courtes ; les compétences attendues au A2 restent à installer.",
    A2: "Vous répondez aux questions simples, mais plusieurs compétences nécessaires au B1 restent fragiles.",
    B1: "Vous tenez l'échange. Défendre un avis développé est ce qui vous sépare du B2.",
    B2: "Votre discours est structuré et tenu dans la durée.",
  },
  TCF_CE: {
    A1_NON_ATTEINT:
      "Les documents les plus simples ne sont pas encore décodés : c'est le A2 qui se construit d'abord.",
    A1: "Vous repérez quelques mots ; lire un document simple en entier reste à travailler.",
    A2: "Vous repérez les informations explicites ; l'implicite vous échappe encore souvent.",
    B1: "Votre B1 est presque stabilisé : quelques documents B2 sont déjà réussis.",
    B2: "Votre domaine le plus stable : rien à consolider en priorité.",
  },
  TCF_CO: {
    A1_NON_ATTEINT:
      "Les messages les plus simples ne sont pas encore repérés : c'est le A2 qui se construit d'abord.",
    A1: "Vous saisissez quelques mots-clés ; comprendre un message simple en entier reste à travailler.",
    A2: "Vous comprenez les messages simples et directs ; une situation B1 sur deux reste difficile.",
    B1: "Votre B1 est stable : les documents B2 deviennent la prochaine marche.",
    B2: "Vos résultats sont réguliers, y compris sur les documents longs.",
  },
};

/** C1 / C2 (historique) se lisent comme B2 : le contrat TCF IRN s'arrête là. */
function epreuveSummary(epreuve: PlanDomainEpreuve, level: NiveauCecrl): string {
  const palier = level === "C1" || level === "C2" ? "B2" : level;
  return EPREUVE_SUMMARY[epreuve][palier];
}

/** « Objectif B2 · prochain palier B1 ». L'objectif est **nullable** — il vient
 *  de la démarche déclarée, et on n'en invente aucun. */
function epreuveMeta(objective: string | null, next: TargetLevel | null): string {
  const cible = `${HERO_OBJECTIVE} ${objective ?? HERO_OBJECTIVE_UNKNOWN}`;
  return next ? `${cible} · prochain palier ${next}` : cible;
}

/**
 * **L'ordre des cartes est FIGÉ** : expression écrite, expression orale,
 * compréhension écrite, compréhension orale — le même sur les deux fronts.
 *
 * ⚠️ **Écart assumé avec `plan.domaines`, qui est trié par URGENCE côté
 * serveur.** Cet ordre-là est celui du Plan (« qu'est-ce que je fais
 * maintenant ? ») et il reste intact chez lui. Ici la question est « où en
 * suis-je, épreuve par épreuve ? » : un ordre qui bouge à chaque mesure
 * empêcherait le candidat de retrouver sa carte. Aucune règle n'est rejouée —
 * on ne trie pas les domaines, on les **lit** dans un ordre stable.
 */
const EPREUVE_ORDER: readonly PlanDomainEpreuve[] = [
  "TCF_EE",
  "TCF_EO",
  "TCF_CE",
  "TCF_CO",
];

/* --------------------------------------------------------------- le modèle */

/** Une compétence rangée pour l'affichage. `nature` prime sur `status` — une
 *  compétence à acquérir n'est **pas** une fragilité. */
type SkillGroup = "PRIORITY" | "REINFORCE" | "ACQUIRE" | "SOLID" | "NOT_OBSERVED";

function skillGroup(skill: PlanDomainSkillDto): SkillGroup {
  if (skill.nature === "A_ACQUERIR") return "ACQUIRE";
  if (skill.status === "PRIORITY") return "PRIORITY";
  if (skill.status === "TO_REINFORCE") return "REINFORCE";
  if (skill.status === "SOLID") return "SOLID";
  return "NOT_OBSERVED";
}

/** Ce que la carte d'une épreuve a besoin de savoir. **Union discriminée** :
 *  les trois états ne portent pas les mêmes champs, et c'est le type qui
 *  l'impose plutôt qu'une convention à relire. */
type EpreuveCard =
  | {
      epreuve: PlanDomainEpreuve;
      domain: PlanDomainDto;
      state: "TO_EVALUATE" | "INCOMPLETE";
      assessment: PlanDomainAssessmentDto | null;
    }
  | {
      epreuve: PlanDomainEpreuve;
      domain: PlanDomainDto;
      state: "OK";
      niveau: NiveauCecrl;
      summary: string;
      explanation: string | null;
      work: PlanDomainSkillDto[];
      solid: PlanDomainSkillDto[];
      notObserved: number;
      /**
       * 🛑 Compteurs **servis** par le serveur (`fragileSkillCount` /
       * `solidSkillCount`), jamais recomptés depuis une liste tronquée à
       * l'affichage : c'est d'eux que dépend la justesse du « + N autres ».
       *
       * ⚠️ `fragileTotal` ne compte **que** ce qui a été observé fragile — une
       * compétence **à acquérir** n'a rien d'observé, donc rien de « détecté ».
       * Miroir de `_EpreuveView.fragileTotal` côté mobile.
       */
      fragileTotal: number;
      solidTotal: number;
    };

/**
 * **La lecture d'un domaine, décidée une seule fois.**
 *
 * Ordre des tests, et il compte : un domaine **mesuré** rend son niveau, quoi
 * qu'il soit arrivé à la production du diagnostic ; sinon une production
 * *rendue mais inexploitable* dit ce qui manque ; sinon le domaine n'a
 * simplement jamais été mesuré.
 *
 * ⚠️ **La maquette teste l'inverse** (« non exploitable » d'abord) parce que son
 * bouchon n'a pas de serveur : une production ratée puis une vraie production
 * réussie y afficherait encore « évaluation incomplète ».
 */
function buildCard(
  plan: LearningPlanDto,
  result: DiagnosticResultDto | null,
  epreuve: PlanDomainEpreuve,
): EpreuveCard | null {
  const domain = findDomain(plan, epreuve);
  if (!domain) return null;
  const assessment = findAssessment(plan, epreuve) ?? null;

  if (!domain.evaluated || !domain.niveau) {
    // 🛑 Seule la valeur `NON_EVALUABLE` **explicite** se lit « rendue, rien à
    // observer » : l'absence du bloc, elle, veut dire « pas encore analysée ».
    const production =
      epreuve === "TCF_EE" ? result?.written : epreuve === "TCF_EO" ? result?.oral : null;
    const state = production?.evaluabilite === "NON_EVALUABLE" ? "INCOMPLETE" : "TO_EVALUATE";
    return {epreuve, domain, state, assessment};
  }

  const skills = domain.skills ?? [];
  const grouped = skills.map((skill) => ({skill, group: skillGroup(skill)}));
  // L'ordre des groupes est celui de `PlanActionNature` : réparer ce qui est
  // fragile avant d'apprendre ce qui vient. À l'intérieur d'un groupe, l'ordre
  // du serveur est conservé — on ne retrie jamais.
  const pick = (group: SkillGroup) =>
    grouped.filter((row) => row.group === group).map((row) => row.skill);
  const work = [...pick("PRIORITY"), ...pick("REINFORCE"), ...pick("ACQUIRE")];
  const solid = pick("SOLID");
  // 🛑 SERVI, plus recompté : ce compte excluait les acquisitions ici pendant
  // que le serveur les incluait dans `notObservedSkillCount` — deux nombres
  // pour la même épreuve. Le serveur en publie désormais deux, nommés.
  const notObserved = domain.notObservedWithoutActionCount;

  return {
    epreuve,
    domain,
    state: "OK",
    niveau: domain.niveau,
    summary: epreuveSummary(epreuve, domain.niveau),
    explanation: domainExplanation(domain, {
      total: skills.length,
      // 🛑 « Observées » = ce que le serveur a réellement observé — les
      // acquisitions n'en sont pas (elles n'ont aucune ligne d'historique) et
      // les compter ici gonflerait la phrase. Miroir du mobile.
      observed: domain.fragileSkillCount + domain.solidSkillCount,
      fragile: domain.fragileSkillCount,
      solid: domain.solidSkillCount,
    }),
    work,
    solid,
    notObserved,
    fragileTotal: domain.fragileSkillCount,
    solidTotal: domain.solidSkillCount,
  };
}

/**
 * **Sur quoi ce niveau repose**, en une phrase de **faits servis** — jamais une
 * interprétation. Miroir de `diagnosticEpreuveExplanation` côté mobile.
 *
 * - **compréhension** : le palier consolidé et celui qui bloque ;
 * - **expression** : combien de compétences ont été observées sur combien, sur
 *   combien de tâches, et comment elles se répartissent.
 *
 * `null` ⇒ l'encart n'existe pas. Rien n'est deviné pour le remplir.
 */
function domainExplanation(
  domain: PlanDomainDto,
  counts: {total: number; observed: number; fragile: number; solid: number},
): string | null {
  if (domain.paliers.length > 0) {
    const blocking = domain.blockingLevel;
    const consolidated = domain.consolidatedLevel;
    if (!blocking) return "Vos trois paliers sont consolidés sur ce domaine.";
    if (!consolidated) {
      return `Le palier ${blocking} n'est pas encore consolidé : c'est lui qui commande la suite.`;
    }
    return `Palier consolidé : ${consolidated}. Le ${blocking} n'est pas encore acquis,`
      + " c'est lui qui commande la suite.";
  }

  const {total, observed, fragile, solid} = counts;
  if (total === 0 || observed === 0) return null;

  const tasks = domain.taches.length;
  const scope = tasks === 0 ? "" : `, réparties sur ${tasks} tâche${tasks > 1 ? "s" : ""}`;
  const detail = [
    fragile > 0 ? `${fragile} à travailler` : null,
    solid > 0 ? `${solid} déjà solide${solid > 1 ? "s" : ""}` : null,
  ]
    .filter(Boolean)
    .join(" et ");

  const head = `${observed} compétence${observed > 1 ? "s" : ""}`
    + ` observée${observed > 1 ? "s" : ""} sur ${total}${scope}`;
  return detail ? `${head} : ${detail}.` : `${head}.`;
}

/** Le repère d'une compétence, **sous son titre** : la tâche en expression, le
 *  palier en compréhension. Le code seul quand ni l'un ni l'autre n'est servi —
 *  on n'invente pas de rattachement. Miroir de `diagnosticSkillSubtitle`. */
function skillMetaLine(skill: PlanDomainSkillDto): string {
  if (skill.tacheNumero !== null) return `Tâche ${skill.tacheNumero}`;
  if (skill.targetLevel) return `Palier ${skill.targetLevel}`;
  return skill.skillCode;
}

/* ------------------------------------------------------------ le hook plan */

/**
 * **Le Plan, lu une seule fois pour tout le rapport.**
 *
 * ⚠️ Lecture FRAÎCHE, pas `getCached()` : le Plan a pu être lu avant que le
 * diagnostic ne se termine, et le cache dirait encore « aucun domaine mesuré »
 * sur l'écran qui vient précisément d'en mesurer deux.
 *
 * `null` tant qu'il n'a pas répondu, et `null` à jamais s'il échoue : le héros
 * rend alors « — » et la liste des épreuves disparaît. Confort d'affichage — le
 * reste du rapport est entier.
 */
export function useDiagnosticPlan(): LearningPlanDto | null {
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);

  useEffect(() => {
    let cancelled = false;
    learningPlanApi.get().then(
      (current) => {
        if (!cancelled) setPlan(current);
      },
      () => {
        /* Confort d'affichage : un échec ne remonte pas à l'écran. */
      },
    );
    return () => {
      cancelled = true;
    };
  }, []);

  return plan;
}

/* ------------------------------------------------------------- vers l'offre */

/**
 * Lien vers l'offre, avec sa mesure de conversion. **Le seul chemin instrumenté
 * de cet écran vers l'achat** : l'événement est émis ici, jamais recopié dans un
 * `onClick` de composant, et aucun événement d'audience n'est ajouté.
 */
function PremiumLink({className, children}: {className: string; children: ReactNode}) {
  const href = useTrafficSourceHref("/paiement?module=INTEGRAL");
  return (
    <Link
      className={className}
      href={href}
      onClick={() =>
        track("PREMIUM_CTA_CLICKED", {
          ctaLocation: "DIAGNOSTIC_REPORT",
          screen: "diagnostic_result",
        })
      }
    >
      {children}
    </Link>
  );
}

/* ------------------------------------------------------------------- écran */

export function DiagnosticReport({
  diagnostic,
  targetLevel,
  hasTcf,
  planHref,
  notice,
}: {
  diagnostic: {result: DiagnosticResultDto | null};
  targetLevel: string | null;
  /** Accès TCF du compte. Il ne masque **aucune** mesure du candidat : il ne
   *  décide que de ce qui reste à faire. */
  hasTcf: boolean;
  planHref: string;
  notice?: ReactNode;
}) {
  const plan = useDiagnosticPlan();
  const result = diagnostic.result;
  // La première carte est ouverte : le candidat lit son épreuve écrite sans un
  // clic, et les trois autres restent compactes.
  const [open, setOpen] = useState<PlanDomainEpreuve | null>("TCF_EE");

  const cards = useMemo(
    () =>
      plan
        ? EPREUVE_ORDER.map((epreuve) => buildCard(plan, result, epreuve)).filter(
            (card): card is EpreuveCard => card !== null,
          )
        : [],
    [plan, result],
  );

  /** Une colonne du héros déplie sa carte **et l'amène à l'écran** : sans ça, le
   *  clic n'aurait aucun effet visible sur un grand écran. */
  const reveal = useCallback((epreuve: PlanDomainEpreuve) => {
    setOpen(epreuve);
    const node = document.getElementById(cardId(epreuve));
    if (!node) return;
    const still = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    node.scrollIntoView({behavior: still ? "auto" : "smooth", block: "start"});
  }, []);

  const objective = plan?.cycle.objectiveLevel ?? targetLevel ?? null;
  // 🛑 **Le compte se lit sur le CYCLE**, jamais sur la longueur d'une liste :
  // trois surfaces qui compteraient chacune de leur côté finiraient par se
  // contredire. Tant que le Plan n'a pas répondu, rien n'est « complet ».
  const evaluated = plan?.cycle.domainsEvaluated ?? 0;
  const expected = plan?.cycle.domainsExpected ?? EPREUVE_ORDER.length;
  const complete = plan?.cycle.profileComplete ?? false;
  // 🛑 Le compte de l'offre se lit sur le **compteur serveur** de chaque
  // domaine (`fragileSkillCount`), jamais sur une liste affichée. Miroir du
  // mobile (`detected`).
  const toWork = cards.reduce(
    (total, card) => (card.state === "OK" ? total + card.fragileTotal : total),
    0,
  );

  return (
    <>
      <div className={styles.result}>
      {notice}

      <header className={styles.resultHeader}>
        <h1>{REPORT_TITLE}</h1>
        <p>{hasTcf ? REPORT_SUB_PREMIUM : REPORT_SUB_FREE}</p>
      </header>

      {/* ------------------------------------------------ le héros global */}
      <section className={styles.hero} aria-labelledby="hero-title">
        <div className={styles.heroTop}>
          <div className={styles.heroMain}>
            <p className={styles.heroEyebrow} id="hero-title">{HERO_EYEBROW}</p>
            <div className={styles.heroPair}>
              {/* Forme **courte** (« <A1 »), miroir de `NiveauCecrl.shortName` :
                  « A1 non atteint » en corps de titre déborde et ne se lit plus. */}
              <p className={styles.heroLevel}>{niveauCecrlShort(plan?.cycle.startingLevel)}</p>
              <p className={styles.heroGoal}>
                {HERO_OBJECTIVE} {objective ?? HERO_OBJECTIVE_UNKNOWN}
              </p>
            </div>
            <p className={styles.heroBadge}>
              {complete ? <Check size={15} strokeWidth={2.8} aria-hidden /> : <Info size={15} aria-hidden />}
              {complete ? HERO_COMPLETE : heroProgress(evaluated, expected)}
            </p>
            {!complete && <p className={styles.heroText}>{heroPartial(evaluated, expected)}</p>}
          </div>
          {plan && (
            <div className={styles.heroRail}>
              <PlanLevelRail current={plan.cycle.targetLevel} dark />
            </div>
          )}
        </div>

        {cards.length > 0 && (
          <div className={styles.heroStrip}>
            {cards.map((card) => (
              <button
                key={card.epreuve}
                type="button"
                className={styles.heroCell}
                data-on={open === card.epreuve ? "1" : "0"}
                onClick={() => reveal(card.epreuve)}
              >
                <span className={styles.heroCellLevel} data-known={card.state === "OK" ? "1" : "0"}>
                  {card.state === "OK" ? niveauCecrlShort(card.niveau) : LEVEL_UNKNOWN}
                </span>
                <span className={styles.heroCellLabel}>{planDomainLabel(card.epreuve)}</span>
              </button>
            ))}
          </div>
        )}
      </section>

      {/* ------------------------------------------------ les 4 épreuves */}
      {cards.length > 0 && (
        <section aria-labelledby="epreuves-title">
          <SectionHead title={EPREUVES_TITLE} text={EPREUVES_TEXT} titleId="epreuves-title" />
          <div className={styles.cards}>
            {cards.map((card) => (
              <EpreuveCardView
                key={card.epreuve}
                card={card}
                hasTcf={hasTcf}
                objective={objective}
                /* Le palier annoncé est celui de CETTE épreuve, plus celui du
                   cycle global : depuis le 2026-08-26 deux domaines peuvent en
                   construire deux différents. */
                buildLevel={card.domain.nextTargetLevel}
                open={open === card.epreuve}
                onToggle={() => setOpen(open === card.epreuve ? null : card.epreuve)}
              />
            ))}
          </div>
        </section>
      )}

      {/* --------------------------------- prochaine étape, ou l'offre */}
      {hasTcf ? (
        <section aria-labelledby="next-title">
          <SectionHead title={NEXT_TITLE} titleId="next-title" />
          <div className={styles.nextCard}>
            <p>{nextText(objective)}</p>
            <div className={styles.nextActions}>
              <Link href={planHref} className={styles.nextPrimary}>
                {FOOT_CTA_EXPRESSION} <ArrowRight size={17} aria-hidden />
              </Link>
              <Link href={PLAN_SKILLS_HREF} className={styles.nextGhost}>
                {PLAN_SKILLS_TITLE}
              </Link>
            </div>
          </div>
        </section>
      ) : (
        <section className={styles.unlockCard} aria-labelledby="unlock-title">
          <span className={styles.finalSpark} aria-hidden><Sparkles size={20} /></span>
          <h2 id="unlock-title">{OFFER_TITLE}</h2>
          <p>{offerText(objective)}</p>
          <ul className={styles.unlockList}>
            {offerBenefits(toWork).map((benefit) => (
              <li key={benefit}>
                <Check size={15} strokeWidth={2.8} aria-hidden />
                {benefit}
              </li>
            ))}
          </ul>
          <div className={styles.finalActions}>
            <PremiumLink className={styles.finalPrimary}>
              {OFFER_CTA} <ArrowRight size={17} aria-hidden />
            </PremiumLink>
            <Link href="/tarifs" className={styles.finalGhost}>{OFFER_GHOST}</Link>
          </div>
        </section>
      )}

      <p className={styles.note}>
        <Info size={15} aria-hidden />
        {ESTIMATION_NOTE}
      </p>
      </div>

      {/* Barre collante mobile : la réserve de pied de page est posée sur
          `.result`, elle ne masque donc aucun contenu. */}
      <div className={styles.stickyCta}>
        <Link href={planHref} className={styles.primaryButton}>
          {CTA_PLAN} <ArrowRight size={17} aria-hidden />
        </Link>
      </div>
    </>
  );
}

function cardId(epreuve: PlanDomainEpreuve): string {
  return `epreuve-${epreuve.toLowerCase()}`;
}

/* --------------------------------------------------- la carte d'une épreuve */

function EpreuveCardView({
  card,
  hasTcf,
  objective,
  buildLevel,
  open,
  onToggle,
}: {
  card: EpreuveCard;
  hasTcf: boolean;
  objective: string | null;
  /** Le palier que le **cycle construit** (`cycle.targetLevel`), pas l'objectif :
   *  c'est celui dont les compétences « à acquérir » sont tirées. */
  buildLevel: string | null;
  open: boolean;
  onToggle: () => void;
}) {
  if (card.state !== "OK") {
    return <PendingCard card={card} />;
  }
  return (
    <OkCard
      card={card}
      hasTcf={hasTcf}
      objective={objective}
      buildLevel={buildLevel}
      open={open}
      onToggle={onToggle}
    />
  );
}

/**
 * **« À évaluer » et « Évaluation incomplète »** — deux absences de niveau, deux
 * causes, deux phrases. Aucune des deux n'est une faiblesse : *null = inconnu,
 * jamais mauvais*.
 *
 * 🛑 **Le parcours de mesure vient du serveur** (`domainesAEvaluer`) et se lance
 * par `usePlanAssessment`, le lanceur qui sert déjà « Compléter mon profil ». On
 * ouvre un parcours **déjà existant**, on n'en écrit pas un second.
 */
function PendingCard({card}: {card: Extract<EpreuveCard, {state: "TO_EVALUATE" | "INCOMPLETE"}>}) {
  const {start, starting, error, paywallOpen, closePaywall} = usePlanAssessment();
  const label = planDomainLabel(card.epreuve);
  const empty = card.state === "TO_EVALUATE";
  // Capturé en `const` : sans ça, la fermeture du `onClick` perd le
  // rétrécissement de type que le ternaire vient d'établir.
  const assessment = card.assessment;

  return (
    <article className={styles.card} id={cardId(card.epreuve)} aria-label={label}>
      <div className={styles.cardHead}>
        <PlanDomainIcon epreuve={card.epreuve} />
        <div className={styles.cardHeadBody}>
          <div className={styles.cardTitleRow}>
            <span className={styles.cardTitle}>{label}</span>
            <span className={styles.statePill} data-state={empty ? "none" : "warn"}>
              {empty ? STATE_TO_EVALUATE : STATE_INCOMPLETE}
            </span>
          </div>
          <p className={styles.cardSummary}>{empty ? toEvaluateText(label) : INCOMPLETE_TEXT}</p>
        </div>
        <div className={styles.cardLevel}>
          <span className={styles.cardLevelValue} data-known="0">{LEVEL_UNKNOWN}</span>
        </div>
      </div>
      {/* 🛑 Sans mesure servie, **aucun bouton** : le serveur ne désigne pas de
          parcours pour cette épreuve, et on n'en invente pas. Miroir du mobile. */}
      {assessment && (
        <div className={styles.cardFoot}>
          <button
            type="button"
            className={styles.outlineCta}
            disabled={starting !== null}
            onClick={() => void start(assessment)}
          >
            {empty ? <Play size={16} aria-hidden /> : <RotateCcw size={16} aria-hidden />}
            {starting !== null ? STARTING : empty ? toEvaluateCta(card.epreuve) : redoCta(label)}
          </button>
        </div>
      )}
      {error && <p className={styles.cardError} role="alert">{error}</p>}
      <PaywallSheet
        ctaLocation="DIAGNOSTIC_REPORT"
        screen="diagnostic_result"
        open={paywallOpen}
        onClose={closePaywall}
        module="INTEGRAL"
      />
    </article>
  );
}

/**
 * **La carte d'une épreuve mesurée**, dépliable.
 *
 * Trois lectures d'une même liste de compétences, et **une seule source** —
 * `domain.skills`, servi par le serveur dans son ordre :
 *
 * - **abonné, dépliée** : deux colonnes, les groupes d'action à gauche, ce qui
 *   est déjà solide à droite ;
 * - **abonné, repliée** : les deux premières lignes de travail, puis « + N
 *   autres » qui déplie ;
 * - **compte gratuit** : la première ligne de travail, une ligne solide, et le
 *   verrou qui annonce **exactement** ce qui reste.
 */
function OkCard({
  card,
  hasTcf,
  objective,
  buildLevel,
  open,
  onToggle,
}: {
  card: Extract<EpreuveCard, {state: "OK"}>;
  hasTcf: boolean;
  objective: string | null;
  buildLevel: string | null;
  open: boolean;
  onToggle: () => void;
}) {
  const {startSeries, starting, error, paywallOpen, closePaywall} = usePlanExercise();
  const label = planDomainLabel(card.epreuve);
  const comprehension = isComprehension(PLAN_DOMAIN_SECTION[card.epreuve]);

  const visibleWork = hasTcf
    ? card.work.slice(0, COLLAPSED_WORK_VISIBLE)
    : card.work.slice(0, FREE_WORK_VISIBLE);
  const visibleSolid = hasTcf ? card.solid : card.solid.slice(0, FREE_SOLID_VISIBLE);
  const restWork = Math.max(0, card.work.length - visibleWork.length);
  // 🛑 Le compteur du verrou est **exact** : ce qui reste sur les compteurs
  // servis, jamais une constante recopiée de la maquette. `0` ⇒ pas de bloc.
  // ⚠️ On retranche les seules lignes **détectées** déjà montrées : une
  // acquisition affichée ne réduit pas un compte de fragilités.
  const shownFragile = visibleWork.filter((skill) => {
    const group = skillGroup(skill);
    return group === "PRIORITY" || group === "REINFORCE";
  }).length;
  const hiddenWork = Math.max(0, card.fragileTotal - shownFragile);
  const hiddenSolid = Math.max(0, card.solidTotal - visibleSolid.length);
  // Le vrai libellé de la compétence suivante — flouté, jamais un décor.
  const teasedTitle =
    card.work[visibleWork.length]?.title
    ?? card.solid[visibleSolid.length]?.title
    ?? LOCK_FALLBACK;

  const groups = [
    {key: "PRIORITY" as const, label: GROUP_PRIORITY, note: null},
    {key: "REINFORCE" as const, label: GROUP_REINFORCE, note: null},
    {
      key: "ACQUIRE" as const,
      label: GROUP_ACQUIRE,
      note: acquireNote(buildLevel),
    },
  ];

  const next = card.work[0] ?? null;
  const showSolid = visibleSolid.length > 0 && (open || !hasTcf);
  const twoColumns = open && hasTcf && visibleSolid.length > 0;
  // Une épreuve mesurée dont aucune compétence n'est encore observée n'a rien à
  // montrer ici : un bloc vide se lirait comme une donnée manquante.
  const showBody = visibleWork.length > 0 || showSolid;

  return (
    <article
      className={`${styles.card} ${open ? styles.cardOpen : ""}`}
      id={cardId(card.epreuve)}
      aria-label={label}
    >
      {/* 🛑 Le titre est un `<span>`, pas un `<h3>` : un titre est du contenu de
          flux et n'a rien à faire dans un `<button>`. L'épreuve reste nommée —
          c'est l'`aria-label` de l'article qui la porte. */}
      <button type="button" className={styles.cardHead} onClick={onToggle} aria-expanded={open}>
        <PlanDomainIcon epreuve={card.epreuve} active={open} />
        <span className={styles.cardHeadBody}>
          {/* 🛑 Aucune pastille ici : la **priorité du domaine** (« Priorité forte »…)
              qualifie ce que le Plan fait de l'épreuve, pas son résultat — elle vit
              sur le Plan, et le mobile n'en affiche aucune sur cette carte. */}
          <span className={styles.cardTitleRow}>
            <span className={styles.cardTitle}>{label}</span>
          </span>
          <span className={styles.cardSummary}>{card.summary}</span>
        </span>
        <span className={styles.cardLevel}>
          <span className={styles.cardLevelValue} data-known="1">{niveauCecrlShort(card.niveau)}</span>
          <span className={styles.cardLevelCaption}>{LEVEL_CAPTION}</span>
          <span className={styles.cardLevelGoal}>
            {/* 🛑 SERVI (`nextTargetLevel`), plus dérivé du niveau : la copie
                locale ignorait l'objectif du candidat, et un candidat B1 visant
                le B1 lisait « prochain palier B2 ». Supprimée le 2026-08-26. */}
            {epreuveMeta(objective, card.domain.nextTargetLevel)}
          </span>
        </span>
        <span className={styles.cardChevron} data-open={open ? "1" : "0"} aria-hidden>
          <ChevronDown size={20} />
        </span>
      </button>

      {open && card.explanation && (
        <p className={styles.cardWhy}>{card.explanation}</p>
      )}

      {showBody && (
        <div className={styles.cardBody} data-columns={twoColumns ? "2" : "1"}>
          <div className={styles.cardColumn}>
            {/* 🛑 Aucun intertitre sans ligne dessous : une épreuve mesurée dont
                rien n'est encore à travailler ne rend pas un groupe vide. */}
            {card.work.length === 0 ? null : open && hasTcf ? (
              groups.map((group) => {
                const items = card.work.filter((skill) => skillGroup(skill) === group.key);
                if (items.length === 0) return null;
                return (
                  <div key={group.key} className={styles.groupBlock}>
                    <GroupHead
                      label={group.label}
                      count={items.length > 1 ? String(items.length) : null}
                      note={group.note}
                    />
                    {items.map((skill) => (
                      <SkillRow
                        key={skill.skillId}
                        skill={skill}
                        starting={starting}
                        onStartSeries={startSeries}
                      />
                    ))}
                  </div>
                );
              })
            ) : (
              <div className={styles.groupBlock}>
                <GroupHead
                  label={
                    hasTcf
                      ? GROUP_PRIORITIES
                      : card.work[0] && skillGroup(card.work[0]) === "PRIORITY"
                        ? GROUP_FREE_MAIN
                        : GROUP_FREE_MAIN_ALT
                  }
                  count={hasTcf ? null : freeCounter(visibleWork.length, card.work.length)}
                  note={null}
                />
                {visibleWork.map((skill) => (
                  <SkillRow
                    key={skill.skillId}
                    skill={skill}
                    pill
                    starting={starting}
                    onStartSeries={startSeries}
                  />
                ))}
                {hasTcf && restWork > 0 && (
                  <button type="button" className={styles.moreButton} onClick={onToggle}>
                    {moreToWork(restWork)}
                  </button>
                )}
              </div>
            )}

            {/* 🛑 `N === 0` ⇒ **le bloc n'existe pas** : on ne fabrique jamais de
                reste à vendre. */}
            {!hasTcf && hiddenWork + hiddenSolid > 0 && (
              <PremiumLink className={styles.lock}>
                <span className={styles.lockIcon} aria-hidden><Lock size={16} /></span>
                <span className={styles.lockBody}>
                  <span className={styles.srOnly}>{LOCK_SR}</span>
                  {/* Le contenu flouté est le VRAI, hors de l'arbre
                      d'accessibilité et du parcours clavier. L'information nette
                      — le compteur, le CTA — vit hors du rideau. */}
                  <PlanBlur>
                    <span className={styles.lockPreview}>{teasedTitle}</span>
                  </PlanBlur>
                  <span className={styles.lockCount}>{lockCount(hiddenWork, hiddenSolid)}</span>
                </span>
                <span className={styles.lockCta}>{LOCK_CTA}</span>
              </PremiumLink>
            )}
          </div>

          {showSolid && (
            <div className={styles.cardColumn}>
              <GroupHead
                label={GROUP_SOLID}
                count={hasTcf && card.solidTotal > 1 ? String(card.solidTotal) : null}
                note={null}
              />
              {visibleSolid.map((skill) => (
                <SkillRow
                  key={skill.skillId}
                  skill={skill}
                  starting={starting}
                  onStartSeries={startSeries}
                />
              ))}
            </div>
          )}
        </div>
      )}

      {/* 🛑 « Non observées » vit ICI, pas dans la colonne des solides : c'est un
          fait de l'épreuve, il ne doit pas disparaître parce qu'aucune compétence
          n'est encore solide. Même emplacement que le mobile. */}
      {open && hasTcf && (next || card.notObserved > 0) && (
        <div className={styles.cardAction}>
          {card.notObserved > 0 && (
            <p className={styles.notObserved}>
              <span className={styles.statePill} data-state="none">
                {LEARNING_PLAN_SKILL_STATUS_LABEL.NOT_OBSERVED}
              </span>
              {notObservedLine(card.notObserved)}
            </p>
          )}
          {next && (
            <>
              <SkillCta
                skill={next}
                label={comprehension ? footCtaComprehension(label) : FOOT_CTA_EXPRESSION}
                comprehension={comprehension}
                starting={starting}
                onStartSeries={startSeries}
              />
              <span className={styles.cardActionNote}>{footNext(next.title)}</span>
            </>
          )}
        </div>
      )}

      {error && <p className={styles.cardError} role="alert">{error}</p>}
      <PaywallSheet
        ctaLocation="DIAGNOSTIC_REPORT"
        screen="diagnostic_result"
        open={paywallOpen}
        onClose={closePaywall}
        module="INTEGRAL"
      />
    </article>
  );
}

/**
 * **La pastille d'une ligne de compétence — elle porte le GROUPE.**
 *
 * 🛑 Ni `PlanNaturePill` (qui dirait « À vérifier » sur une ligne rangée en
 * « Priorité ») ni `LearningPlanStatusPill` (qui dirait « Prioritaire ») : c'est
 * le **titre de groupe** qui doit se lire, exactement comme le mobile
 * (`_SkillGroup.label`). Les libellés sont ceux déjà déclarés en tête de fichier.
 *
 * ⚠️ **Aucune teinte nouvelle** : chacune est celle de l'état qu'elle nomme
 * ailleurs dans l'app — rouge (priorité), ambre (à renforcer), bleu (à acquérir).
 */
const GROUP_PILL_LABEL: Record<SkillGroup, string> = {
  PRIORITY: GROUP_PRIORITY,
  REINFORCE: GROUP_REINFORCE,
  ACQUIRE: GROUP_ACQUIRE,
  SOLID: GROUP_SOLID,
  NOT_OBSERVED: LEARNING_PLAN_SKILL_STATUS_LABEL.NOT_OBSERVED,
};

function GroupPill({group}: {group: SkillGroup}) {
  return (
    <span className={styles.groupPill} data-group={group}>
      {GROUP_PILL_LABEL[group]}
    </span>
  );
}

/** L'intertitre d'un groupe de compétences : son nom, son compte, et — pour les
 *  acquisitions seulement — pourquoi elles sont là. */
function GroupHead({
  label,
  count,
  note,
}: {
  label: string;
  count: string | null;
  note: string | null;
}) {
  return (
    <div className={styles.groupHead}>
      <p>
        <span>{label}</span>
        {count && <b>{count}</b>}
      </p>
      {note && <span>{note}</span>}
    </div>
  );
}

/**
 * Une ligne de compétence.
 *
 * 🛑 **Trois destinations, décidées par des FAITS servis** : un verrou
 * (`skill.locked`) ouvre l'offre, une compétence de compréhension **démarre sa
 * série ciblée** (le parcours réel — elle n'a aucun petit sujet), une compétence
 * d'expression ouvre sa fiche par `planSkillHref`, l'autorité que le Plan
 * emprunte déjà. Aucun second chemin.
 */
function SkillRow({
  skill,
  pill,
  starting,
  onStartSeries,
}: {
  skill: PlanDomainSkillDto;
  pill?: boolean;
  starting: boolean;
  onStartSeries: (skillId: string) => Promise<void>;
}) {
  // 🛑 Le groupe, jamais le seul `status` : une compétence **à acquérir** a un
  // statut `NOT_OBSERVED` et se lit pourtant comme une action à venir.
  const group = skillGroup(skill);
  const solid = group === "SOLID";
  const body = (
    <>
      <span className={styles.skillMark} data-solid={solid ? "1" : "0"} data-group={group}>
        {solid && <Check size={13} strokeWidth={3} aria-hidden />}
      </span>
      <span className={styles.skillBody}>
        <b>{skill.title}</b>
        <span>{skillMetaLine(skill)}</span>
      </span>
      {pill && !solid && <GroupPill group={group} />}
      <RowChevron />
    </>
  );

  if (skill.locked) {
    return <PremiumLink className={styles.skillRow}>{body}</PremiumLink>;
  }
  if (isComprehension(skill.section)) {
    return (
      <button
        type="button"
        className={styles.skillRow}
        disabled={starting}
        onClick={() => void onStartSeries(skill.skillId)}
      >
        {body}
      </button>
    );
  }
  return (
    <Link className={styles.skillRow} href={planSkillHref(skill, {planStep: true})}>
      {body}
    </Link>
  );
}

/** Le bouton de pied de carte : il ouvre **la même chose** que la première ligne
 *  de travail, jamais une seconde destination. */
function SkillCta({
  skill,
  label,
  comprehension,
  starting,
  onStartSeries,
}: {
  skill: PlanDomainSkillDto;
  label: string;
  comprehension: boolean;
  starting: boolean;
  onStartSeries: (skillId: string) => Promise<void>;
}) {
  if (skill.locked) {
    return (
      <PremiumLink className={styles.cardActionCta}>
        {label} <ArrowRight size={16} aria-hidden />
      </PremiumLink>
    );
  }
  if (comprehension) {
    return (
      <button
        type="button"
        className={styles.cardActionCta}
        disabled={starting}
        onClick={() => void onStartSeries(skill.skillId)}
      >
        {starting ? STARTING : label} <ArrowRight size={16} aria-hidden />
      </button>
    );
  }
  return (
    <Link className={styles.cardActionCta} href={planSkillHref(skill, {planStep: true})}>
      {label} <ArrowRight size={16} aria-hidden />
    </Link>
  );
}
