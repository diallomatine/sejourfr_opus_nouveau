// Le contrat de navigation du parcours TCF EE/EO, mesuré bout en bout.
//
// C'est le constat du client, transcrit en test : « quand on change de
// Compétences / Sujets / Examens, ou de Tâche 1 / 2 / 3, j'ai l'impression
// qu'il y a un appel au back ». Le client factice compte **chaque** appel ; on
// rejoue les deux parcours qui posaient problème et on vérifie le total.
//
// Ce fichier ne teste pas des composants (le projet n'a pas de moteur de rendu
// en test) : il teste la **couche de données** que les écrans consomment, une
// fonction par écran. C'est là que vivaient les appels redondants.
//
// Exécution : `npm test`.

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {createDataCache, type DataCache} from "./data-cache.ts";
import {
  examDrafts,
  latestSubmissionByTask,
  loadBilan,
  loadEpreuveTasks,
  loadMySubmissions,
  productionMineKey,
  type ProductionCatalogClient,
  tasksOfTache,
} from "./production-catalog.ts";
import {
  loadSectionSkills,
  loadTaskProgress,
  type SkillCatalogClient,
  skillsOfTask,
} from "./skill-catalog.ts";
import type {
  ProductionBilanResponse,
  ProductionSubmissionDto,
  ProductionTaskDto,
  SkillDto,
  SkillTaskCode,
} from "./types.ts";

/** Compteur d'appels au backend, toutes routes confondues. */
class BackendSpy {
  readonly calls: string[] = [];

  private hit<T>(label: string, value: T): Promise<T> {
    this.calls.push(label);
    return Promise.resolve(value);
  }

  get count(): number {
    return this.calls.length;
  }

  readonly skills: SkillCatalogClient = {
    listSkillsBySection: (section) =>
      this.hit(
        `GET /api/skills?section=${section}`,
        [1, 2, 3].flatMap((n) =>
          [1, 2].map(
            (order): SkillDto => ({
              id: `${section}${n}-${order}`,
              section,
              taskCode: `${section}${n}` as SkillTaskCode,
              code: `${section}${n}-C${order}`,
              title: `Compétence ${order}`,
              description: "",
              generalCriterion: "",
              targetLevel: "B1",
              displayOrder: order,
              promptCount: 5,
              attemptedCount: 0,
              validatedCount: 0,
              toReinforceCount: 0,
            }),
          ),
        ),
      ),
    listSkills: (taskCode) => this.hit(`GET /api/skills?taskCode=${taskCode}`, []),
    progress: (section) => this.hit(`GET /api/skills/progress?section=${section}`, []),
  };

  readonly production: ProductionCatalogClient = {
    listTasks: (opts) =>
      this.hit(
        `GET /api/production-tasks?epreuve=${opts.epreuve}`,
        [1, 2, 3].map(
          (n): ProductionTaskDto => ({
            id: `task-${n}`,
            epreuve: opts.epreuve,
            tacheNumero: n,
            niveauCible: "B1",
            consigne: `Sujet ${n}`,
            contexte: null,
            dureeMaxSec: null,
            dureeMinSec: null,
            motsMin: 40,
            motsMax: 90,
          }),
        ),
      ),
    listExamples: (epreuve, n) =>
      this.hit(`GET /api/production-examples?epreuve=${epreuve}&tacheNumero=${n}`, []),
    listMine: (opts) =>
      this.hit<ProductionSubmissionDto[]>(
        `GET /api/users/me/production-submissions?epreuve=${opts.epreuve}`,
        [
          {
            id: "sub-1",
            attemptId: "att-1",
            productionTaskId: "task-1",
            tacheNumero: 1,
            statut: "EVALUATED",
            mediaUrl: null,
            texteSoumis: "…",
            motsCount: 70,
            mediaDurationSec: null,
            retryCount: 0,
            erreurMessage: null,
            submittedAt: "2026-08-01T10:00:00Z",
            evaluation: null,
            transcription: null,
          },
          {
            id: "sub-2",
            attemptId: "att-1",
            productionTaskId: "task-2",
            tacheNumero: 2,
            statut: "EVALUATED",
            mediaUrl: null,
            texteSoumis: "…",
            motsCount: 70,
            mediaDurationSec: null,
            retryCount: 0,
            erreurMessage: null,
            submittedAt: "2026-08-01T10:20:00Z",
            evaluation: null,
            transcription: null,
          },
        ],
      ),
    getBilan: (attemptId) =>
      this.hit<ProductionBilanResponse>(`GET /api/attempts/${attemptId}/production-bilan`, {
        attemptId,
        epreuve: "TCF_EE",
        exam: true,
        evaluatedCount: 3,
        expectedCount: 3,
        moyenneSur20: 12.5,
        niveauGlobal: "B2",
        slotNumber: 1,
        finished: true,
        correspondanceTcf: null,
      }),
  };
}

/** Ce que fait l'écran « Compétences » à l'ouverture, pour une tâche donnée. */
async function openCompetences(spy: BackendSpy, cache: DataCache, task: number) {
  const [all] = await Promise.all([
    loadSectionSkills(spy.skills, "EE", cache),
    loadTaskProgress(spy.skills, "EE", cache),
  ]);
  return skillsOfTask(all, `EE${task}` as SkillTaskCode);
}

/** Ce que fait l'écran « Sujets » à l'ouverture, pour une tâche donnée. */
async function openSujets(spy: BackendSpy, cache: DataCache, task: number) {
  const [all, mine] = await Promise.all([
    loadEpreuveTasks(spy.production, "TCF_EE", cache),
    loadMySubmissions(spy.production, "TCF_EE", cache),
  ]);
  return {tasks: tasksOfTache(all, task), done: latestSubmissionByTask(mine)};
}

/** Ce que fait l'écran « Examens blancs » à l'ouverture. */
async function openExamens(spy: BackendSpy, cache: DataCache) {
  const mine = await loadMySubmissions(spy.production, "TCF_EE", cache);
  const drafts = examDrafts(mine);
  return Promise.all(drafts.map((d) => loadBilan(spy.production, d.attemptId, cache)));
}

describe("parcours TCF EE/EO — aucun appel réseau redondant", () => {
  it("T1 → T2 → T1 sur les compétences : 2 appels à l'arrivée, 0 ensuite", async () => {
    const spy = new BackendSpy();
    const cache = createDataCache();

    const t1 = await openCompetences(spy, cache, 1);
    const atArrival = spy.count;

    await openCompetences(spy, cache, 2);
    const back = await openCompetences(spy, cache, 1);

    assert.equal(atArrival, 2, "compétences de l'épreuve + agrégat par tâche");
    assert.equal(spy.count, 2, "changer de tâche puis revenir ne coûte AUCUN appel");
    assert.equal(t1.length, 2);
    assert.deepEqual(
      back.map((s) => s.id),
      t1.map((s) => s.id),
    );
  });

  it("T1 → T2 → T1 sur les sujets : 2 appels à l'arrivée, 0 ensuite", async () => {
    const spy = new BackendSpy();
    const cache = createDataCache();

    await openSujets(spy, cache, 1);
    const atArrival = spy.count;
    await openSujets(spy, cache, 2);
    const back = await openSujets(spy, cache, 1);

    assert.equal(atArrival, 2, "catalogue de l'épreuve + historique du candidat");
    assert.equal(spy.count, 2);
    assert.deepEqual(back.tasks.map((t) => t.id), ["task-1"]);
  });

  it("tour complet des trois modes, puis retour : rien n'est rechargé", async () => {
    const spy = new BackendSpy();
    const cache = createDataCache();

    await openCompetences(spy, cache, 1); // 2 appels
    await openSujets(spy, cache, 1); // + catalogue + historique
    await openExamens(spy, cache); // + le bilan de la session passée
    const firstPass = spy.count;

    await openCompetences(spy, cache, 1);
    await openSujets(spy, cache, 1);
    await openExamens(spy, cache);

    assert.equal(firstPass, 5, [...new Set(spy.calls)].join(" · "));
    assert.equal(spy.count, 5, "le second tour ne parle pas au backend");
  });

  it("l'historique des sujets et celui des examens ne font qu'UN appel", async () => {
    const spy = new BackendSpy();
    const cache = createDataCache();

    await openSujets(spy, cache, 1);
    await openExamens(spy, cache);

    const historyCalls = spy.calls.filter((c) => c.includes("production-submissions"));
    assert.equal(historyCalls.length, 1);
  });

  it("après une soumission, la progression EST rechargée (le catalogue, non)", async () => {
    const spy = new BackendSpy();
    const cache = createDataCache();

    await openSujets(spy, cache, 1);
    const before = spy.count;

    // Ce que fait `lib/api.ts` juste après une soumission de production.
    cache.invalidate(productionMineKey("TCF_EE"));
    await openSujets(spy, cache, 1);

    const added = spy.calls.slice(before);
    assert.deepEqual(added, ["GET /api/users/me/production-submissions?epreuve=TCF_EE"]);
  });
});
