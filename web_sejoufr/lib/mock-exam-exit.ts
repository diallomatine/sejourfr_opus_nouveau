/**
 * Quitter un **examen blanc QCM joué seul** — les libellés, déclarés **une
 * seule fois** pour tout le web.
 *
 * > **Quitter un examen, c'est le terminer.** La croix n'est pas un « je
 * > reviendrai » : l'attempt est finalisé, donc définitif et non reprenable, et
 * > le candidat arrive directement sur son résultat.
 *
 * Périmètre : civique global (40 Q), civique par thème (20 Q), examens TCF par
 * épreuve (CO / CE / STRUCTURE) et examens issus d'un `ExamTemplate`.
 * **Hors périmètre** : les séries d'entraînement (quitter n'y coûte rien, la
 * session se reprend) et les sous-épreuves d'un examen blanc complet, qui ont
 * leurs propres libellés dans `lib/full-exam-exit.ts` — là, quitter clôt
 * l'épreuve **sans** ouvrir de bilan.
 *
 * Le bouton de confirmation **nomme l'issue** : la croix devient destructrice
 * sur un simple appui, la confirmation est la seule protection, elle doit être
 * lisible.
 *
 * Miroir mot pour mot du mobile :
 * `mobile_sejourfr/lib/screens/question_runner/mock_exam_exit_labels.dart`.
 */

export const MOCK_EXAM_QUIT_TITLE = "Quitter l'examen ?";

/**
 * Le message dit les **trois** conséquences, avant l'action : plus de reprise,
 * un résultat quand même, et le reste compté non répondu.
 */
export const MOCK_EXAM_QUIT_MESSAGE =
    "Quitter, c'est terminer cet examen : vous ne pourrez plus le reprendre. " +
    "Vous verrez votre résultat sur les questions déjà répondues, et les questions " +
    "restantes seront comptées comme non répondues.";

export const MOCK_EXAM_QUIT_CONFIRM = "Quitter et voir mon résultat";
export const MOCK_EXAM_QUIT_CANCEL = "Continuer l'examen";
