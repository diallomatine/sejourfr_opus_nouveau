package com.sejourfr.app.calibration;

import java.util.List;
import java.util.Map;

/**
 * Resultat brut d'un cas du corpus « Competences » : ce que le pipeline de
 * production a repondu, en face de ce que le corpus attendait.
 *
 * <p>Jumeau de {@link CaseRun}, avec une difference de fond : <b>il n'y a
 * aucune note</b>. Le module ne produit ni note sur 20 ni fourchette — les deux
 * grandeurs mesurees sont le <b>palier</b> ({@code level_reached}) et le
 * <b>verdict de critere</b> ({@code status}), et elles sont independantes.
 *
 * @param horsScore     production reelle servie en temoin : mesuree, affichee,
 *                      mais exclue de TOUS les agregats. C'est le garde-fou qui
 *                      empeche des lignes sans verite terrain de peser sur un
 *                      taux d'accord.
 * @param statut        {@code OK} · {@code SORTIE_INVALIDE} (une cle du contrat
 *                      manque encore apres la reparation) · {@code ERREUR_APPEL}
 * @param tentatives    ANALYSES COMPLETES tentees par la boucle externe du banc.
 *                      Une tentative = un {@code analyse()} entier, donc jusqu'a
 *                      DEUX appels LLM (appel initial + reparation unique).
 * @param tentativesRatees analyses completes qui ont echoue. En production il
 *                      n'y a pas de boucle externe : {@code tentativesRatees /
 *                      tentatives} est le taux d'ECHEC EN CONDITIONS DE
 *                      PRODUCTION, la seule metrique qui decrit ce que vit un
 *                      candidat.
 * @param appelsLlm     appels reellement emis au correcteur, reparations
 *                      comprises. Denominateur du taux de SORTIES REFUSEES.
 * @param sortiesRefusees sorties bien formees que NOS controles ont refusees.
 *                      Une reparation suit toujours un refus : c'est ce lien qui
 *                      les rend observables sans instrumenter le service.
 * @param preuveAbaissee le garde-fou de preuve a-t-il fait descendre le palier
 *                      d'un cran ? Un B2 sans segment designe redevient un B1 —
 *                      c'est la premiere explication a regarder quand le taux de
 *                      B2 rendus s'effondre.
 */
record CompetenceCaseRun(
    String casId,
    String groupe,
    String promptCode,
    String echelle,
    int passe,
    boolean horsScore,
    String statut,
    String erreur,
    String niveauAttendu,
    List<String> niveauTolerance,
    String niveauObtenu,
    String statutAttendu,
    List<String> statutTolerance,
    String statutObtenu,
    String verdict,
    boolean preuveServie,
    boolean preuveAbaissee,
    Map<String, Long> motifsPreuve,
    List<String> pieges,
    List<String> clesManquantes,
    int tentatives,
    int tentativesRatees,
    int appelsLlm,
    int sortiesRefusees,
    List<Refus> refus,
    String modele,
    Integer tokensInput,
    Integer tokensOutput,
    Integer coutCentimes,
    long dureeMs) {

    /**
     * Une sortie que nos controles ont refusee, et POURQUOI.
     *
     * @param violations libelles rendus par {@code CompetenceAnalysisValidator}.
     *                   Vides quand le refus vient du garde-fou de preuve : ce
     *                   sont deux familles differentes, et les confondre
     *                   empecherait de savoir laquelle durcir.
     */
    record Refus(int appel, String famille, List<String> violations) {
    }

    /** Un palier a-t-il ete rendu ? Sans lui, le cas ne peut pas etre agrege. */
    boolean exploitable() {
        return !horsScore && niveauObtenu != null && "OK".equals(statut);
    }

    boolean accordExactNiveau() {
        return exploitable() && niveauAttendu.equals(niveauObtenu);
    }

    boolean accordToleranceNiveau() {
        return exploitable() && niveauTolerance.contains(niveauObtenu);
    }

    boolean accordStatut() {
        return exploitable() && statutObtenu != null && statutTolerance.contains(statutObtenu);
    }

    boolean accordExactStatut() {
        return exploitable() && statutAttendu.equals(statutObtenu);
    }

    /**
     * Ecart de palier, convention du depot : {@code reference - IA}.
     * <b>Negatif = l'IA situe le candidat AU-DESSUS de la reference, donc trop
     * haut.</b> Positif = trop bas.
     */
    Integer ecartNiveau() {
        if (!exploitable()) return null;
        int att = CompetenceCalibrationMetrics.NIVEAUX.indexOf(niveauAttendu);
        int obt = CompetenceCalibrationMetrics.NIVEAUX.indexOf(niveauObtenu);
        return att < 0 || obt < 0 ? null : att - obt;
    }
}
