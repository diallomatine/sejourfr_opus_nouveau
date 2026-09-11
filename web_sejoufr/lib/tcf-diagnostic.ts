/**
 * Règles d'affichage du diagnostic TCF 4 épreuves — **pures**, déclarées une
 * fois pour tout le web.
 *
 * 🛑 Le serveur n'expose que des **faits** (état d'une section, niveau, rang
 * d'une priorité). Les phrases vivent ici, et sont des **miroirs mot pour mot**
 * de `mobile_sejourfr/lib/screens/diagnostic_tcf/tcf_diagnostic_labels.dart` :
 * un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * 🛑 Ce fichier ne **dérive** aucun état pédagogique : `etat` et `niveau`
 * arrivent servis. Il ne fait que les mettre en mots.
 */
import type {
    EpreuveType,
    NiveauCecrl,
    NiveauEvolution,
    TcfDiagnosticDto,
    TcfDiagnosticSectionDto,
    TcfDiagnosticSectionState,
    TcfReassessmentEligibilityDto,
} from "./types";

/** Titre de la page. « Diagnostic TCF », jamais « examen blanc » (`10_` §4.1). */
export const TCF_DIAGNOSTIC_TITLE = "Diagnostic TCF";
export const TCF_DIAGNOSTIC_SUBTITLE =
    "4 épreuves, à faire séparément quand vous voulez.";

/** Le résultat n'arrive qu'à la fin — c'est dit avant, pas découvert après. */
export const TCF_DIAGNOSTIC_RESULT_NOTE =
    "Votre résultat complet s'affichera une fois les 4 sections terminées.";

/**
 * Une section commencée se termine d'une traite (`10_` §4.2). L'écran le dit
 * **avant** de lancer, pas après.
 */
export const TCF_DIAGNOSTIC_SECTION_WARNING =
    "Une fois commencée, cette section se termine d'une traite.";

/** Le micro est annoncé avant l'oral, jamais demandé par surprise. */
export const TCF_DIAGNOSTIC_MIC_WARNING = "Cette section utilise votre micro.";

export const TCF_DIAGNOSTIC_ESTIMATION_NOTE =
    "Estimation SejourFR, non officielle.";

const SECTION_CTA: Record<TcfDiagnosticSectionState, string> = {
    A_FAIRE: "Commencer",
    EN_COURS: "Reprendre",
    TERMINEE: "Terminée",
};

/** Le bouton dit ce qui va se passer. */
export function sectionCtaLabel(etat: TcfDiagnosticSectionState): string {
    return SECTION_CTA[etat];
}

const SECTION_ETAT: Record<TcfDiagnosticSectionState, string> = {
    A_FAIRE: "À faire",
    EN_COURS: "En cours",
    TERMINEE: "Terminée",
};

export function sectionEtatLabel(etat: TcfDiagnosticSectionState): string {
    return SECTION_ETAT[etat];
}

/** « 2 sections sur 4 terminées ». Compté sur ce que le serveur a servi. */
export function progressionLabel(d: TcfDiagnosticDto): string {
    const faites = d.sections.filter((s) => s.etat === "TERMINEE").length;
    const total = d.sections.length;
    return `${faites} section${faites > 1 ? "s" : ""} sur ${total} terminée${
        faites > 1 ? "s" : ""
    }`;
}

/** Toutes les sections existantes sont closes ⇒ le résultat est demandable. */
export function resultatDisponible(d: TcfDiagnosticDto): boolean {
    const existantes = d.sections.filter((s) => s.attemptId !== null);
    if (existantes.length === 0) return false;
    return existantes.every((s) => s.etat === "TERMINEE");
}

/**
 * Le délai de reprise est passé.
 *
 * 🛑 **Ce n'est PAS une perte.** Les sections réalisées comptent toujours et le
 * résultat se calcule sur elles ; les autres restent « non évaluée ». Le
 * message doit le dire, jamais alarmer.
 */
export const TCF_DIAGNOSTIC_REPRISE_ECOULEE =
    "Le délai de reprise est écoulé. Nous calculerons votre résultat sur les sections terminées.";

/**
 * Une section absente du diagnostic (mode dégradé : aucun contenu disponible).
 *
 * 🛑 Le candidat ne doit **jamais** voir qu'il manque du contenu (`00_` §7.4) :
 * on la nomme « non évaluée », comme une épreuve qu'il n'a pas passée.
 */
export function sectionIndisponible(s: TcfDiagnosticSectionDto): boolean {
    return s.attemptId === null;
}

/**
 * Le niveau d'une épreuve, ou la mention **non évaluée**.
 *
 * 🛑 `null` = inconnu, jamais un palier plancher. Afficher « A1 » sur une
 * épreuve non passée serait un verdict que personne n'a rendu.
 */
export const NIVEAU_NON_EVALUE = "Non évaluée";

/** Le décompte de jours restants, calculé à l'affichage et jamais persisté. */
export function joursRestants(expiresAt: string, now: Date = new Date()): number {
    const fin = new Date(expiresAt).getTime();
    const reste = fin - now.getTime();
    return Math.max(0, Math.ceil(reste / (24 * 60 * 60 * 1000)));
}

/**
 * Où mène le bouton d'une section.
 *
 * 🛑 **Aucun écran de passation n'est créé pour le diagnostic** : les QCM vont
 * sur le runner de session existant, les productions sur la session EE/EO
 * existante. Un second parcours de passation divergerait du premier.
 */
export function sectionHref(
    epreuve: EpreuveType,
    attemptId: string,
    sessionId: string,
): string {
    const suffix = `?${TCF_DIAGNOSTIC_PARAM}=${sessionId}`;
    switch (epreuve) {
        case "TCF_CO":
        case "TCF_CE":
            return `/sessions/${attemptId}${suffix}`;
        case "TCF_EE":
            return `/entrainement/tcf/ee/session/${attemptId}${suffix}`;
        case "TCF_EO":
            return `/entrainement/tcf/eo/session/${attemptId}${suffix}`;
        default:
            return `/sessions/${attemptId}${suffix}`;
    }
}

/** Le libellé d'un niveau servi, ou la mention « non évaluée ». */
export function niveauOuNonEvalue(
    niveau: NiveauCecrl | null,
    label: (n: NiveauCecrl) => string,
): string {
    return niveau === null ? NIVEAU_NON_EVALUE : label(niveau);
}

/**
 * Le palier à afficher sur le rail A2 — B1 — B2, ou `null` quand le niveau
 * mesuré sort de cette échelle.
 *
 * 🛑 On **réutilise** `PlanLevelRail` plutôt que d'écrire une seconde jauge :
 * deux rails finiraient par ne plus se ressembler. Mais le rail ne connaît que
 * A2/B1/B2, alors que le diagnostic peut mesurer `A1_NON_ATTEINT`, `A1`, `C1`
 * ou `C2`. Dans ces cas on ne dessine **rien** plutôt que de rabattre le
 * candidat sur un palier qui n'est pas le sien.
 */
export function railLevel(niveau: NiveauCecrl | null): "A2" | "B1" | "B2" | null {
    switch (niveau) {
        case "A2":
        case "B1":
        case "B2":
            return niveau;
        default:
            return null;
    }
}

/**
 * Les trois paliers de la piste de niveau du kit (`LevelTrack`).
 *
 * 🛑 C'est l'échelle du TCF IRN telle qu'elle est **affichée**, pas une échelle
 * de classement : rien ici ne décide d'un niveau, on place un palier déjà servi.
 */
const NIVEAU_TRACK: readonly string[] = ["A2", "B1", "B2"];

/**
 * Où poser « Vous » et « Objectif » sur la piste.
 *
 * `null` — donc **aucune piste dessinée** — dès que l'un des deux paliers sort
 * de l'échelle A2/B1/B2 (`A1`, `A1_NON_ATTEINT`, `C1`, `C2`, ou aucun objectif
 * déclaré). Même règle que `railLevel` : on préfère ne rien montrer plutôt que
 * de rabattre le candidat sur un palier qui n'est pas le sien.
 */
export function levelTrackPosition(
    niveau: NiveauCecrl | null,
    cible: string | null,
): {levels: readonly string[]; currentIndex: number; goalIndex: number} | null {
    const current = railLevel(niveau);
    if (!current || !cible) return null;
    const goalIndex = NIVEAU_TRACK.indexOf(cible);
    if (goalIndex < 0) return null;
    return {levels: NIVEAU_TRACK, currentIndex: NIVEAU_TRACK.indexOf(current), goalIndex};
}

/**
 * L'épreuve est-elle déjà à la cible ?
 *
 * 🛑 **Le front ne compare pas des paliers lui-même** : le serveur sert
 * `dejaAuNiveau`, cette fonction ne fait que tester l'appartenance. Ne pas la
 * remplacer par une comparaison d'index CECRL côté client.
 */
export function estDejaAuNiveau(
    epreuve: EpreuveType,
    dejaAuNiveau: {epreuve: EpreuveType}[],
): boolean {
    return dejaAuNiveau.some((e) => e.epreuve === epreuve);
}

/**
 * **La phrase d'analyse sous le niveau global.**
 *
 * 🛑 Elle n'est pas servie, et elle ne **dérive** aucun état : chaque branche
 * se lit sur des listes que le serveur a composées (`dejaAuNiveau`,
 * `priorites`). Aucun palier n'est comparé ici, aucun nombre n'est classé.
 *
 * `null` quand rien de sûr ne peut être dit — un hero sans phrase vaut mieux
 * qu'une phrase qui affirme ce que personne n'a mesuré.
 */
export function analyseGlobale(r: {
    niveauGlobal: NiveauCecrl | null;
    cible: NiveauCecrl | null;
    dejaAuNiveau: {epreuve: EpreuveType}[];
    priorites: {epreuve: EpreuveType}[];
}): string | null {
    if (r.niveauGlobal === null) return null;
    const vise = r.cible;
    if (r.priorites.length === 0) {
        return vise
            ? `Les épreuves mesurées sont au niveau attendu pour le ${vise}. Votre plan sert maintenant à le tenir dans la durée.`
            : "Les épreuves mesurées sont au niveau attendu. Votre plan sert maintenant à le tenir dans la durée.";
    }
    if (r.dejaAuNiveau.length === 0) {
        return vise
            ? `Votre progression vers le ${vise} passe par quelques tâches précises, que votre plan prend l'une après l'autre.`
            : "Votre progression passe par quelques tâches précises, que votre plan prend l'une après l'autre.";
    }
    return vise
        ? `Vous avez déjà plusieurs acquis solides. Votre progression vers le ${vise} dépend maintenant surtout de certaines tâches.`
        : "Vous avez déjà plusieurs acquis solides. Votre progression dépend maintenant surtout de certaines tâches.";
}

/**
 * Le ton d'une évolution **servie** (`NiveauEvolution`), pour la pastille du
 * bloc de réévaluation. `null` sur `STABLE` et `INCONNUE` : rien à colorer —
 * un niveau tenu n'est ni un succès ni une alerte.
 */
export function evolutionTone(e: NiveauEvolution): "ok" | "warn" | null {
    switch (e) {
        case "HAUSSE":
            return "ok";
        case "BAISSE":
            return "warn";
        default:
            return null;
    }
}

/** Titre du bloc de conversion, contextualisé par la cible servie. */
export function blocageTitle(cible: NiveauCecrl | null): string {
    return cible
        ? `Ce qui vous empêche aujourd'hui d'atteindre ${cible}`
        : "Ce qui vous limite aujourd'hui";
}

/**
 * L'étiquette de rang d'une priorité — « Priorité 1 ».
 *
 * Séparée du titre depuis la refonte : la carte `Prio` du kit porte le rang
 * dans son kicker et l'objet de la priorité dans son titre. Une seule chaîne
 * pour les deux obligeait à couper au tiret à l'affichage.
 */
export function prioriteTag(rang: number): string {
    return `Priorité ${rang}`;
}

/** « Expression orale — Tâche 3 ». La tâche est nommée, jamais la compétence. */
export function prioriteLibelle(epreuveLabel: string, taskCode: string | null): string {
    return taskCode ? `${epreuveLabel} — Tâche ${taskCode.slice(-1)}` : epreuveLabel;
}

/**
 * **Ce que le candidat a à faire sur cette tâche, en une phrase.**
 *
 * 🛑 Le serveur ne sert **aucune** phrase de priorité : il sert l'épreuve, le
 * `taskCode` et le rang. Ces phrases sont donc des **libellés gelés**, indexés
 * par `(epreuve, taskCode)` — le couple exact que le serveur désigne — et
 * elles décrivent **la tâche officielle du TCF**, jamais la personne.
 *
 * 🛑 **Un couple absent ne rend rien.** On n'écrit pas de phrase générique pour
 * remplir la carte : le rang, l'épreuve et la tâche suffisent à dire ce qui
 * bloque. Vaut pour tout `taskCode` inconnu d'une version ultérieure du
 * référentiel.
 *
 * ⚠️ Miroir attendu côté mobile (`tcf_diagnostic_labels.dart`) : un libellé qui
 * bouge, ce sont deux fichiers dans la même passe.
 */
const PRIORITE_PHRASE: Record<string, string> = {
    // Expression écrite — les 3 tâches officielles.
    "TCF_EE:EE1": "Donner les informations attendues et écrire un message complet.",
    "TCF_EE:EE2": "Raconter et décrire avec assez de détails et de liens entre vos idées.",
    "TCF_EE:EE3": "Structurer et développer davantage vos idées.",
    // Expression orale — les 3 tâches officielles.
    "TCF_EO:EO1": "Vous présenter et répondre avec des phrases plus développées.",
    "TCF_EO:EO2": "Poser des questions plus développées et naturelles.",
    "TCF_EO:EO3": "Développer vos arguments et mieux nuancer votre opinion.",
    // Compréhension : la priorité porte sur l'épreuve, `taskCode` est nul.
    "TCF_CO:": "Suivre des documents plus longs et repérer l'implicite.",
    "TCF_CE:": "Lire des documents plus longs et repérer l'implicite.",
};

/** La phrase d'une priorité, ou `null` si le couple n'en a pas. */
export function prioritePhrase(epreuve: EpreuveType, taskCode: string | null): string | null {
    return PRIORITE_PHRASE[`${epreuve}:${taskCode ?? ""}`] ?? null;
}

/** Le bloc de rassurance : personne n'a besoin de tout retravailler. */
export const TCF_DIAGNOSTIC_RASSURANCE_TITLE =
    "Vous n'avez pas besoin de tout retravailler";
export function rassuranceText(cible: NiveauCecrl | null): string {
    return cible
        ? `Votre plan se concentrera d'abord sur les tâches qui ont le plus d'impact pour atteindre ${cible}.`
        : "Votre plan se concentrera d'abord sur les tâches qui ont le plus d'impact.";
}

export const TCF_DIAGNOSTIC_DEJA_TITLE = "Déjà au niveau attendu";
export const TCF_DIAGNOSTIC_PLAN_CTA = "Découvrir mon plan";

/** L'accueil des 4 sections. Le hub relit `current()`, il n'a pas besoin d'id. */
export const TCF_DIAGNOSTIC_HUB_HREF = "/diagnostic-tcf";

/**
 * Le paramètre que les écrans de passation reçoivent quand la section
 * appartient à un diagnostic.
 *
 * 🛑 **Sa seule fonction est le RETOUR** : une section de diagnostic ramène à
 * l'accueil des 4 sections, jamais au rapport individuel — exactement comme une
 * épreuve d'examen complet ramène à son hub. Sans ça, le candidat termine sa
 * compréhension orale et se retrouve sur un bilan de série, sans savoir qu'il
 * lui reste trois sections.
 *
 * Il ne change **rien d'autre** : ni la passation, ni la notation, ni le chrono.
 */
export const TCF_DIAGNOSTIC_PARAM = "tcfDiagnosticId";

// ----------------------------------------------------------------------------
// L7 — LA BOUCLE DE RÉÉVALUATION
//
// 🛑 **Rien ici ne décide.** `canStart`, `locked`, `daysUntilAvailable` et le
// `message` arrivent servis ; ces fonctions ne font que les mettre en mots. Ne
// jamais recompter les 14 jours depuis `lastCompletedAt` : le serveur connaît
// aussi la dérogation du Plan, que le front ne peut pas voir.
// ----------------------------------------------------------------------------

/** T11 — l'écran « Diagnostic déjà réalisé » (`30_` §5.6). */
export const TCF_DIAGNOSTIC_DEJA_FAIT_TITLE =
    "Votre diagnostic initial a déjà été réalisé";
export const TCF_DIAGNOSTIC_VOIR_CTA = "Voir mon diagnostic";
export const TCF_DIAGNOSTIC_REEVALUER_CTA = "Réévaluer mon niveau";
export const TCF_DIAGNOSTIC_DEBLOQUER_CTA = "Débloquer ma réévaluation";
export const TCF_DIAGNOSTIC_MESURER_TITLE = "Mesurer votre progression";

/**
 * « Vous l'avez passé le 12 mars. Votre niveau estimé était B1. »
 *
 * 🛑 Sans niveau mesuré, on ne l'annonce pas : `null` = non évalué, jamais A1.
 */
export function derniereMesureLine(e: TcfReassessmentEligibilityDto): string | null {
    if (!e.lastCompletedAt) return null;
    const jour = formatJourCourt(e.lastCompletedAt);
    return e.lastNiveauGlobal
        ? `Vous l'avez passé le ${jour}. Votre niveau estimé était ${e.lastNiveauGlobal}.`
        : `Vous l'avez passé le ${jour}.`;
}

/**
 * Ce que le bloc Premium promet — contextualisé par le palier réellement mesuré
 * et la cible, jamais deux paliers inventés.
 */
export function reevaluationPitch(
    e: TcfReassessmentEligibilityDto,
    cible: NiveauCecrl | null,
): string {
    if (e.lastNiveauGlobal && cible && e.lastNiveauGlobal !== cible) {
        return `Avec Premium, réévaluez votre niveau et vérifiez que vous êtes réellement passé de ${e.lastNiveauGlobal} à ${cible}.`;
    }
    return "Avec Premium, réévaluez votre niveau et mesurez votre progression.";
}

/**
 * La règle, dite au candidat. Elle est **servie** (`intervalDays`) : ce fichier
 * ne connaît pas le nombre 14, et c'est voulu.
 */
export function reevaluationRegleLine(e: TcfReassessmentEligibilityDto): string {
    return `Une réévaluation est possible tous les ${e.intervalDays} jours.`;
}

/**
 * Pourquoi la réévaluation est ouverte **avant** le délai.
 *
 * `null` quand ce n'est pas le cas : on n'invente pas une bonne nouvelle.
 */
export function declencheParLePlanLine(
    e: TcfReassessmentEligibilityDto,
): string | null {
    return e.triggeredByPlan
        ? "Vous avez terminé une priorité de votre plan : votre réévaluation est ouverte dès maintenant."
        : null;
}

/** Le symbole d'une évolution. `INCONNUE` n'en a **aucun** — rien à montrer. */
export function evolutionSymbole(e: NiveauEvolution): string | null {
    switch (e) {
        case "HAUSSE":
            return "↑";
        case "BAISSE":
            return "↓";
        case "STABLE":
            return "=";
        case "INCONNUE":
            return null;
    }
}

/**
 * « ↑ depuis A2 », « = », ou rien.
 *
 * 🛑 **`INCONNUE` ne rend jamais « = ».** L'épreuve n'était pas évaluée d'un
 * côté ou de l'autre : il n'y a pas de comparaison à annoncer, et « = » se
 * lirait « vous avez tenu votre niveau ».
 */
export function evolutionLabel(
    evolution: NiveauEvolution,
    avant: NiveauCecrl | null,
): string | null {
    switch (evolution) {
        case "HAUSSE":
            return avant ? `↑ depuis ${avant}` : "↑";
        case "BAISSE":
            return avant ? `↓ depuis ${avant}` : "↓";
        case "STABLE":
            return "=";
        case "INCONNUE":
            return null;
    }
}

/** Le titre du bloc de progression, honnête dans les trois sens. */
export function progressionTitle(evolution: NiveauEvolution): string {
    switch (evolution) {
        case "HAUSSE":
            return "Votre niveau a progressé";
        case "BAISSE":
            return "Votre niveau a baissé";
        case "STABLE":
            return "Votre niveau est stable";
        case "INCONNUE":
            return "Depuis votre dernier diagnostic";
    }
}

/** « 12 mars ». Le jour, sans heure : une date d'examen n'est pas un instant. */
export function formatJourCourt(iso: string): string {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return iso;
    const mois = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre",
    ];
    return `${d.getDate()} ${mois[d.getMonth()]}`;
}

// ----------------------------------------------------------------------------
// La MENTION d'une épreuve, et le mini-plan du rapport complet
//
// 🛑 **Rien n'est dérivé d'un niveau.** « Objectif atteint » se lit sur
// `dejaAuNiveau`, que le serveur sert ; « Prioritaire » se lit sur le rang 1 de
// `priorites`, que le serveur a classé. Le front met en mots des faits servis,
// il ne compare aucun palier — c'est l'invariant « aucun front ne classe un
// nombre en état pédagogique ».
// ----------------------------------------------------------------------------

/** Le ton d'une mention. `hot` = ce qui bloque le plus, `ok` = rien à y faire. */
export type EpreuveMentionTone = "ok" | "warn" | "hot";

export interface EpreuveMention {
    label: string;
    tone: EpreuveMentionTone;
}

/**
 * La mention affichée à côté du niveau d'une épreuve.
 *
 * 🛑 `null` quand l'épreuve n'est **pas mesurée** : la colonne de niveau dit
 * déjà « Non évaluée », et y accoler « À renforcer » serait un verdict que
 * personne n'a rendu.
 */
export function epreuveMention(
    epreuve: EpreuveType,
    niveau: NiveauCecrl | null,
    dejaAuNiveau: {epreuve: EpreuveType}[],
    priorites: {rang: number; epreuve: EpreuveType}[],
): EpreuveMention | null {
    if (niveau === null) return null;
    if (estDejaAuNiveau(epreuve, dejaAuNiveau)) {
        return {label: "Objectif atteint", tone: "ok"};
    }
    const premiere = priorites.find((p) => p.rang === 1);
    if (premiere && premiere.epreuve === epreuve) {
        return {label: "Prioritaire", tone: "hot"};
    }
    return {label: "À renforcer", tone: "warn"};
}

/** Le bloc « Votre plan est prêt » du rapport complet. */
export const TCF_DIAGNOSTIC_PLAN_PRET_TITLE = "Votre plan est prêt";

/** « Votre plan B2 est prêt » quand la cible est connue. */
export function planPretTitle(cible: NiveauCecrl | null): string {
    return cible ? `Votre plan ${cible} est prêt` : TCF_DIAGNOSTIC_PLAN_PRET_TITLE;
}

/** « EO · Tâche 3 » — la forme courte du mini-plan. */
export function prioriteCourte(epreuveCourte: string, taskCode: string | null): string {
    return taskCode ? `${epreuveCourte} · Tâche ${taskCode.slice(-1)}` : epreuveCourte;
}

/** La pastille d'une ligne du mini-plan : le rang 1 est le seul « Prioritaire ». */
export function prioritePastille(rang: number): EpreuveMention {
    return rang === 1
        ? {label: "Prioritaire", tone: "hot"}
        : {label: "À renforcer", tone: "warn"};
}

/**
 * « 4 compétences ciblées détectées dans vos réponses ».
 *
 * 🛑 Le nombre est **servi** (`tachesSousLaCible`), non plafonné, et `0` rend
 * `null` : on n'annonce jamais un compteur vide, et on ne le recalcule pas sur
 * la liste des priorités, bornée à trois.
 */
export function competencesCibleesLine(taches: number): string | null {
    if (taches <= 0) return null;
    return `${taches} compétence${taches > 1 ? "s" : ""} ciblée${taches > 1 ? "s" : ""} `
        + `détectée${taches > 1 ? "s" : ""} dans vos réponses`;
}
