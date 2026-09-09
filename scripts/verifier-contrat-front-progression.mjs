#!/usr/bin/env node
/**
 * T36 — vérificateur statique du contrat de rendu front (§25 bis, §49.6).
 *
 * 🛑 Ce n'est pas un test de front. Le dépôt n'en accepte aucun (CLAUDE.md
 * racine : ni `*.test.ts`, ni `flutter_test`). C'est un vérificateur autonome,
 * sans dépendance, qui relit le code web et mobile et échoue si le front s'est
 * remis à décider ce que seul le serveur décide.
 *
 *     node scripts/verifier-contrat-front-progression.mjs
 *
 * Il cherche trois choses, et rien d'autre :
 *
 *   1. une fonction qui rend un niveau CECRL à partir d'un nombre ;
 *   2. une comparaison d'un pourcentage à un seuil de classement, suivie d'un
 *      libellé d'état pédagogique ;
 *   3. un pourcentage et un libellé CECRL dans le même bloc visuel.
 *
 * Il vérifie aussi que les six états de §13 sont bien déclarés des deux côtés :
 * une UI qui n'en gère que quatre est non conforme, et ce sont toujours `WATCH`
 * et `READY_FOR_REASSESSMENT` qu'on perd en premier.
 *
 * Sortie 0 = conforme. Sortie 1 = une violation, décrite avec son fichier et sa
 * ligne.
 */

import {readFileSync, readdirSync, statSync} from "node:fs";
import {join, relative, extname} from "node:path";
import {fileURLToPath} from "node:url";

const RACINE = join(fileURLToPath(new URL(".", import.meta.url)), "..");

/** Ce qu'on relit : le code des trois fronts, pas leurs dépendances. */
const SOURCES = [
    {racine: "web_sejoufr/app", extensions: [".ts", ".tsx"]},
    {racine: "web_sejoufr/lib", extensions: [".ts", ".tsx"]},
    {racine: "admin_sejourfr/src", extensions: [".ts", ".tsx"]},
    {racine: "mobile_sejourfr/lib", extensions: [".dart"]},
];

const IGNORES = new Set(["node_modules", ".next", "build", "dist", ".dart_tool"]);

/** Les libellés d'état de §25 bis.3 — les seuls autorisés. */
const ETATS_AUTORISES = [
    "À évaluer", "À renforcer", "En progression",
    "Prêt à vérifier", "Acquis", "À vérifier",
];

/**
 * Les vocabulaires d'états concurrents. Un mot n'est fautif que **dérivé d'un
 * nombre** : c'est la règle 2 qui le juge, pas sa simple présence — le serveur
 * a le droit de servir « Solide », le front n'a pas le droit de le calculer.
 */
const MOTS_ETAT = [
    "Solide", "Fragile", "En bonne voie", "À renforcer", "Prioritaire",
    "Priorité", "En consolidation", "Presque acquis", "Non observée",
];

const SEUILS_DE_CLASSEMENT = ["40", "45", "55", "60", "65", "70", "80", "85"];

const violations = [];

for (const source of SOURCES) {
    for (const fichier of fichiers(join(RACINE, source.racine), source.extensions)) {
        analyser(fichier, readFileSync(fichier, "utf8"));
    }
}

verifierLesSixEtats(
    "web_sejoufr/lib/progression-contract.ts",
    ["NOT_EVALUATED", "FRAGILE", "PROGRESSING", "READY_FOR_REASSESSMENT", "SOLID", "WATCH"],
);
verifierLesSixEtats(
    "mobile_sejourfr/lib/core/models/progression_status.dart",
    ["NOT_EVALUATED", "FRAGILE", "PROGRESSING", "READY_FOR_REASSESSMENT", "SOLID", "WATCH"],
);

if (violations.length > 0) {
    console.error(`\nT36 — contrat de rendu front NON CONFORME (${violations.length}) :\n`);
    for (const v of violations) {
        console.error(`  ${v.fichier}:${v.ligne}`);
        console.error(`    ${v.regle}`);
        console.error(`    > ${v.extrait.trim()}\n`);
    }
    console.error("§25 bis : le front ne calcule aucun état, aucun niveau CECRL, aucun seuil.");
    process.exit(1);
}

console.log("T36 — contrat de rendu front conforme.");

/* ------------------------------------------------------------------ règles */

function analyser(chemin, contenu) {
    const fichier = relative(RACINE, chemin);
    const lignes = contenu.split("\n");

    // Règle 0 — les deux fonctions nommément supprimées par §25 bis.4.
    lignes.forEach((ligne, i) => {
        if (estCommentaire(ligne)) return;
        if (/\b(masteryTone|masteryLabel)\s*\(/.test(ligne)) {
            signaler(fichier, i, ligne,
                "§25 bis.4 — masteryTone/masteryLabel supprimés : un état ne se dérive pas d'un nombre.");
        }
    });

    // Règle 1 — une fonction qui rend un niveau CECRL à partir d'un nombre.
    lignes.forEach((ligne, i) => {
        if (estCommentaire(ligne)) return;
        const rendUnNiveau = /return\s+.*["']\s*(A1|A2|B1|B2)\s*["']/.test(ligne);
        const compareUnNombre = /[<>]=?\s*\d/.test(ligne);
        if (rendUnNiveau && compareUnNombre) {
            signaler(fichier, i, ligne,
                "§25 bis.6 — un niveau CECRL n'est jamais dérivé d'un nombre côté client.");
        }
        if (/\bcefr\s*\(/.test(ligne)) {
            signaler(fichier, i, ligne,
                "§25 bis.4 — cefr() supprimé : le niveau CECRL vient servi ou n'existe pas.");
        }
    });

    // Règle 2 — un seuil de classement suivi d'un libellé d'état.
    lignes.forEach((ligne, i) => {
        if (estCommentaire(ligne)) return;
        const compareUnSeuil = SEUILS_DE_CLASSEMENT.some(
            (seuil) => new RegExp(`[<>]=?\\s*${seuil}\\b`).test(ligne));
        if (!compareUnSeuil) return;
        const suite = lignes.slice(i, i + 3).join(" ");
        const mot = MOTS_ETAT.find((m) => suite.includes(`'${m}`) || suite.includes(`"${m}`));
        if (mot) {
            signaler(fichier, i, ligne,
                `§25 bis.3 — « ${mot} » classé à partir d'un pourcentage : c'est le moteur, pas le front.`);
        }
    });

    // Règle 3 — un pourcentage et un niveau CECRL dans le même bloc visuel.
    lignes.forEach((ligne, i) => {
        if (estCommentaire(ligne)) return;
        const bloc = lignes.slice(i, i + 2).join(" ");
        const pourcentage = /%["'`}\s]/.test(bloc) || /\bpercent\b/.test(bloc);
        const niveauCecrl = /["'](A1|A2|B1|B2)["']/.test(bloc)
            || /\b(cefr|niveauCecrl|estimatedLevel)\b/.test(bloc);
        if (pourcentage && niveauCecrl && /\b(label|k:|title|Text\()/.test(bloc)) {
            signaler(fichier, i, ligne,
                "§25 bis.5 — pourcentage et niveau CECRL dans le même bloc : se lit comme un score TCF.");
        }
    });

    // Les libellés d'état inventés : un mot du vocabulaire de §25 bis.3
    // orthographié autrement finit par cohabiter avec l'original.
    lignes.forEach((ligne, i) => {
        if (estCommentaire(ligne)) return;
        for (const proche of ["Prêt à vérifer", "A évaluer", "A vérifier", "A renforcer"]) {
            const motEntier = new RegExp(`(^|[^\\p{L}])${proche}([^\\p{L}]|$)`, "u");
            if (motEntier.test(ligne) && !ETATS_AUTORISES.includes(proche)) {
                signaler(fichier, i, ligne,
                    `§25 bis.3 — « ${proche} » n'est pas un libellé du mapping unique.`);
            }
        }
    });
}

function verifierLesSixEtats(chemin, attendus) {
    let contenu;
    try {
        contenu = readFileSync(join(RACINE, chemin), "utf8");
    } catch {
        violations.push({
            fichier: chemin, ligne: 0, extrait: "(fichier absent)",
            regle: "§25 bis.3 — le mapping unique des six états doit exister de ce côté.",
        });
        return;
    }
    const manquants = attendus.filter((etat) => !contenu.includes(etat));
    if (manquants.length > 0) {
        violations.push({
            fichier: chemin, ligne: 0, extrait: manquants.join(", "),
            regle: "§25 bis.3 — les six états doivent tous être déclarés ; il en manque.",
        });
    }
}

/* ---------------------------------------------------------------- outillage */

/**
 * Une exemption ne se decide pas en assouplissant une regle : elle s'ecrit sur
 * la ligne concernee, avec sa raison, sous la forme
 *
 *     // t36-ok: <pourquoi ce n'est pas un verdict sur le candidat>
 *
 * On voit alors en revue combien il y en a et pourquoi. Un motif elargi, lui,
 * disparait dans la regex et ne se recompte jamais.
 */
function signaler(fichier, index, extrait, regle) {
    if (/\/\/\s*t36-ok:/.test(extrait)) return;
    violations.push({fichier, ligne: index + 1, extrait, regle});
}

/** Une ligne de commentaire ne décrit pas un comportement : elle l'explique. */
function estCommentaire(ligne) {
    const nue = ligne.trimStart();
    return nue.startsWith("//") || nue.startsWith("///") || nue.startsWith("*")
        || nue.startsWith("/*");
}

function* fichiers(racine, extensions) {
    let entrees;
    try {
        entrees = readdirSync(racine);
    } catch {
        return;
    }
    for (const entree of entrees) {
        if (IGNORES.has(entree)) continue;
        const chemin = join(racine, entree);
        if (statSync(chemin).isDirectory()) {
            yield* fichiers(chemin, extensions);
        } else if (extensions.includes(extname(chemin))) {
            yield chemin;
        }
    }
}
