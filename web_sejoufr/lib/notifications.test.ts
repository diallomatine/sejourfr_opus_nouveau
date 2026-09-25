// « Notifications par e-mail » : chargement, bascule optimiste, succès, échec
// et retour arrière. Test ajouté À LA DEMANDE EXPLICITE du propriétaire (revue
// du chantier e-mails, 2026-09-25) — exception à « aucun nouveau test front »
// limitée à cette page. Miroir mobile : `test/notifications_screen_test.dart`.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
    loadEmailPreferences,
    NOTIF_INITIAL_STATE,
    type NotifState,
    toggleEngagement,
} from "./notifications.ts";
import type {EmailPreferences, UpdateEmailPreferencesRequest} from "./types";

const actif: EmailPreferences = {engagementEnabled: true, marketingEnabled: false};
const inactif: EmailPreferences = {engagementEnabled: false, marketingEnabled: false};

function fakeUpdate(outcome: "ok" | "ko") {
    const calls: UpdateEmailPreferencesRequest[] = [];
    const update = async (patch: UpdateEmailPreferencesRequest): Promise<EmailPreferences> => {
        calls.push(patch);
        if (outcome === "ko") throw new Error("500");
        return {...actif, ...patch};
    };
    return {calls, update};
}

describe("loadEmailPreferences", () => {
    it("part de l'état de chargement", () => {
        assert.deepEqual(NOTIF_INITIAL_STATE, {load: {state: "loading"}, saving: false, feedback: null});
    });

    it("rend les préférences servies", async () => {
        const state = await loadEmailPreferences(async () => inactif);
        assert.deepEqual(state, {load: {state: "ready", prefs: inactif}, saving: false, feedback: null});
    });

    it("rend l'état d'erreur si le GET échoue", async () => {
        const state = await loadEmailPreferences(async () => {
            throw new Error("réseau");
        });
        assert.deepEqual(state.load, {state: "error"});
    });
});

describe("toggleEngagement", () => {
    for (const [from, next] of [[actif, false], [inactif, true]] as const) {
        it(`bascule tout de suite vers ${next}, puis confirme l'enregistrement`, async () => {
            const {calls, update} = fakeUpdate("ok");
            const optimistic: NotifState[] = [];
            const final = await toggleEngagement(from, next, update, (s) => optimistic.push(s));

            assert.equal(optimistic.length, 1);
            assert.deepEqual(optimistic[0], {
                load: {state: "ready", prefs: {...from, engagementEnabled: next}},
                saving: true,
                feedback: null,
            });
            assert.deepEqual(calls, [{engagementEnabled: next}]);
            assert.deepEqual(final, {
                load: {state: "ready", prefs: {...from, engagementEnabled: next}},
                saving: false,
                feedback: "saved",
            });
        });

        it(`rétablit ${from.engagementEnabled} et signale l'échec si le PATCH échoue`, async () => {
            const {calls, update} = fakeUpdate("ko");
            const optimistic: NotifState[] = [];
            const final = await toggleEngagement(from, next, update, (s) => optimistic.push(s));

            assert.equal(optimistic[0]?.load.state === "ready" && optimistic[0].load.prefs.engagementEnabled, next);
            assert.deepEqual(calls, [{engagementEnabled: next}]);
            assert.deepEqual(final, {load: {state: "ready", prefs: from}, saving: false, feedback: "failed"});
        });
    }

    it("garde les préférences RENDUES par le serveur, pas celles envoyées", async () => {
        const final = await toggleEngagement(inactif, true, async () => ({engagementEnabled: true, marketingEnabled: true}), () => {});
        assert.deepEqual(final.load, {state: "ready", prefs: {engagementEnabled: true, marketingEnabled: true}});
    });
});
