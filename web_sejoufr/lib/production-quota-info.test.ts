// Info one-time « 1 essai d'entraînement gratuit par épreuve » (EE/EO).
//
// Ce qui se joue ici n'est pas cosmétique : l'annonce a disparu du parcours
// quand le hub d'épreuve a été supprimé, et un candidat découvrait la limite
// en la consommant — ou en se prenant un 403. Ces règles verrouillent le
// « quand », et surtout le « pour qui » : un abonné ne doit jamais lire qu'il
// dispose d'un quota gratuit.
//
// La clé est verrouillée telle quelle parce que le mobile écrit la MÊME
// (`sejourfr.prodQuotaInfo.TCF_{EE,EO}`, cf. `EpreuveType.wire`) : les deux
// fronts annoncent la même chose au même moment.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {prodQuotaInfoKey, shouldAnnounceFreeTrial} from "./production-quota-info.ts";

const gratuit = {status: "authenticated", hasUser: true, isPremium: false, alreadySeen: false};

describe("prodQuotaInfoKey", () => {
    it("mémorise PAR ÉPREUVE — l'essai gratuit se compte par épreuve", () => {
        assert.equal(prodQuotaInfoKey("TCF_EE"), "sejourfr.prodQuotaInfo.TCF_EE");
        assert.equal(prodQuotaInfoKey("TCF_EO"), "sejourfr.prodQuotaInfo.TCF_EO");
        assert.notEqual(prodQuotaInfoKey("TCF_EE"), prodQuotaInfoKey("TCF_EO"));
    });
});

describe("shouldAnnounceFreeTrial", () => {
    it("annonce à un compte gratuit qui ne l'a pas encore vue", () => {
        assert.equal(shouldAnnounceFreeTrial(gratuit), true);
    });

    it("ne l'affiche qu'une fois", () => {
        assert.equal(shouldAnnounceFreeTrial({...gratuit, alreadySeen: true}), false);
    });

    it("jamais à un abonné TCF : lui annoncer un quota gratuit n'a aucun sens", () => {
        assert.equal(shouldAnnounceFreeTrial({...gratuit, isPremium: true}), false);
    });

    it("rien tant que l'auth n'est pas résolue — sinon l'abonné la voit passer", () => {
        assert.equal(
            shouldAnnounceFreeTrial({...gratuit, status: "loading", hasUser: false}),
            false,
        );
        assert.equal(shouldAnnounceFreeTrial({...gratuit, hasUser: false}), false);
    });
});
