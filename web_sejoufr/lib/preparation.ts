/**
 * Les phrases de « Ma préparation » — **pures**, déclarées une fois pour tout
 * le web.
 *
 * 🛑 **Le serveur sert l'ÉTAPE, ce fichier sert la PHRASE.** C'est la même
 * discipline que partout ailleurs : « Faire mon diagnostic » est une
 * formulation, pas une donnée.
 *
 * 🛑 **Un seul état pour tous les écrans.** L'Accueil, le Plan et Réviser
 * lisent `userContentApi.preparation()` et passent par ces fonctions. Aucun
 * écran ne déduit son propre libellé — c'est ce qui garantit qu'ils proposent
 * la même chose.
 *
 * 🛑 **D-69 (2026-09-28) : le Plan existe pour TOUT compte**, diagnostic fait
 * ou non (`planDisponible` toujours vrai). Le diagnostic n'est plus une porte :
 * c'est une proposition SECONDAIRE, `diagnosticAAffiner`.
 *
 * Miroir de `mobile_sejourfr/lib/core/models/preparation_labels.dart`.
 */
import {MENTION_LABEL} from "./civic-diagnostic";
import type {ModulePreparation, PreparationDto, TargetProcedure} from "./types";

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

/**
 * **Le marqueur « lance-le tout de suite »** de `/diagnostic`.
 *
 * 🛑 Demande du propriétaire (2026-09-12) : « Faire mon diagnostic », depuis le
 * Plan ou l'Accueil, doit **lancer** le diagnostic, pas ouvrir une page qui
 * redemande de le lancer. Le bouton porte déjà la décision.
 *
 * 🛑 **Un marqueur, aucun identifiant.** La présentation reste l'écran normal
 * de `/diagnostic` — elle garde tout son sens pour qui y arrive sans l'avoir
 * demandé (lien profond, visiteur, où elle porte aussi le choix TCF / civique).
 *
 * Miroir de `kDiagnosticDemarrageDirect`
 * (`mobile_sejourfr/lib/core/models/preparation_labels.dart`).
 */
export const DIAGNOSTIC_START_PARAM = "demarrer";

/** L'adresse qui démarre le diagnostic sans présentation. */
export const DIAGNOSTIC_RAPIDE_START_HREF =
    `${DIAGNOSTIC_RAPIDE_HREF}?${DIAGNOSTIC_START_PARAM}=1`;

/** Le marqueur est-il posé ? Lu par l'écran, jamais deviné. */
export function demarrageDirectDemande(
    params: {get(name: string): string | null} | null | undefined,
): boolean {
    return params?.get(DIAGNOSTIC_START_PARAM) === "1";
}

/*
 * 🛑 **Le diagnostic COMPLET (4 épreuves) n'est plus un parcours proposé**
 * (décision du propriétaire, 2026-09-26). `DIAGNOSTIC_COMPLET_HREF` et ses deux
 * CTA (« Faire le diagnostic complet » / « Continuer le diagnostic ») sont
 * supprimés, avec l'écran `/diagnostic-tcf` (redirigé vers le Plan TCF par
 * `next.config.ts`). Le rapide ouvre le Plan ; les épreuves qu'il ne mesure pas
 * se mesurent par l'examen blanc que le Plan propose. Ne pas les recréer.
 *
 * ⚠️ Le serveur sert ENCORE l'avancement d'un complet commencé avant le retrait
 * (`etape: DIAGNOSTIC_EN_COURS`, `fait`/`total` sur 4, `prochaineEpreuve`) : ces
 * écrans ne l'affichent plus et n'y renvoient plus (voir `diagnosticAAffiner`).
 */

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
    // 🛑 **Le Plan est TOUJOURS la prochaine action** (D-69) : il existe pour
    // tout compte, diagnostic fait ou non. Le diagnostic se propose à part
    // (`diagnosticAAffiner`), jamais à sa place.
    return {statut: tcfStatut(m), cta: "Continuer mon plan", href: "/plan"};
}

/**
 * Ce qu'on sait du candidat.
 *
 * 🛑 **Aucun compteur « N / 4 »** : il décrivait l'avancement du diagnostic
 * complet, parcours retiré le 2026-09-26. Le palier mesuré prime dès qu'il est
 * servi, et `null` veut dire « pas encore mesuré », jamais A1.
 */
function tcfStatut(m: ModulePreparation): string {
    return niveauLine(m)
        ?? (m.estimationSessionId ? "Première estimation terminée" : "Diagnostic non réalisé");
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
    // 🛑 **Le Plan civique existe pour tout compte** (D-69) : c'est lui la
    // prochaine action, quelle que soit l'étape. Seul l'état change.
    return {statut: civiqueStatut(m), cta: "Continuer mon plan", href: "/plan?module=CIVIQUE"};
}

function civiqueStatut(m: ModulePreparation): string {
    switch (m.etape) {
        case "DIAGNOSTIC_EN_COURS":
            return m.fait !== null && m.total !== null
                ? `Diagnostic : ${m.fait} / ${m.total} questions`
                : "Diagnostic en cours";
        case "PLAN_PRET":
            return aRenforcerLine(m) ?? "Diagnostic terminé";
        // 🛑 `ESTIMATION_FAITE` n'existe pas côté civique — il n'a qu'UN
        // diagnostic. Ce cas est ici parce que le type est partagé.
        case "ESTIMATION_FAITE":
        case "DIAGNOSTIC_A_FAIRE":
            return "Diagnostic non réalisé";
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
   Le DIAGNOSTIC — une proposition SECONDAIRE (D-69, 2026-09-28)
   -------------------------------------------------------------------------- */

/** La proposition d'affiner le Plan par le diagnostic. */
export interface DiagnosticAAffiner {
    titre: string;
    texte: string;
    cta: string;
    href: string;
}

const AFFINER_TERMINER = "Terminez-le pour affiner votre plan.";

/**
 * Le diagnostic reste-t-il à proposer pour ce module ?
 *
 * 🛑 **Une proposition, jamais une porte** (D-69) : le Plan existe sans
 * diagnostic, et cette carte se pose SOUS « À faire maintenant », jamais à sa
 * place ni avec le CTA rouge. `null` = rien à proposer.
 *
 * 🛑 **Seule autorité** de ces phrases sur le web — Plan TCF, Plan civique et
 * Accueil l'appellent tous. Miroir de `mobile_sejourfr/lib/core/models/preparation_labels.dart`.
 */
export function diagnosticAAffiner(
    m: ModulePreparation,
    module: "TCF" | "CIVIQUE",
): DiagnosticAAffiner | null {
    if (module === "CIVIQUE") {
        const titre = "Affinez votre plan avec le diagnostic civique";
        const href = "/diagnostic-civique";
        if (m.etape === "DIAGNOSTIC_A_FAIRE") {
            return {
                titre,
                texte: "Quelques questions pour repérer les thèmes et les notions à travailler en priorité.",
                cta: "Affiner avec le diagnostic civique",
                href,
            };
        }
        // 🛑 **Un diagnostic COMMENCÉ ne se « fait » pas, il se REPREND.**
        if (m.etape === "DIAGNOSTIC_EN_COURS") {
            return {
                titre,
                texte: avancement(m) ?? AFFINER_TERMINER,
                cta: "Reprendre mon diagnostic civique",
                href,
            };
        }
        return null;
    }

    const titre = "Affinez votre plan avec le diagnostic";
    if (m.etape === "DIAGNOSTIC_A_FAIRE") {
        return {
            titre,
            texte:
                "En quelques minutes, une production écrite repère vos premières priorités. Vos examens blancs restent la base de votre plan.",
            cta: "Affiner avec le diagnostic",
            href: DIAGNOSTIC_RAPIDE_START_HREF,
        };
    }
    /* 🛑 Seul le **rapide** se reprend (`fait === null`). Un complet commencé
       avant son retrait (`fait !== null`) ne se reprend plus (2026-09-26). */
    if (m.etape === "DIAGNOSTIC_EN_COURS" && m.fait === null) {
        return {
            titre,
            texte: AFFINER_TERMINER,
            cta: "Reprendre mon diagnostic",
            href: DIAGNOSTIC_RAPIDE_START_HREF,
        };
    }
    return null;
}

/**
 * « Vous avez répondu à 14 questions sur 40. » — l'avancement du diagnostic
 * CIVIQUE, seul lecteur depuis le retrait du complet TCF (2026-09-26).
 *
 * 🛑 `null` quand le serveur n'a pas servi d'avancement : on ne fabrique pas un
 * compteur pour remplir une phrase.
 */
function avancement(m: ModulePreparation): string | null {
    if (m.fait === null || m.total === null) return null;
    return `Vous avez répondu à ${m.fait} question${m.fait > 1 ? "s" : ""} sur ${m.total}.`;
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
   AFFINER le Plan — SUPPRIMÉ le 2026-09-19
   --------------------------------------------------------------------------

   🛑 `affinerPlan()`, son type `AffinerPlan` et `AffinerPlanCard` sont
   **supprimés** : la carte « Continuez votre diagnostic complet » a quitté le
   Plan le 2026-09-19, puis l'Accueil dans la même journée (arbitrage du
   propriétaire), et plus rien ne les lisait. Ne pas les recréer — le parcours
   du diagnostic complet lui-même est retiré des fronts depuis le 2026-09-26.

   ⚠️ Conséquence à connaître : `ModulePreparation.prochaineEpreuve` n'a plus de
   lecteur front. Le champ **reste servi** — on ne touche pas au backend.
   -------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------
   La DÉMARCHE visée, dite au candidat
   -------------------------------------------------------------------------- */

/**
 * « Objectif : naturalisation ».
 *
 * 🛑 **Une seule table de démarches sur le web** : `MENTION_LABEL`
 * (`lib/civic-diagnostic.ts`). Cette phrase-ci était écrite en dur dans
 * `AppSidebar`, et l'Accueil allait en poser une deuxième copie sous son
 * « Bonjour » — deux copies d'un libellé de démarche finissent toujours par
 * diverger (c'est exactement ce qui est arrivé à la table des paliers).
 *
 * `null` / démarche inconnue ⇒ l'invitation à la choisir, jamais une démarche
 * par défaut : `null = inconnu, jamais mauvais`.
 */
export function objectifLabel(procedure: TargetProcedure | null | undefined): string {
    const mention = procedure ? MENTION_LABEL[procedure] : undefined;
    return mention ? `Objectif : ${mention.toLowerCase()}` : "Choisir mon parcours";
}
