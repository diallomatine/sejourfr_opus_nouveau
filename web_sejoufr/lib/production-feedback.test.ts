// Verrouille les règles de LECTURE d'une évaluation EE/EO : ce sont elles qui
// décident si l'écran est honnête (quel niveau on ose afficher, où se lit une
// note sur l'échelle du TCF) et si les ~100 évaluations déjà en base
// continuent de s'afficher sans planter.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {readFileSync, readdirSync} from "node:fs";
import {describe, it} from "node:test";
import {
    NIVEAU_PORTEE_TACHE,
    NIVEAU_VISE_ATTEINT_EYEBROW,
    NIVEAU_VISE_ATTEINT_INTRO,
    SITUATION_LIBELLES,
    SITUATION_QUALIFICATIFS,
    TACHE_EVALUEE_LABEL,
    TACHE_TRAITEE_LABEL,
    TCF_NOTE_BANDS,
    VERSION_CIBLEE_EYEBROW,
    VERSION_CIBLEE_LEVIERS_TITLE,
    bilanNiveauPendingLabel,
    canShowNiveau,
    critereBandeFromNote,
    demarcheRappel,
    groupAccomplishment,
    hasAccomplishmentDetail,
    niveauAtteintLabel,
    niveauViseAtteintTitle,
    objectifPresentation,
    shouldShowConfiance,
    situationView,
    splitHighlight,
    tacheNiveau,
    tacheNiveauLabel,
    tacheNiveauTone,
    tcfBandIndex,
    tcfNiveauTone,
    tcfPalierIndex,
    treatedPointsSummary,
    versionCibleeIntro,
    versionCibleeTitle,
} from "./production-feedback.ts";
import {
    bandeCritereLabel,
    parseEeFeedback,
    type BandeCritere,
    type EvaluationResultDto,
    type NiveauCecrl,
    type SituationDansNiveau,
} from "./types.ts";

function evaluation(feedback: Record<string, unknown> | null): EvaluationResultDto {
    return {
        noteSurVingt: 4.5,
        niveauObserve: "A2",
        confiance: "HAUTE",
        avertissementNiveau: null,
        situationDansNiveau: null,
        situationDansNiveauLabel: null,
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
            assert.equal(tcfBandIndex(note), expected, `note ${note}`);
        }
    });

    it("rattache une note à décimale entre deux bandes à la bande basse, comme le serveur", () => {
        // 5,5 < 6 : le backend en fait un A2, l'échelle doit dire la même chose.
        assert.equal(tcfBandIndex(5.5), 2);
        assert.equal(tcfBandIndex(0.5), 0);
        assert.equal(tcfBandIndex(9.9), 3);
    });

    it("borne les notes aberrantes plutôt que de sortir de la barre", () => {
        assert.equal(tcfBandIndex(-3), 0);
        assert.equal(tcfBandIndex(42), 4);
    });

    it("n'a pas de palier sans note exploitable", () => {
        // `NaN >= 0` est faux : une comparaison naïve retombait sur l'index 0 et
        // inventait un « A1 non atteint », un niveau que personne n'a obtenu.
        assert.equal(tcfBandIndex(null), null);
        assert.equal(tcfBandIndex(undefined), null);
        assert.equal(tcfBandIndex(Number.NaN), null);
    });

    it("range les paliers dans l'ordre du TCF IRN, C1/C2 rabattus sur B2", () => {
        assert.deepEqual(
            TCF_NOTE_BANDS.map((b) => tcfPalierIndex(b.niveau)),
            [0, 1, 2, 3, 4],
        );
        assert.equal(tcfPalierIndex("C1"), 4);
        assert.equal(tcfPalierIndex("C2"), 4);
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

describe("teinte d'un palier acquis (badges, pastilles)", () => {
    it("ne teinte JAMAIS un B2 comme un échec : c'est le haut du TCF", () => {
        // Le bug d'origine : `note <= 12` → badge rouge, sur le meilleur
        // résultat que l'examen sache produire.
        assert.equal(tacheNiveauTone("B2"), "green");
    });

    it("sépare B1 et B2 — deux paliers, deux teintes", () => {
        assert.equal(tacheNiveauTone("B1"), "blue");
        assert.notEqual(tacheNiveauTone("B1"), tacheNiveauTone("B2"));
    });

    it("n'utilise JAMAIS de rouge, sur aucun palier du TCF", () => {
        // Vaut partout où la teinte se rend : segments de l'échelle, badges de
        // la liste de sujets, marque de ligne — tout part de cette fonction.
        for (const band of TCF_NOTE_BANDS) {
            assert.notEqual(tacheNiveauTone(band.niveau), "red", band.niveau);
        }
        // Typé en dur : le rouge n'appartient même plus à l'union des teintes.
        const tones: string[] = TCF_NOTE_BANDS.map((b) => tacheNiveauTone(b.niveau));
        assert.equal(tones.includes("red"), false);
    });

    it("rend une production pas encore évaluée en NEUTRE, jamais en rouge", () => {
        // Un sujet fait mais pas encore corrigé garde un badge : neutre = gris,
        // comme le mobile. Ce n'est pas un échec.
        for (const absent of [null, undefined]) {
            assert.equal(tacheNiveauTone(absent), "neutral");
            assert.notEqual(tacheNiveauTone(absent), "red");
        }
    });
});

// ---------------------------------------------------------------------------

describe("le niveau d'UNE tâche remplace sa note partout", () => {
    it("nomme le palier comme une bande de critère, au caractère près", () => {
        // Un badge doit se lire pareil d'un écran à l'autre : la bande d'un
        // critère et le résultat d'une tâche disent le même palier.
        assert.equal(tacheNiveauLabel("B2"), "Niveau B2");
        assert.equal(tacheNiveauLabel("B1"), "Niveau B1");
        assert.equal(tacheNiveauLabel("A2"), "Niveau A2");
        assert.equal(tacheNiveauLabel("A1"), "Niveau A1");
        assert.equal(bandeCritereLabel("TRES_BONNE_MAITRISE"), tacheNiveauLabel("B2"));
        assert.equal(bandeCritereLabel("SATISFAISANT"), tacheNiveauLabel("B1"));
        assert.equal(bandeCritereLabel("EN_COURS_ACQUISITION"), tacheNiveauLabel("A2"));
        assert.equal(bandeCritereLabel("FRAGILE"), tacheNiveauLabel("A1"));
    });

    it("ne dit jamais « Niveau A1 non atteint », qui se contredit tout seul", () => {
        assert.equal(tacheNiveauLabel("A1_NON_ATTEINT"), "A1 non atteint");
    });

    it("n'affiche AUCUN /20 : une tâche isolée n'a pas de note au TCF", () => {
        const niveaux: NiveauCecrl[] = ["A1_NON_ATTEINT", "A1", "A2", "B1", "B2"];
        for (const n of niveaux) {
            const label = tacheNiveauLabel(n);
            assert.equal(label.includes("/20"), false, n);
            assert.equal(label.includes("20"), false, n);
        }
    });

    it("garde le niveau muet tant que la confiance manque", () => {
        // Miroir du garde-fou serveur : pas de niveau sans confiance.
        assert.equal(
            tacheNiveau({niveauObserve: "B1", confiance: null}),
            null,
        );
        assert.equal(
            tacheNiveau({niveauObserve: null, confiance: "HAUTE"}),
            null,
        );
        assert.equal(tacheNiveau(null), null);
        assert.equal(tacheNiveau(undefined), null);
    });

    it("rend le niveau d'une évaluation complète", () => {
        assert.equal(tacheNiveau({niveauObserve: "A2", confiance: "MOYENNE"}), "A2");
    });
});

// ---------------------------------------------------------------------------

// Ces chaînes ne transitent PAS par le réseau non plus (le serveur n'envoie que
// la forme composée) : chaque front en tient une copie, donc elles sont gelées
// des deux côtés — miroir de `test/production_result_labels_test.dart`.
describe("situation dans le palier — ce qui remplace la note d'une tâche", () => {
    const situated = (
        cran: SituationDansNiveau | null,
        label: string | null = null,
        niveau: NiveauCecrl | null = "A2",
    ): EvaluationResultDto => ({
        noteSurVingt: 4.5,
        niveauObserve: niveau,
        confiance: "HAUTE",
        avertissementNiveau: null,
        situationDansNiveau: cran,
        situationDansNiveauLabel: label,
        feedback: null,
    });

    it("gèle les trois libellés autonomes, miroir du serveur", () => {
        assert.deepEqual(SITUATION_LIBELLES, {
            ENTREE_DE_PALIER: "Palier atteint",
            PALIER_CONFIRME: "Palier confirmé",
            PALIER_SOLIDE: "Palier solide",
        });
    });

    it("gèle les trois qualificatifs — « A2 solide » se compose avec eux", () => {
        assert.deepEqual(SITUATION_QUALIFICATIFS, {
            ENTREE_DE_PALIER: "atteint",
            PALIER_CONFIRME: "confirmé",
            PALIER_SOLIDE: "solide",
        });
    });

    it("ne nomme JAMAIS un manque : ni « presque », ni « pas encore », ni chiffre", () => {
        // C'est la contrepartie de la note masquée. Réintroduire « presque B1 »
        // remettrait exactement le vocabulaire de déficit qu'on vient de retirer.
        for (const cran of Object.keys(SITUATION_LIBELLES) as SituationDansNiveau[]) {
            const textes = [SITUATION_LIBELLES[cran], SITUATION_QUALIFICATIFS[cran]];
            for (const t of textes) {
                assert.equal(/presque|pas encore|manqu|faible|insuffis/i.test(t), false, t);
                assert.equal(/\d/.test(t), false, t);
            }
        }
    });

    it("affiche la forme composée du serveur — « A2 solide », cf. la doc §6.3 bis", () => {
        const view = situationView(situated("PALIER_SOLIDE", "A2 solide"));
        assert.deepEqual(view, {
            cran: "PALIER_SOLIDE",
            libelle: "Palier solide",
            libelleAvecNiveau: "A2 solide",
        });
    });

    it("recompose « niveau + qualificatif » si le serveur n'a pas envoyé le libellé", () => {
        assert.equal(situationView(situated("PALIER_CONFIRME"))!.libelleAvecNiveau, "A2 confirmé");
    });

    it("ne situe rien sans niveau affichable : pas de position dans une bande anonyme", () => {
        assert.equal(situationView(situated("PALIER_SOLIDE", "A2 solide", null)), null);
        assert.equal(
            situationView({
                ...situated("PALIER_SOLIDE", "A2 solide"),
                confiance: null,
            }),
            null,
        );
    });

    it("ne rend rien quand le backend n'a pas de cran (legacy, <A1, C1/C2)", () => {
        assert.equal(situationView(situated(null)), null);
        assert.equal(situationView(null), null);
        assert.equal(situationView(undefined), null);
    });
});

// ---------------------------------------------------------------------------

describe("libellés gelés — sujet rendu sans niveau (miroir mobile)", () => {
    it("dit « Traité » des deux côtés — le mobile disait « Fait »", () => {
        assert.equal(TACHE_TRAITEE_LABEL, "Traité");
        assert.equal(TACHE_EVALUEE_LABEL, "Évaluée");
    });

    it("n'affiche aucun chiffre : c'est l'absence de niveau qu'on nomme", () => {
        for (const label of [TACHE_TRAITEE_LABEL, TACHE_EVALUEE_LABEL]) {
            assert.equal(/\d/.test(label), false, label);
        }
    });
});

// ---------------------------------------------------------------------------

describe("version au niveau visé — la marche au-dessus", () => {
    it("dit dès le titre que c'est un modèle, pas la production du candidat", () => {
        assert.equal(
            versionCibleeTitle("B2"),
            "Au niveau B2, votre réponse pourrait ressembler à ceci",
        );
        assert.equal(VERSION_CIBLEE_EYEBROW, "La marche au-dessus");
        assert.equal(VERSION_CIBLEE_LEVIERS_TITLE, "Ce qui vous en sépare");
    });

    it("désamorce explicitement la confusion « c'est mon texte »", () => {
        assert.ok(versionCibleeIntro("B2").startsWith("Ce texte n'est pas le vôtre"));
    });

    it("relie chaque palier à SA démarche, sans recopier le rappel d'enjeu", () => {
        assert.ok(versionCibleeIntro("A2").includes("la carte de séjour pluriannuelle"));
        assert.ok(versionCibleeIntro("B1").includes("la carte de résident"));
        assert.ok(versionCibleeIntro("B2").includes("la naturalisation"));
        // Le hero écrit « Le niveau B2 est celui demandé pour… » : la section ne
        // doit pas répéter la même phrase deux écrans plus bas.
        const rappel = demarcheRappel("B2", "B1")!.text;
        for (const cible of ["A2", "B1", "B2"] as const) {
            assert.notEqual(versionCibleeIntro(cible), rappel);
            assert.equal(versionCibleeIntro(cible).includes("est celui demandé pour"), false);
        }
    });
});

// ---------------------------------------------------------------------------

describe("niveau visé déjà atteint — la victoire, dite", () => {
    it("annonce l'objectif atteint, palier nommé", () => {
        assert.equal(NIVEAU_VISE_ATTEINT_EYEBROW, "Objectif atteint");
        assert.equal(niveauViseAtteintTitle("B2"), "Objectif B2 : vous y êtes");
        assert.equal(niveauViseAtteintTitle("A2"), "Objectif A2 : vous y êtes");
    });

    it("explique l'absence de texte modèle, sans chiffre ni vocabulaire de manque", () => {
        assert.ok(NIVEAU_VISE_ATTEINT_INTRO.includes("pas de version d'un niveau supérieur"));
        for (const interdit of ["/20", "note", "manque", "insuffis", "échec", "faible"]) {
            assert.equal(
                NIVEAU_VISE_ATTEINT_INTRO.toLowerCase().includes(interdit),
                false,
                `« ${interdit} » n'a rien à faire dans un message de réussite`,
            );
        }
    });

    it("ne recopie pas le rappel d'enjeu du hero", () => {
        // Le hero écrit déjà « Le niveau B2 est celui demandé pour la
        // naturalisation. Cette production l'atteint. » Deux blocs qui se
        // répètent mot pour mot se lisent comme un bug d'affichage.
        const rappel = demarcheRappel("B2", "B2")!;
        assert.equal(rappel.atteint, true);
        assert.notEqual(NIVEAU_VISE_ATTEINT_INTRO, rappel.text);
        assert.equal(NIVEAU_VISE_ATTEINT_INTRO.includes("est celui demandé pour"), false);
        assert.notEqual(niveauViseAtteintTitle("B2"), niveauAtteintLabel("B2"));
    });
});

// ---------------------------------------------------------------------------

describe("parseEeFeedback — bloc niveau_vise_atteint", () => {
    it("lit le signal serveur d'objectif atteint", () => {
        const fb = parseEeFeedback(
            evaluation({
                niveau_vise_atteint: {niveau_vise: "B2", niveau_constate: "B2"},
            }),
        );
        assert.deepEqual(fb.niveauViseAtteint, {niveauVise: "B2", niveauConstate: "B2"});
        assert.equal(fb.versionCiblee, null);
    });

    it("sans palier visé, il n'y a rien à féliciter", () => {
        const fb = parseEeFeedback(evaluation({niveau_vise_atteint: {niveau_constate: "B2"}}));
        assert.equal(fb.niveauViseAtteint, null);
    });

    it("absent des évaluations qui ne le portent pas", () => {
        assert.equal(parseEeFeedback(evaluation({})).niveauViseAtteint, null);
        assert.equal(parseEeFeedback(null).niveauViseAtteint, null);
    });
});

// ---------------------------------------------------------------------------

describe("parseEeFeedback — bloc version_ciblee", () => {
    it("lit le bloc et PRÉSERVE l'ordre des leviers", () => {
        const fb = parseEeFeedback(
            evaluation({
                version_ciblee: {
                    niveau_vise: "B2",
                    niveau_constate: "B1",
                    texte: "Madame, Monsieur,\nJe me permets de vous écrire…",
                    ce_qui_manque: ["Articuler deux arguments", "Varier les temps", "Nuancer"],
                },
            }),
        );
        assert.equal(fb.versionCiblee?.niveauVise, "B2");
        assert.equal(fb.versionCiblee?.niveauConstate, "B1");
        assert.match(fb.versionCiblee?.texte ?? "", /^Madame, Monsieur,/);
        assert.deepEqual(fb.versionCiblee?.ceQuiManque, [
            "Articuler deux arguments",
            "Varier les temps",
            "Nuancer",
        ]);
    });

    it("accepte un bloc sans niveau constaté (évaluation dont le niveau est inconnu)", () => {
        const fb = parseEeFeedback(
            evaluation({version_ciblee: {niveau_vise: "A2", texte: "Bonjour Sofia, …"}}),
        );
        assert.equal(fb.versionCiblee?.niveauConstate, null);
        assert.deepEqual(fb.versionCiblee?.ceQuiManque, []);
    });

    it("reste null quand le bloc est absent — le cas de TOUTES les évals existantes et de l'EO", () => {
        assert.equal(parseEeFeedback(evaluation({})).versionCiblee, null);
        assert.equal(parseEeFeedback(evaluation(null)).versionCiblee, null);
        assert.equal(parseEeFeedback(null).versionCiblee, null);
    });

    it("refuse un bloc inexploitable plutôt que d'afficher un cadre vide", () => {
        // Sans palier visé, on ne saurait pas au nom de quoi ce texte est
        // montré ; sans texte, il n'y a rien à montrer.
        for (const bloc of [
            {texte: "Un modèle."},
            {niveau_vise: "B2"},
            {niveau_vise: "C1", texte: "Un modèle."},
            {niveau_vise: "B2", texte: "   "},
            "pas un objet",
        ]) {
            assert.equal(parseEeFeedback(evaluation({version_ciblee: bloc})).versionCiblee, null);
        }
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
            assert.equal(bandeCritereLabel(bande), "Niveau B2");
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
            const index = tcfBandIndex(note);
            assert.ok(index != null, `note ${note}`);
            assert.equal(
                critereBandeFromNote(note),
                attendu[TCF_NOTE_BANDS[index].niveau],
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

// Ces chaînes ne transitent PAS par le réseau : le web et le mobile en tiennent
// chacun une copie écrite à la main. Rien n'empêche une couche de dériver — d'où
// ce gel, miroir de `test/skill_models_test.dart` et de `SkillLabelsTest`. Un
// libellé qui bouge, ce sont deux fichiers et deux tests dans la même passe.
describe("libellés gelés — bandes de critère (miroir mobile `BandeCritere.displayName`)", () => {
    it("nomme le palier atteint, jamais un déficit", () => {
        const attendu: Record<BandeCritere, string> = {
            TRES_BONNE_MAITRISE: "Niveau B2",
            SATISFAISANT: "Niveau B1",
            EN_COURS_ACQUISITION: "Niveau A2",
            FRAGILE: "Niveau A1",
            NON_EVALUABLE: "Non évaluable",
        };
        for (const [bande, label] of Object.entries(attendu)) {
            assert.equal(bandeCritereLabel(bande as BandeCritere), label);
        }
    });

    it("ne contient plus le vocabulaire d'échec qui décrivait un palier normal", () => {
        // Les bornes des bandes (10 / 6 / 2) sont celles des paliers du TCF :
        // « En cours d'acquisition » couvrait TOUTE la bande A2, donc un
        // candidat A2 ne pouvait voir que ça, quoi qu'il produise.
        const bandes: BandeCritere[] = [
            "TRES_BONNE_MAITRISE",
            "SATISFAISANT",
            "EN_COURS_ACQUISITION",
            "FRAGILE",
            "NON_EVALUABLE",
        ];
        for (const b of bandes) {
            const label = bandeCritereLabel(b);
            assert.equal(label.includes("acquisition"), false, b);
            assert.equal(label.includes("Fragile"), false, b);
        }
    });
});

// ---------------------------------------------------------------------------

describe("le niveau, affirmé (résultat d'une tâche)", () => {
    it("ne dit plus « proche de » : le niveau EST celui-là", () => {
        assert.equal(niveauAtteintLabel("A2"), "Votre production est au niveau A2");
        assert.equal(niveauAtteintLabel("B1"), "Votre production est au niveau B1");
        assert.equal(niveauAtteintLabel("B2"), "Votre production est au niveau B2");
        for (const n of ["A1", "A2", "B1", "B2"] as NiveauCecrl[]) {
            assert.equal(niveauAtteintLabel(n).includes("Proche"), false, n);
        }
    });

    it("garde son traitement propre au plancher, sans humilier", () => {
        assert.equal(
            niveauAtteintLabel("A1_NON_ATTEINT"),
            "Votre production n'atteint pas encore le niveau A1",
        );
        // « Proche d'un niveau non atteint » n'a aucun sens, et « sous le A1 »
        // n'apprend rien : on dit ce qui reste à faire.
        assert.equal(niveauAtteintLabel("A1_NON_ATTEINT").includes("Proche"), false);
    });

    it("explique le NIVEAU, jamais une note invisible", () => {
        // Le résultat d'une tâche n'affiche plus de /20 : une info-bulle qui
        // commenterait une note absente serait pire que pas d'info-bulle.
        assert.equal(NIVEAU_PORTEE_TACHE.includes("note"), false);
        assert.equal(NIVEAU_PORTEE_TACHE.includes("/20"), false);
        assert.ok(NIVEAU_PORTEE_TACHE.includes("cette seule tâche"));
    });
});

// ---------------------------------------------------------------------------

describe("rappel d'enjeu (niveau atteint ⇄ démarche visée)", () => {
    it("dit clairement qu'un A2 qui vise la carte de séjour est au niveau demandé", () => {
        const r = demarcheRappel("A2", "A2");
        assert.ok(r);
        assert.equal(r.atteint, true);
        assert.equal(
            r.text,
            "Le niveau A2 est celui demandé pour la carte de séjour pluriannuelle. " +
                "Cette production l'atteint.",
        );
    });

    it("nomme la bonne démarche pour chaque palier (seuils du 1ᵉʳ janvier 2026)", () => {
        assert.ok(demarcheRappel("A2", "B2")!.text.includes("la carte de séjour pluriannuelle"));
        assert.ok(demarcheRappel("B1", "B2")!.text.includes("la carte de résident"));
        assert.ok(demarcheRappel("B2", "B2")!.text.includes("la naturalisation"));
    });

    it("compte un niveau au-dessus de l'objectif comme atteint", () => {
        assert.equal(demarcheRappel("A2", "B1")!.atteint, true);
        assert.equal(demarcheRappel("A2", "B2")!.atteint, true);
        assert.equal(demarcheRappel("B1", "B2")!.atteint, true);
        assert.equal(demarcheRappel("B2", "C1")!.atteint, true);
    });

    it("dit l'objectif encore devant sans dramatiser ni condescendance", () => {
        const r = demarcheRappel("B1", "A2");
        assert.ok(r);
        assert.equal(r.atteint, false);
        assert.equal(
            r.text,
            "Le niveau B1 est celui demandé pour la carte de résident. " +
                "Cette production est au niveau A2 : continuez à vous entraîner.",
        );
    });

    it("reformule le plancher au lieu d'écrire « au niveau A1 non atteint »", () => {
        const r = demarcheRappel("A2", "A1_NON_ATTEINT");
        assert.ok(r);
        assert.equal(r.atteint, false);
        assert.ok(r.text.includes("n'atteint pas encore le niveau A1"));
    });

    it("n'affiche RIEN quand la démarche ou le niveau est inconnu", () => {
        // Un message générique parlerait d'une démarche que le candidat n'a pas
        // choisie : mieux vaut se taire.
        assert.equal(demarcheRappel(null, "A2"), null);
        assert.equal(demarcheRappel(undefined, "A2"), null);
        assert.equal(demarcheRappel("B1", null), null);
        assert.equal(demarcheRappel("B1", undefined), null);
    });

    it("n'affiche aucune borne chiffrée de barème", () => {
        for (const cible of ["A2", "B1", "B2"] as const) {
            for (const obtenu of [
                "A1_NON_ATTEINT",
                "A1",
                "A2",
                "B1",
                "B2",
            ] as NiveauCecrl[]) {
                const r = demarcheRappel(cible, obtenu)!;
                assert.equal(/\d/.test(r.text.replace(/A1|A2|B1|B2/g, "")), false, r.text);
            }
        }
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

// ---------------------------------------------------------------------------

// ⚠️ Garde de RENDU, faute de harnais de composants côté web : le seul texte
// modèle du rapport est `version_ciblee`. `version_amelioree` réécrit la
// production au niveau DÉJÀ CONSTATÉ — un candidat l'a recopiée telle quelle
// (c'était le texte le plus visible et le plus copiable de la page, et il ne
// nommait aucun niveau), l'a resoumise, et a obtenu exactement la même note et
// le même niveau. Le champ reste servi par l'API et typé plus haut dans ce
// dossier ; ce test verrouille qu'AUCUN composant ne le lit.
describe("aucun composant ne rend `version_amelioree` (retrait 2026-08-08)", () => {
    const dir = new URL("../app/_components/production/", import.meta.url);
    const fichiers = readdirSync(dir).filter((f) => f.endsWith(".tsx") || f.endsWith(".ts"));

    it("lit bien tout le dossier des composants de production", () => {
        assert.ok(fichiers.includes("ProductionFeedbackView.tsx"));
        assert.ok(fichiers.includes("ProductionTextCard.tsx"));
        assert.ok(fichiers.includes("TargetLevelVersionCard.tsx"));
    });

    for (const fichier of fichiers) {
        it(`${fichier} ne lit ni le champ ni son libellé`, () => {
            const source = readFileSync(new URL(fichier, dir), "utf8");
            // Les commentaires expliquent POURQUOI il a disparu : on ne
            // regarde que le code.
            const code = source
                .replace(/\/\*[\s\S]*?\*\//g, "")
                .replace(/^\s*\/\/.*$/gm, "");
            assert.equal(/versionAmelioree/.test(code), false, fichier);
            assert.equal(/[Vv]ersion améliorée/.test(code), false, fichier);
        });
    }
});
