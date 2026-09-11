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
import {PLAN_DOMAIN_SECTION, planDomainLabel, type PlanDomainEpreuve} from "./plan-domain";
import type {EpreuveType, ModulePreparation, PreparationDto} from "./types";

export const PREPARATION_TITLE = "Ma préparation";

/**
 * Où se relit le diagnostic RAPIDE déjà passé.
 *
 * 🛑 **Aucun écran de rapport n'est recréé** : `/diagnostic` sert déjà le
 * rapport quand la session est `COMPLETED` (web `DiagnosticView`, mobile
 * `DiagnosticScreen`). Une seconde route vers le même contenu aurait fini par
 * en montrer une version qui ne bouge plus.
 */
export const DIAGNOSTIC_RAPIDE_HREF = "/diagnostic";

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
    // 🛑 **Dès que le Plan existe, c'est LUI la prochaine action** (arbitrage du
    // 2026-09-12). Le diagnostic complet n'est plus une porte à franchir : il
    // affine, et cette invitation-là vit dans `affinerPlan`, en action
    // **secondaire**. Envoyer ici vers `/diagnostic-tcf` remettrait une étape
    // obligatoire devant un plan déjà utilisable.
    if (m.planDisponible) {
        return {statut: tcfStatut(m), cta: "Continuer mon plan", href: "/plan"};
    }
    // Sans estimation close, il n'y a qu'une seule porte : le diagnostic rapide.
    return m.etape === "DIAGNOSTIC_EN_COURS"
        ? {statut: "Diagnostic en cours", cta: "Reprendre", href: DIAGNOSTIC_RAPIDE_HREF}
        : {
              statut: "Diagnostic non réalisé",
              cta: "Faire mon diagnostic",
              href: DIAGNOSTIC_RAPIDE_HREF,
          };
}

/**
 * Ce qu'on sait du candidat quand son Plan existe.
 *
 * 🛑 **Jamais « 0 / 4 »** : un compteur à zéro se lit comme un échec alors que
 * le candidat vient de terminer son estimation. Le palier mesuré prime dès
 * qu'il existe — c'est le complet qui le sert, et `null` veut dire « pas encore
 * mesuré », jamais A1.
 */
function tcfStatut(m: ModulePreparation): string {
    const niveau = niveauLine(m);
    if (niveau) return niveau;
    if (m.fait !== null && m.total !== null && m.fait > 0) {
        return `Diagnostic complet : ${m.fait} / ${m.total} épreuves`;
    }
    return "Première estimation terminée";
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
    // 🛑 **Le fait servi, jamais l'étape.** Arbitrage du propriétaire du
    // 2026-09-12 : le diagnostic complet n'est plus un prérequis d'accès au
    // Plan, seulement un moyen de l'affiner. Dès que le diagnostic rapide est
    // clos, le serveur sait bâtir un Plan provisoire mais **réel** — ses
    // priorités viennent d'observations vraies, et aucun domaine non mesuré
    // n'en reçoit. Lire `etape` ici ferait dire « pas encore prêt » à un écran
    // que le moteur sert déjà.
    if (m.planDisponible) return null;

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
        // Seul le diagnostic **rapide** inachevé arrive ici : dès qu'il est
        // clos, `planDisponible` est vrai et la porte ne s'affiche plus, même
        // pendant le complet.
        return {
            titre: "Votre diagnostic TCF est commencé",
            texte: avancement(m) ?? "Terminez-le pour que votre plan se construise.",
            cta: "Reprendre mon diagnostic",
            href: DIAGNOSTIC_RAPIDE_HREF,
        };
    }

    return {
        titre: "Votre plan TCF commence par un diagnostic",
        texte:
            "Une première estimation écrite, puis les quatre épreuves : c'est ce qui permet de savoir quoi travailler en premier.",
        cta: "Faire mon diagnostic",
        href: DIAGNOSTIC_RAPIDE_HREF,
    };
}

/**
 * Le **même** écran « pas encore de plan », dérivé de l'état que sert
 * `GET /api/me/plan` — le repli quand `preparation()` n'a pas répondu.
 *
 * 🛑 Il n'écrit **aucune phrase** : il rappelle `planIndisponible`, seule
 * autorité, avec l'étape correspondante. Deux copies de ces quatre lignes
 * auraient fini par proposer deux actions différentes sur le même écran.
 */
export function planIndisponibleDepuisEtat(
    etape: "DIAGNOSTIC_A_FAIRE" | "DIAGNOSTIC_EN_COURS",
    module: "TCF" | "CIVIQUE",
): PlanIndisponible {
    const m: ModulePreparation = {
        etape,
        fait: null,
        total: null,
        sessionId: null,
        estimationSessionId: null,
        niveau: null,
        cible: null,
        aRenforcer: null,
        // Ce repli n'existe que quand `GET /api/me/plan` a répondu autre chose
        // qu'`ACTIVE` : par construction, le Plan n'est pas disponible.
        planDisponible: false,
        prochaineEpreuve: null,
    };
    // `planIndisponible` ne rend `null` que si le Plan existe, exclu ici.
    return planIndisponible(m, module)!;
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

/* --------------------------------------------------------------------------
   AFFINER le Plan — le diagnostic complet devient une action SECONDAIRE
   -------------------------------------------------------------------------- */

/**
 * L'invitation au diagnostic complet, sous ses **trois** formes.
 *
 * 🛑 **Le complet ne bloque jamais le Plan** (arbitrage du propriétaire,
 * 2026-09-12) : il l'affine. Cette carte se pose donc **après** le contenu
 * principal, et ne concurrence jamais le CTA d'abonnement d'un compte gratuit.
 *
 * Trois formes, décidées par des **faits servis**, jamais par un compteur
 * reconstruit :
 * - `0 / 4`, jamais commencé → « Affiner votre Plan ». 🛑 **On n'affiche pas
 *   « 0 / 4 »** : un compteur à zéro se lit comme un retard alors que rien n'a
 *   été promis.
 * - `1 / 4` à `3 / 4` → « Diagnostic complet en cours », avec sa progression,
 *   sa barre, et la prochaine épreuve **si le serveur la sert**.
 * - `4 / 4` → `null`, plus aucune invitation nulle part.
 *
 * Miroir mot pour mot de `mobile_sejourfr/lib/core/models/preparation_labels.dart`.
 */
export interface AffinerPlan {
    /** Épreuves terminées du diagnostic complet — **servi**. */
    fait: number;
    total: number;
    /** `true` dès la première épreuve terminée. */
    enCours: boolean;
    titre: string;
    texte: string;
    /** « 2 / 4 épreuves terminées ». `null` tant que rien n'est commencé. */
    progression: string | null;
    /** « Prochaine épreuve : Expression orale ». 🛑 `null` si non servie. */
    prochaineEpreuve: string | null;
    cta: string;
    href: string;
}

/**
 * Où le candidat reprend son diagnostic complet.
 *
 * 🛑 **Le hub, jamais un lancement direct.** C'est lui qui « reprend où on
 * s'est arrêté » : une épreuve terminée n'y porte plus aucun bouton, et une
 * épreuve qui démarre le fait après son avertissement (« une fois commencée,
 * elle se termine d'une traite »). Un lien profond qui lancerait la prochaine
 * épreuve sauterait cet avertissement et déclencherait un chrono par surprise.
 */
const DIAGNOSTIC_COMPLET_HREF = "/diagnostic-tcf";

export function affinerPlan(
    m: ModulePreparation,
    options: {surface: "plan" | "accueil"; abonne: boolean},
): AffinerPlan | null {
    // Pas de Plan ⇒ rien à affiner : la porte d'entrée dit déjà quoi faire.
    if (!m.planDisponible) return null;
    // 🛑 Aucun compteur servi ⇒ aucune carte. On ne fabrique pas un « 0 / 4 »
    // pour remplir un emplacement (le civique n'a qu'un diagnostic, il n'a
    // jamais rien à affiner).
    if (m.fait === null || m.total === null || m.total <= 0) return null;
    // 4 / 4 : plus aucune invitation, plus aucune progression, nulle part.
    if (m.fait >= m.total) return null;

    const enCours = m.fait > 0;
    const restant = m.total - m.fait;
    const progression = enCours
        ? `${m.fait} / ${m.total} épreuves terminées`
        : null;
    const prochaine = m.prochaineEpreuve
        ? `Prochaine épreuve : ${epreuveDuDiagnostic(m.prochaineEpreuve)}`
        : null;

    if (options.surface === "accueil") {
        // 🛑 L'Accueil ne montre le complet **que** s'il est commencé : une
        // invitation de plus sur un écran qui en porte déjà deux deviendrait du
        // bruit, et elle vit déjà sur le Plan.
        if (!enCours) return null;
        return {
            fait: m.fait,
            total: m.total,
            enCours,
            titre: "Continuez votre diagnostic complet",
            texte: `Il vous reste ${restant} épreuve${restant > 1 ? "s" : ""} pour compléter l'analyse de vos compétences.`,
            progression,
            prochaineEpreuve: prochaine,
            cta: "Continuer",
            href: DIAGNOSTIC_COMPLET_HREF,
        };
    }

    if (enCours) {
        return {
            fait: m.fait,
            total: m.total,
            enCours,
            titre: "Diagnostic complet en cours",
            texte: "Continuez votre diagnostic pour affiner progressivement votre Plan.",
            progression,
            prochaineEpreuve: prochaine,
            cta: "Continuer le diagnostic",
            href: DIAGNOSTIC_COMPLET_HREF,
        };
    }

    // Jamais commencé. Deux formulations : un compte gratuit vient de voir ce
    // qui a été détecté et doit d'abord débloquer ; un abonné utilise déjà son
    // Plan et n'a qu'à le préciser.
    return {
        fait: m.fait,
        total: m.total,
        enCours,
        titre: options.abonne ? "Rendez votre Plan encore plus précis" : "Affiner votre Plan",
        texte: options.abonne
            ? "Complétez le diagnostic complet pour analyser les autres compétences et affiner vos priorités."
            : "Votre diagnostic rapide nous a permis d'identifier vos premières priorités. Le diagnostic complet analyse vos 4 compétences pour rendre votre Plan encore plus précis.",
        progression: null,
        prochaineEpreuve: null,
        cta: "Faire le diagnostic complet",
        href: DIAGNOSTIC_COMPLET_HREF,
    };
}

/**
 * Le nom d'une épreuve du diagnostic complet.
 *
 * 🛑 **Aucune seconde table de libellés** : `planDomainLabel` est déjà
 * l'autorité, et les quatre épreuves du diagnostic sont exactement les quatre
 * domaines du Plan. Une épreuve hors de ces quatre (jamais servie ici) ne se
 * nomme pas plutôt que de se nommer faux.
 */
function epreuveDuDiagnostic(epreuve: EpreuveType): string {
    return epreuve in PLAN_DOMAIN_SECTION
        ? planDomainLabel(epreuve as PlanDomainEpreuve)
        : "";
}
