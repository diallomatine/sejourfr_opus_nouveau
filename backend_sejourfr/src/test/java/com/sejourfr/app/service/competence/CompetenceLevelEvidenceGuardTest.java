package com.sejourfr.app.service.competence;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.EvaluationProductionSegments;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LE GARDE-FOU QUI REND LE NIVEAU OPPOSABLE : un B1 ou un B2 se demontre par le
 * numero d'un segment reel, sinon le serveur abaisse.
 *
 * <p>Ce que ces tests protegent : la promesse que le niveau affiche au candidat
 * repose sur quelque chose qu'il a vraiment ecrit ou dit. Et son revers, tout
 * aussi important : ce garde-fou <b>ne peut qu'abaisser</b>, il ne releve
 * jamais, et il ne fait <b>jamais</b> echouer une analyse.
 */
class CompetenceLevelEvidenceGuardTest {

    private static final String ECRIT =
        "Je prefere le train. Comme la route est longue, nous serions fatigues en arrivant.";
    private static final String DIALOGUE = """
        Examinateur : Bonjour, que faites-vous le week-end ?
        Candidat : Je fais du sport avec mes amis.
        Examinateur : Et quel sport exactement ?
        Candidat : Du football, parce que c'est le seul sport que je pratique depuis l'enfance.
        """;

    private CompetenceLevelDowngradeMetrics metrics;
    private CompetenceLevelEvidenceGuard guard;

    @BeforeEach
    void setUp() {
        metrics = new CompetenceLevelDowngradeMetrics();
        guard = new CompetenceLevelEvidenceGuard(metrics);
    }

    private static EvaluationProductionSegments ecrit() {
        return EvaluationProductionSegments.of(ECRIT, EpreuveType.TCF_EE);
    }

    private static EvaluationProductionSegments oral() {
        return EvaluationProductionSegments.of(DIALOGUE, EpreuveType.TCF_EO);
    }

    private static Map<String, Object> sortie(String niveau, Object preuve) {
        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(CompetenceAnalysisFields.STATUS, "VALIDATED");
        sortie.put(CompetenceAnalysisFields.LEVEL_REACHED, niveau);
        if (preuve != null) sortie.put(CompetenceAnalysisFields.LEVEL_EVIDENCE, preuve);
        sortie.put(CompetenceAnalysisFields.VERDICT, "Le critere est atteint.");
        sortie.put(CompetenceAnalysisFields.STRENGTH_TAG, "Idee claire");
        sortie.put(CompetenceAnalysisFields.FOCUS_TAG, "Nuancer l'avis");
        return sortie;
    }

    // --------------------------------------------------- numero valide accepte

    @Test
    void unNumeroValideNeDeclencheAucuneViolation() {
        assertThat(guard.violations(sortie("B1", 2), ecrit())).isEmpty();
    }

    @Test
    void unNumeroValideEstResoluEnTexteEtLeNiveauNeBougePas() {
        Map<String, Object> analyse = sortie("B2", 2);

        boolean abaisse = guard.applique(analyse, ecrit());

        assertThat(abaisse).isFalse();
        assertThat(analyse)
            .containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B2")
            .containsEntry(CompetenceAnalysisFields.LEVEL_EVIDENCE,
                "Comme la route est longue, nous serions fatigues en arrivant.");
        assertThat(metrics.compteurs()).isEmpty();
    }

    /**
     * Le passage restitue est la sous-chaine ORIGINALE exacte du segment, pas une
     * reecriture : c'est l'invariant de {@link EvaluationProductionSegments}.
     */
    @Test
    void lePremierSegmentEstBienLePremierEtPasUneApproximation() {
        Map<String, Object> analyse = sortie("B1", 1);

        guard.applique(analyse, ecrit());

        assertThat(analyse).containsEntry(
            CompetenceAnalysisFields.LEVEL_EVIDENCE, "Je prefere le train.");
    }

    // ------------------------------------------------------- hors bornes / type

    @Test
    void unNumeroHorsBornesEstReprocheAvecLesBornesReelles() {
        assertThat(guard.violations(sortie("B1", 9), ecrit()))
            .singleElement()
            .asString()
            .contains("level_evidence vaut 9")
            .contains("les numeros vont de 1 a 2");
    }

    @Test
    void unNumeroHorsBornesAbaisseDUnSeulPalier() {
        Map<String, Object> analyse = sortie("B2", 9);

        assertThat(guard.applique(analyse, ecrit())).isTrue();

        assertThat(analyse)
            .containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B1")
            .doesNotContainKey(CompetenceAnalysisFields.LEVEL_EVIDENCE);
        assertThat(metrics.compteurs()).containsEntry("PREUVE_HORS_BORNES/B2->B1", 1L);
    }

    @Test
    void zeroNEstJamaisUnNumeroDeSegment() {
        Map<String, Object> analyse = sortie("B1", 0);

        assertThat(guard.applique(analyse, ecrit())).isTrue();
        assertThat(analyse).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "A2");
    }

    @Test
    void uneCitationALaPlaceDUnNumeroEstUnDefautDeType() {
        Map<String, Object> analyse = sortie("B2", "Comme la route est longue");

        assertThat(guard.applique(analyse, ecrit())).isTrue();
        assertThat(metrics.compteurs()).containsEntry("PREUVE_NON_ENTIERE/B2->B1", 1L);
    }

    /**
     * Un fournisseur qui serialise l'entier en chaine ne doit pas couter un
     * palier au candidat : {@code "2"} reste le segment 2. On refuse le type, pas
     * la valeur.
     */
    @Test
    void unEntierSerialiseEnChaineResteUnNumeroValide() {
        Map<String, Object> analyse = sortie("B1", "2");

        assertThat(guard.applique(analyse, ecrit())).isFalse();
        assertThat(analyse).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B1");
    }

    // ------------------------------------------------------ ce qui n'exige rien

    @Test
    void unA2SansPreuveNeDeclencheNiViolationNiAbaissement() {
        Map<String, Object> analyse = sortie("A2", null);

        assertThat(guard.violations(analyse, ecrit())).isEmpty();
        assertThat(guard.applique(analyse, ecrit())).isFalse();
        assertThat(analyse).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "A2");
        assertThat(metrics.compteurs()).isEmpty();
    }

    @Test
    void unA1NonAtteintSansPreuveNeDeclencheRien() {
        Map<String, Object> analyse = sortie("A1_NON_ATTEINT", null);

        assertThat(guard.applique(analyse, ecrit())).isFalse();
        assertThat(analyse).containsEntry(
            CompetenceAnalysisFields.LEVEL_REACHED, "A1_NON_ATTEINT");
    }

    /**
     * Une production sans le moindre segment citable ne peut rien demontrer : on
     * ne reproche pas au correcteur de n'avoir pas designe ce qui n'existe pas.
     */
    @Test
    void uneProductionSansSegmentCitableNExigeAucunePreuve() {
        EvaluationProductionSegments vide =
            EvaluationProductionSegments.of("... ...", EpreuveType.TCF_EE);
        Map<String, Object> analyse = sortie("B2", null);

        assertThat(vide.taille()).isZero();
        assertThat(guard.violations(analyse, vide)).isEmpty();
        assertThat(guard.applique(analyse, vide)).isFalse();
        assertThat(analyse).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B2");
    }

    /** Sous un contrat anterieur a v4, aucun decoupage n'est fourni : tout est inerte. */
    @Test
    void sansDecoupageLeGardeFouEstInerte() {
        Map<String, Object> analyse = sortie("B2", null);

        assertThat(guard.violations(analyse, null)).isEmpty();
        assertThat(guard.applique(analyse, null)).isFalse();
        assertThat(analyse).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B2");
    }

    // --------------------------------------------------------------- oral (EO)

    /**
     * En dialogue, un segment est UN TOUR {@code Candidat :} — et les tours de
     * l'examinateur ne portent aucun numero. Citer l'examinateur devient
     * structurellement impossible, pas « interdit ».
     */
    @Test
    void aLOralSeulsLesToursDuCandidatSontNumerotes() {
        EvaluationProductionSegments segments = oral();

        assertThat(segments.taille()).isEqualTo(2);
        assertThat(segments.texte(1)).contains("Je fais du sport avec mes amis.");
        assertThat(segments.texte(2))
            .contains("Du football, parce que c'est le seul sport que je pratique depuis l'enfance.");
        assertThat(segments.rendu())
            .as("les tours de l'examinateur sont montres, sans numero")
            .contains("Examinateur : Bonjour, que faites-vous le week-end ?")
            .doesNotContain("[3]");
    }

    @Test
    void aLOralUnNumeroDeTourCandidatEstResoluEnTexte() {
        Map<String, Object> analyse = sortie("B1", 2);

        assertThat(guard.applique(analyse, oral())).isFalse();

        assertThat(analyse).containsEntry(CompetenceAnalysisFields.LEVEL_EVIDENCE,
            "Du football, parce que c'est le seul sport que je pratique depuis l'enfance.");
    }

    @Test
    void aLOralUnNumeroQuiDepasseLesToursCandidatAbaisse() {
        Map<String, Object> analyse = sortie("B1", 3);

        assertThat(guard.applique(analyse, oral())).isTrue();
        assertThat(analyse).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "A2");
    }

    // ---------------------------------------------------- ce qu'il ne fait pas

    /**
     * IL NE RELEVE JAMAIS. Une preuve parfaitement valide sur un A2 ne fabrique
     * pas un B1 : le garde-fou n'a qu'un sens, comme {@code applyCouplage} et
     * {@code applyPlafonds}.
     */
    @Test
    void neReleveJamaisUnNiveau() {
        Map<String, Object> analyse = sortie("A2", 2);

        guard.applique(analyse, ecrit());

        assertThat(analyse).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "A2");
        assertThat(metrics.compteurs()).isEmpty();
    }

    /** Un seul palier, meme sur une preuve absurde : on est prudent, pas punitif. */
    @Test
    void nAbaisseQueDUnPalierEtJamaisSousLePlancher() {
        Map<String, Object> b1 = sortie("B1", 42);
        guard.applique(b1, ecrit());
        assertThat(b1).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "A2");

        Map<String, Object> b2 = sortie("B2", 42);
        guard.applique(b2, ecrit());
        assertThat(b2).containsEntry(CompetenceAnalysisFields.LEVEL_REACHED, "B1");
    }

    /** Aucun chemin ne leve : une analyse perdue coute plus cher qu'un niveau prudent. */
    @Test
    void neLeveJamaisQuelQueSoitLeContenu() {
        Map<String, Object> vide = new LinkedHashMap<>();
        assertThat(guard.violations(vide, ecrit())).isEmpty();
        assertThat(guard.applique(vide, ecrit())).isFalse();
        assertThat(guard.applique(null, ecrit())).isFalse();

        Map<String, Object> niveauInconnu = sortie("C3", 1);
        assertThat(guard.violations(niveauInconnu, ecrit())).isEmpty();
        assertThat(guard.applique(niveauInconnu, ecrit())).isFalse();
    }
}
