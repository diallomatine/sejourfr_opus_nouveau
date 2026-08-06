// Catalogue « Compétences » d'une épreuve productive.
//
// Le contrat mesuré ici est celui que le client a formulé sur le mobile, et qui
// vaut pour le web : « quand on change de Tâche 1 / 2 / 3, il ne doit pas y
// avoir d'appel au back ». Le client factice **compte ses appels** : un
// aller-retour T1 → T2 → T1 doit en coûter zéro de plus que le premier.
//
// Exécution : `npm test`.

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {createDataCache} from "./data-cache.ts";
import {
  loadSectionSkills,
  loadTaskProgress,
  type SkillCatalogClient,
  skillsOfTask,
} from "./skill-catalog.ts";
import type {SkillDto, SkillSection, SkillTaskCode, SkillTaskProgressDto} from "./types.ts";

function skill(taskCode: SkillTaskCode, order: number): SkillDto {
  return {
    id: `${taskCode}-${order}`,
    section: taskCode.startsWith("EE") ? "EE" : "EO",
    taskCode,
    code: `${taskCode}-C${order}`,
    title: `Compétence ${order}`,
    description: "",
    generalCriterion: "",
    targetLevel: "B1",
    displayOrder: order,
    promptCount: 5,
    attemptedCount: 0,
    validatedCount: 0,
    toReinforceCount: 0,
  };
}

/** Les 24 compétences d'une épreuve, dans un ordre volontairement mélangé. */
function sectionFixture(section: SkillSection): SkillDto[] {
  const out: SkillDto[] = [];
  for (const order of [8, 1, 5, 2, 7, 3, 6, 4]) {
    for (const n of [3, 1, 2]) {
      out.push(skill(`${section}${n}` as SkillTaskCode, order));
    }
  }
  return out;
}

interface Fake extends SkillCatalogClient {
  readonly sectionCalls: number;
  readonly taskCalls: readonly string[];
  readonly progressCalls: number;
}

function fakeClient(opts: {sectionFails?: number | null} = {}): Fake {
  let sectionCalls = 0;
  const taskCalls: string[] = [];
  let progressCalls = 0;

  return {
    get sectionCalls() {
      return sectionCalls;
    },
    get taskCalls() {
      return taskCalls;
    },
    get progressCalls() {
      return progressCalls;
    },
    async listSkillsBySection(section) {
      sectionCalls += 1;
      if (opts.sectionFails != null) {
        throw Object.assign(new Error("filtre inconnu"), {status: opts.sectionFails});
      }
      return sectionFixture(section);
    },
    async listSkills(taskCode) {
      taskCalls.push(taskCode);
      return sectionFixture(taskCode.slice(0, 2) as SkillSection).filter(
        (s) => s.taskCode === taskCode,
      );
    },
    async progress(section): Promise<SkillTaskProgressDto[]> {
      progressCalls += 1;
      return [
        {
          taskCode: `${section}1` as SkillTaskCode,
          section,
          title: "Tâche 1",
          targetLevel: "A2",
          skillCount: 8,
          promptCount: 40,
          attemptedCount: 0,
          validatedCount: 0,
          toReinforceCount: 0,
        },
      ];
    },
  };
}

describe("loadSectionSkills", () => {
  it("charge les 24 compétences de l'épreuve en UN appel", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    const all = await loadSectionSkills(client, "EE", cache);
    assert.equal(all.length, 24);
    assert.equal(client.sectionCalls, 1);
    assert.equal(client.taskCalls.length, 0, "aucun appel par tâche ne doit subsister");
  });

  it("rend la liste triée taskCode puis displayOrder, quel que soit l'ordre reçu", async () => {
    const cache = createDataCache();
    const all = await loadSectionSkills(fakeClient(), "EO", cache);

    assert.deepEqual(
      all.slice(0, 9).map((s) => `${s.taskCode}:${s.displayOrder}`),
      ["EO1:1", "EO1:2", "EO1:3", "EO1:4", "EO1:5", "EO1:6", "EO1:7", "EO1:8", "EO2:1"],
    );
  });

  it("T1 → T2 → T1 : aucun appel réseau supplémentaire, les pastilles filtrent", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    const first = skillsOfTask(await loadSectionSkills(client, "EE", cache), "EE1");
    const second = skillsOfTask(await loadSectionSkills(client, "EE", cache), "EE2");
    const back = skillsOfTask(await loadSectionSkills(client, "EE", cache), "EE1");

    assert.equal(first.length, 8);
    assert.equal(second.length, 8);
    assert.deepEqual(
      back.map((s) => s.id),
      first.map((s) => s.id),
    );
    assert.equal(client.sectionCalls, 1, "un seul appel pour les trois visites");
    assert.equal(client.taskCalls.length, 0);
  });

  it("les deux épreuves ont leur propre entrée (l'écrit ne sert pas l'oral)", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    await loadSectionSkills(client, "EE", cache);
    const oral = await loadSectionSkills(client, "EO", cache);

    assert.equal(client.sectionCalls, 2);
    assert.ok(oral.every((s) => s.section === "EO"));
  });

  it("recompose l'épreuve par 3 appels si le filtre section n'est pas servi — une seule fois", async () => {
    const cache = createDataCache();
    const client = fakeClient({sectionFails: 400});

    const all = await loadSectionSkills(client, "EE", cache);
    await loadSectionSkills(client, "EE", cache);

    assert.equal(all.length, 24);
    assert.deepEqual(client.taskCalls, ["EE1", "EE2", "EE3"]);
    assert.equal(client.sectionCalls, 1, "le repli est mémorisé avec la donnée");
  });

  it("ne masque PAS une session expirée derrière le repli", async () => {
    const cache = createDataCache();
    const client = fakeClient({sectionFails: 401});

    await assert.rejects(() => loadSectionSkills(client, "EE", cache));
    assert.equal(client.taskCalls.length, 0);
  });
});

describe("skillsOfTask", () => {
  it("sans donnée chargée, rend une liste vide plutôt que de casser", () => {
    assert.deepEqual(skillsOfTask(undefined, "EE1"), []);
  });

  it("ne rend que la tâche demandée", async () => {
    const all = await loadSectionSkills(fakeClient(), "EE", createDataCache());
    assert.ok(skillsOfTask(all, "EE3").every((s) => s.taskCode === "EE3"));
  });
});

describe("loadTaskProgress", () => {
  it("un seul appel par épreuve, pas un par tâche", async () => {
    const cache = createDataCache();
    const client = fakeClient();

    await loadTaskProgress(client, "EE", cache);
    await loadTaskProgress(client, "EE", cache);
    await loadTaskProgress(client, "EE", cache);

    assert.equal(client.progressCalls, 1);
  });
});
