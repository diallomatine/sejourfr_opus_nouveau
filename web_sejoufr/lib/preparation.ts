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
 * ou non (`planDisponible` toujours vrai). Le diagnostic n'est plus une porte,
 * et il n'est plus proposé sur l'Accueil ni sur le Plan (2026-09-28).
 *
 * Miroir de `mobile_sejourfr/lib/core/models/preparation_labels.dart`.
 */
import {MENTION_LABEL} from "./civic-diagnostic";
import {niveauCecrlLabel} from "./types";
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
 * écrans ne l'affichent plus et n'y renvoient plus.
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
    // tout compte, diagnostic fait ou non.
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
    // 🛑 Le LIBELLÉ, jamais le code (« A1_NON_ATTEINT ») : une seule autorité.
    const niveau = niveauCecrlLabel(m.niveau);
    return m.cible ? `${niveau} → objectif ${niveauCecrlLabel(m.cible)}` : niveau;
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
   Le DIAGNOSTIC n'est plus PROPOSÉ — ni sur l'Accueil, ni sur le Plan
   (2026-09-28)
   --------------------------------------------------------------------------

   🛑 `diagnosticAAffiner`, son type `DiagnosticAAffiner` et la carte
   `DiagnosticAffinerCard` (« Affinez votre plan avec le diagnostic ») sont
   **supprimés**. Le diagnostic reste atteignable par sa route et par le lien
   « Mon diagnostic » du Plan (`PlanLinks`). Ne pas les recréer.
   -------------------------------------------------------------------------- */

/**
 * **Le diagnostic de ce module est-il fait (clos) ?** — le seul prédicat qui
 * décide d'afficher la ligne « Mon diagnostic » sous le cycle du Plan.
 *
 * 🛑 **Deux faits SERVIS, aucune déduction** : TCF → `estimationSessionId`,
 * que le serveur ne sert que si un diagnostic RAPIDE est clos ; civique →
 * `etape === "PLAN_PRET"` (diagnostic civique clos). `null` (préparation pas
 * encore lue, ou en échec) ⇒ `false` : la ligne reste masquée.
 *
 * Miroir mobile : `diagnosticFait` (`preparation_labels.dart`).
 */
export function diagnosticFait(
    m: ModulePreparation | null,
    module: "TCF" | "CIVIQUE",
): boolean {
    if (!m) return false;
    return module === "TCF" ? m.estimationSessionId !== null : m.etape === "PLAN_PRET";
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
