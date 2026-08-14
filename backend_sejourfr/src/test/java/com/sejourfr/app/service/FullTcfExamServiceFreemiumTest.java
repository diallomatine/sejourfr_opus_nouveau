package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Verrouille le freemium de l'examen blanc TCF complet pour les comptes
 * gratuits (cf. {@link FullTcfExamService#start}) :
 *
 * <ul>
 *   <li>l'expression écrite et orale (EE/EO) ne sont offertes qu'<b>une seule
 *       fois</b> ;</li>
 *   <li>le freebie n'est consommé que par une <b>vraie soumission</b> EE/EO
 *       dans un examen complet ({@code hasFullExamProductionSubmission}) —
 *       démarrer puis abandonner un examen sans toucher à EE/EO ne le consomme
 *       PAS, donc EE/EO restent jouables au prochain examen.</li>
 * </ul>
 *
 * Test unitaire pur (mocks Mockito, pas de contexte Spring ni de DB) : on pilote
 * directement le verdict {@code hasFullExamProductionSubmission} et on vérifie
 * l'état des sous-épreuves EE/EO dans la réponse.
 */
class FullTcfExamServiceFreemiumTest {

    private AttemptManager attemptManager;
    private ProductionSubmissionManager productionSubmissionManager;
    private SubscriptionService subscriptionService;
    private FullTcfExamService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        UserManager userManager = mock(UserManager.class);
        productionSubmissionManager = mock(ProductionSubmissionManager.class);
        subscriptionService = mock(SubscriptionService.class);
        AttemptService attemptService = mock(AttemptService.class);
        TcfLevelEstimatorService levelEstimator = mock(TcfLevelEstimatorService.class);
        ProductionBilanService productionBilanService = mock(ProductionBilanService.class);

        FullTcfExamResponseBuilder responseBuilder = new FullTcfExamResponseBuilder(
                attemptManager, productionSubmissionManager, levelEstimator, productionBilanService);
        // Le verrou EE/EO d'un examen complet vit desormais dans
        // ProductionAccessService, qui le sert AUSSI en lecture au jalon du
        // Plan. On le construit ICI POUR DE VRAI, sur les memes mocks : c'est ce
        // qui garantit que le cadenas affiche et le verrou applique restent la
        // meme regle.
        ProductionAccessService productionAccessService = new ProductionAccessService(
                subscriptionService, attemptManager, productionSubmissionManager,
                mock(com.sejourfr.app.manager.DiagnosticSessionManager.class));
        service = new FullTcfExamService(
                attemptManager, userManager, attemptService, productionAccessService,
                responseBuilder);

        when(userManager.findById(userId)).thenReturn(Optional.of(new User()));
        // Compte gratuit (pas d'abonnement TCF).
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        // save renvoie l'entité telle quelle (pas de DB).
        when(attemptManager.save(any(Attempt.class))).thenAnswer(inv -> inv.getArgument(0));
        // Les 4 sous-attempts "créés" par AttemptService (mocké) sont fournis via
        // findSubAttempts — même liste pour le verrouillage et pour buildResponse,
        // donc les mutations (finishedAt) sont visibles dans la réponse.
        List<Attempt> subs = List.of(
                sub(EpreuveType.TCF_CO), sub(EpreuveType.TCF_CE),
                sub(EpreuveType.TCF_EE), sub(EpreuveType.TCF_EO));
        when(attemptManager.findSubAttempts(any())).thenReturn(subs);
        when(productionSubmissionManager.findByAttemptId(any())).thenReturn(List.of());
        // capB2 neutre : renvoie son argument (le niveau n'est pas l'objet du test).
        when(levelEstimator.capB2(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private static Attempt sub(EpreuveType e) {
        Attempt a = new Attempt();
        a.setEpreuve(e);
        return a;
    }

    private static FullTcfExamResponse.SubAttempt subOf(FullTcfExamResponse r, EpreuveType e) {
        return r.subAttempts().stream()
                .filter(s -> s.epreuve() == e)
                .findFirst()
                .orElseThrow();
    }

    @Test
    void eeEoDeverrouillees_quandAucuneSoumissionAnterieure() {
        // Aucune tâche EE/EO encore soumise en examen complet : freebie intact.
        when(productionSubmissionManager.hasFullExamProductionSubmission(userId)).thenReturn(false);

        FullTcfExamResponse r = service.start(userId, 1);

        // EE/EO jouables : ni verrouillées, ni pré-terminées.
        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_EO).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_EE).finishedAt()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).finishedAt()).isNull();
    }

    @Test
    void eeEoVerrouillees_apresUneSoumissionEnExamenComplet() {
        // Le freebie a été consommé (≥ 1 tâche EE/EO soumise dans un examen complet).
        when(productionSubmissionManager.hasFullExamProductionSubmission(userId)).thenReturn(true);

        FullTcfExamResponse r = service.start(userId, 1);

        // EE/EO verrouillées (réservées à l'abonnement) + pré-terminées. Leur
        // restitution (pas de niveau, hors plancher) est verrouillée par
        // FullTcfExamResponseBuilderTest — ici on ne teste que le VERROU.
        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EO).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EE).finishedAt()).isNotNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).finishedAt()).isNotNull();
        // La compréhension (CO/CE) reste jouable même au refaire.
        assertThat(subOf(r, EpreuveType.TCF_CO).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_CE).locked()).isFalse();
    }

    @Test
    void demarrerNeCreeAucuneSoumission_doncNeConsommePasLeFreebie() {
        when(productionSubmissionManager.hasFullExamProductionSubmission(userId)).thenReturn(false);

        service.start(userId, 1);

        // start() ne persiste jamais de ProductionSubmission : le freebie n'est
        // consommé que par une vraie soumission (submitText / submitAudio). Donc
        // démarrer — puis abandonner — un examen sans toucher EE/EO laisse le
        // compteur à 0 et EE/EO restent jouables au prochain examen.
        verify(productionSubmissionManager, never()).save(any());
    }

    // ------------------------------------------------------------------ slots

    /**
     * La grille compte 20 slots : un {@code slotNumber} hors borne était
     * persisté tel quel (999, -3), là où les MOCK_EXAM QCM sont bornés depuis
     * le lot précédent.
     */
    @Test
    void slotHorsBorne_refuse() {
        when(productionSubmissionManager.hasFullExamProductionSubmission(userId)).thenReturn(false);

        assertThatThrownBy(() -> service.start(userId, 999))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.start(userId, 0))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.start(userId, -3))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void slotAuxBornes_accepte() {
        when(productionSubmissionManager.hasFullExamProductionSubmission(userId)).thenReturn(false);

        assertThat(service.start(userId, 1)).isNotNull();
        assertThat(service.start(userId, FullTcfExamService.EXAM_SLOTS)).isNotNull();
    }

    /** Sans slot demandé, on retombe sur le slot 1 (et pas sur NULL en base). */
    @Test
    void slotAbsent_vautUn() {
        when(productionSubmissionManager.hasFullExamProductionSubmission(userId)).thenReturn(false);

        service.start(userId, null);

        org.mockito.ArgumentCaptor<Attempt> captor =
                org.mockito.ArgumentCaptor.forClass(Attempt.class);
        verify(attemptManager, org.mockito.Mockito.atLeastOnce()).save(captor.capture());
        assertThat(captor.getAllValues())
                .filteredOn(a -> a.getEpreuve() == EpreuveType.TCF_COMPLET)
                .allMatch(a -> Integer.valueOf(1).equals(a.getSlotNumber()));
    }
}
