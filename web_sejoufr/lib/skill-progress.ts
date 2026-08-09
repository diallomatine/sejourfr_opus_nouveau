/**
 * Agrégats de progression du module « Compétences TCF ».
 *
 * Le contrat d'API n'expose **pas** de compteur « sujets traités » prêt à
 * afficher pour la tête d'écran : `GET /api/skills?taskCode=` sert les 8
 * compétences avec leurs compteurs, `GET /api/skills/progress?section=` sert
 * une ligne par tâche. Le hero de l'accueil et la barre « Progression de la
 * compétence » de l'écran d'un sujet se **calculent** à partir de là — on
 * n'invente aucun endpoint.
 *
 * Ces fonctions sont pures et testées (`skill-progress.test.ts`) : un composant
 * ne doit jamais refaire ce calcul à la main, sinon deux écrans finissent par
 * afficher deux pourcentages différents pour la même tâche.
 */

/** Sujets traités / total, plus le pourcentage entier correspondant. */
export interface SkillProgress {
  attempted: number;
  total: number;
  /** 0 quand rien n'est encore mesurable — jamais NaN. */
  percent: number;
}

/** Ce dont l'agrégat a besoin, et rien de plus : accepte aussi bien un
 *  `SkillDto` qu'un `SkillTaskProgressDto` (mêmes deux champs). */
interface Countable {
  promptCount: number;
  attemptedCount: number;
}

/** Pourcentage entier borné à [0, 100]. Une division par zéro vaut 0. */
export function progressPercent(attempted: number, total: number): number {
  if (!Number.isFinite(attempted) || !Number.isFinite(total) || total <= 0) return 0;
  const pct = Math.round((attempted / total) * 100);
  return Math.min(100, Math.max(0, pct));
}

/**
 * Somme d'une liste de compteurs — les 8 compétences d'une tâche, ou une seule
 * d'entre elles. C'est l'agrégat affiché dans le hero de l'accueil.
 */
export function sumProgress(items: readonly Countable[]): SkillProgress {
  let attempted = 0;
  let total = 0;
  for (const item of items) {
    total += Math.max(0, item.promptCount);
    // Un backend qui compterait plus de tentés que de sujets ne doit pas
    // produire « 6/5 » à l'écran.
    attempted += Math.min(Math.max(0, item.attemptedCount), Math.max(0, item.promptCount));
  }
  return {attempted, total, percent: progressPercent(attempted, total)};
}

/** Progression d'une compétence donnée dans une liste, par son id. Null quand
 *  la liste n'est pas (encore) chargée ou ne la contient pas : l'appelant
 *  n'affiche alors pas de barre plutôt qu'une barre fausse à 0 %. */
export function findSkillProgress(
  skills: readonly (Countable & {id: string})[] | null | undefined,
  skillId: string,
): SkillProgress | null {
  if (!skills) return null;
  const found = skills.find((s) => s.id === skillId);
  return found ? sumProgress([found]) : null;
}

/** Ce dont le libellé d'état a besoin : les trois compteurs servis par
 *  `GET /api/skills` — aucun agrégat inventé. */
interface SkillCounters {
  promptCount: number;
  attemptedCount: number;
  validatedCount: number;
}

/**
 * État d'une compétence en une phrase : « 2 réussis · 3 restants »,
 * « 1 commencé · 4 restants », « 5 à découvrir ».
 *
 * ⚠️ **Libellé gelé**, miroir mot pour mot du mobile
 * (`competenceProgressLabel`, `competences/widgets/competence_card.dart`). Les
 * deux fronts en tiennent chacun une copie écrite à la main : un libellé qui
 * bouge, ce sont deux fichiers à changer dans la même passe, et deux tests.
 */
/**
 * Un compteur absent vaut 0, jamais `NaN`. Le mobile pose ce repli au décodage
 * (`fromJson`) ; le web n'a pas de couche de parsing, donc il le pose ici — sans
 * ça, une réponse servie par un backend plus ancien affichait « NaN commencé ».
 */
function counter(value: number | undefined | null): number {
  return Number.isFinite(value) ? Math.max(0, value as number) : 0;
}

export function competenceProgressLabel(skill: SkillCounters): string {
  const total = counter(skill.promptCount);
  if (total === 0) return "Bientôt disponible";

  const attempted = Math.min(counter(skill.attemptedCount), total);
  if (attempted === 0) return `${total} à découvrir`;

  const validated = Math.min(counter(skill.validatedCount), attempted);
  const head =
    validated > 0
      ? `${validated} réussi${validated > 1 ? "s" : ""}`
      : `${attempted} commencé${attempted > 1 ? "s" : ""}`;

  const remaining = total - attempted;
  if (remaining === 0) return head;
  return `${head} · ${remaining} restant${remaining > 1 ? "s" : ""}`;
}
