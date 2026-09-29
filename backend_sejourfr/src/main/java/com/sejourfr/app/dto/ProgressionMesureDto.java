package com.sejourfr.app.dto;

import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProgressionProvenance;
import com.sejourfr.app.enums.ProgressionRapport;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * <b>Un examen blanc</b> sur un écran de progression — un point de la courbe et
 * une ligne de la liste, les deux étant la même chose.
 *
 * @param attemptId       la session (en TCF complet : la sous-épreuve)
 * @param numero          ordinal <b>chronologique</b> dans sa liste, 1 = le plus
 *                        ancien. 🛑 Jamais le {@code slotNumber}, qui est un
 *                        créneau de grille réutilisé à chaque rejeu (D8)
 * @param date            fin de l'examen
 * @param score           CO/CE : score de progression 100-499 ; EE/EO : note /20
 *                        (une décimale) ; civique : bonnes réponses.
 *                        {@code null} = aucun score exploitable (inconnu,
 *                        jamais 0)
 * @param max             499, 20, ou le nombre de questions de l'examen
 * @param niveau          TCF : palier <b>de cet examen</b> (strates en CO/CE,
 *                        bilan d'épreuve en EE/EO). {@code null} en civique
 * @param etat            civique : état de l'examen
 *                        ({@code CivicDiagnosticThemeResolver.etat}) ;
 *                        {@code null} en TCF
 * @param seuilAtteint    civique : {@code score >= seuil} ; {@code null} en TCF
 * @param pointsManquants civique : points qui manquaient pour le seuil (0 s'il
 *                        est atteint) ; {@code null} en TCF
 * @param taux            civique : bonnes / posées, 0..1 — ce que remplit
 *                        l'anneau (D5). {@code null} en TCF, où il n'y a pas
 *                        d'anneau
 * @param dureeSecondes   durée réelle, servie <b>seulement si elle est fiable</b>
 *                        (close dans sa limite + 60 s de grâce, ancre connue) ;
 *                        {@code null} sinon, et toujours en EO (D9)
 * @param provenance      d'où vient l'examen
 * @param rapport         ce qu'ouvre « Voir → »
 */
public record ProgressionMesureDto(
        UUID attemptId,
        int numero,
        Instant date,
        BigDecimal score,
        int max,
        NiveauCecrl niveau,
        CivicThemeState etat,
        Boolean seuilAtteint,
        Integer pointsManquants,
        Double taux,
        Integer dureeSecondes,
        ProgressionProvenance provenance,
        Rapport rapport) {

    /**
     * @param kind      l'écran de rapport
     * @param attemptId l'attempt à ouvrir : la session, ou le PARENT pour une
     *                  sous-épreuve d'examen complet ({@code EXAMEN_COMPLET})
     */
    public record Rapport(ProgressionRapport kind, UUID attemptId) {
    }
}
