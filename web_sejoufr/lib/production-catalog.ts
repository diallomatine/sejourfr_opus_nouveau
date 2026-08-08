/**
 * Chargement du catalogue et de l'historique d'une épreuve productive (EE/EO).
 *
 * Même motif que `skill-catalog.ts` : les trois modes du parcours (Compétences ·
 * Sujets · Examens) et les trois tâches sont des routes distinctes, donc chaque
 * bascule relançait les mêmes appels. Ici, deux natures de données très
 * différentes cohabitent — et c'est le seul piège de ce cache :
 *
 * - **Catalogue** (`production-tasks`, `production-examples`) : contenu
 *   éditorial, il ne bouge pas d'une session à l'autre. Chargé **une fois**, et
 *   pour l'épreuve **entière** (`listTasks` sans `tacheNumero`) — les pastilles
 *   T1/T2/T3 filtrent ensuite localement (`tasksOfTache`).
 * - **Progression** (`production-submissions`, bilans) : elle change dès que le
 *   candidat rend une production. Elle est mise en cache **mais invalidée
 *   explicitement** par `lib/api.ts` à chaque soumission / relance
 *   d'évaluation. Sans cela l'écran des sujets afficherait « à faire » sur un
 *   sujet qu'on vient de rendre.
 *
 * Le client est passé en paramètre (jamais importé depuis `lib/api`) : ce module
 * reste testable au runner de Node avec un client factice qui compte les appels.
 */

import {type DataCache, dataCache} from "./data-cache.ts";
import type {
  EpreuveType,
  ProductionBilanResponse,
  ProductionExampleDto,
  ProductionSubmissionDto,
  ProductionTaskDto,
} from "./types.ts";

/** Clé du catalogue de sujets d'une épreuve — les 3 tâches d'un coup. */
export function productionTasksKey(epreuve: EpreuveType): string {
  return `production:tasks:${epreuve}`;
}

/** Clé des réponses-modèles d'une tâche. */
export function productionExamplesKey(epreuve: EpreuveType, tacheNumero: number): string {
  return `production:examples:${epreuve}:${tacheNumero}`;
}

/** Clé de l'historique de soumissions de l'utilisateur sur une épreuve. */
export function productionMineKey(epreuve: EpreuveType): string {
  return `production:mine:${epreuve}`;
}

/** Clé du bilan d'une session d'examen blanc. */
export function productionBilanKey(attemptId: string): string {
  return `production:bilan:${attemptId}`;
}

/** Ce que purge une soumission de production (progression + bilans), catalogue
 *  éditorial exclu : une soumission ne change pas la liste des sujets. */
export const PRODUCTION_PROGRESS_PREFIXES = ["production:mine:", "production:bilan:"] as const;

/**
 * Profondeur d'historique demandée. Le backend plafonne à 20 par défaut, ce qui
 * suffisait à l'écran des sujets mais pas à la grille des 10 examens blancs (2 à
 * 3 soumissions chacun). Une seule valeur pour les deux écrans = **une seule
 * entrée de cache**, donc un seul appel pour les deux.
 */
export const PRODUCTION_HISTORY_LIMIT = 100;

/** Le strict nécessaire de `productionApi`, pour injecter un faux en test. */
export interface ProductionCatalogClient {
  listTasks(opts: {
    epreuve: EpreuveType;
    niveau?: string;
    tacheNumero?: number;
  }): Promise<ProductionTaskDto[]>;
  listExamples(epreuve: EpreuveType, tacheNumero: number): Promise<ProductionExampleDto[]>;
  listMine(opts: {epreuve?: EpreuveType; limit?: number}): Promise<ProductionSubmissionDto[]>;
  getBilan(attemptId: string): Promise<ProductionBilanResponse>;
}

/** Tous les sujets de l'épreuve (les 3 tâches), chargés une fois par session. */
export function loadEpreuveTasks(
  client: ProductionCatalogClient,
  epreuve: EpreuveType,
  cache: DataCache = dataCache,
): Promise<ProductionTaskDto[]> {
  return cache.cached(productionTasksKey(epreuve), () => client.listTasks({epreuve}));
}

/**
 * Les sujets d'une tâche, **sans réseau**. L'ordre (par niveau cible) est celui
 * qui numérote les cartes à l'écran et décide quel sujet est offert au compte
 * gratuit : il doit rester stable, donc il se calcule ici et nulle part ailleurs.
 */
export function tasksOfTache(
  all: readonly ProductionTaskDto[] | undefined,
  tacheNumero: number,
): ProductionTaskDto[] {
  if (!all) return [];
  return all
    .filter((t) => t.tacheNumero === tacheNumero)
    .sort((a, b) => a.niveauCible.localeCompare(b.niveauCible));
}

/** Réponses-modèles d'une tâche (contenu éditorial, une fois par session). */
export function loadExamples(
  client: ProductionCatalogClient,
  epreuve: EpreuveType,
  tacheNumero: number,
  cache: DataCache = dataCache,
): Promise<ProductionExampleDto[]> {
  return cache.cached(productionExamplesKey(epreuve, tacheNumero), () =>
    client.listExamples(epreuve, tacheNumero),
  );
}

/** Historique des soumissions de l'épreuve. **Invalidé à chaque soumission**
 *  (cf. `lib/api.ts`) : c'est la donnée qui doit rester fraîche. */
export function loadMySubmissions(
  client: ProductionCatalogClient,
  epreuve: EpreuveType,
  cache: DataCache = dataCache,
): Promise<ProductionSubmissionDto[]> {
  return cache.cached(productionMineKey(epreuve), () =>
    client.listMine({epreuve, limit: PRODUCTION_HISTORY_LIMIT}),
  );
}

/**
 * Un bilan ne se fige que lorsque la session est terminée **et** que ses trois
 * évaluations sont revenues. Avant cela, l'IA travaille encore en arrière-plan :
 * le mettre en cache figerait une note incomplète sans qu'aucune action du
 * candidat ne vienne l'invalider.
 */
export function isFinalBilan(bilan: ProductionBilanResponse): boolean {
  return bilan.finished && bilan.evaluatedCount >= bilan.expectedCount;
}

/**
 * Bilan d'une session : mis en cache **seulement s'il est final**. Les
 * chargements concurrents restent mutualisés dans tous les cas.
 */
export async function loadBilan(
  client: ProductionCatalogClient,
  attemptId: string,
  cache: DataCache = dataCache,
): Promise<ProductionBilanResponse> {
  const key = productionBilanKey(attemptId);
  const bilan = await cache.cached(key, () => client.getBilan(attemptId));
  if (!isFinalBilan(bilan)) cache.invalidate(key);
  return bilan;
}

/** Session d'examen blanc reconstituée depuis l'historique des soumissions. */
export interface ProductionExamDraft {
  attemptId: string;
  /** Date de la première tâche rendue — l'ancre de tri de la grille. */
  date: string;
  /** Moyenne des tâches évaluées, à une décimale. Null tant que rien n'est noté. */
  avgNote: number | null;
}

/**
 * Nombre de soumissions à partir duquel un attempt se lit comme une **session
 * d'examen blanc** et non comme un entraînement libre.
 *
 * Deux, et pas trois. Une épreuve complète en compte bien trois, mais ce seuil
 * n'est pas la définition de l'épreuve : c'est un **discriminant**. Un
 * entraînement libre n'ouvre qu'un attempt par tâche, donc ne porte jamais deux
 * soumissions ; à l'inverse, un examen abandonné après deux tâches reste un
 * examen — il a consommé son slot et le freebie EE/EO côté backend. Le passer à
 * trois le ferait disparaître de la grille alors que le serveur, lui, l'a bien
 * compté : le candidat verrait « examen 1 jamais fait » et se prendrait un 403
 * en le relançant.
 *
 * ⚠️ Miroir de `kProductionExamMinSubmissions` (mobile,
 * `expression_hub_data.dart`), qui valait 3 : un attempt à 2 tâches
 * apparaissait en examen sur le web et **nulle part** sur mobile.
 */
export const PRODUCTION_EXAM_MIN_SUBMISSIONS = 2;

/**
 * Regroupe les soumissions par session d'examen blanc : un attempt qui porte au
 * moins {@link PRODUCTION_EXAM_MIN_SUBMISSIONS} soumissions.
 *
 * Pur et testé : c'est ce qui alimente la grille des 10 examens, et le calcul
 * ne doit pas se refaire à la main dans un JSX.
 */
export function examDrafts(
  subs: readonly ProductionSubmissionDto[] | undefined,
): ProductionExamDraft[] {
  if (!subs) return [];
  const byAttempt = new Map<string, ProductionSubmissionDto[]>();
  for (const sub of subs) {
    const arr = byAttempt.get(sub.attemptId) ?? [];
    arr.push(sub);
    byAttempt.set(sub.attemptId, arr);
  }

  const drafts: ProductionExamDraft[] = [];
  for (const [attemptId, items] of byAttempt) {
    if (items.length < PRODUCTION_EXAM_MIN_SUBMISSIONS) continue;
    const date = items.map((i) => i.submittedAt).sort((a, b) => a.localeCompare(b))[0];
    const notes = items
      .map((i) => i.evaluation?.noteSurVingt)
      .filter((v): v is number => v != null);
    drafts.push({
      attemptId,
      date,
      // Une décimale, comme les notes elles-mêmes : arrondir à l'entier
      // afficherait 13 là où la session vaut 12,5.
      avgNote: notes.length
        ? Math.round((notes.reduce((acc, v) => acc + v, 0) / notes.length) * 10) / 10
        : null,
    });
  }
  drafts.sort((a, b) => a.date.localeCompare(b.date));
  return drafts;
}

/** Dernière soumission par sujet — l'état « traité » des cartes de sujet. */
export function latestSubmissionByTask(
  subs: readonly ProductionSubmissionDto[] | undefined,
): Record<string, ProductionSubmissionDto> {
  const map: Record<string, ProductionSubmissionDto> = {};
  for (const sub of subs ?? []) {
    const prev = map[sub.productionTaskId];
    if (!prev || sub.submittedAt > prev.submittedAt) map[sub.productionTaskId] = sub;
  }
  return map;
}
