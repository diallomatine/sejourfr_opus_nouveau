package com.sejourfr.app.calibration;

import java.util.List;
import java.util.Map;

/**
 * Resultat brut d'un cas du corpus pour une passe : ce que le pipeline de
 * production a repondu, en face de ce que le corpus attendait.
 *
 * @param criteres         note /20 par code de critere, telle qu'elle a servi au
 *                         calcul serveur. Conservee pour pouvoir REJOUER HORS
 *                         LIGNE le passage note -> niveau (balayage de seuils
 *                         {@code niveau-cecrl.seuil-*}, plafonds) sans refaire
 *                         un seul appel LLM.
 *
 * @param statut           {@code OK} · {@code VALIDITE_SERVEUR} (court-circuite
 *                         avant le LLM par les controles deterministes) ·
 *                         {@code SORTIE_INVALIDE} (champ requis manquant) ·
 *                         {@code ERREUR_APPEL}
 * @param tentatives       EVALUATIONS COMPLETES tentees pour ce cas par la boucle
 *                         externe du banc. Une tentative = un {@code evaluate()}
 *                         entier, donc jusqu'a DEUX appels LLM (appel initial +
 *                         reparation). A ne pas confondre avec {@code appelsLlm}.
 * @param tentativesRatees evaluations completes qui ont echoue. En production il
 *                         n'y a qu'une tentative : {@code tentativesRatees /
 *                         tentatives} est donc le taux d'ECHEC EN CONDITIONS DE
 *                         PRODUCTION — la seule metrique qui decrit ce que vit un
 *                         candidat.
 * @param appelsLlm        appels reellement emis au correcteur, reparations
 *                         comprises. Denominateur du taux de SORTIES REFUSEES.
 * @param traces           ce qui s'est passe a CHAQUE tentative : violations et
 *                         citations refusees comprises. Sans elles, {@code erreur}
 *                         etait remis a {@code null} des qu'une tentative
 *                         reussissait et le motif de refus disparaissait du
 *                         rapport (mesure : 2 motifs tracables sur 102 refus).
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
    Map<String, Double> criteres,
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
    Integer coutMicroUsd,
    long dureeMs,
    int appelsLlm,
    List<Tentative> traces) {

    /**
     * Une evaluation complete tentee par le banc.
     *
     * @param violations        ce que NOS validateurs ont refuse, par appel. Les
     *                          violations du PREMIER appel n'apparaissent nulle
     *                          part ailleurs : l'exception ne porte que celles du
     *                          reessai.
     * @param citationsRefusees la citation exacte que le rapprochement de preuve
     *                          n'a pas su rattacher, critere par critere. C'est
     *                          elle qui dit si le correcteur a invente sa preuve
     *                          ou si c'est notre controle qui l'a manquee.
     */
    record Tentative(
        int numero,
        boolean reussie,
        String erreur,
        int sortiesRefusees,
        List<String> violations,
        List<String> citationsRefusees,
        Map<String, Integer> motifs) {

        /** Vrai si l'echec vient de NOS controles, pas du fournisseur. */
        boolean refuseeParNosControles() {
            return !reussie && sortiesRefusees > 0;
        }
    }

    /**
     * Gabarit des tests d'arithmetique : un run sans instrumentation d'appels.
     * Le banc, lui, utilise toujours le constructeur canonique.
     */
    CaseRun(
        String casId, String groupe, int passe, String statut, String erreur,
        String niveauAttendu, List<String> niveauTolerance, String niveauObtenu, String niveauIa,
        Double note, Map<String, Double> criteres, double noteMin, double noteMax,
        String confianceAttendue, String confianceObtenue,
        Boolean obligatoireTraiteAttendu, Boolean obligatoireTraiteObtenu,
        List<String> pointsOubliesAttendus, List<String> pointsOubliesObtenus,
        List<String> pieges, List<String> champsRequisManquants, List<String> criteresManquants,
        boolean llmAppele, int tentatives, int tentativesRatees, String modele,
        Integer tokensInput, Integer tokensOutput, Integer coutMicroUsd, long dureeMs) {
        this(casId, groupe, passe, statut, erreur, niveauAttendu, niveauTolerance, niveauObtenu,
            niveauIa, note, criteres, noteMin, noteMax, confianceAttendue, confianceObtenue,
            obligatoireTraiteAttendu, obligatoireTraiteObtenu, pointsOubliesAttendus,
            pointsOubliesObtenus, pieges, champsRequisManquants, criteresManquants, llmAppele,
            tentatives, tentativesRatees, modele, tokensInput, tokensOutput, coutMicroUsd, dureeMs,
            tentatives, List.of());
    }

    /** Sorties que NOS controles ont refusees sur ce cas, appel par appel. */
    int sortiesRefusees() {
        return traces.stream().mapToInt(Tentative::sortiesRefusees).sum();
    }

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
