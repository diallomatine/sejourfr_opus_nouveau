/**
 * Les **mots** de l'écran Progrès (T28, `30_` §7) — **purs**, déclarés une fois
 * pour tout le web.
 *
 * 🛑 **Le serveur n'expose que des faits** : un palier, un sens d'évolution, un
 * compte de jours. Les phrases vivent ici, et sont des **miroirs mot pour mot**
 * de `mobile_sejourfr/lib/screens/progres/progres_labels.dart`.
 *
 * 🛑 **Deux règles de la spec que ce fichier fait respecter**, et qui sont plus
 * faciles à violer qu'à tenir :
 *
 * - **aucun pourcentage de progression vers un palier.** Un palier CECRL n'est
 *   pas une barre : « 68 % vers le B2 » n'a aucun sens mesurable et se lit
 *   pourtant comme une promesse ;
 * - **aucune gamification.** L'activité se dit en jours travaillés, sans record
 *   à battre et sans rien à perdre. Un compteur qu'on peut casser transforme
 *   une mesure en dette.
 */
import type {BarTone} from "@/app/_components/sejour/SejourKit";
import {niveauCecrlLabel, niveauCecrlShort} from "./types";
import type {
    NiveauEvolution,
    ProgressActiviteDto,
    ProgressCiviqueDto,
    ProgressCompetencesDto,
    ProgressEpreuveDto,
    ProgressTcfDto,
    StatutObjectif,
} from "./types";

export const PROGRES_TITLE = "Ce qui a bougé";
export const PROGRES_LEAD =
    "Votre mouvement depuis votre diagnostic — pas un tableau de bord.";

/** Bloc 1 — le niveau. */
export const PROGRES_NIVEAU_TITLE = "Votre niveau";

/** Bloc 2 — par épreuve. */
export const PROGRES_EPREUVES_TITLE = "Par épreuve";

/** Bloc 3 — les compétences. */
export const PROGRES_COMPETENCES_TITLE = "Vos compétences";
export const PROGRES_COMPETENCES_LOCKED =
    "Le détail de vos compétences tenues fait partie de l'abonnement. "
    + "Vos compteurs, eux, restent les vôtres.";

/** Bloc 4 — l'activité. */
export const PROGRES_ACTIVITE_TITLE = "Votre activité";

/** Bloc 5 — l'historique. 🛑 Un LIEN, pas une seconde liste. */
export const PROGRES_HISTORIQUE_TITLE = "Vos rapports";
export const PROGRES_HISTORIQUE_TEXT =
    "Vos examens et vos productions restent consultables.";

export const PROGRES_CIVIQUE_TITLE = "Examen civique";

/**
 * Le détail par thème du civique.
 *
 * 🛑 Le libellé d'un état vient de `CIVIC_THEME_STATE_LABEL` et son ton de
 * `kitTone` (`lib/civic-diagnostic.ts`) : ce sont les **autorités déjà en
 * place** pour cet enum, employées aussi par le Plan et le rapport de
 * diagnostic. Une seconde table finirait par nommer autrement le même état.
 */
export const PROGRES_CIVIQUE_THEMES_TITLE = "Par thème";

/** État vide (`30_` §7). */
export const PROGRES_VIDE_TEXT =
    "Votre progression s'affichera après votre premier diagnostic.";

/**
 * L'écran a-t-il **vraiment** l'écran vide ?
 *
 * 🛑 **Ce n'est plus `!tcf.disponible && !civique.disponible`** (2026-09-16) :
 * depuis que les 4 épreuves sont servies indépendamment du diagnostic
 * 4 épreuves, un candidat dont la CO est mesurée par un examen de module a de
 * quoi remplir le bloc « Par épreuve ». Garder l'ancienne condition aurait
 * affiché « votre progression s'affichera après votre premier diagnostic »
 * juste au-dessus de sa progression.
 *
 * 🛑 **Rien n'est classé ici** : on lit trois faits servis — deux booléens et
 * la présence d'un palier.
 */
export function progresEcranVide(
    tcf: ProgressTcfDto,
    civique: ProgressCiviqueDto,
): boolean {
    return !tcf.disponible
        && !civique.disponible
        && tcf.epreuves.every((e) => e.niveau === null);
}

/**
 * Le niveau et son objectif. 🛑 **Aucun pourcentage** : on nomme deux paliers,
 * on ne trace pas une barre entre eux.
 *
 * `null` quand rien n'est mesuré — « — » se suffit, et « inconnu » ne se dit
 * jamais « &lt; A1 ».
 */
export function progresNiveauLabel(tcf: ProgressTcfDto): string | null {
    if (!tcf.niveauActuel) return null;
    const actuel = niveauCecrlLabel(tcf.niveauActuel);
    return tcf.objectif ? `${actuel} → objectif ${niveauCecrlLabel(tcf.objectif)}` : actuel;
}

/**
 * Le marqueur d'évolution d'une épreuve.
 *
 * 🛑 **`INCONNUE` ne rend rien** — surtout pas « = ». Une épreuve non comparable
 * n'a ni progressé ni tenu, et lui donner le signe de la stabilité déguiserait
 * une absence de mesure en bonne nouvelle.
 *
 * 🛑 **`BAISSE` se dit.** La masquer rendrait la mesure de progression
 * invendable : c'est précisément ce qu'une réévaluation promet de mesurer.
 */
export function progresEvolutionLabel(epreuve: ProgressEpreuveDto): string | null {
    switch (epreuve.evolution) {
        case "HAUSSE":
            return epreuve.niveauInitial
                ? `↑ depuis ${niveauCecrlLabel(epreuve.niveauInitial)}`
                : "↑";
        case "BAISSE":
            return epreuve.niveauInitial
                ? `↓ depuis ${niveauCecrlLabel(epreuve.niveauInitial)}`
                : "↓";
        case "STABLE":
            return "=";
        case "INCONNUE":
            return null;
    }
}

/** Le ton du marqueur. `INCONNUE` et `STABLE` restent **neutres**. */
export function progresEvolutionTone(
    evolution: NiveauEvolution,
): "up" | "down" | "flat" {
    if (evolution === "HAUSSE") return "up";
    if (evolution === "BAISSE") return "down";
    return "flat";
}

/** « B2 » ou « Non évaluée ». 🛑 Jamais « A1 » pour une absence de mesure. */
export function progresEpreuveNiveau(epreuve: ProgressEpreuveDto): string {
    return epreuve.niveau ? niveauCecrlLabel(epreuve.niveau) : "Non évaluée";
}

/**
 * Libellés **gelés** du statut d'une épreuve face à l'objectif (spec V2 §2),
 * miroirs mot pour mot de `kProgresStatutLabel` côté mobile.
 *
 * 🛑 Le statut est **servi** : ce fichier ne fait que poser un mot dessus. Aucun
 * front ne compare deux paliers CECRL.
 */
const PROGRES_STATUT_LABEL: Record<StatutObjectif, string> = {
    TARGET_REACHED: "Objectif atteint",
    CLOSE_TO_TARGET: "Proche de l'objectif",
    TO_REINFORCE: "À renforcer",
};

/**
 * Le statut d'une épreuve, dit au candidat.
 *
 * 🛑 **Une épreuve jamais mesurée ne se dit PAS « à renforcer »** : le serveur
 * la range bien dans `TO_REINFORCE`, mais son `niveau` vaut `null` et c'est ce
 * qu'il faut lire — « À évaluer ». Fondre les deux cas dans le même mot
 * rejouerait l'incident V040/V041/V042, où une absence de mesure était devenue
 * un verdict.
 *
 * `null` quand aucune démarche n'est déclarée : sans objectif, rien à situer.
 */
export function progresStatutLabel(epreuve: ProgressEpreuveDto): string | null {
    if (!epreuve.status) return null;
    if (!epreuve.niveau) return NON_MESURE_LABEL;
    return PROGRES_STATUT_LABEL[epreuve.status];
}

/**
 * Le mot d'une chose **jamais mesurée** — épreuve sans palier, thème civique
 * `NON_EVALUE`.
 *
 * 🛑 **Un seul endroit** : il vit sur la pastille d'une carte d'accueil, sur le
 * statut d'une épreuve de Progrès et sur les thèmes civiques. Recopié, il
 * finirait par diverger d'une surface à l'autre — et c'est le mot qui empêche
 * une absence de mesure de se lire comme un verdict (V040/V041/V042). Miroir
 * mobile : `kNonMesureLabel`.
 */
export const NON_MESURE_LABEL = "À évaluer";

/** Le ton du statut. `null` (jamais mesuré, ou sans objectif) reste **neutre**. */
export function progresStatutTone(
    epreuve: ProgressEpreuveDto,
): "ok" | "warn" | "hot" | "muted" {
    if (!epreuve.status || !epreuve.niveau) return "muted";
    if (epreuve.status === "TARGET_REACHED") return "ok";
    if (epreuve.status === "CLOSE_TO_TARGET") return "warn";
    return "hot";
}

/* ---------------------------------------------------------------------------
 * « Où vous en êtes » — la carte compacte d'une épreuve sur l'ACCUEIL
 * ------------------------------------------------------------------------- */

/**
 * 🛑 **Une seule dérivation pour les deux écrans.** Progrès dit « où vous en
 * êtes face à l'objectif » ; l'Accueil dit la même chose **plus ce qu'il faut
 * faire**. Deux tables auraient fini par nommer différemment le même statut
 * servi, sur deux écrans que le candidat voit dans la même minute — c'est le
 * défaut le plus cher du dépôt.
 *
 * 🛑 **Rien n'est classé ici.** Les deux seuls faits lus sont **servis** :
 * `status` (dérivé par `StatutObjectifResolver`) et `evolution` (dérivé par
 * `TcfDiagnosticProgressionResolver`). Aucun nombre n'entre, aucun palier n'est
 * comparé à un autre.
 *
 * 🛑 **Miroir mot pour mot de `AccueilEpreuveEtat` côté mobile**
 * (`screens/progres/progres_labels.dart`).
 */
export type AccueilEpreuveEtat =
    /**
     * Jamais mesurée. 🛑 Elle ne se dit **jamais** « à renforcer » : le serveur
     * la range bien dans `TO_REINFORCE`, mais son niveau vaut `null` et c'est
     * ce qu'il faut lire (V040/V041/V042).
     */
    | "A_EVALUER"
    /**
     * Mesurée, et le palier a **monté** depuis la première mesure. 🛑 Ce cas
     * passe **avant** le statut : dire « à renforcer » à quelqu'un qui vient de
     * progresser lui cache la seule bonne nouvelle qu'il a.
     */
    | "EN_PROGRESSION"
    /** Au niveau visé, ou au-dessus. */
    | "SOLIDE"
    /** Un cran sous l'objectif. */
    | "PROCHE"
    /** Mesurée, et loin de l'objectif. */
    | "A_RENFORCER"
    /** Mesurée, mais aucune démarche déclarée : rien vers quoi situer. */
    | "SANS_OBJECTIF";

/** L'état d'une épreuve **sur l'Accueil**, dans l'ordre où il se décide. */
export function accueilEpreuveEtat(epreuve: ProgressEpreuveDto): AccueilEpreuveEtat {
    if (!epreuve.niveau) return "A_EVALUER";
    if (epreuve.evolution === "HAUSSE") return "EN_PROGRESSION";
    if (!epreuve.status) return "SANS_OBJECTIF";
    if (epreuve.status === "TARGET_REACHED") return "SOLIDE";
    if (epreuve.status === "CLOSE_TO_TARGET") return "PROCHE";
    return "A_RENFORCER";
}

/**
 * La phrase courte de la carte. `null` = rien à dire, pas « rien à faire ».
 *
 * 🛑 `PROCHE` et `A_RENFORCER` reprennent **les libellés gelés** de
 * `PROGRES_STATUT_LABEL` : même statut servi, même mot, d'un écran à l'autre.
 */
export function accueilEpreuveStatut(epreuve: ProgressEpreuveDto): string | null {
    switch (accueilEpreuveEtat(epreuve)) {
        case "A_EVALUER":
            return "Pas encore évaluée";
        case "EN_PROGRESSION":
            return "En progression";
        case "SOLIDE":
            return "Solide · à maintenir";
        case "PROCHE":
            return PROGRES_STATUT_LABEL.CLOSE_TO_TARGET;
        case "A_RENFORCER":
            return PROGRES_STATUT_LABEL.TO_REINFORCE;
        case "SANS_OBJECTIF":
            return null;
    }
}

/**
 * La pastille de niveau. « À évaluer » quand rien n'a été mesuré.
 *
 * 🛑 `niveauCecrlShort` et jamais un troncage maison : `A1_NON_ATTEINT` se rend
 * « &lt;A1 », pas « A1 ».
 */
export function accueilEpreuveBadge(epreuve: ProgressEpreuveDto): string {
    return epreuve.niveau ? niveauCecrlShort(epreuve.niveau) : NON_MESURE_LABEL;
}

/**
 * Ce que la carte propose de faire.
 *
 * 🛑 **Dérivé de l'état, jamais un texte fixe** : une épreuve jamais mesurée ne
 * propose pas de « voir » des résultats qui n'existent pas, et une épreuve qui
 * monte propose de continuer plutôt que de relire.
 */
export function accueilEpreuveCta(epreuve: ProgressEpreuveDto): string {
    const etat = accueilEpreuveEtat(epreuve);
    if (etat === "A_EVALUER") return "Faire un exercice";
    if (etat === "EN_PROGRESSION") return "Continuer";
    return "Voir mes résultats";
}

/**
 * La carte mène-t-elle à un **exercice** plutôt qu'aux résultats ?
 *
 * 🛑 Le chemin d'un exercice est celui du Plan, jamais un second : c'est la
 * fiche du domaine qui porte les lanceurs.
 */
export function accueilEpreuveOuvreLExercice(epreuve: ProgressEpreuveDto): boolean {
    const etat = accueilEpreuveEtat(epreuve);
    return etat === "A_EVALUER" || etat === "EN_PROGRESSION";
}

/** Le ton de la jauge et du statut. */
export function accueilEpreuveTon(epreuve: ProgressEpreuveDto): BarTone {
    switch (accueilEpreuveEtat(epreuve)) {
        case "A_EVALUER":
        case "SANS_OBJECTIF":
            return "muted";
        case "EN_PROGRESSION":
            return "now";
        case "SOLIDE":
            return "ok";
        case "PROCHE":
            return "warn";
        case "A_RENFORCER":
            return "hot";
    }
}

/**
 * Le remplissage de la jauge.
 *
 * 🛑 **Ce n'est PAS un pourcentage de progression vers un palier** — la règle
 * qui l'interdit (`30_` §7) tient toujours, et aucun chiffre n'est affiché.
 * C'est le **codage visuel d'un état servi**, à cinq positions fixes : la barre
 * dit la même chose que le mot juste en dessous, elle ne mesure rien de plus.
 * Un palier CECRL n'est toujours pas une barre.
 */
export function accueilEpreuveJauge(epreuve: ProgressEpreuveDto): number {
    switch (accueilEpreuveEtat(epreuve)) {
        case "A_EVALUER":
        case "SANS_OBJECTIF":
            return 0;
        case "A_RENFORCER":
            return 0.35;
        case "EN_PROGRESSION":
            return 0.55;
        case "PROCHE":
            return 0.75;
        case "SOLIDE":
            return 1;
    }
}

/**
 * « 4 compétences maîtrisées sur 11 travaillées ».
 *
 * `null` quand rien n'a jamais été observé : « 0 sur 0 » ne dit rien.
 */
export function progresCompetencesLabel(
    competences: ProgressCompetencesDto,
): string | null {
    if (competences.travaillees <= 0) return null;
    const m = competences.maitrisees;
    return `${m} compétence${m > 1 ? "s" : ""} maîtrisée${m > 1 ? "s" : ""} `
        + `sur ${competences.travaillees} travaillée${competences.travaillees > 1 ? "s" : ""}`;
}

/**
 * « 12 jours travaillés sur les 28 derniers ».
 *
 * 🛑 La fenêtre vient du **serveur** : aucun écran n'écrit « 30 » en dur, donc
 * aucun ne peut mentir sur ce qu'il compte.
 */
export function progresActiviteLabel(activite: ProgressActiviteDto): string {
    const j = activite.joursActifs;
    return `${j} jour${j > 1 ? "s" : ""} travaillé${j > 1 ? "s" : ""} `
        + `sur les ${activite.fenetreJours} derniers`;
}

/**
 * La régularité, dite sans jugement : combien de semaines portent au moins une
 * séance. 🛑 Ni objectif, ni série à tenir — c'est un constat.
 */
export function progresRegulariteLabel(activite: ProgressActiviteDto): string | null {
    const actives = activite.semaines.filter((s) => s.jours > 0).length;
    if (activite.semaines.length === 0) return null;
    if (actives === 0) return null;
    return `${actives} semaine${actives > 1 ? "s" : ""} sur ${activite.semaines.length} `
        + "avec au moins une séance";
}

/**
 * « 3 notions tenues sur 12 travaillées », ou « thèmes » tant que le tagging
 * n'a pas basculé.
 *
 * 🛑 L'écran **nomme** ce qu'il compte : le plan civique ne se dit jamais plus
 * précis qu'il ne l'est.
 */
export function progresCiviqueLabel(civique: ProgressCiviqueDto): string | null {
    if (civique.travaillees <= 0) return null;
    const nom = civique.grainNotion ? "notion" : "thème";
    const m = civique.maitrisees;
    return `${m} ${nom}${m > 1 ? "s" : ""} tenu${m > 1 ? "s" : ""} `
        + `sur ${civique.travaillees} travaillé${civique.travaillees > 1 ? "s" : ""}`;
}

/** Le dernier score civique, comparable au seuil. `null` s'il n'y en a aucun. */
export function progresCiviqueScore(civique: ProgressCiviqueDto): string | null {
    const dernier = civique.historique.at(-1);
    if (!dernier) return null;
    return `${dernier.bonnes} / ${dernier.posees} · seuil ${dernier.seuil} / ${dernier.format}`;
}

/** Où mènent les rapports (bloc 5). 🛑 L'existant, jamais une seconde liste. */
export const PROGRES_HISTORIQUE_HREF = "/historique";
