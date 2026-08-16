import type {
  LearningPlanCompletedStepDto,
  LearningPlanDto,
  LearningPlanPriorityDto,
  PlanStepExerciseDto,
  SkillPromptSummaryDto,
} from "./types";

/**
 * **Une compétence ouverte depuis le Plan reste dans son étape.**
 *
 * Une étape du Plan, ce sont les 5 premiers sujets actifs d'une compétence
 * (`stepPromptIds`, servis par le serveur). La carte d'étape affiche déjà
 * « 2/5 » ; sans ce marqueur, ouvrir la compétence retombait sur la fiche
 * générique et son « 1/15 », donc le candidat perdait de vue ce qu'il lui reste
 * à faire pour finir son étape.
 *
 * Deux vues d'une même compétence selon la porte d'entrée, c'est **assumé** :
 * par « Réviser → épreuve → Compétences », la fiche complète (les 15 sujets,
 * « x/15 ») ne bouge pas d'un pixel.
 *
 * 🛑 **Rien n'est recalculé ici** : ni « les 5 premiers par ordre d'affichage »,
 * ni un statut de sujet, ni un compteur. Le serveur sert le périmètre
 * (`stepPromptIds`) et les compteurs (`stepAttemptedCount` /
 * `stepPromptCount`), ce module ne fait que les retrouver.
 *
 * ⚠️ **Aucun identifiant ne voyage dans l'URL** : on passe un simple marqueur
 * (`?etape=1`) et on relit le Plan **déjà en cache** (`learningPlanApi
 * .peekCached()`). Rien à charger, donc aucun appel réseau supplémentaire.
 */

/** Marqueur d'URL. Sa valeur ne porte aucune information : seule sa présence
 *  dit « on arrive du Plan ». */
export const PLAN_STEP_PARAM = "etape";
const PLAN_STEP_VALUE = "1";

/** Ajoute le marqueur à un chemin interne, sans écraser une query existante. */
export function withPlanStep(href: string, step = true): string {
  if (!step) return href;
  const [path, query] = href.split("?", 2);
  const params = new URLSearchParams(query ?? "");
  params.set(PLAN_STEP_PARAM, PLAN_STEP_VALUE);
  return `${path}?${params.toString()}`;
}

/** Vrai quand l'écran a été ouvert depuis le Plan. */
export function isPlanStep(params: {get(name: string): string | null} | null): boolean {
  return params?.get(PLAN_STEP_PARAM) === PLAN_STEP_VALUE;
}

/**
 * Le **périmètre** d'une étape, quelle que soit sa nature — priorité en cours,
 * priorité à venir ou étape **franchie**. C'est le seul contrat dont l'écran
 * d'étape a besoin : les identifiants de ses sujets et ses compteurs servis.
 *
 * ⚠️ Une étape **franchie** n'a **ni exercice recommandé ni cadenas** (le
 * serveur n'en sert aucun), et son `stepCompleted` vaut `false` : le serveur ne
 * publie ce dérivé que sur une priorité, et le recalculer ici serait
 * réimplémenter une règle serveur. L'écran retombe alors sur son comportement
 * historique — c'est le repli voulu, pas un manque.
 */
export interface PlanStepScope {
  skillId: string;
  stepPromptCount: number;
  stepAttemptedCount: number;
  stepValidatedCount: number;
  stepPromptIds: string[];
  stepCompleted: boolean;
  recommendedExercise: PlanStepExerciseDto | null;
}

function scopeOfPriority(priority: LearningPlanPriorityDto): PlanStepScope {
  return {
    skillId: priority.skillId,
    stepPromptCount: priority.stepPromptCount,
    stepAttemptedCount: priority.stepAttemptedCount,
    stepValidatedCount: priority.stepValidatedCount,
    stepPromptIds: priority.stepPromptIds,
    stepCompleted: priority.stepCompleted,
    recommendedExercise: priority.recommendedExercise,
  };
}

function scopeOfCompleted(step: LearningPlanCompletedStepDto): PlanStepScope {
  return {
    skillId: step.skillId,
    stepPromptCount: step.stepPromptCount,
    stepAttemptedCount: step.stepAttemptedCount,
    stepValidatedCount: step.stepValidatedCount,
    stepPromptIds: step.stepPromptIds,
    stepCompleted: false,
    recommendedExercise: null,
  };
}

/**
 * L'étape du Plan qui porte cette compétence — priorité n°1 et **étape
 * franchie** comprises. Une étape franchie garde son périmètre : ouvrir une
 * carte cochée doit mener aux mêmes 5 sujets, pas à la fiche des 15.
 *
 * `null` est un cas **normal et fréquent** : le Plan n'est pas chargé, ou la
 * compétence n'apparaît plus dans le parcours (une étape franchie sort du Plan
 * quand la borne serveur est atteinte). L'appelant retombe alors
 * silencieusement sur la fiche complète.
 */
export function planStepFor(
  plan: LearningPlanDto | null | undefined,
  skillId: string,
): PlanStepScope | null {
  if (!plan || !skillId) return null;
  const priority = [plan.currentPriority, ...plan.nextPriorities].find(
    (p) => p && p.skillId === skillId,
  );
  const scope = priority
    ? scopeOfPriority(priority)
    : (() => {
        const done = (plan.completedSteps ?? []).find((s) => s.skillId === skillId);
        return done ? scopeOfCompleted(done) : null;
      })();
  if (!scope || scope.stepPromptIds.length === 0) return null;
  return scope;
}

/**
 * Les sujets de l'étape, **dans l'ordre servi**. Un identifiant sans sujet
 * correspondant est simplement ignoré — on n'invente jamais une carte.
 * Tableau vide ⇒ l'appelant se replie sur la fiche complète.
 */
export function planStepPrompts<T extends Pick<SkillPromptSummaryDto, "id">>(
  prompts: readonly T[],
  stepPromptIds: readonly string[],
): T[] {
  const byId = new Map(prompts.map((p) => [p.id, p]));
  return stepPromptIds
    .map((id) => byId.get(id))
    .filter((p): p is T => p !== undefined);
}

/**
 * **Le sujet que l'écran d'étape propose de faire — désigné par le SERVEUR.**
 *
 * 🛑 Aucune règle de choix n'est écrite ici. `RecommendedExerciseSelector`
 * (premier sujet jamais tenté, sinon le `TO_REINFORCE` le plus ancien, sinon le
 * plus anciennement tenté) tourne côté serveur, son périmètre est **déjà borné
 * aux sujets de l'étape**, et son résultat est servi sur la priorité. On ne fait
 * que retrouver le sujet correspondant : un « premier sujet non validé » recodé
 * ici désignerait un autre sujet que le Plan, et les deux écrans se
 * contrediraient.
 *
 * `null` est un cas **normal** : pas d'exercice recommandé, exercice qui n'est
 * pas un micro-sujet (une **vérification** se lance depuis le Plan, jamais
 * d'ici), ou sujet absent du périmètre servi. L'appelant garde alors son
 * comportement habituel.
 */
export function planStepRecommendedPrompt<T extends Pick<SkillPromptSummaryDto, "id">>(
  step: PlanStepScope | null,
  prompts: readonly T[],
): T | null {
  const exercise = step?.recommendedExercise;
  if (!exercise || exercise.kind !== "MICRO_TRAINING" || !exercise.skillPromptId) {
    return null;
  }
  return prompts.find((p) => p.id === exercise.skillPromptId) ?? null;
}

/* ------------------------------------------------------------------ libellés
 *
 * ⚠️ **Contrat gelé, miroir mot pour mot du mobile**
 * (`mobile_sejourfr/lib/screens/plan/plan_step_labels.dart`). Ces chaînes ne
 * transitent pas par le réseau : chaque front en tient sa copie, un libellé qui
 * bouge, ce sont **deux** fichiers à changer dans la même passe.
 *
 * **Tutoiement** : on est dans le module « Compétences », qui tutoie son chrome.
 */

export const PLAN_STEP_PILL = "Étape de ton plan";
export const PLAN_STEP_BACK_LABEL = "Mon plan";
export const PLAN_STEP_SECTION_TITLE = "Les sujets de cette étape";
export const PLAN_STEP_LINK = "Voir mon plan";
export const PLAN_STEP_DONE_TITLE = "Étape terminée";
export const PLAN_STEP_DONE_CTA = "Revenir à mon plan";

/** Les deux libellés du bouton d'action de l'écran d'étape. Commencer un sujet
 *  neuf et revenir sur un sujet déjà rendu ne se disent pas pareil : c'est le
 *  **statut servi** du sujet désigné qui tranche (`TODO` ou non), jamais une
 *  règle de choix recodée côté front. */
export const PLAN_STEP_START_CTA = "Commencer le prochain sujet";
export const PLAN_STEP_RETRY_CTA = "Retravailler ce sujet";

/** « Cette étape, ce sont les 5 premiers sujets de cette compétence. » — le
 *  nombre vient du serveur, il n'est jamais écrit en dur (une compétence qui
 *  publie moins de sujets a une étape plus courte). */
export function planStepSectionText(total: number): string {
  return total > 1
    ? `Cette étape, ce sont les ${total} premiers sujets de cette compétence.`
    : "Cette étape, c'est le premier sujet de cette compétence.";
}

/** Ce qu'on dit quand les sujets de l'étape ont tous été traités. On ne promet
 *  aucune suite : c'est le Plan qui décide de ce qui vient après. */
export function planStepDoneText(total: number): string {
  return total > 1
    ? `Tu as traité les ${total} sujets de cette étape. La suite se décide dans ton plan.`
    : "Tu as traité le sujet de cette étape. La suite se décide dans ton plan.";
}

/* ------------------------------------------- étapes franchies (écran « Plan »)
 *
 * ⚠️ **Vouvoiement** : ces chaînes-ci vivent sur le Plan, qui vouvoie — à la
 * différence des libellés ci-dessus, qui appartiennent au module « Compétences ».
 * Miroir mot pour mot de `mobile_sejourfr/lib/screens/plan/plan_step_labels.dart`.
 */

/** Badge d'état d'une étape **franchie**, dans la même famille que « En cours »
 *  et « À venir » de l'étape courante et des suivantes. */
export const PLAN_STEP_BADGE_DONE = "Terminée";

/** Libellé de la coche qui remplace le numéro d'une étape franchie — lu par les
 *  lecteurs d'écran, jamais affiché. */
export const PLAN_STEP_DONE_MARK_LABEL = "Étape terminée";

/**
 * Le sous-titre de « Votre parcours ». Il ne décrit que les **priorités
 * actives** : ce sont elles qui ouvrent la liste, numérotées à partir de 1.
 *
 * ⚠️ Les étapes **franchies** n'y figurent plus. Elles s'accumulent (5 servies
 * par le serveur), et les mettre en tête repoussait la priorité en 6ᵉ position,
 * hors écran — l'inverse de ce que le Plan doit faire. Elles vivent sous la
 * liste, repliées derrière {@link planDoneSectionCta}.
 */
export function planPathSubtitle(active: number): string {
  const s = active > 1 ? "s" : "";
  return `${active} priorité${s} active${s}, dans l'ordre.`;
}

/** Le bouton qui déplie les étapes franchies, sous le parcours. */
export function planDoneSectionCta(count: number, open: boolean): string {
  const s = count > 1 ? "s" : "";
  return open
    ? `Masquer les étapes franchies`
    : `Voir les ${count} étape${s} franchie${s}`;
}
