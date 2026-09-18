package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.ProductionBilanService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * <b>Les deux branchements que {@code doFinish} ne couvre pas</b> (D-24,
 * points 2 et 3) — et le seul qui doit rester muet (point 4).
 *
 * <p>Test unitaire : ce qui est verifie est une <b>decision</b> — signaler ou se
 * taire —, pas une ecriture en base. Les trois cas de silence comptent autant
 * que le cas de signal : chacun protege une regle differente.
 */
class JourneyProductionBridgeTest {

    private ProductionSubmissionManager submissionManager;
    private ProductionBilanService bilanService;
    private JourneyService journeyService;
    private JourneyProductionBridge bridge;

    private final UUID userId = UUID.randomUUID();
    private static final Instant FIN = Instant.now().minusSeconds(120);

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        bilanService = mock(ProductionBilanService.class);
        journeyService = mock(JourneyService.class);
        bridge = new JourneyProductionBridge(submissionManager, bilanService, journeyService);
    }

    @Test
    @DisplayName("D-24/2 — une epreuve EE d'examen close et corrigee est signalee au parcours")
    void uneEpreuveDExamenCorrigeeEstSignalee() {
        Attempt epreuve = epreuveDExamen(EpreuveType.TCF_EE);
        corrigee(epreuve);

        bridge.onProductionAttemptClosed(epreuve);

        org.mockito.ArgumentCaptor<JourneyEvaluation> captor =
                org.mockito.ArgumentCaptor.forClass(JourneyEvaluation.class);
        verify(journeyService).onAssessmentCompleted(eq(userId), captor.capture());
        JourneyEvaluation evaluation = captor.getValue();
        // 🛑 L'unite d'evaluation est l'EPREUVE, jamais la soumission : les 3
        // taches d'une epreuve produisent 3 soumissions.
        assertThat(evaluation.sourceAssessmentId()).isEqualTo(epreuve.getId());
        assertThat(evaluation.examType()).isEqualTo(EpreuveType.TCF_EE);
        assertThat(evaluation.kind()).isEqualTo(JourneyAssessmentKind.SECTION_EXAM);
        assertThat(evaluation.completedAt()).isEqualTo(FIN);
    }

    @Test
    @DisplayName("B-13 — une correction encore en cours fait TAIRE ce branchement")
    void uneCorrectionEnCoursFaitTaireLeBranchement() {
        Attempt epreuve = epreuveDExamen(EpreuveType.TCF_EO);
        when(submissionManager.findByAttemptId(epreuve.getId()))
                .thenReturn(List.of(soumission(SubmissionStatut.EVALUATED),
                        soumission(SubmissionStatut.EVALUATING)));

        bridge.onProductionAttemptClosed(epreuve);

        // 🛑 Sinon l'evenement serait enregistre AVANT que les priorites soient
        // ecrites : l'idempotence ferait ensuite taire la voie de l'analyse, et
        // les priorites de l'epreuve seraient perdues pour de bon.
        verifyNoInteractions(journeyService);
    }

    @Test
    @DisplayName("D-24/4 — une epreuve PRE-TERMINEE, sans aucune correction, ne signale RIEN")
    void uneEpreuvePreTermineeNeSignaleRien() {
        Attempt epreuve = epreuveDExamen(EpreuveType.TCF_EE);
        when(submissionManager.findByAttemptId(epreuve.getId())).thenReturn(List.of());
        when(bilanService.latestEvalsByTache(any())).thenReturn(Map.of());

        bridge.onProductionAttemptClosed(epreuve);

        // 🛑 `lockProductionSubAttempts` pose TERMINE sans qu'aucun examen n'ait
        // ete passe. Signaler aurait INVENTE une mesure, et clos au passage
        // l'etape « Évaluer mon niveau » d'une epreuve jamais ouverte.
        verifyNoInteractions(journeyService);
    }

    @Test
    @DisplayName("R1 — un entrainement libre de production ne signale jamais rien")
    void unEntrainementLibreNeSignaleRien() {
        Attempt entrainement = new Attempt();
        entrainement.setId(UUID.randomUUID());
        entrainement.setUser(user());
        entrainement.setEpreuve(EpreuveType.TCF_EE);
        entrainement.setFinishedAt(FIN);
        // Ni slot, ni parent : ce n'est pas une session d'examen.

        bridge.onProductionAttemptClosed(entrainement);

        verifyNoInteractions(journeyService);
    }

    @Test
    @DisplayName("D-24/3 — a la completion d'un examen complet, chaque SOUS-EPREUVE est signalee")
    void laCompletionDUnExamenCompletSignaleSesSousEpreuves() {
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        Attempt co = new Attempt();
        co.setId(UUID.randomUUID());
        co.setUser(user());
        co.setEpreuve(EpreuveType.TCF_CO);
        co.setParentAttempt(parent);
        co.setFinishedAt(FIN);
        Attempt ee = new Attempt();
        ee.setId(UUID.randomUUID());
        ee.setUser(user());
        ee.setEpreuve(EpreuveType.TCF_EE);
        ee.setParentAttempt(parent);
        ee.setFinishedAt(FIN);
        // L'EE a ete pre-terminee (compte gratuit) : aucune soumission.
        when(submissionManager.findByAttemptId(ee.getId())).thenReturn(List.of());
        when(bilanService.latestEvalsByTache(any())).thenReturn(Map.of());

        bridge.onFullExamCompleted(List.of(co, ee));

        // Le parent TCF_COMPLET ne passe jamais par doFinish, et n'est pas une
        // epreuve : ce sont ses sous-epreuves qui sont signalees.
        org.mockito.ArgumentCaptor<JourneyEvaluation> captor =
                org.mockito.ArgumentCaptor.forClass(JourneyEvaluation.class);
        verify(journeyService).onAssessmentCompleted(eq(userId), captor.capture());
        assertThat(captor.getValue().sourceAssessmentId()).isEqualTo(co.getId());
        assertThat(captor.getValue().examType()).isEqualTo(EpreuveType.TCF_CO);
        // Une sous-epreuve d'examen complet porte un parent : c'est un MOCK_EXAM.
        assertThat(captor.getValue().kind()).isEqualTo(JourneyAssessmentKind.MOCK_EXAM);
        // Et l'EE pre-terminee n'a rien declenche.
        verify(journeyService, never()).onAssessmentCompleted(
                eq(userId), org.mockito.ArgumentMatchers.argThat(
                        evaluation -> evaluation.sourceAssessmentId().equals(ee.getId())));
    }

    // ------------------------------------------------------------- fabriques

    private User user() {
        User user = new User();
        user.setId(userId);
        return user;
    }

    /** Une epreuve de production jouee en <b>examen blanc</b> : slot pose au demarrage. */
    private Attempt epreuveDExamen(EpreuveType epreuve) {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user());
        attempt.setEpreuve(epreuve);
        attempt.setSlotNumber(1);
        attempt.setFinishedAt(FIN);
        return attempt;
    }

    private void corrigee(Attempt epreuve) {
        when(submissionManager.findByAttemptId(epreuve.getId()))
                .thenReturn(List.of(soumission(SubmissionStatut.EVALUATED),
                        soumission(SubmissionStatut.EVALUATED),
                        soumission(SubmissionStatut.EVALUATED)));
        when(bilanService.latestEvalsByTache(any()))
                .thenReturn(Map.of(1, new AiEvaluation(), 2, new AiEvaluation(),
                        3, new AiEvaluation()));
    }

    private static ProductionSubmission soumission(SubmissionStatut statut) {
        ProductionSubmission soumission = new ProductionSubmission();
        soumission.setStatut(statut);
        return soumission;
    }
}
