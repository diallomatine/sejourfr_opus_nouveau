// Catalogue et historique d'une épreuve productive (EE/EO).
//
// Deux contrats mesurés, opposés et également importants :
//   - le **catalogue** (sujets, exemples) ne se recharge pas quand on change de
//     tâche ou de mode — le client factice compte les appels ;
//   - la **progression** (soumissions, bilans) se recharge dès qu'elle a été
//     invalidée, sinon un sujet rendu resterait affiché « à faire ».
//
// Exécution : `npm test`.

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {createDataCache} from "./data-cache.ts";
import {
  examDrafts,
  isFinalBilan,
  latestSubmissionByTask,
  loadBilan,
  loadEpreuveTasks,
  loadExamples,
  loadMySubmissions,
  type ProductionCatalogClient,
  productionMineKey,
  tasksOfTache,
} from "./production-catalog.ts";
import type {
  ProductionBilanResponse,
  ProductionExampleDto,
  ProductionSubmissionDto,
  ProductionTaskDto,
} from "./types.ts";

function task(id: string, tacheNumero: number, niveauCible: string): ProductionTaskDto {
  return {
    id,
    epreuve: "TCF_EE",
    tacheNumero,
    niveauCible,
    consigne: `Sujet ${id}`,
    contexte: null,
    dureeMaxSec: null,
    dureeMinSec: null,
    motsMin: 60,
    motsMax: 90,
  };
}

function submission(
  id: string,
  attemptId: string,
  productionTaskId: string,
  submittedAt: string,
  note: number | null = null,
): ProductionSubmissionDto {
  return {
    id,
    attemptId,
    productionTaskId,
    tacheNumero: 1,
    statut: note == null ? "SUBMITTED" : "EVALUATED",
    mediaUrl: null,
    texteSoumis: "…",
    motsCount: 70,
    mediaDurationSec: null,
    retryCount: 0,
    erreurMessage: null,
    submittedAt,
    evaluation:
      note == null
        ? null
        : ({noteSurVingt: note} as unknown as ProductionSubmissionDto["evaluation"]),
    transcription: null,
  };
}

function bilan(attemptId: string, over: Partial<ProductionBilanResponse> = {}): ProductionBilanResponse {
  return {
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
    ...over,
  };
}

interface Fake extends ProductionCatalogClient {
  readonly taskCalls: readonly (number | undefined)[];
  readonly mineCalls: number;
  readonly exampleCalls: readonly number[];
  readonly bilanCalls: readonly string[];
}

function fakeClient(bilans: Record<string, ProductionBilanResponse> = {}): Fake {
  const taskCalls: (number | undefined)[] = [];
  const exampleCalls: number[] = [];
  const bilanCalls: string[] = [];
  let mineCalls = 0;

  return {
    get taskCalls() {
      return taskCalls;
    },
    get mineCalls() {
      return mineCalls;
    },
    get exampleCalls() {
      return exampleCalls;
    },
    get bilanCalls() {
      return bilanCalls;
    },
    async listTasks(opts) {
      taskCalls.push(opts.tacheNumero);
      return [
        task("t1-b2", 1, "B2"),
        task("t2-a2", 2, "A2"),
        task("t1-a2", 1, "A2"),
        task("t3-b1", 3, "B1"),
        task("t1-b1", 1, "B1"),
      ];
    },
    async listExamples(_epreuve, tacheNumero): Promise<ProductionExampleDto[]> {
      exampleCalls.push(tacheNumero);
      return [];
    },
    async listMine() {
      mineCalls += 1;
      return [
        submission("s1", "att-1", "t1-a2", "2026-08-01T10:00:00Z", 12),
        submission("s2", "att-1", "t2-a2", "2026-08-01T10:20:00Z", 13),
        submission("s3", "att-2", "t1-b1", "2026-08-03T09:00:00Z"),
      ];
    },
    async getBilan(attemptId) {
      bilanCalls.push(attemptId);
      return bilans[attemptId] ?? bilan(attemptId);
    },
  };
}

describe("loadEpreuveTasks / tasksOfTache", () => {
  it("charge les 3 tâches en UN appel, sans paramètre de tâche", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    await loadEpreuveTasks(client, "TCF_EE", cache);
    assert.deepEqual(client.taskCalls, [undefined]);
  });

  it("T1 → T2 → T1 : aucun appel supplémentaire, le filtre est local", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    const t1 = tasksOfTache(await loadEpreuveTasks(client, "TCF_EE", cache), 1);
    const t2 = tasksOfTache(await loadEpreuveTasks(client, "TCF_EE", cache), 2);
    const back = tasksOfTache(await loadEpreuveTasks(client, "TCF_EE", cache), 1);

    assert.equal(client.taskCalls.length, 1);
    assert.equal(t2.length, 1);
    assert.deepEqual(
      back.map((t) => t.id),
      t1.map((t) => t.id),
    );
  });

  it("ordonne les sujets par niveau cible — c'est cet ordre qui numérote les cartes", async () => {
    const all = await loadEpreuveTasks(fakeClient(), "TCF_EE", createDataCache());
    assert.deepEqual(
      tasksOfTache(all, 1).map((t) => t.niveauCible),
      ["A2", "B1", "B2"],
    );
  });

  it("sans donnée chargée, rend une liste vide", () => {
    assert.deepEqual(tasksOfTache(undefined, 1), []);
  });
});

describe("loadExamples", () => {
  it("une entrée par tâche : revenir sur les exemples d'une tâche ne rappelle pas", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    await loadExamples(client, "TCF_EE", 1, cache);
    await loadExamples(client, "TCF_EE", 2, cache);
    await loadExamples(client, "TCF_EE", 1, cache);

    assert.deepEqual(client.exampleCalls, [1, 2]);
  });
});

describe("loadMySubmissions", () => {
  it("un seul appel sert l'écran des sujets ET la grille des examens", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    await loadMySubmissions(client, "TCF_EE", cache);
    await loadMySubmissions(client, "TCF_EE", cache);

    assert.equal(client.mineCalls, 1);
  });

  it("recharge après invalidation — une production rendue doit se voir", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    await loadMySubmissions(client, "TCF_EE", cache);
    cache.invalidate(productionMineKey("TCF_EE"));
    await loadMySubmissions(client, "TCF_EE", cache);

    assert.equal(client.mineCalls, 2);
  });
});

describe("loadBilan", () => {
  it("met en cache un bilan final : la grille des examens ne le redemande pas", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    await loadBilan(client, "att-1", cache);
    await loadBilan(client, "att-1", cache);

    assert.deepEqual(client.bilanCalls, ["att-1"]);
  });

  it("ne fige JAMAIS un bilan dont l'IA évalue encore une tâche", async () => {
    const cache = createDataCache();
    const client = fakeClient({
      "att-2": bilan("att-2", {finished: true, evaluatedCount: 2, niveauGlobal: null}),
    });

    await loadBilan(client, "att-2", cache);
    await loadBilan(client, "att-2", cache);

    assert.deepEqual(client.bilanCalls, ["att-2", "att-2"]);
  });

  it("une session non terminée reste rechargée", () => {
    assert.equal(isFinalBilan(bilan("a", {finished: false})), false);
    assert.equal(isFinalBilan(bilan("a")), true);
  });
});

describe("examDrafts", () => {
  it("ne retient que les attempts à ≥ 2 tâches (les entraînements n'en ont qu'une)", async () => {
    const subs = await fakeClient().listMine({});
    const drafts = examDrafts(subs);

    assert.equal(drafts.length, 1);
    assert.equal(drafts[0].attemptId, "att-1");
  });

  it("moyenne à une décimale, ancrée sur la première tâche rendue", () => {
    const drafts = examDrafts([
      submission("a", "att", "t1", "2026-08-02T10:00:00Z", 12),
      submission("b", "att", "t2", "2026-08-01T10:00:00Z", 13),
    ]);
    assert.equal(drafts[0].avgNote, 12.5);
    assert.equal(drafts[0].date, "2026-08-01T10:00:00Z");
  });

  it("une session sans note évaluée vaut null, jamais 0", () => {
    const drafts = examDrafts([
      submission("a", "att", "t1", "2026-08-01T10:00:00Z"),
      submission("b", "att", "t2", "2026-08-01T10:05:00Z"),
    ]);
    assert.equal(drafts[0].avgNote, null);
  });

  it("sans historique chargé, rend une liste vide", () => {
    assert.deepEqual(examDrafts(undefined), []);
  });
});

describe("latestSubmissionByTask", () => {
  it("garde la plus récente par sujet", () => {
    const map = latestSubmissionByTask([
      submission("old", "att", "t1", "2026-08-01T10:00:00Z", 8),
      submission("new", "att", "t1", "2026-08-04T10:00:00Z", 14),
    ]);
    assert.equal(map["t1"].id, "new");
  });

  it("sans historique chargé, rend un objet vide", () => {
    assert.deepEqual(latestSubmissionByTask(undefined), {});
  });
});
