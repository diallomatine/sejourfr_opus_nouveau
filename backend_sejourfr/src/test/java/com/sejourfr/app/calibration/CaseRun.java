package com.sejourfr.app.calibration;

import java.util.List;

/**
 * Resultat brut d'un cas du corpus pour une passe : ce que le pipeline de
 * production a repondu, en face de ce que le corpus attendait.
 *
 * @param statut           {@code OK} · {@code VALIDITE_SERVEUR} (court-circuite
 *                         avant le LLM par les controles deterministes) ·
 *                         {@code SORTIE_INVALIDE} (champ requis manquant) ·
 *                         {@code ERREUR_APPEL}
 * @param tentatives       appels reellement emis pour ce cas
 * @param tentativesRatees appels dont la reponse etait inexploitable (JSON non
 *                         desorialisable, pas de tool_call, erreur HTTP). En
 *                         production, la 1re de ces reponses fait echouer la
 *                         soumission : c'est le taux de sorties invalides.
 */
record CaseRun(
    String casId,
    String groupe,
    int passe,
    String statut,
    String erreur,
    String niveauAttendu,
    List<String> niveauTolerance,
    String niveauObtenu,
    String niveauIa,
    Double note,
    double noteMin,
    double noteMax,
    String confianceAttendue,
    String confianceObtenue,
    Boolean obligatoireTraiteAttendu,
    Boolean obligatoireTraiteObtenu,
    List<String> pointsOubliesAttendus,
    List<String> pointsOubliesObtenus,
    List<String> pieges,
    List<String> champsRequisManquants,
    List<String> criteresManquants,
    boolean llmAppele,
    int tentatives,
    int tentativesRatees,
    String modele,
    Integer tokensInput,
    Integer tokensOutput,
    Integer coutCentimes,
    long dureeMs) {

    boolean exploitable() {
        return note != null && niveauObtenu != null
            && ("OK".equals(statut) || "VALIDITE_SERVEUR".equals(statut));
    }

    boolean accordExact() {
        return exploitable() && niveauAttendu.equals(niveauObtenu);
    }

    boolean accordTolerance() {
        return exploitable() && niveauTolerance.contains(niveauObtenu);
    }

    boolean noteDansFourchette() {
        return note != null && note >= noteMin && note <= noteMax;
    }

    /**
     * Ecart signe {@code reference - IA}, meme convention que
     * {@code AdminCalibrationService.computeEcart} ({@code note_humaine - note_IA},
     * persistee dans {@code human_calibration_notes.ecart_note}). La reference
     * est le centre de {@code [note_min, note_max]}.
     *
     * <p><b>Negatif = l'IA note AU-DESSUS de la reference = trop indulgente.</b>
     * Positif = l'IA note en dessous = trop severe.
     */
    Double ecartCentre() {
        return note == null ? null : (noteMin + noteMax) / 2.0 - note;
    }

    /**
     * Meme convention, mais mesuree a la borne la plus proche : 0 quand la note
     * tombe dans la fourchette acceptee, sinon de combien elle la deborde
     * (negatif = au-dessus de {@code note_max}).
     */
    Double ecartFourchette() {
        if (note == null) return null;
        if (note > noteMax) return noteMax - note;
        if (note < noteMin) return noteMin - note;
        return 0.0;
    }
}
