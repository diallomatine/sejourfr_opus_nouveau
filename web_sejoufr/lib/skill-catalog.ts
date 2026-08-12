/**
 * Chargement du catalogue « Compétences » d'une épreuve productive.
 *
 * Une épreuve = 3 tâches × 8 compétences. L'écran des compétences les chargeait
 * **tâche par tâche** (`GET /api/skills?taskCode=EE1`), donc un aller-retour
 * réseau à chaque pastille T1/T2/T3. Le backend sert maintenant l'épreuve
 * entière (`GET /api/skills?section=EE|EO`, 24 compétences triées `taskCode`
 * puis `displayOrder`) : **un seul appel**, et les pastilles deviennent un
 * filtre local (`skillsOfTask`).
 *
 * Le repli par tâche reste écrit — pas par prudence décorative : si le filtre
 * `section` n'est pas servi (backend plus ancien), on recompose l'épreuve avec
 * les 3 appels historiques, **une fois**, sous la même clé de cache. Les écrans
 * n'ont ainsi qu'un seul contrat : « la liste, c'est toute l'épreuve ».
 *
 * Le client est passé en paramètre (jamais importé depuis `lib/api`) : ce module
 * reste testable au runner de Node avec un client factice qui compte les appels.
 */

import {type DataCache, dataCache} from "./data-cache.ts";
import {
  type SkillDto,
  type SkillSection,
  type SkillTaskCode,
  type SkillTaskProgressDto,
  skillTaskCodeOf,
} from "./types.ts";

/** Clé de l'épreuve entière. **Une seule** entrée pour les 3 tâches. */
export function skillsSectionKey(section: SkillSection): string {
  return `skills:section:${section}`;
}

/** Clé de l'agrégat par tâche (`GET /api/skills/progress?section=`). */
export function skillsProgressKey(section: SkillSection): string {
  return `skills:progress:${section}`;
}

/** Clé du détail d'une compétence (sa fiche + ses 15 petits sujets). */
export function skillDetailKey(skillId: string): string {
  return `skills:detail:${skillId}`;
}

/** Préfixe commun : ce que purge une soumission ou une analyse de compétence. */
export const SKILLS_CACHE_PREFIX = "skills:";

/** Le strict nécessaire de `skillApi`, pour pouvoir injecter un faux en test. */
export interface SkillCatalogClient {
  listSkills(taskCode: string): Promise<SkillDto[]>;
  listSkillsBySection(section: SkillSection): Promise<SkillDto[]>;
  progress(section: SkillSection): Promise<SkillTaskProgressDto[]>;
}

const TACHES = [1, 2, 3] as const;

/**
 * Statuts qui disent « ce filtre n'existe pas ici » — et eux seuls. Un 401, un
 * 403 ou un 500 doivent **remonter** : les rattraper masquerait une session
 * expirée ou une panne derrière trois appels de repli.
 */
function isFilterUnsupported(error: unknown): boolean {
  const status = (error as {status?: unknown} | null)?.status;
  return status === 400 || status === 404 || status === 405 || status === 501;
}

/** Tri du contrat : `taskCode` puis `displayOrder`. Appliqué localement pour ne
 *  jamais dépendre de l'ordre d'arrivée (repli compris). */
function sortSkills(list: readonly SkillDto[]): SkillDto[] {
  return [...list].sort(
    (a, b) => a.taskCode.localeCompare(b.taskCode) || a.displayOrder - b.displayOrder,
  );
}

/** La réponse couvre-t-elle bien les 3 tâches de l'épreuve ? Un backend qui
 *  ignorerait `section` renverrait autre chose — on le voit ici, on ne l'affiche
 *  pas à l'écran. */
function coversSection(list: readonly SkillDto[], section: SkillSection): boolean {
  const codes = new Set(list.map((s) => s.taskCode));
  return TACHES.every((n) => codes.has(skillTaskCodeOf(section, n)));
}

/**
 * Les 24 compétences de l'épreuve, chargées **une fois par session**.
 * Rechargées seulement après une invalidation explicite (soumission, analyse).
 */
export function loadSectionSkills(
  client: SkillCatalogClient,
  section: SkillSection,
  cache: DataCache = dataCache,
): Promise<SkillDto[]> {
  return cache.cached(skillsSectionKey(section), async () => {
    try {
      const all = await client.listSkillsBySection(section);
      if (coversSection(all, section)) return sortSkills(all);
    } catch (error) {
      if (!isFilterUnsupported(error)) throw error;
    }
    const lists = await Promise.all(
      TACHES.map((n) => client.listSkills(skillTaskCodeOf(section, n))),
    );
    return sortSkills(lists.flat());
  });
}

/** Les 8 compétences d'une tâche, **sans réseau** : un filtre sur la liste déjà
 *  chargée. C'est ce qui rend les pastilles T1/T2/T3 instantanées. */
export function skillsOfTask(
  all: readonly SkillDto[] | undefined,
  taskCode: SkillTaskCode,
): SkillDto[] {
  if (!all) return [];
  return all.filter((s) => s.taskCode === taskCode);
}

/** Agrégat par tâche (palier de la tâche). Best-effort : l'écran sait s'en
 *  passer, mais il n'a aucune raison de le redemander à chaque tâche. */
export function loadTaskProgress(
  client: SkillCatalogClient,
  section: SkillSection,
  cache: DataCache = dataCache,
): Promise<SkillTaskProgressDto[]> {
  return cache.cached(skillsProgressKey(section), () => client.progress(section));
}
