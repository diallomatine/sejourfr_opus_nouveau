// Le défaut corrigé ici : un échec de `POST …/finish` était avalé et le drapeau
// « évalué » restait à `true`. Un envoi raté devenait indistinguable d'un
// succès — l'examen enchaînait la tâche suivante et la production du candidat
// disparaissait sans trace. Ces tests verrouillent l'inverse : l'issue dit ce
// qui s'est passé, et ne promet une relance que quand elle existe vraiment.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
    needsRealtimeAcknowledgement,
    realtimeFinishNotice,
    resolveRealtimeFinish,
    RT_FINISH_GIVE_UP_ACTION,
    RT_FINISH_LOST_MESSAGE,
    RT_FINISH_LOST_TITLE,
    RT_FINISH_PARTIAL_MESSAGE,
    RT_FINISH_PARTIAL_TITLE,
    RT_FINISH_RETRY_ACTION,
    RT_FINISH_RETRYABLE_MESSAGE,
    RT_FINISH_RETRYABLE_TITLE,
    RT_FINISH_SEE_RESULT_ACTION,
} from "./realtime-finish.ts";

const base = {
    finishOk: true,
    serverEvaluated: true,
    candidateTurnsSpoken: 4,
    candidateTurnsRelayed: 4,
    droppedTurns: 0,
};

describe("resolveRealtimeFinish", () => {
    it("clôture OK et notée → résultat à afficher", () => {
        const r = resolveRealtimeFinish(base);
        assert.equal(r.kind, "evaluated");
        assert.equal(needsRealtimeAcknowledgement(r), false);
    });

    it("clôture OK, candidat muet → « rien à évaluer », et c'est exact", () => {
        const r = resolveRealtimeFinish({
            ...base,
            serverEvaluated: false,
            candidateTurnsSpoken: 0,
            candidateTurnsRelayed: 0,
        });
        assert.equal(r.kind, "noSpeech");
        assert.equal(needsRealtimeAcknowledgement(r), false);
    });

    it("clôture OK mais le candidat AVAIT parlé → perdue, jamais « vous n'avez rien dit »", () => {
        const r = resolveRealtimeFinish({
            ...base,
            serverEvaluated: false,
            candidateTurnsSpoken: 3,
            candidateTurnsRelayed: 0,
            droppedTurns: 3,
        });
        assert.equal(r.kind, "lost");
        assert.equal(needsRealtimeAcknowledgement(r), true);
    });

    it("clôture en échec mais parole arrivée au serveur → relançable", () => {
        const r = resolveRealtimeFinish({...base, finishOk: false, serverEvaluated: false});
        assert.equal(r.kind, "retryable");
        assert.equal(needsRealtimeAcknowledgement(r), true);
    });

    it("clôture en échec et rien n'est arrivé → perdue, pas de faux espoir", () => {
        const r = resolveRealtimeFinish({
            ...base,
            finishOk: false,
            serverEvaluated: false,
            candidateTurnsSpoken: 2,
            candidateTurnsRelayed: 0,
            droppedTurns: 2,
        });
        assert.equal(r.kind, "lost");
    });

    it("clôture en échec sans aucune prise de parole → rien à récupérer", () => {
        const r = resolveRealtimeFinish({
            ...base,
            finishOk: false,
            serverEvaluated: false,
            candidateTurnsSpoken: 0,
            candidateTurnsRelayed: 0,
        });
        assert.equal(r.kind, "noSpeech");
        assert.equal(needsRealtimeAcknowledgement(r), false);
    });

    it("notée mais transmission partielle → le candidat doit le savoir", () => {
        const r = resolveRealtimeFinish({
            ...base,
            candidateTurnsSpoken: 6,
            candidateTurnsRelayed: 4,
            droppedTurns: 2,
        });
        assert.equal(r.kind, "evaluated");
        assert.equal(r.droppedTurns, 2);
        assert.equal(needsRealtimeAcknowledgement(r), true);
        assert.equal(realtimeFinishNotice(r).title, RT_FINISH_PARTIAL_TITLE);
    });

    it("un compteur négatif ne fabrique pas une perte", () => {
        const r = resolveRealtimeFinish({...base, droppedTurns: -3});
        assert.equal(r.droppedTurns, 0);
        assert.equal(needsRealtimeAcknowledgement(r), false);
    });
});

describe("realtimeFinishNotice", () => {
    it("annonce la relance quand elle existe, la perte quand elle est réelle", () => {
        assert.deepEqual(realtimeFinishNotice({kind: "retryable", droppedTurns: 0}), {
            title: RT_FINISH_RETRYABLE_TITLE,
            message: RT_FINISH_RETRYABLE_MESSAGE,
        });
        assert.deepEqual(realtimeFinishNotice({kind: "lost", droppedTurns: 1}), {
            title: RT_FINISH_LOST_TITLE,
            message: RT_FINISH_LOST_MESSAGE,
        });
    });
});

// Ces chaînes ne transitent pas par le réseau : le web et le mobile en tiennent
// chacun une copie écrite à la main. Un libellé qui bouge, ce sont DEUX fichiers
// à changer dans la même passe (miroir :
// mobile_sejourfr/lib/screens/tcf_production/realtime/realtime_finish.dart,
// verrouillé par test/realtime_finish_test.dart).
describe("libellés — contrat gelé, miroir mobile", () => {
    it("les chaînes ne bougent pas sans changer les deux fronts", () => {
        assert.equal(RT_FINISH_RETRYABLE_TITLE, "Envoi impossible");
        assert.equal(
            RT_FINISH_RETRYABLE_MESSAGE,
            "Votre échange n'a pas pu être envoyé à l'évaluation. Il est conservé sur nos serveurs : réessayez, vous n'avez pas à refaire l'oral.",
        );
        assert.equal(RT_FINISH_LOST_TITLE, "Réponse non transmise");
        assert.equal(
            RT_FINISH_LOST_MESSAGE,
            "Votre échange n'est pas arrivé jusqu'à nous : il n'y a rien à évaluer, et il ne peut pas être récupéré. Refaites l'oral quand vous êtes prêt·e.",
        );
        assert.equal(RT_FINISH_PARTIAL_TITLE, "Transmission partielle");
        assert.equal(
            RT_FINISH_PARTIAL_MESSAGE,
            "Une partie de votre échange n'a pas pu être transmise. Votre évaluation portera uniquement sur ce qui nous est parvenu.",
        );
        assert.equal(RT_FINISH_RETRY_ACTION, "Réessayer l'envoi");
        assert.equal(RT_FINISH_GIVE_UP_ACTION, "Continuer sans cette réponse");
        assert.equal(RT_FINISH_SEE_RESULT_ACTION, "Voir mon évaluation");
    });
});
