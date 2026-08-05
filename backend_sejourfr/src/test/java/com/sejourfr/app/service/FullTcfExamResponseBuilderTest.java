package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.FullTcfExamSummaryResponse;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Verrouille la RESTITUTION du bilan d'un examen blanc TCF complet — ce que le
 * candidat lit, par opposition aux règles qui la produisent :
 *
 * <ul>
 *   <li>une épreuve <b>verrouillée</b> par le freemium n'a pas été passée :
 *       elle n'a aucun niveau et sort du plancher global. Un verrou commercial
 *       n'est pas un verdict de langue — le défaut historique affichait
 *       « A1 non atteint » à un candidat qui n'avait simplement pas payé ;</li>
 *   <li>une épreuve dont les évaluations IA ont <b>échoué</b> est également hors
 *       plancher (niveau inconnu, pas mauvais niveau) ;</li>
 *   <li>dans les deux cas le périmètre réel du plancher est publié
 *       ({@code epreuvesCountedInFinalLevel} / {@code finalLevelPartial}), pour
 *       que les fronts n'affirment pas « le plus bas de tes 4 épreuves » quand
 *       il n'y en a que 2 ou 3.</li>
 * </ul>
 *
 * <p>Unitaire pur. {@link TcfLevelEstimatorService} est utilisé RÉEL (sans
 * dépendance, c'est la math CECRL elle-même) ; seul le bilan de production est
 * mocké, ses propres règles étant couvertes par {@code ProductionBilanServiceTest}.
 */
class FullTcfExamResponseBuilderTest {

    private AttemptManager attemptManager;
    private ProductionSubmissionManager productionSubmissionManager;
    private ProductionBilanService productionBilanService;
    private FullTcfExamResponseBuilder builder;

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        productionSubmissionManager = mock(ProductionSubmissionManager.class);
        productionBilanService = mock(ProductionBilanService.class);
        builder = new FullTcfExamResponseBuilder(
                attemptManager, productionSubmissionManager,
                new TcfLevelEstimatorService(), productionBilanService);

        when(productionSubmissionManager.findByAttemptId(any())).thenReturn(List.of());
        // Fidèle au vrai service : seules les submissions EVALUATED donnent une
        // évaluation exploitable (une par tâche). Une épreuve dont tout a échoué
        // rend donc une map vide, comme en production.
        when(productionBilanService.latestEvalsByTache(any())).thenAnswer(inv -> {
            List<ProductionSubmission> subs = inv.getArgument(0);
            Map<Integer, AiEvaluation> out = new java.util.LinkedHashMap<>();
            int tache = 1;
            for (ProductionSubmission s : subs) {
                if (s.getStatut() == SubmissionStatut.EVALUATED) {
                    out.put(tache++, new AiEvaluation());
                }
            }
            return out;
        });
        // Une épreuve productive terminée sans aucune tâche rendue vaut
        // A1_NON_ATTEINT : c'est précisément ce qu'on ne veut PAS voir remonter
        // sur une épreuve verrouillée.
        when(productionBilanService.bilanEpreuveTerminee(any()))
                .thenReturn(NiveauCecrl.A1_NON_ATTEINT);
        when(productionBilanService.bilanEpreuve(any())).thenReturn(NiveauCecrl.B1);
    }

    // ------------------------------------------------------------------ fixtures

    /** Parent TCF_COMPLET terminé, verrou de production optionnel. */
    private Attempt parent(boolean productionLocked) {
        Attempt p = new Attempt();
        p.setId(UUID.randomUUID());
        p.setEpreuve(EpreuveType.TCF_COMPLET);
        p.setStartedAt(Instant.now().minusSeconds(5400));
        p.setFinishedAt(Instant.now());
        p.setStatus(AttemptStatus.TERMINE);
        p.setProductionLocked(productionLocked);
        return p;
    }

    /** Sous-attempt QCM terminé portant son niveau persisté. */
    private static Attempt qcm(EpreuveType e, NiveauCecrl level) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        a.setFinishedAt(Instant.now());
        a.setStatus(AttemptStatus.TERMINE);
        a.setCecrlLevel(level);
        a.setWeightedScore(40);
        a.setMaxWeightedScore(50);
        return a;
    }

    /** Sous-attempt productif terminé (EE/EO). */
    private static Attempt production(EpreuveType e) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        a.setFinishedAt(Instant.now());
        a.setStatus(AttemptStatus.TERMINE);
        return a;
    }

    private static ProductionSubmission submission(SubmissionStatut statut) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setStatut(statut);
        return s;
    }

    private static FullTcfExamResponse.SubAttempt subOf(FullTcfExamResponse r, EpreuveType e) {
        return r.subAttempts().stream().filter(s -> s.epreuve() == e).findFirst().orElseThrow();
    }

    // ------------------------------------------------- épreuve VERROUILLÉE

    /**
     * LE défaut corrigé : un compte gratuit qui refait l'examen 1 voyait ses
     * EE/EO pré-terminées comptées A1_NON_ATTEINT, ce qui tirait le plancher
     * global au plus bas niveau de l'examen. On lui annonçait qu'il n'avait pas
     * atteint le A1 parce qu'il n'avait pas payé.
     */
    @Test
    void epreuveVerrouillee_naAucunNiveauEtSortDuPlancher() {
        Attempt p = parent(true);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B2),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EO).cecrlLevel()).isNull();
        // Le niveau global est celui des épreuves RÉELLEMENT passées (CO+CE).
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(2);
        assertThat(r.epreuvesExpected()).isEqualTo(4);
        assertThat(r.finalLevelPartial()).isTrue();
    }

    /** On ne calcule même pas un bilan pour une épreuve jamais passée. */
    @Test
    void epreuveVerrouillee_neDeclencheAucunCalculDeBilan() {
        Attempt p = parent(true);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        builder.buildResponse(p);

        verify(productionBilanService, never()).bilanEpreuveTerminee(any());
        verify(productionBilanService, never()).bilanEpreuve(any());
    }

    /** Le verrou ne déborde jamais sur la compréhension : CO/CE restent notées. */
    @Test
    void epreuveVerrouillee_nafectePasLesNiveauxCoCe() {
        Attempt p = parent(true);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.A2),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_CO).cecrlLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(subOf(r, EpreuveType.TCF_CO).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_CE).cecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * Contamination des statistiques : le résumé d'historique (« meilleur
     * niveau », « dernier examen ») porte le drapeau de partialité, faute de
     * quoi un examen à moitié verrouillé passerait pour un résultat complet.
     */
    @Test
    void resume_dUnExamenVerrouille_estMarquePartiel() {
        Attempt p = parent(true);
        p.setSlotNumber(3);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamSummaryResponse s = builder.buildSummary(p);

        assertThat(s.finalLevelPartial()).isTrue();
        assertThat(s.finalCecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(s.slotNumber()).isEqualTo(3);
    }

    // ---------------------------------------------------- épreuve EN ÉCHEC

    /**
     * Les 3 soumissions EE sont FAILED : l'épreuve n'a pas de niveau. Le
     * plancher l'ignore (calcul correct, déjà en place) — ce qui manquait,
     * c'est de le DIRE aux fronts, qui affirment « le plus bas de tes 4
     * épreuves » pendant qu'il n'y en a que 3.
     */
    @Test
    void epreuveEnEchec_sortDuPlancherEtRendLeBilanPartiel() {
        Attempt p = parent(false);
        Attempt ee = production(EpreuveType.TCF_EE);
        Attempt eo = production(EpreuveType.TCF_EO);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B2),
                ee, eo));
        when(productionSubmissionManager.findByAttemptId(ee.getId())).thenReturn(List.of(
                submission(SubmissionStatut.FAILED),
                submission(SubmissionStatut.FAILED),
                submission(SubmissionStatut.FAILED)));
        when(productionSubmissionManager.findByAttemptId(eo.getId())).thenReturn(List.of(
                submission(SubmissionStatut.EVALUATED),
                submission(SubmissionStatut.EVALUATED),
                submission(SubmissionStatut.EVALUATED)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EE).failedSubmissionIds()).hasSize(3);
        assertThat(subOf(r, EpreuveType.TCF_EO).cecrlLevel()).isEqualTo(NiveauCecrl.B1);
        // Plancher sur CO(B1) + CE(B2) + EO(B1) = B1, sur 3 épreuves seulement.
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(3);
        assertThat(r.finalLevelPartial()).isTrue();
        assertThat(r.status()).isEqualTo(FullTcfExamResponse.FullTcfExamStatus.COMPLETED);
    }

    // ------------------------------------------------------ examen complet

    /** Les 4 épreuves passées et notées : rien de partiel, plancher sur 4. */
    @Test
    void examenIntegralement_passe_nestPasPartiel() {
        Attempt p = parent(false);
        Attempt ee = production(EpreuveType.TCF_EE);
        Attempt eo = production(EpreuveType.TCF_EO);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B2),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B2),
                ee, eo));
        List<ProductionSubmission> evaluees = List.of(
                submission(SubmissionStatut.EVALUATED),
                submission(SubmissionStatut.EVALUATED),
                submission(SubmissionStatut.EVALUATED));
        when(productionSubmissionManager.findByAttemptId(ee.getId())).thenReturn(evaluees);
        when(productionSubmissionManager.findByAttemptId(eo.getId())).thenReturn(evaluees);

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(4);
        assertThat(r.finalLevelPartial()).isFalse();
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.B1); // plancher EE/EO
        assertThat(builder.buildSummary(p).finalLevelPartial()).isFalse();
    }

    /**
     * Épreuve productive terminée SANS verrou et sans rien rendre (abandon,
     * chrono écoulé) : elle vaut bien A1_NON_ATTEINT et compte au plancher.
     * Le « reste noté 0 » d'un examen écourté n'est pas remis en cause — seul
     * le verrou commercial l'était.
     */
    @Test
    void epreuveAbandonnee_sansVerrou_compteToujoursAuPlancher() {
        Attempt p = parent(false);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B2),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B2),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(4);
        assertThat(r.finalLevelPartial()).isFalse();
    }
}
