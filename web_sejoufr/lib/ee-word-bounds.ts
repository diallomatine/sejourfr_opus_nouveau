import type {ProductionTaskDto} from "./types";

/**
 * Compteur de mots des productions écrites. Même définition que le serveur
 * (`ProductionEvaluationService.validateTextWordCount`) et que le mobile
 * (`_countWords`) : on découpe sur les blancs, un texte vide vaut 0. Le
 * compteur affiché au candidat et la règle qui débloque le bouton doivent
 * compter pareil, sinon l'écran promet une soumission que le serveur refuse.
 */
export function countEeWords(texte: string): number {
    const t = texte.trim();
    return t ? t.split(/\s+/).length : 0;
}

/**
 * Bornes de mots d'une tâche EE, **strictes** : le TCF IRN attend 30–60 mots en
 * tâche 1 et **40–90** en tâches 2 et 3, sans aucune tolérance. Les valeurs ne
 * sont jamais écrites ici : elles viennent de la tâche servie par le backend
 * (`production_tasks.mots_min/mots_max`), seule source de vérité — c'est ce qui
 * garantit que web, mobile et serveur bloquent au même mot.
 *
 * Une borne absente (`null`) ne bloque rien de ce côté-là.
 *
 * Miroir Dart : `isEeWordCountWithinBounds` (`production_models.dart`).
 */
export function isEeWordCountWithinBounds(
    task: Pick<ProductionTaskDto, "motsMin" | "motsMax">,
    wordCount: number,
): boolean {
    const {motsMin: min, motsMax: max} = task;
    return (min == null || wordCount >= min) && (max == null || wordCount <= max);
}
