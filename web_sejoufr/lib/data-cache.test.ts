// Cache mémoire partagé du parcours TCF EE/EO.
//
// Ce qui est verrouillé ici, c'est le contrat que le client a demandé : une
// donnée déjà chargée ne se recharge pas, une donnée périmée ne survit pas à son
// invalidation, et une panne ne se met pas en cache.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {createDataCache} from "./data-cache.ts";

/** Loader qui compte ses appels — l'outil de mesure de tout ce fichier. */
function counter<T>(value: T) {
  let calls = 0;
  return {
    get calls() {
      return calls;
    },
    load: async () => {
      calls += 1;
      return value;
    },
  };
}

describe("createDataCache", () => {
  it("ne charge qu'une fois, quel que soit le nombre de lectures", async () => {
    const cache = createDataCache();
    const src = counter(["a"]);

    assert.deepEqual(await cache.cached("k", src.load), ["a"]);
    assert.deepEqual(await cache.cached("k", src.load), ["a"]);
    assert.deepEqual(await cache.cached("k", src.load), ["a"]);
    assert.equal(src.calls, 1);
  });

  it("mutualise un chargement déjà en vol (deux écrans montés en même temps)", async () => {
    const cache = createDataCache();
    const src = counter(42);

    const [a, b] = await Promise.all([cache.cached("k", src.load), cache.cached("k", src.load)]);
    assert.equal(a, 42);
    assert.equal(b, 42);
    assert.equal(src.calls, 1);
  });

  it("peek rend la valeur SANS attendre — c'est ce qui supprime le squelette", async () => {
    const cache = createDataCache();
    assert.equal(cache.peek("k"), undefined);

    const pending = cache.cached("k", async () => "v");
    // En vol : rien à peindre, l'écran affiche son chargement.
    assert.equal(cache.peek("k"), undefined);

    await pending;
    assert.equal(cache.peek<string>("k"), "v");
  });

  it("n'immortalise pas une panne : l'entrée est effacée, l'appel suivant retente", async () => {
    const cache = createDataCache();
    let calls = 0;
    const flaky = async () => {
      calls += 1;
      if (calls === 1) throw new Error("réseau");
      return "ok";
    };

    await assert.rejects(() => cache.cached("k", flaky));
    assert.equal(cache.peek("k"), undefined);
    assert.equal(await cache.cached("k", flaky), "ok");
    assert.equal(calls, 2);
  });

  it("invalide par préfixe, et seulement par préfixe", async () => {
    const cache = createDataCache();
    await cache.cached("production:mine:TCF_EE", async () => 1);
    await cache.cached("production:bilan:a1", async () => 2);
    await cache.cached("production:tasks:TCF_EE", async () => 3);

    assert.equal(cache.invalidate("production:mine:"), 1);
    assert.equal(cache.peek("production:mine:TCF_EE"), undefined);
    // Le catalogue éditorial, lui, n'a aucune raison d'être rechargé.
    assert.equal(cache.peek("production:tasks:TCF_EE"), 3);
    assert.equal(cache.peek("production:bilan:a1"), 2);
  });

  it("une réponse en vol ne réécrit pas par-dessus une invalidation", async () => {
    const cache = createDataCache();
    let release: (v: string) => void = () => {};
    const slow = () =>
      new Promise<string>((resolve) => {
        release = resolve;
      });

    const pending = cache.cached("k", slow);
    // Le candidat soumet une production pendant le vol : la donnée devient
    // fausse avant même d'être arrivée.
    cache.invalidate("k");
    release("périmé");
    assert.equal(await pending, "périmé");
    assert.equal(cache.peek("k"), undefined, "la valeur périmée ne doit pas ressusciter");
  });

  it("clear vide tout — le changement d'utilisateur ne laisse rien derrière", async () => {
    const cache = createDataCache();
    await cache.cached("skills:section:EE", async () => 1);
    await cache.cached("production:mine:TCF_EO", async () => 2);
    assert.equal(cache.size(), 2);

    cache.clear();
    assert.equal(cache.size(), 0);
    assert.equal(cache.peek("skills:section:EE"), undefined);
  });

  it("désactivé (rendu serveur), il est transparent : rien n'est retenu", async () => {
    const cache = createDataCache({enabled: false});
    const src = counter("v");

    assert.equal(await cache.cached("k", src.load), "v");
    assert.equal(await cache.cached("k", src.load), "v");
    assert.equal(src.calls, 2);
    assert.equal(cache.peek("k"), undefined);
    assert.equal(cache.size(), 0);
  });
});
