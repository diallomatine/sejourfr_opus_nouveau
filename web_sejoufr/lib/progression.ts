/**
 * **Les écrans de progression** (maquettes `docs/progression/maquettes-progression/`,
 * arbitrages D1–D20 du 2026-09-24) — leurs adresses, leurs mots et la mise en
 * forme des valeurs **servies**.
 *
 * 🛑 **Rien n'est classé ici.** Palier, état, bandes, écart, sens, ordinal,
 * meilleur / premier / dernier, durée fiable, seuil atteint et points manquants
 * arrivent tous servis (`GET /api/me/progression/*`,
 * `docs/regles/progression.md` § « Écrans de progression »). Ce fichier ne fait
 * que les ÉCRIRE : un nombre devient une chaîne, un enum servi devient un mot.
 *
 * 🛑 `null` = inconnu : « — », jamais `0`, jamais « A1 ». Un écart `null` ne
 * rend AUCUN marqueur (surtout pas « +0 ») ; un sens `INCONNUE` non plus.
 *
 * Miroir mobile : `mobile_sejourfr/lib/screens/progression/progression_labels.dart`.
 */
import type {BarTone} from "@/app/_components/sejour/SejourKit";
import {civicBarTone} from "./civic-diagnostic";
import type {ParcoursModule} from "./module-switch";
import {planDomainFromSlug, planDomainLabel, planDomainShort, planDomainSlug, type PlanDomainEpreuve} from "./plan-domain";
import {TCF_EPREUVES_OFFICIELLES} from "./tcf-epreuves";
import {civicThemeExamsHref, themeSlug} from "./themes";
import {CIVIC_THEME_STATE_LABEL, formatDurationSec, niveauCecrlShort} from "./types";
import type {
    CivicThemeState,
    EpreuveType,
    NiveauCecrl,
    NiveauEvolution,
    ProgressionBandeDto,
    ProgressionEchelleDto,
    ProgressionMesureDto,
    ProgressionRapport,
} from "./types";

/* --------------------------------------------------------------- adresses */

export const PROGRESSION_TCF_HREF = "/progression/tcf";
export const PROGRESSION_CIVIQUE_HREF = "/progression/civique";

/** L'écran global d'un module — l'unique forme écrite dans le web. */
export function progressionHref(module: ParcoursModule): string {
    return module === "CIVIQUE" ? PROGRESSION_CIVIQUE_HREF : PROGRESSION_TCF_HREF;
}

/** L'écran global avec l'historique complet (D8, `?tous=true`). */
export function progressionTousHref(module: ParcoursModule): string {
    return `${progressionHref(module)}?tous=true`;
}

/** Les quatre épreuves qui ont un écran : CO, CE, EE, EO. */
function epreuveDomaine(epreuve: EpreuveType): PlanDomainEpreuve | null {
    return (TCF_EPREUVES_OFFICIELLES as readonly string[]).includes(epreuve)
        ? (epreuve as PlanDomainEpreuve)
        : null;
}

/** L'écran d'une épreuve (`co|ce|ee|eo`). `null` hors des quatre. */
export function progressionEpreuveHref(epreuve: EpreuveType): string | null {
    const domaine = epreuveDomaine(epreuve);
    return domaine ? `${PROGRESSION_TCF_HREF}/${planDomainSlug(domaine)}` : null;
}

/** Le segment d'URL d'une épreuve relu en épreuve. `null` sur un inconnu. */
export function progressionEpreuveFromSlug(slug: string): PlanDomainEpreuve | null {
    return planDomainFromSlug(slug);
}

/**
 * L'écran d'un thème civique. Prend le **segment d'URL** — `themeSlug(code)`
 * quand on tient un code, l'UUID sinon —, comme toutes les routes de thème du
 * web.
 */
export function progressionThemeHref(ref: string): string {
    return `${PROGRESSION_CIVIQUE_HREF}/${ref}`;
}

/**
 * **Où mène « Voir → »** — choisi par le `rapport.kind` SERVI, jamais déduit
 * d'une route ni d'une provenance.
 *
 * `PRODUCTION` a besoin de l'épreuve (EE ou EO) pour nommer son bilan : elle
 * n'existe que sur l'écran d'une épreuve, qui la connaît. `null` = pas de lien.
 */
export function progressionRapportHref(
    rapport: {kind: ProgressionRapport; attemptId: string},
    epreuve?: EpreuveType,
): string | null {
    switch (rapport.kind) {
        case "QCM":
            return `/sessions/${rapport.attemptId}`;
        case "EXAMEN_COMPLET":
            return `/examens-blancs/tcf/${rapport.attemptId}/bilan`;
        case "PRODUCTION": {
            if (epreuve !== "TCF_EE" && epreuve !== "TCF_EO") return null;
            return `/entrainement/tcf/${planDomainSlug(epreuve)}/session/${rapport.attemptId}`;
        }
    }
}

/** Le CTA d'une épreuve : sa GRILLE d'examens, jamais un démarrage direct. */
export function progressionEpreuveCtaHref(epreuve: PlanDomainEpreuve): string {
    return `/entrainement/tcf/${planDomainSlug(epreuve)}/examens`;
}

/** Le CTA d'un thème : la grille de ses examens. */
export function progressionThemeCtaHref(code: string): string {
    return civicThemeExamsHref(themeSlug(code));
}

/** Le CTA des deux écrans globaux : la grille des examens blancs. */
export const PROGRESSION_GLOBAL_CTA_HREF = "/examens-blancs";

/* ------------------------------------------------------------ mots communs */

export const PROGRESSION_EYEBROW = "Votre progression";
export const PROGRESSION_VOIR = "Voir →";
export const PROGRESSION_LOADING = "Chargement…";
export const PROGRESSION_ERROR = "Impossible de charger votre progression.";
export const PROGRESSION_RETRY = "Réessayer";
export const PROGRESSION_SCORE_LABEL = "Score";
export const PROGRESSION_TEMPS_LABEL = "Temps";
export const PROGRESSION_VIDE = "—";
/** Revenir des « tous » aux 3 derniers (D8). */
export const PROGRESSION_LISTE_MOINS_LINK = "Afficher les 3 derniers";

/** Une épreuve sans examen blanc — le mot des écrans de suivi chiffré. */
export const PROGRESSION_SANS_EXAMEN = "Pas encore d'examen";
/** Un thème sans examen de thème (D10 : aucun repli sur un examen global). */
export const PROGRESSION_SANS_EXAMEN_THEME = "Pas encore d'examen de thème";

/* ------------------------------------------------------------ mise en forme */

/** Un score servi, tel qu'il s'écrit : entier, ou une décimale à la française. */
export function progressionNombre(n: number): string {
    return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}

/** « 422 / 499 », « 12,5 / 20 », « 29 / 40 » ; `null` ⇒ « — ». */
export function progressionScore(score: number | null, max: number): string {
    return score == null ? PROGRESSION_VIDE : `${progressionNombre(score)} / ${max}`;
}

/** La valeur seule (le gros chiffre) ; `null` ⇒ « — ». */
export function progressionValeur(score: number | null): string {
    return score == null ? PROGRESSION_VIDE : progressionNombre(score);
}

/** L'unité accolée au gros chiffre : « / 499 ». */
export function progressionUnite(max: number): string {
    return `/ ${max}`;
}

/** « 22 septembre 2026 ». */
export function progressionDateLongue(iso: string): string {
    return new Date(iso).toLocaleDateString("fr-FR", {
        day: "numeric", month: "long", year: "numeric",
    });
}

/** « 22 sept. » — l'axe de la courbe. */
export function progressionDateCourte(iso: string): string {
    return new Date(iso).toLocaleDateString("fr-FR", {day: "numeric", month: "short"});
}

/** « 22 septembre » — la date sous un meilleur score. */
export function progressionDateJour(iso: string): string {
    return new Date(iso).toLocaleDateString("fr-FR", {day: "numeric", month: "long"});
}

/** L'année seule, sous « Dernier examen ». */
export function progressionAnnee(iso: string): string {
    return String(new Date(iso).getFullYear());
}

/** La durée **fiable** servie (D9) ; `null` ⇒ « — ». */
export function progressionDuree(secondes: number | null): string {
    return secondes == null ? PROGRESSION_VIDE : formatDurationSec(secondes) || PROGRESSION_VIDE;
}

/** Un palier servi, forme courte (« <A1 » pour A1 non atteint) ; `null` ⇒ « — ». */
export function progressionPalier(niveau: NiveauCecrl | null): string {
    return niveauCecrlShort(niveau);
}

/** « Niveau B2 » — la pastille d'un palier servi. */
export function progressionNiveauPill(niveau: NiveauCecrl | null): string | null {
    return niveau ? `Niveau ${niveauCecrlShort(niveau)}` : null;
}

/** Le libellé gelé d'un état civique servi. */
export function progressionEtatLabel(etat: CivicThemeState | null): string | null {
    return etat ? CIVIC_THEME_STATE_LABEL[etat] : null;
}

/** Le ton d'un état civique servi — l'autorité existante, pas une seconde table. */
export function progressionEtatTon(etat: CivicThemeState | null): BarTone {
    return etat ? civicBarTone(etat) : "muted";
}

/* ------------------------------------------------------------- évolution */

const SENS_GLYPHE: Record<NiveauEvolution, string | null> = {
    HAUSSE: "↗",
    STABLE: "→",
    BAISSE: "↘",
    INCONNUE: null,
};

const SENS_TON: Record<NiveauEvolution, BarTone> = {
    HAUSSE: "ok",
    STABLE: "muted",
    BAISSE: "warn",
    INCONNUE: "muted",
};

/** Le ton de la pastille d'écart : il suit le SENS servi, jamais un signe. */
export function progressionSensTon(sens: NiveauEvolution): BarTone {
    return SENS_TON[sens];
}

function pointsMot(ecart: number): string {
    return Math.abs(ecart) >= 2 ? "points" : "point";
}

/**
 * « ↗ +148 points » — l'écart servi (`dernier − premier`), avec son sens servi.
 *
 * 🛑 `null` avec un seul examen ⇒ rien. `INCONNUE` ⇒ rien. Jamais « +0 ».
 */
export function progressionEcart(
    ecart: number | null,
    sens: NiveauEvolution,
    depuisLeDebut = false,
): string | null {
    const glyphe = SENS_GLYPHE[sens];
    if (ecart == null || glyphe == null) return null;
    const suffixe = depuisLeDebut ? " depuis le début" : "";
    if (sens === "STABLE") return `${glyphe} Stable${suffixe}`;
    const signe = ecart > 0 ? "+" : ecart < 0 ? "−" : "";
    return `${glyphe} ${signe}${progressionNombre(Math.abs(ecart))} ${pointsMot(ecart)}${suffixe}`;
}

/** L'évolution de PALIER des examens complets (D6) — aucun point, aucun score. */
export function progressionEvolutionPalier(sens: NiveauEvolution): string | null {
    switch (sens) {
        case "HAUSSE":
            return "↗ En hausse depuis votre premier examen complet";
        case "BAISSE":
            return "↘ En baisse depuis votre premier examen complet";
        case "STABLE":
            return "→ Stable depuis votre premier examen complet";
        case "INCONNUE":
            return null;
    }
}

/* ------------------------------------------------------------- échelle */

/** « / 499 » en bout d'axe : ce que mesure la courbe (maquette, en haut à droite). */
export function progressionEchelleNote(echelle: ProgressionEchelleDto): string {
    switch (echelle.unite) {
        case "PROGRESSION_499":
            return `Score de progression · /${echelle.max}`;
        case "NOTE_20":
            return `Note d'épreuve · /${echelle.max}`;
        case "QUESTIONS":
            return `Bonnes réponses · /${echelle.max}`;
    }
}

/** Le libellé d'une bande servie : son palier (EE/EO) ou son état (civique). */
export function progressionBandeLabel(bande: ProgressionBandeDto): string {
    if (bande.niveau) return niveauCecrlShort(bande.niveau);
    if (bande.etat) return CIVIC_THEME_STATE_LABEL[bande.etat];
    return PROGRESSION_VIDE;
}

/** « 10–20 / 20 », « 0 / 20 ». */
export function progressionBandeEtendue(bande: ProgressionBandeDto, max: number): string {
    const etendue = bande.min === bande.max ? `${bande.min}` : `${bande.min}–${bande.max}`;
    return `${etendue} / ${max}`;
}

/** Le ton d'une bande servie : l'état civique porte le sien, un palier est bleu. */
export function progressionBandeTon(bande: ProgressionBandeDto): BarTone {
    return bande.etat ? civicBarTone(bande.etat) : "now";
}

/** La phrase qui remplace la légende quand l'échelle n'a PAS de bande (D2). */
export const PROGRESSION_PORTEE_499 =
    "Score de progression : il mesure votre avancée d'un examen à l'autre. " +
    "Votre niveau se lit palier par palier, à côté de chaque examen.";

/* ----------------------------------------------------------- seuil civique */

/** Le verdict servi face au seuil : « Seuil atteint » / « Il manque 3 points ». */
export function progressionSeuilVerdict(
    mesure: ProgressionMesureDto | null,
    seuil: number | null,
): string | null {
    if (!mesure || seuil == null || mesure.seuilAtteint == null) return null;
    if (mesure.seuilAtteint) return `Seuil de réussite atteint (${seuil} / ${mesure.max})`;
    if (mesure.pointsManquants == null) return null;
    const n = mesure.pointsManquants;
    return `Il manque ${n} ${pointsMot(n)} pour le seuil de ${seuil} / ${mesure.max}`;
}

/** Le repère du seuil sur la courbe (« Seuil 16 »). */
export function progressionSeuilLabel(seuil: number | null): string | null {
    return seuil == null ? null : `Seuil ${seuil}`;
}

/** Le centre de l'anneau civique : le taux servi, écrit. */
export function progressionTaux(taux: number | null): string | null {
    return taux == null ? null : `${Math.round(taux * 100)} %`;
}

/* ---------------------------------------------------------------- compteurs */

export function progressionTermines(n: number): string {
    return n > 1 ? "terminés" : "terminé";
}

export function progressionExamensTermines(n: number): string {
    return n > 1 ? "examens blancs terminés" : "examen blanc terminé";
}

/* ======================================================================
   Écran d'une ÉPREUVE TCF (`progression_epreuve_tcf.html`)
   ====================================================================== */

export const EPREUVE_BACK_LABEL = "Progression globale";
export const EPREUVE_CTA = "Nouvel examen blanc";
export const EPREUVE_HERO_LABEL = "Dernier résultat";
export const EPREUVE_MEILLEUR_LABEL = "Meilleur score";
export const EPREUVE_NOMBRE_LABEL = "Examens réalisés";
export const EPREUVE_COURBE_TITLE = "Évolution de votre score";
export const EPREUVE_LISTE_TITLE = "Mes examens blancs";
export const EPREUVE_LISTE_SUB = "Vos résultats, du plus récent au plus ancien.";
export const EPREUVE_VIDE = "Aucun examen blanc de cette épreuve pour l'instant.";
export const EPREUVE_INTROUVABLE = "Cette épreuve est introuvable.";

export function epreuveTitre(epreuve: PlanDomainEpreuve): string {
    return planDomainLabel(epreuve);
}

export function epreuveLead(epreuve: PlanDomainEpreuve): string {
    return epreuve === "TCF_EE" || epreuve === "TCF_EO"
        ? "Suivez l'évolution de votre note sur 20 au fil de vos examens blancs."
        : "Suivez l'évolution de votre score de progression au fil de vos examens blancs.";
}

export function epreuveCourbeSub(epreuve: PlanDomainEpreuve): string {
    return `Chaque point correspond à un examen blanc de ${planDomainLabel(epreuve).toLowerCase()}.`;
}

/** D4 — le niveau de l'Accueil, en ligne secondaire. */
export function epreuveNiveauActuel(niveau: NiveauCecrl | null): string | null {
    return niveau ? `Niveau actuel estimé : ${niveauCecrlShort(niveau)}` : null;
}

/** « Niveau B2 · 22 septembre » sous le meilleur score. */
export function epreuveMeilleurSub(mesure: ProgressionMesureDto | null): string | null {
    if (!mesure) return null;
    const jour = progressionDateJour(mesure.date);
    return mesure.niveau ? `Niveau ${niveauCecrlShort(mesure.niveau)} · ${jour}` : jour;
}

/** La ligne sous le titre d'un examen : sa date, et d'où il vient (servi). */
export function epreuveExamenDate(mesure: ProgressionMesureDto): string {
    const date = progressionDateLongue(mesure.date);
    return mesure.provenance === "EXAMEN_COMPLET" ? `${date} · examen complet` : date;
}

export function examenBlancTitre(numero: number): string {
    return `Examen blanc n°${numero}`;
}

/** Le pied des épreuves notées sur 20 (D3 : l'écart note ⇄ palier est assumé). */
export const EPREUVE_NOTE_20_PORTEE =
    "La note sur 20 est celle de votre bilan. Le niveau tient compte de chaque " +
    "tâche : il peut rester en dessous de la bande de la note.";

/* ======================================================================
   Écran TCF GLOBAL (`progression_global_tcf.html`)
   ====================================================================== */

export const TCF_BACK_LABEL = "Accueil";
export const TCF_CTA = "Faire un examen blanc";
export const TCF_TITLE = "Progression globale";
export const TCF_LEAD = "Suivez l'évolution de vos résultats sur toutes les épreuves du TCF.";
export const TCF_HERO_LABEL = "Niveau global estimé";
export const TCF_STAT_NOMBRE = "Examens blancs";
export const TCF_STAT_MEILLEUR = "Meilleur résultat";
export const TCF_STAT_PREMIER = "Première évaluation";
export const TCF_STAT_DERNIER = "Dernier examen";
export const TCF_EPREUVES_TITLE = "Progression par épreuve";
export const TCF_EPREUVES_SUB = "Cliquez sur une épreuve pour voir son évolution détaillée.";
export const TCF_CARTE_SUB = "Dernier examen blanc";
export const TCF_LISTE_TITLE = "Mes derniers examens blancs";
export const TCF_LISTE_SUB = "Une vue rapide de vos résultats complets.";
export const TCF_LISTE_TOUS_TITLE = "Tous mes examens blancs";
export const TCF_LISTE_TOUS_SUB = "Vos examens blancs complets, du plus récent au plus ancien.";
export const TCF_LISTE_TOUS_LINK = "Tous mes examens blancs →";
export const TCF_LISTE_VIDE = "Aucun examen blanc complet terminé pour l'instant.";
export const TCF_HINT = "Le détail de chaque épreuve ouvre l'écran de progression dédié.";

/** « Dernier examen complet : B1 · partiel » — servi (D6, D7). */
export function tcfDernierComplet(
    niveau: NiveauCecrl | null,
    partiel: boolean,
): string | null {
    if (!niveau) return null;
    return `Dernier examen complet : ${niveauCecrlShort(niveau)}${partiel ? " · partiel" : ""}`;
}

/** Le palier global est un plancher : on dit sur combien d'épreuves il repose. */
export function tcfNiveauPartielNote(epreuves: number, partiel: boolean): string | null {
    if (!partiel) return null;
    return `Estimé sur ${epreuves} épreuve${epreuves > 1 ? "s" : ""} sur ${TCF_EPREUVES_OFFICIELLES.length}`;
}

export const TCF_NIVEAU_INCONNU_NOTE = "Passez un examen blanc pour obtenir un premier niveau.";

/** « Examen n°3 · 22 sept. 2026 » sous un palier d'examen complet. */
export function tcfExamenSub(numero: number, iso: string): string {
    const date = new Date(iso).toLocaleDateString("fr-FR", {
        day: "numeric", month: "short", year: "numeric",
    });
    return `Examen n°${numero} · ${date}`;
}

/** La ligne sous le titre d'un examen complet : date, et « partiel » servi. */
export function tcfExamenDate(iso: string, partiel: boolean, comptees: number): string {
    const date = progressionDateLongue(iso);
    return partiel
        ? `${date} · partiel (${comptees}/${TCF_EPREUVES_OFFICIELLES.length} épreuves)`
        : date;
}

/** Le repère court d'une épreuve (« CO »). */
export function tcfEpreuveMark(epreuve: EpreuveType): string {
    const domaine = epreuveDomaine(epreuve);
    return domaine ? planDomainShort(domaine) : epreuve;
}

/** Le nom d'une épreuve (« Compréhension orale »). */
export function tcfEpreuveNom(epreuve: EpreuveType): string {
    const domaine = epreuveDomaine(epreuve);
    return domaine ? planDomainLabel(domaine) : epreuve;
}

/* ======================================================================
   Écran CIVIQUE GLOBAL (`progression_global_civique.html`)
   ====================================================================== */

export const CIVIQUE_BACK_LABEL = "Accueil";
export const CIVIQUE_CTA = "Faire un examen blanc global";
export const CIVIQUE_TITLE = "Examen civique";
export const CIVIQUE_LEAD = "Suivez votre progression globale et celle de chaque thème.";
export const CIVIQUE_HERO_LABEL = "Dernier résultat global";
export const CIVIQUE_STAT_NOMBRE = "Examens globaux";
export const CIVIQUE_STAT_MEILLEUR = "Meilleur résultat";
export const CIVIQUE_STAT_PREMIER = "Premier résultat";
export const CIVIQUE_STAT_DERNIER = "Dernier examen";
export const CIVIQUE_THEMES_TITLE = "Progression par thème";
export const CIVIQUE_THEMES_SUB = "Cliquez sur un thème pour voir son évolution détaillée.";
export const CIVIQUE_CARTE_SUB = "Dernier examen du thème";
export const CIVIQUE_LISTE_TITLE = "Mes derniers examens globaux";
export const CIVIQUE_LISTE_SUB = "Vos résultats par thème : bonnes réponses sur questions posées.";
export const CIVIQUE_LISTE_TOUS_TITLE = "Tous mes examens globaux";
export const CIVIQUE_LISTE_TOUS_LINK = "Tous mes examens globaux →";
export const CIVIQUE_LISTE_VIDE = "Aucun examen civique global terminé pour l'instant.";
export const CIVIQUE_HINT = "Chaque carte thème ouvre l'écran de progression détaillée du thème.";

export function civiqueExamenTitre(numero: number): string {
    return `Examen civique global n°${numero}`;
}

/** « Global : 29 / 40 ». */
export function civiqueGlobalBadge(mesure: ProgressionMesureDto): string {
    return `Global : ${progressionScore(mesure.score, mesure.max)}`;
}

/** La part d'un thème dans un examen global (D11) : « 3 / 4 », « — » si non posé. */
export function civiquePart(bonnes: number, posees: number): string {
    return posees === 0 ? PROGRESSION_VIDE : `${bonnes} / ${posees}`;
}

/* ======================================================================
   Écran d'un THÈME civique (`progression_theme_civique.html`)
   ====================================================================== */

export const THEME_BACK_LABEL = "Examen civique";
export const THEME_CTA = "Nouvel examen blanc";
export const THEME_LEAD = "Suivez vos résultats sur ce thème précis à travers vos examens blancs.";
export const THEME_HERO_LABEL = "Dernier résultat";
export const THEME_MEILLEUR_LABEL = "Meilleur score";
export const THEME_NOMBRE_LABEL = "Examens réalisés";
export const THEME_NOMBRE_SUB = "sur ce thème";
export const THEME_COURBE_TITLE = "Évolution de votre score";
export const THEME_COURBE_SUB = "Chaque point correspond à un examen blanc sur ce thème.";
export const THEME_LISTE_TITLE = "Mes examens blancs du thème";
export const THEME_LISTE_SUB = "Vos résultats, du plus récent au plus ancien.";
export const THEME_VIDE = "Aucun examen blanc de ce thème pour l'instant.";
export const THEME_FOOT = "Cet écran suit uniquement la progression du thème sélectionné.";
export const THEME_INTROUVABLE = "Ce thème est introuvable.";

export function themeTitre(label: string): string {
    return `Thème : ${label}`;
}

export function themeExamenTitre(numero: number): string {
    return `Examen thème n°${numero}`;
}

/** « Solide · 22 septembre » sous le meilleur score d'un thème. */
export function themeMeilleurSub(mesure: ProgressionMesureDto | null): string | null {
    if (!mesure) return null;
    const jour = progressionDateJour(mesure.date);
    const etat = progressionEtatLabel(mesure.etat);
    return etat ? `${etat} · ${jour}` : jour;
}
