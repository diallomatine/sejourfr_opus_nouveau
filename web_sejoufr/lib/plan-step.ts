import type {LearningPlanDto, LearningPlanPriorityDto, SkillPromptSummaryDto} from "./types";

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
 * L'étape du Plan qui porte cette compétence — priorité n°1 comprise.
 *
 * `null` est un cas **normal et fréquent** : le Plan n'est pas chargé, ou la
 * compétence **n'est plus une priorité** (le serveur l'en sort dès qu'une
 * vérification en situation a réussi). L'appelant retombe alors silencieusement
 * sur la fiche complète.
 */
export function planStepFor(
  plan: LearningPlanDto | null | undefined,
  skillId: string,
): LearningPlanPriorityDto | null {
  if (!plan || !skillId) return null;
  const priorities = [plan.currentPriority, ...plan.nextPriorities];
  const match = priorities.find((p) => p && p.skillId === skillId);
  if (!match || match.stepPromptIds.length === 0) return null;
  return match;
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
