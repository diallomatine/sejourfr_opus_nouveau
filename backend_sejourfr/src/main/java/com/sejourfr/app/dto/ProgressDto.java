package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.enums.StatutObjectif;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * <b>« Où vous en êtes »</b> — ce que l'<b>Accueil</b> lit de la progression
 * ({@code GET /api/me/progress}).
 *
 * <p>🛑 <b>Élagué le 2026-09-24</b> (demande du propriétaire : l'espace
 * Progression ne contient plus que les 4 maquettes). L'ancien écran
 * « Votre progression » ({@code /statistiques} ⇄ {@code ProgresScreen}) lisait
 * ici l'activité sur 30 jours, la courbe des diagnostics TCF, le palier global,
 * les compteurs de compétences et les compteurs civiques : ces champs n'avaient
 * <b>aucun autre lecteur</b> et sont supprimés avec lui. Les écrans de
 * progression lisent désormais {@code /api/me/progression/*}.
 *
 * <h2>Ce que ce DTO refuse de servir</h2>
 * <ul>
 *   <li>🛑 <b>Aucun pourcentage de progression vers un niveau</b> ({@code 30_}
 *       §7, règle explicite). On sert des <b>paliers</b> et des <b>sens
 *       d'évolution</b>.</li>
 * </ul>
 */
public record ProgressDto(
        Tcf tcf,
        Civique civique
) {

    /**
     * Le côté <b>TCF</b> de l'Accueil.
     *
     * @param objectif      le palier visé, ou {@code null} si aucune démarche
     *                      n'est déclarée — on ne devine jamais à la place du
     *                      candidat
     * @param epreuves      les 4 épreuves, <b>toutes</b>, évaluées ou non
     */
    public record Tcf(
            NiveauCecrl objectif,
            List<Epreuve> epreuves
    ) {
    }

    /**
     * Une épreuve, son palier d'aujourd'hui et ce qui a bougé.
     *
     * @param niveau        le palier <b>actuel</b> (meilleur résultat, toutes
     *                      sources). {@code null} = jamais évaluée
     * @param niveauInitial le palier au <b>premier</b> diagnostic clos
     * @param evolution     🛑 {@code INCONNUE} n'est <b>pas</b> {@code STABLE} :
     *                      une épreuve non évaluée d'un côté n'a ni progressé ni
     *                      tenu. Et {@code BAISSE} existe et se sert
     * @param status        où en est cette épreuve <b>par rapport à
     *                      l'objectif</b> ({@code StatutObjectifResolver}, spec
     *                      V2 §2). 🛑 {@code null} quand aucune démarche n'est
     *                      déclarée — sans palier exigé, il n'y a rien à
     *                      comparer. 🛑 {@code TO_REINFORCE} couvre aussi
     *                      l'épreuve <b>jamais mesurée</b> : c'est
     *                      {@code niveau == null} qui distingue les deux, et un
     *                      écran doit lire les deux
     * @param evaluation    <b>par quoi mesurer cette épreuve</b>, quand elle ne
     *                      l'a <b>jamais</b> été ({@code niveau == null}).
     *                      {@code null} dès qu'un palier existe : il n'y a plus
     *                      rien à lancer, et proposer une mesure qui existe
     *                      déjà serait faux.
     *                      <p>🛑 <b>Même descripteur que « Compléter mon
     *                      profil » et que la ligne {@code A_EVALUER} de la
     *                      séance</b> — {@code PlanDomainAssessmentResolver} en
     *                      reste l'unique autorité, et les fronts le lancent
     *                      par le lanceur qu'ils ont déjà. Aucun mécanisme
     *                      nouveau, aucune 5ᵉ porte : c'est un point d'appel de
     *                      plus, pas une règle de plus.
     */
    public record Epreuve(
            EpreuveType epreuve,
            NiveauCecrl niveau,
            NiveauCecrl niveauInitial,
            NiveauEvolution evolution,
            StatutObjectif status,
            PlanDomainAssessmentDto evaluation
    ) {
    }

    /**
     * Le côté <b>civique</b> de l'Accueil.
     *
     * <p>🛑 <b>Aucune métrique CECRL ici</b> ({@code 20_} §12) : le civique se
     * mesure en points sur 40, jamais en paliers.
     *
     * @param historique   les diagnostics clos, du plus ancien au plus récent —
     *                     l'Accueil en affiche le dernier score
     * @param themes       le <b>détail par thème</b>, tel que le moteur du plan
     *                     le produit déjà ({@code CivicPlanService.themeLignes},
     *                     même record que l'écran Plan / Réviser). 🛑 L'état est
     *                     servi en {@code CivicThemeState} <b>brut</b> : les
     *                     fronts posent le libellé, ils ne le dérivent d'aucun
     *                     nombre. 🛑 {@code NON_EVALUE} n'est pas
     *                     {@code FAIBLE} — un thème jamais interrogé n'a pas été
     *                     raté
     */
    public record Civique(
            List<Score> historique,
            List<CivicPlanDto.ThemeLigne> themes
    ) {
    }


    /**
     * Un résultat civique, directement comparable au seuil.
     *
     * @param seuil  32, la règle de l'épreuve — servi pour que l'écran le DISE
     * @param format 40, le format de l'épreuve
     */
    public record Score(
            UUID sessionId,
            int bonnes,
            int posees,
            int seuil,
            int format,
            Instant mesureA
    ) {
    }
}
