// Dégradation du guidage d'un petit sujet.
//
// Les quatre champs de guidage (V026) sont nullables : un sujet créé depuis la
// console d'administration peut naître sans check-list, sans étiquette, sans
// amorce et sans astuce. L'écran de saisie doit alors rester complet — jamais
// de carte vide, jamais de « null » affiché. Ces tests figent ce que chaque
// absence produit, pour que le web et le mobile se dégradent pareil.
//
// Exécution : `npm test` (runner natif de Node, aucune dépendance ajoutée).

import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
    answerStarterOf,
    checklistOf,
    constraintTagsOf,
    lengthChipLabel,
    MAX_CHECKLIST_ITEMS,
    MAX_CONSTRAINT_TAGS,
    SKILL_ANALYSIS_MAX_AUDIO_SEC,
    SKILL_ANALYSIS_MAX_WORDS,
    tipOf,
} from "./skill-guidance.ts";

describe("plafonds durs de production", () => {
    // Ce ne sont pas des valeurs de confort : au-delà, le serveur refuse la
    // soumission. Aucun DTO ne les publie, les deux fronts les recopient — donc
    // on les fige ici. Faire échouer ce test est le seul signal qui reste quand
    // `application.yaml` bouge : le corriger veut dire corriger le mobile dans
    // la même passe (point C2 de l'audit de parité).
    it("recopient les gardes serveur, à l'identique du mobile", () => {
        assert.equal(SKILL_ANALYSIS_MAX_WORDS, 400);
        assert.equal(SKILL_ANALYSIS_MAX_AUDIO_SEC, 180);
    });

    it("laissent de la marge aux longueurs conseillées des sujets", () => {
        // Le plus long des petits sujets se traite en quelques phrases : un
        // plafond qui mordrait sur la fourchette conseillée transformerait un
        // repère indicatif en blocage, ce que la spec §8 règle 15 interdit.
        assert.ok(SKILL_ANALYSIS_MAX_WORDS > 100);
        assert.ok(SKILL_ANALYSIS_MAX_AUDIO_SEC > 120);
    });
});

describe("checklistOf", () => {
    it("rend les gestes dans l'ordre du contenu", () => {
        assert.deepEqual(
            checklistOf({checklist: ["Saluez votre voisine", "Dites qui vous êtes"]}),
            ["Saluez votre voisine", "Dites qui vous êtes"],
        );
    });

    it("absence, tableau vide et éléments blancs valent tous « pas de check-list »", () => {
        assert.deepEqual(checklistOf({}), []);
        assert.deepEqual(checklistOf({checklist: null}), []);
        assert.deepEqual(checklistOf({checklist: []}), []);
        assert.deepEqual(checklistOf({checklist: ["   ", ""]}), []);
    });

    it("nettoie les espaces et retire les trous au milieu", () => {
        assert.deepEqual(checklistOf({checklist: ["  Saluez  ", "  ", "Concluez"]}), [
            "Saluez",
            "Concluez",
        ]);
    });

    it("plafonne à 4 gestes", () => {
        const items = ["un", "deux", "trois", "quatre", "cinq", "six"];
        assert.equal(checklistOf({checklist: items}).length, MAX_CHECKLIST_ITEMS);
    });
});

describe("constraintTagsOf", () => {
    it("conserve libellé et icône", () => {
        assert.deepEqual(
            constraintTagsOf({constraintTags: [{label: "Vouvoiement", icon: "PERSON"}]}),
            [{label: "Vouvoiement", icon: "PERSON"}],
        );
    });

    it("retire une étiquette sans libellé — une puce vide n'apprend rien", () => {
        assert.deepEqual(
            constraintTagsOf({
                constraintTags: [
                    {label: "  ", icon: "TONE"},
                    {label: " Ton poli ", icon: "TONE"},
                ],
            }),
            [{label: "Ton poli", icon: "TONE"}],
        );
    });

    it("absence et tableau vide valent « seule la puce de longueur »", () => {
        assert.deepEqual(constraintTagsOf({}), []);
        assert.deepEqual(constraintTagsOf({constraintTags: null}), []);
        assert.deepEqual(constraintTagsOf({constraintTags: []}), []);
    });

    it("plafonne à 3 étiquettes", () => {
        const tags = [
            {label: "a", icon: "TONE" as const},
            {label: "b", icon: "PERSON" as const},
            {label: "c", icon: "TIME" as const},
            {label: "d", icon: "PLACE" as const},
        ];
        assert.equal(constraintTagsOf({constraintTags: tags}).length, MAX_CONSTRAINT_TAGS);
    });
});

describe("answerStarterOf / tipOf", () => {
    it("rendent la valeur nettoyée", () => {
        assert.equal(
            answerStarterOf({answerStarter: " Bonjour Madame, je suis votre voisin du… "}),
            "Bonjour Madame, je suis votre voisin du…",
        );
        assert.equal(tipOf({tip: "commencez par bonjour"}), "commencez par bonjour");
    });

    it("rendent null sur une absence ou une chaîne blanche", () => {
        assert.equal(answerStarterOf({}), null);
        assert.equal(answerStarterOf({answerStarter: null}), null);
        assert.equal(answerStarterOf({answerStarter: "   "}), null);
        assert.equal(tipOf({}), null);
        assert.equal(tipOf({tip: "  "}), null);
    });

    it("n'ajoute pas le préfixe « Astuce : » — c'est l'affichage qui le pose", () => {
        assert.equal(tipOf({tip: "présentez-vous"}), "présentez-vous");
    });
});

describe("lengthChipLabel", () => {
    it("écrit : la fourchette de mots", () => {
        assert.equal(
            lengthChipLabel({recommendedMinWords: 15, recommendedMaxWords: 35}, false),
            "≈ 15–35 mots",
        );
    });

    it("écrit : une seule borne reste lisible", () => {
        assert.equal(lengthChipLabel({recommendedMinWords: 30}, false), "≈ 30 mots minimum");
        assert.equal(lengthChipLabel({recommendedMaxWords: 90}, false), "≈ 90 mots maximum");
    });

    it("oral : la durée en toutes lettres", () => {
        assert.equal(lengthChipLabel({recommendedDurationSeconds: 45}, true), "≈ 45 secondes");
        assert.equal(lengthChipLabel({recommendedDurationSeconds: 60}, true), "≈ 1 minute");
        assert.equal(lengthChipLabel({recommendedDurationSeconds: 120}, true), "≈ 2 minutes");
        assert.equal(lengthChipLabel({recommendedDurationSeconds: 90}, true), "≈ 1 min 30");
    });

    it("sans borne, aucune puce inventée", () => {
        assert.equal(lengthChipLabel({}, false), null);
        assert.equal(lengthChipLabel({}, true), null);
        assert.equal(lengthChipLabel({recommendedDurationSeconds: 0}, true), null);
    });

    it("ne lit pas les bornes de l'autre épreuve", () => {
        assert.equal(
            lengthChipLabel({recommendedMinWords: 15, recommendedMaxWords: 35}, true),
            null,
        );
        assert.equal(lengthChipLabel({recommendedDurationSeconds: 45}, false), null);
    });
});
