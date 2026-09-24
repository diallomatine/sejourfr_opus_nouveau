package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ContinuiteSimulation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * {@code GET /api/me/progression/tcf} — la progression <b>globale</b> TCF.
 *
 * <p>🛑 <b>Aucun score global</b> (D6) : on ne moyenne pas un score de
 * progression /499 avec une note /20. Le global se lit en <b>paliers</b>.
 *
 * @param niveauActuel          palier global actuel = plancher des 4 niveaux
 *                              affichés sur l'Accueil ; {@code null} = à évaluer
 * @param niveauActuelEpreuves  épreuves réellement comptées dans ce plancher (0..4)
 * @param niveauActuelPartiel   {@code true} si moins de 4 épreuves comptent
 * @param examensComplets       les encarts des examens blancs complets (D7)
 * @param epreuves              les 4 cartes, <b>toujours</b> servies, ordre CO, CE, EE, EO
 * @param examens               examens complets comptés, du plus récent au plus
 *                              ancien : les 3 derniers, ou tous (au plus 50)
 *                              avec {@code ?tous=true}
 * @param cta                   « Faire un examen blanc » (grille des examens complets)
 */
public record ProgressionTcfDto(
        NiveauCecrl niveauActuel,
        int niveauActuelEpreuves,
        boolean niveauActuelPartiel,
        ExamensComplets examensComplets,
        List<EpreuveCarte> epreuves,
        List<ExamenComplet> examens,
        ProgressionCtaDto cta) {

    /** Carte d'une épreuve : le même résumé que l'en-tête de son écran. */
    public record EpreuveCarte(
            EpreuveType epreuve,
            ProgressionEchelleDto echelle,
            ProgressionResumeDto resume) {
    }

    /**
     * 🛑 <b>D7</b> : ne comptent que les examens complets <b>terminés</b> dont au
     * moins une épreuve est réellement mesurée ; « meilleur » et « premier » ne
     * regardent que les examens <b>non partiels</b> (les 4 épreuves comptées).
     *
     * @param nombre    examens complets comptés
     * @param dernier   le plus récent compté (partiel ou non)
     * @param meilleur  le plus haut palier non partiel ; à égalité, le plus récent
     * @param premier   le plus ancien non partiel
     * @param evolution palier du premier non partiel → palier du dernier non
     *                  partiel ({@code TcfDiagnosticProgressionResolver.evolution}) ;
     *                  {@code INCONNUE} avec moins de deux examens non partiels
     */
    public record ExamensComplets(
            int nombre,
            ExamenComplet dernier,
            ExamenComplet meilleur,
            ExamenComplet premier,
            NiveauEvolution evolution) {
    }

    /**
     * Un examen blanc complet. Son « Voir → » ouvre le bilan de l'examen
     * complet ({@code attemptId} = le parent).
     *
     * @param numero           ordinal chronologique parmi les examens comptés, 1 = le plus ancien
     * @param niveau           palier global, <b>re-dérivé à la lecture</b> (D19) ;
     *                         {@code null} tant qu'une évaluation est en vol
     * @param partiel          moins de 4 épreuves comptées
     * @param epreuvesComptees épreuves réellement mesurées (1..4)
     * @param parEpreuve       les 4 épreuves, ordre CO, CE, EE, EO
     */
    public record ExamenComplet(
            UUID attemptId,
            int numero,
            Instant date,
            NiveauCecrl niveau,
            boolean partiel,
            int epreuvesComptees,
            ContinuiteSimulation continuite,
            List<EpreuveLigne> parEpreuve) {
    }

    /**
     * Une épreuve d'un examen complet.
     *
     * @param attemptId la sous-épreuve, {@code null} si elle n'existe pas
     * @param score     CO/CE : score de progression /499 ; EE/EO : note /20 ;
     *                  🛑 {@code null} pour une épreuve verrouillée, jamais
     *                  ouverte ou sans verdict (« — », jamais 0)
     * @param max       499 ou 20
     * @param niveau    palier de l'épreuve, {@code null} = inconnu
     * @param locked    épreuve fermée par le freemium (jamais passée)
     */
    public record EpreuveLigne(
            EpreuveType epreuve,
            UUID attemptId,
            BigDecimal score,
            int max,
            NiveauCecrl niveau,
            boolean locked) {
    }
}
