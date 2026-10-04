/**
 * **Propositions réduites à une lettre-clé** (compréhension orale) : l'autorité
 * unique du web, partagée par le runner, le rapport d'examen et le détail d'un
 * favori. Miroir mobile : `QuestionDto.isLetterKeyQuestion` /
 * `QuestionDto.choiceKeyLetter` (`core/models/question_models.dart`).
 *
 * - `CO_IMAGE` : toujours. Le texte des propositions vit dans l'audio ; le
 *   `label` n'est jamais affiché, même s'il n'est pas une lettre (sinon la
 *   réponse s'afficherait à l'écran).
 * - `CO` (`FULL_AUDIO`) : quand TOUS les labels sont une lettre (« A » ou
 *   « Réponse A »), clé citée par l'audio et l'explication.
 * - Aucun autre type : une question STRUCTURE dont un choix est « a » (verbe
 *   avoir) garde son texte.
 *
 * La lettre vient du label quand il en est une, sinon de la position : l'ordre
 * reçu suit déjà les lettres (`QuestionMapper.ordreReference` côté serveur).
 */

import type { QuestionType } from "./types";

const LETTER_KEY_LABEL = /^(?:r[ée]ponse\s+)?([A-D])$/i;

interface LetterKeyQuestion {
  questionType: QuestionType;
  choices: ReadonlyArray<{ label: string }>;
}

export function isLetterKeyQuestion(q: LetterKeyQuestion): boolean {
  if (q.questionType === "CO_IMAGE") return true;
  return (
    q.questionType === "CO" &&
    q.choices.length > 0 &&
    q.choices.every((c) => LETTER_KEY_LABEL.test(c.label.trim()))
  );
}

/** Lettre de la proposition d'indice `index` (A, B, C, D…). */
export function choiceKeyLetter(label: string, index: number): string {
  const match = LETTER_KEY_LABEL.exec(label.trim());
  return match ? match[1].toUpperCase() : String.fromCharCode(65 + index);
}
