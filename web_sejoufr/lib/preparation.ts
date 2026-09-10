/**
 * Les phrases de « Ma préparation » — **pures**, déclarées une fois pour tout
 * le web.
 *
 * 🛑 **Le serveur sert l'ÉTAPE, ce fichier sert la PHRASE.** C'est la même
 * discipline que partout ailleurs : « Faire mon diagnostic complet » est une
 * formulation, pas une donnée.
 *
 * 🛑 **Trois portes, un seul état.** L'Accueil, le Plan et les Examens
 * appellent tous les trois `userContentApi.preparation()` et passent par ces
 * fonctions. Aucun écran ne déduit son propre libellé — c'est ce qui garantit
 * qu'ils proposent la même prochaine action.
 *
 * Miroir de `mobile_sejourfr/lib/core/models/preparation_labels.dart`.
 */
import type {ModulePreparation, PreparationDto} from "./types";

export const PREPARATION_TITLE = "Ma préparation";

export const TCF_LABEL = "TCF IRN";
export const CIVIQUE_LABEL = "Examen civique";

/** Où mène la prochaine action d'un module. */
export interface PreparationAction {
    /** L'état, dit au candidat. */
    statut: string;
    /** Le bouton. Jamais « Continuer » tout court : il dit ce qui va se passer. */
    cta: string;
    href: string;
}

/* --------------------------------------------------------------------------
   TCF — deux diagnostics, deux objectifs
   -------------------------------------------------------------------------- */

export function tcfAction(m: ModulePreparation): PreparationAction {
    switch (m.etape) {
        case "DIAGNOSTIC_A_FAIRE":
            return {
                statut: "Diagnostic non réalisé",
                cta: "Faire mon diagnostic",
                href: "/diagnostic",
            };
        case "DIAGNOSTIC_EN_COURS":
            return {
                statut:
                    m.fait !== null && m.total !== null
                        ? `Diagnostic complet : ${m.fait} / ${m.total} épreuves`
                        : "Diagnostic en cours",
                cta: "Reprendre",
                href: m.fait !== null ? "/diagnostic-tcf" : "/diagnostic",
            };
        case "ESTIMATION_FAITE":
            return {
                // 🛑 Le rapide est **terminé**, et on le dit — mais il ne suffit
                // pas à bâtir le Plan : il n'a observé qu'une production écrite.
                statut: "Première estimation terminée",
                cta: "Faire mon diagnostic complet",
                href: "/diagnostic-tcf",
            };
        case "PLAN_PRET":
            return {
                statut: niveauLine(m) ?? "Diagnostic terminé",
                cta: "Continuer mon plan",
                href: "/plan",
            };
    }
}

/** « B1 → objectif B2 ». `null` si rien n'est mesuré : jamais un palier inventé. */
export function niveauLine(m: ModulePreparation): string | null {
    if (!m.niveau) return null;
    return m.cible ? `${m.niveau} → objectif ${m.cible}` : `${m.niveau}`;
}

/* --------------------------------------------------------------------------
   CIVIQUE — un seul diagnostic
   -------------------------------------------------------------------------- */

export function civiqueAction(m: ModulePreparation): PreparationAction {
    switch (m.etape) {
        case "DIAGNOSTIC_A_FAIRE":
            return {
                statut: "Diagnostic non réalisé",
                cta: "Faire mon diagnostic civique",
                href: "/diagnostic-civique",
            };
        case "DIAGNOSTIC_EN_COURS":
            return {
                statut:
                    m.fait !== null && m.total !== null
                        ? `Diagnostic : ${m.fait} / ${m.total} questions`
                        : "Diagnostic en cours",
                cta: "Reprendre",
                href: "/diagnostic-civique",
            };
        case "ESTIMATION_FAITE":
            // 🛑 N'existe pas côté civique — il n'a qu'UN diagnostic. Ce cas est
            // ici parce que le type est partagé, pas parce qu'il peut arriver.
            return {
                statut: "Diagnostic non réalisé",
                cta: "Faire mon diagnostic civique",
                href: "/diagnostic-civique",
            };
        case "PLAN_PRET":
            return {
                statut: aRenforcerLine(m) ?? "Diagnostic terminé",
                cta: "Continuer mon plan",
                href: "/plan?module=CIVIQUE",
            };
    }
}

/**
 * « 3 thèmes à renforcer ».
 *
 * 🛑 `null` tant que rien n'est mesuré, et une phrase **différente** quand le
 * compte est zéro : « 0 thème à renforcer » se lit comme une erreur d'affichage
 * alors que c'est une bonne nouvelle.
 */
export function aRenforcerLine(m: ModulePreparation): string | null {
    if (m.aRenforcer === null) return null;
    if (m.aRenforcer === 0) return "Tous vos thèmes sont solides";
    return `${m.aRenforcer} thème${m.aRenforcer > 1 ? "s" : ""} à renforcer`;
}

/* --------------------------------------------------------------------------
   Le PLAN — pourquoi il n'est pas encore prêt
   -------------------------------------------------------------------------- */

export interface PlanIndisponible {
    titre: string;
    texte: string;
    cta: string;
    href: string;
}

/**
 * Le Plan d'un module peut-il être construit ?
 *
 * 🛑 `null` = **oui**, l'onglet affiche le vrai Plan. Sinon, il explique
 * pourquoi et ouvre la seule porte qui débloque — jamais un plan vide, jamais
 * un plan bâti sur une mesure qui n'existe pas.
 */
export function planIndisponible(
    m: ModulePreparation,
    module: "TCF" | "CIVIQUE",
): PlanIndisponible | null {
    if (m.etape === "PLAN_PRET") return null;

    if (module === "CIVIQUE") {
        // 🛑 **Un diagnostic COMMENCÉ ne se « fait » pas, il se REPREND.**
        // Redemander « Faire mon diagnostic » à quelqu'un qui vient d'en
        // répondre la moitié lui fait croire que son travail est perdu.
        return m.etape === "DIAGNOSTIC_EN_COURS"
            ? {
                  titre: "Votre diagnostic civique est commencé",
                  texte: avancement(m)
                      ?? "Terminez-le pour que votre plan se construise.",
                  cta: "Reprendre mon diagnostic",
                  href: "/diagnostic-civique",
              }
            : {
                  titre: "Votre plan civique commence par un diagnostic",
                  texte:
                      "Répondez à quelques questions pour identifier les thèmes et les notions à travailler.",
                  cta: "Faire mon diagnostic civique",
                  href: "/diagnostic-civique",
              };
    }

    if (m.etape === "DIAGNOSTIC_EN_COURS") {
        return {
            titre: "Votre diagnostic TCF est commencé",
            texte: avancement(m) ?? "Terminez-le pour que votre plan se construise.",
            cta: "Reprendre mon diagnostic",
            href: m.fait !== null ? "/diagnostic-tcf" : "/diagnostic",
        };
    }

    if (m.etape === "ESTIMATION_FAITE") {
        return {
            titre: "Votre plan TCF n'est pas encore prêt",
            texte:
                "Votre première estimation a identifié quelques axes, mais nous devons aussi évaluer votre oral et vos compréhensions.",
            cta: "Faire mon diagnostic TCF complet",
            href: "/diagnostic-tcf",
        };
    }

    return {
        titre: "Votre plan TCF commence par un diagnostic",
        texte:
            "Une première estimation écrite, puis les quatre épreuves : c'est ce qui permet de savoir quoi travailler en premier.",
        cta: "Faire mon diagnostic",
        href: "/diagnostic",
    };
}

/**
 * « Vous avez répondu à 14 questions sur 40. »
 *
 * 🛑 `null` quand le serveur n'a pas servi d'avancement : on ne fabrique pas un
 * compteur pour remplir une phrase.
 */
function avancement(m: ModulePreparation): string | null {
    if (m.fait === null || m.total === null) return null;
    return m.total > 4
        ? `Vous avez répondu à ${m.fait} question${m.fait > 1 ? "s" : ""} sur ${m.total}.`
        : `Vous avez terminé ${m.fait} épreuve${m.fait > 1 ? "s" : ""} sur ${m.total}.`;
}

/** Le module sur lequel ouvrir le toggle : celui qui a quelque chose à dire. */
export function moduleParDefaut(prep: PreparationDto): "TCF" | "CIVIQUE" {
    // 🛑 On ouvre sur le module DÉJÀ commencé plutôt que toujours sur le TCF :
    // un candidat qui ne prépare que le civique n'a aucune raison d'arriver sur
    // un onglet vide.
    if (prep.tcf.etape === "DIAGNOSTIC_A_FAIRE"
        && prep.civique.etape !== "DIAGNOSTIC_A_FAIRE") {
        return "CIVIQUE";
    }
    return "TCF";
}
