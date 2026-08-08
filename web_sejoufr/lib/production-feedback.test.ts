// Verrouille les règles de LECTURE d'une évaluation EE/EO : ce sont elles qui
// décident si l'écran est honnête (quel niveau on ose afficher, où se lit une
// note sur l'échelle du TCF) et si les ~100 évaluations déjà en base
// continuent de s'afficher sans planter.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
    TCF_NOTE_BANDS,
    bilanNiveauPendingLabel,
    canShowNiveau,
    critereBandeFromNote,
    groupAccomplishment,
    hasAccomplishmentDetail,
    objectifPresentation,
    shouldShowConfiance,
    splitHighlight,
    tcfBandRange,
    tcfNiveauTone,
    tcfNoteTone,
    tcfScalePosition,
    treatedPointsSummary,
} from "./production-feedback.ts";
import {bandeCritereLabel, parseEeFeedback, type EvaluationResultDto} from "./types.ts";

function evaluation(feedback: Record<string, unknown> | null): EvaluationResultDto {
    return {
        noteSurVingt: 4.5,
        niveauObserve: "A2",
        confiance: "HAUTE",
        avertissementNiveau: null,
        feedback,
    };
}

// ---------------------------------------------------------------------------

describe("échelle du TCF", () => {
    it("couvre 0 à 20 sans trou ni recouvrement, dans l'ordre officiel", () => {
        assert.deepEqual(
            TCF_NOTE_BANDS.map((b) => [b.niveau, b.min, b.max]),
            [
                ["A1_NON_ATTEINT", 0, 0],
                ["A1", 1, 1],
                ["A2", 2, 5],
                ["B1", 6, 9],
                ["B2", 10, 20],
            ],
        );
    });

    it("écrit les plages comme on les lit sous la barre", () => {
        assert.equal(tcfBandRange(TCF_NOTE_BANDS[0]), "0");
        assert.equal(tcfBandRange(TCF_NOTE_BANDS[2]), "2-5");
        assert.equal(tcfBandRange(TCF_NOTE_BANDS[4]), "10-20");
    });

    it("place une note de chaque palier dans SA bande", () => {
        const cases: [number, number][] = [
            [0, 0], // A1 non atteint
            [1, 1], // A1
            [2, 2], // bas de A2
            [4.5, 2], // le cas qui motive tout l'écran : 4,5/20 = A2
            [5, 2], // haut de A2
            [6, 3], // bas de B1
            [9, 3], // haut de B1
            [10, 4], // bas de B2
            [20, 4], // haut de B2
        ];
        for (const [note, expected] of cases) {
            const pos = tcfScalePosition(note);
            assert.ok(pos, `note ${note}`);
            assert.equal(pos.bandIndex, expected, `note ${note}`);
        }
    });

    it("garde le curseur à l'intérieur de la case de sa bande", () => {
        const width = 100 / TCF_NOTE_BANDS.length;
        for (const note of [0, 1, 2, 4.5, 5, 6, 9, 10, 15, 20]) {
            const pos = tcfScalePosition(note);
            assert.ok(pos);
            const low = pos.bandIndex * width;
            assert.ok(
                pos.percent > low && pos.percent < low + width,
                `note ${note} → ${pos.percent}% hors de [${low}, ${low + width}]`,
            );
        }
    });

    it("progresse avec la note", () => {
        const a = tcfScalePosition(2)!.percent;
        const b = tcfScalePosition(4.5)!.percent;
        const c = tcfScalePosition(12)!.percent;
        assert.ok(a < b && b < c);
    });

    it("rattache une note à décimale entre deux bandes à la bande basse, comme le serveur", () => {
        // 5,5 < 6 : le backend en fait un A2, l'échelle doit dire la même chose.
        assert.equal(tcfScalePosition(5.5)!.bandIndex, 2);
        assert.equal(tcfScalePosition(0.5)!.bandIndex, 0);
        assert.equal(tcfScalePosition(9.9)!.bandIndex, 3);
    });

    it("borne les notes aberrantes plutôt que de sortir de la barre", () => {
        assert.equal(tcfScalePosition(-3)!.bandIndex, 0);
        assert.equal(tcfScalePosition(42)!.bandIndex, 4);
    });

    it("n'a pas de curseur sans note", () => {
        assert.equal(tcfScalePosition(null), null);
        assert.equal(tcfScalePosition(undefined), null);
        assert.equal(tcfScalePosition(Number.NaN), null);
    });

    it("teinte les bandes de l'ambre au vert — aucun palier n'est rouge", () => {
        assert.deepEqual(
            TCF_NOTE_BANDS.map((b) => tcfNiveauTone(b.niveau)),
            ["amber", "amber", "amber", "blue", "green"],
        );
    });

    it("teinte par NIVEAU, pas par position : ajouter un palier ne décale rien", () => {
        // La garantie qu'on cherche : la teinte d'un palier ne dépend que de son
        // niveau, donc réordonner ou insérer une bande ne repeint pas les autres.
        const byNiveau = new Map(TCF_NOTE_BANDS.map((b) => [b.niveau, tcfNiveauTone(b.niveau)]));
        assert.equal(byNiveau.get("A1_NON_ATTEINT"), "amber");
        assert.equal(byNiveau.get("A1"), "amber");
        assert.equal(byNiveau.get("A2"), "amber");
        assert.equal(byNiveau.get("B1"), "blue");
        assert.equal(byNiveau.get("B2"), "green");
        // Les niveaux hors profil TCF IRN (plafonné B2) restent teintés.
        assert.equal(tcfNiveauTone("C1"), "green");
        assert.equal(tcfNiveauTone("C2"), "green");
    });
});

// ---------------------------------------------------------------------------

describe("teinte d'une note acquise (badges, pastilles)", () => {
    it("ne traite JAMAIS 12/20 comme un échec : c'est un B2, le haut du TCF", () => {
        // Le bug d'origine : `note <= 12` → badge rouge, sur la meilleure note
        // que l'examen sache produire.
        assert.equal(tcfNoteTone(12), "green");
        assert.equal(tcfNoteTone(10), "green"); // pile le seuil B2
        assert.equal(tcfNoteTone(20), "green");
    });

    it("sépare le haut du B1 du bas du B2 — 9 et 10 ne sont pas le même palier", () => {
        assert.equal(tcfNoteTone(9), "blue");
        assert.equal(tcfNoteTone(10), "green");
        assert.notEqual(tcfNoteTone(9), tcfNoteTone(10));
    });

    it("suit les paliers du TCF, et eux seuls", () => {
        const cases: [number, string][] = [
            [0, "amber"], // A1 non atteint
            [1, "amber"], // A1
            [2, "amber"], // bas de A2
            [4.5, "amber"], // le 4,5/20 qui vaut A2
            [5, "amber"], // haut de A2
            [5.5, "amber"], // entre deux bandes → bande basse, comme le serveur
            [6, "blue"], // bas de B1
            [9.9, "blue"], // toujours B1
            [10, "green"],
        ];
        for (const [note, expected] of cases) {
            assert.equal(tcfNoteTone(note), expected, `note ${note}`);
        }
    });

    it("n'utilise JAMAIS de rouge, sur tout le balayage 0 → 20 par pas de 0,5", () => {
        // Vaut pour les trois endroits où la teinte se rend : le grand chiffre
        // du hero, les segments de l'échelle et les badges de la liste de
        // sujets — ils partent tous de ces deux fonctions.
        for (let note = 0; note <= 20; note += 0.5) {
            assert.notEqual(tcfNoteTone(note), "red", `note ${note}`);
            const pos = tcfScalePosition(note);
            assert.ok(pos, `note ${note}`);
            assert.notEqual(
                tcfNiveauTone(TCF_NOTE_BANDS[pos.bandIndex].niveau),
                "red",
                `bande de la note ${note}`,
            );
        }
        // Typé en dur : le rouge n'appartient même plus à l'union des teintes.
        const tones: string[] = TCF_NOTE_BANDS.map((b) => tcfNiveauTone(b.niveau));
        assert.equal(tones.includes("red"), false);
    });

    it("rend une production pas encore évaluée en NEUTRE, jamais en rouge", () => {
        // Le hero doit colorer son « — » même sans note : neutre = gris, comme
        // le mobile. Une production non notée n'est pas un échec.
        for (const absente of [null, undefined, Number.NaN]) {
            assert.equal(tcfNoteTone(absente), "neutral");
            assert.notEqual(tcfNoteTone(absente), "red");
        }
    });

    it("borne les notes aberrantes au lieu de perdre la teinte", () => {
        assert.equal(tcfNoteTone(-3), "amber");
        assert.equal(tcfNoteTone(42), "green");
    });
});

// ---------------------------------------------------------------------------

describe("bande d'un critère legacy (évaluations sans `bande`)", () => {
    it("dérive la bande de la table des paliers TCF, sans seuil scolaire", () => {
        const cases: [number, string][] = [
            [20, "TRES_BONNE_MAITRISE"],
            [15, "TRES_BONNE_MAITRISE"], // le seuil maison disait « vert » : même verdict, autre raison
            [14, "TRES_BONNE_MAITRISE"], // le seuil mobile (15) en faisait un ambre : divergence supprimée
            [12, "TRES_BONNE_MAITRISE"], // 12 = B2, le haut du TCF — surtout pas un rouge
            [10, "TRES_BONNE_MAITRISE"], // pile le seuil B2
            [9.5, "SATISFAISANT"],
            [6, "SATISFAISANT"], // bas de B1
            [5, "EN_COURS_ACQUISITION"], // haut de A2
            [2, "EN_COURS_ACQUISITION"], // bas de A2
            [1, "FRAGILE"], // A1
            [0.5, "FRAGILE"], // sous le A1 mais quelque chose a été produit
            [0, "NON_EVALUABLE"], // hors-sujet : la seule bande qui ne décrit pas une performance
        ];
        for (const [note, expected] of cases) {
            assert.equal(critereBandeFromNote(note), expected, `note ${note}`);
        }
    });

    it("rend un critère legacy exactement comme son équivalent moderne", () => {
        // Un critère ancien à 12/20 et un critère moderne portant déjà
        // `TRES_BONNE_MAITRISE` doivent produire le même libellé, donc le même
        // rendu (la teinte est portée par `data-band` en CSS).
        for (const note of [12, 14, 15]) {
            const bande = critereBandeFromNote(note);
            assert.equal(bande, "TRES_BONNE_MAITRISE", `note ${note}`);
            assert.equal(bandeCritereLabel(bande), "Très bonne maîtrise");
        }
    });

    it("suit la même lecture que la note globale : même palier, même verdict", () => {
        // Aucun jeu de seuils propre aux critères : sur toute l'échelle, la
        // bande d'un critère suit la bande de l'échelle du TCF.
        const attendu: Record<string, string> = {
            B2: "TRES_BONNE_MAITRISE",
            B1: "SATISFAISANT",
            A2: "EN_COURS_ACQUISITION",
            A1: "FRAGILE",
            A1_NON_ATTEINT: "FRAGILE",
        };
        for (let note = 0.5; note <= 20; note += 0.5) {
            const pos = tcfScalePosition(note);
            assert.ok(pos, `note ${note}`);
            assert.equal(
                critereBandeFromNote(note),
                attendu[TCF_NOTE_BANDS[pos.bandIndex].niveau],
                `note ${note}`,
            );
        }
    });

    it("traite une note absente comme non évaluable, pas comme un échec", () => {
        assert.equal(critereBandeFromNote(null), "NON_EVALUABLE");
        assert.equal(critereBandeFromNote(undefined), "NON_EVALUABLE");
        assert.equal(critereBandeFromNote(Number.NaN), "NON_EVALUABLE");
        assert.equal(critereBandeFromNote(-3), "NON_EVALUABLE");
    });
});

// ---------------------------------------------------------------------------

describe("niveau et confiance", () => {
    it("n'affiche jamais un niveau sans sa confiance (garde-fou existant)", () => {
        assert.equal(canShowNiveau("A2", "HAUTE"), true);
        assert.equal(canShowNiveau("A2", "FAIBLE"), true);
        assert.equal(canShowNiveau("A2", null), false);
        assert.equal(canShowNiveau(null, "HAUTE"), false);
        assert.equal(canShowNiveau(null, null), false);
    });

    it("masque une confiance HAUTE et n'affiche que celles qui nuancent", () => {
        assert.equal(shouldShowConfiance("HAUTE"), false);
        assert.equal(shouldShowConfiance("MOYENNE"), true);
        assert.equal(shouldShowConfiance("FAIBLE"), true);
        assert.equal(shouldShowConfiance(null), false);
    });
});

// ---------------------------------------------------------------------------

describe("objectif de la tâche", () => {
    it("rend les trois verdicts capitalisés, avec trois traitements distincts", () => {
        // Le verdict se lit seul sous l'eyebrow « OBJECTIF DE LA TÂCHE » : il
        // commence donc par une majuscule, il n'est plus au fil d'une phrase.
        assert.deepEqual(objectifPresentation("ATTEINT"), {label: "Atteint", tone: "done"});
        assert.deepEqual(objectifPresentation("PARTIELLEMENT_ATTEINT"), {
            label: "Partiellement atteint",
            tone: "partial",
        });
        assert.deepEqual(objectifPresentation("NON_ATTEINT"), {
            label: "Non atteint",
            tone: "missed",
        });
        const tones = new Set(
            (["ATTEINT", "PARTIELLEMENT_ATTEINT", "NON_ATTEINT"] as const).map(
                (o) => objectifPresentation(o)!.tone,
            ),
        );
        assert.equal(tones.size, 3);
    });

    it("ne rend rien sur une évaluation legacy sans verdict", () => {
        assert.equal(objectifPresentation(null), null);
        assert.equal(objectifPresentation(undefined), null);
    });
});

// ---------------------------------------------------------------------------

describe("check-list de la consigne", () => {
    const acc = {
        objectif: null,
        objectifResume: null,
        pointsTraites: [
            {libelle: "Se présenter", obligatoire: true},
            {libelle: "Citer un loisir", obligatoire: false},
        ],
        pointsOublies: [
            {libelle: "Donner la date", obligatoire: true},
            {libelle: "Évoquer le prix", obligatoire: false},
        ],
    };

    it("sépare manques exigés et pistes ignorées (3 groupes, parité mobile)", () => {
        const g = groupAccomplishment(acc);
        assert.deepEqual(
            g.traites.map((p) => p.libelle),
            ["Se présenter", "Citer un loisir"],
        );
        assert.deepEqual(
            g.manquesObligatoires.map((p) => p.libelle),
            ["Donner la date"],
        );
        assert.deepEqual(
            g.pistesNonAbordees.map((p) => p.libelle),
            ["Évoquer le prix"],
        );
        assert.equal(hasAccomplishmentDetail(g), true);
    });

    it("ne casse pas sans accomplissement", () => {
        const g = groupAccomplishment(null);
        assert.deepEqual(g, {traites: [], manquesObligatoires: [], pistesNonAbordees: []});
        assert.equal(hasAccomplishmentDetail(g), false);
    });
});

// ---------------------------------------------------------------------------

describe("parseEeFeedback — contrat v8 / tool-schema v5", () => {
    it("lit le verdict d'objectif, son résumé et la version améliorée", () => {
        const fb = parseEeFeedback(
            evaluation({
                note_globale: 4.5,
                accomplissement: {
                    objectif: "PARTIELLEMENT_ATTEINT",
                    objectif_resume: "Vous décrivez la panne mais ne demandez rien.",
                    points_traites: [{libelle: "Décrire la panne", obligatoire: true}],
                    points_oublies: [{libelle: "Formuler la demande", obligatoire: true}],
                },
                version_amelioree: "Madame, Monsieur,\nMon chauffage est en panne…",
                points_forts: ["Le ton reste courtois."],
                exemples_corriges: [{original: "j'ai froid", corrige: "j'ai eu froid"}],
            }),
        );
        assert.equal(fb.accomplissement?.objectif, "PARTIELLEMENT_ATTEINT");
        assert.equal(
            fb.accomplissement?.objectifResume,
            "Vous décrivez la panne mais ne demandez rien.",
        );
        assert.match(fb.versionAmelioree ?? "", /^Madame, Monsieur,/);
        assert.equal(fb.noteGlobale, 4.5);
    });

    it("tolère une évaluation legacy dépourvue des nouveaux champs", () => {
        const fb = parseEeFeedback(
            evaluation({
                note_globale: 11,
                accomplissement: {
                    points_traites: [{libelle: "Raconter le voyage", obligatoire: true}],
                    points_oublies: [],
                },
                points_a_ameliorer: ["Trop de répétitions."],
                scores_criteres: [{code: "lexique", note_sur_20: 9}],
            }),
        );
        assert.equal(fb.accomplissement?.objectif, null);
        assert.equal(fb.accomplissement?.objectifResume, null);
        assert.equal(fb.versionAmelioree, null);
        // Le reste du contrat historique continue de se lire.
        assert.equal(fb.accomplissement?.pointsTraites.length, 1);
        assert.deepEqual(fb.pointsAAmeliorer, [
            {constat: "Trop de répétitions.", comment: null, exemple: null},
        ]);
        assert.equal(fb.criteres[0].noteSurVingt, 9);
    });

    it("ne plante pas sur un feedback absent ou vide", () => {
        for (const raw of [null, {}]) {
            const fb = parseEeFeedback(evaluation(raw));
            assert.equal(fb.accomplissement, null);
            assert.equal(fb.versionAmelioree, null);
            assert.deepEqual(fb.pointsForts, []);
            assert.equal(fb.noteGlobale, 4.5); // repli sur la note du DTO
        }
        assert.equal(parseEeFeedback(null).versionAmelioree, null);
    });

    it("ignore un verdict d'objectif inconnu au lieu de l'afficher tel quel", () => {
        const fb = parseEeFeedback(
            evaluation({accomplissement: {objectif: "PRESQUE", objectif_resume: "  "}}),
        );
        assert.equal(fb.accomplissement?.objectif, null);
        assert.equal(fb.accomplissement?.objectifResume, null);
        assert.equal(objectifPresentation(fb.accomplissement?.objectif ?? null), null);
    });

    it("laisse la version améliorée absente en EO (voulu, pas un bug)", () => {
        const ee = parseEeFeedback(evaluation({version_amelioree: "Texte réécrit."}));
        const eo = parseEeFeedback(evaluation({points_forts: ["Bon rythme d'échange."]}));
        assert.equal(ee.versionAmelioree, "Texte réécrit.");
        assert.equal(eo.versionAmelioree, null);
    });
});

describe("bilanNiveauPendingLabel — badge « Niveau global » sans niveau", () => {
    it("annonce une attente quand le pipeline IA tourne encore", () => {
        assert.equal(bilanNiveauPendingLabel(false), "Évaluation en cours…");
    });

    it("annonce une relance quand une correction a échoué", () => {
        // Le serveur suspend le niveau d'épreuve tant qu'une tâche rendue n'a
        // pas de note : « en cours » y était faux et sans fin.
        assert.equal(bilanNiveauPendingLabel(true), "Évaluation à relancer");
        assert.notEqual(bilanNiveauPendingLabel(true), bilanNiveauPendingLabel(false));
    });
});

describe("treatedPointsSummary — le chiffre du bandeau « Ce qui marche »", () => {
    const point = (libelle: string, obligatoire: boolean) => ({libelle, obligatoire});

    it("ne compte QUE les points obligatoires, des deux côtés de la fraction", () => {
        // Une piste traitée ne gonfle pas le numérateur, une piste ignorée ne
        // gonfle pas le dénominateur : sinon une consigne entièrement remplie
        // s'affiche « 3/5 » et le candidat croit avoir oublié quelque chose.
        const summary = treatedPointsSummary({
            objectif: null,
            objectifResume: null,
            pointsTraites: [
                point("Excuse", true),
                point("Raison", true),
                point("Ambiance du quartier", false),
            ],
            pointsOublies: [point("Nouvelle séance", true), point("Loyer", false)],
        });

        assert.deepEqual(summary, {
            done: 2,
            total: 3,
            libelles: ["Excuse", "Raison"],
        });
    });

    it("ne dit rien quand la consigne n'exigeait rien d'identifiable", () => {
        assert.equal(treatedPointsSummary(null), null);
        assert.equal(
            treatedPointsSummary({
                objectif: null,
                objectifResume: null,
                pointsTraites: [point("Ambiance", false)],
                pointsOublies: [],
            }),
            null,
        );
    });
});

describe("splitHighlight — repérer la phrase visée dans la production", () => {
    const texte = "Bonjour Khalil. On va regler ça ensemble. À bientôt.";

    it("découpe autour de la première occurrence exacte", () => {
        assert.deepEqual(splitHighlight(texte, "On va regler ça ensemble."), {
            before: "Bonjour Khalil. ",
            match: "On va regler ça ensemble.",
            after: " À bientôt.",
        });
    });

    it("ne surligne RIEN si la phrase a été recomposée par le correcteur", () => {
        // Un repère faux coûte plus cher que pas de repère : on ne cherche ni
        // approximation ni casse différente.
        assert.equal(splitHighlight(texte, "on va régler ça ensemble"), null);
        assert.equal(splitHighlight(texte, "   "), null);
        assert.equal(splitHighlight(texte, null), null);
    });
});
