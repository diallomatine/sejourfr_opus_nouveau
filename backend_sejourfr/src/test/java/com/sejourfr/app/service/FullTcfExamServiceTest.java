package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.FullTcfExamSummaryResponse;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Couverture complémentaire de {@link FullTcfExamService} — lecture, marquage
 * explicite, ancrage de chrono et finalisation. Le freemium de {@link
 * FullTcfExamService#start} est déjà couvert par {@code FullTcfExamServiceFreemiumTest}.
 *
 * <p>Unitaire pur (mocks Mockito, pas de contexte Spring). Les stubs larges de
 * {@link #setUp} sont volontairement lenient — sans {@code MockitoExtension},
 * pas de strict stubbing.
 */
class FullTcfExamServiceTest {

    private AttemptManager attemptManager;
    private ProductionSubmissionManager productionSubmissionManager;
    private ProductionBilanService productionBilanService;
    private TcfLevelEstimatorService levelEstimator;
    private FullTcfExamService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        UserManager userManager = mock(UserManager.class);
        productionSubmissionManager = mock(ProductionSubmissionManager.class);
        SubscriptionService subscriptionService = mock(SubscriptionService.class);
        AttemptService attemptService = mock(AttemptService.class);
        levelEstimator = mock(TcfLevelEstimatorService.class);
        productionBilanService = mock(ProductionBilanService.class);

        FullTcfExamResponseBuilder responseBuilder = new FullTcfExamResponseBuilder(
                attemptManager, productionSubmissionManager, levelEstimator, productionBilanService);
        service = new FullTcfExamService(
                attemptManager, userManager, productionSubmissionManager,
                subscriptionService, attemptService, responseBuilder);

        when(attemptManager.save(any(Attempt.class))).thenAnswer(inv -> inv.getArgument(0));
        when(levelEstimator.capB2(any())).thenAnswer(inv -> inv.getArgument(0));
        when(levelEstimator.min(any(), any())).thenReturn(NiveauCecrl.B1);
        when(productionSubmissionManager.findByAttemptId(any())).thenReturn(List.of());
        when(productionBilanService.latestEvalsByTache(any())).thenReturn(Map.of());
        when(productionBilanService.bilanEpreuve(any())).thenReturn(NiveauCecrl.B1);
        when(productionBilanService.bilanEpreuveTerminee(any())).thenReturn(NiveauCecrl.A1_NON_ATTEINT);
    }

    private Attempt parent(UUID id) {
        Attempt p = new Attempt();
        p.setId(id);
        User u = new User();
        u.setId(userId);
        p.setUser(u);
        p.setEpreuve(EpreuveType.TCF_COMPLET);
        p.setStartedAt(Instant.now());
        return p;
    }

    private Attempt sub(EpreuveType e, boolean finished) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        if (finished) {
            a.setFinishedAt(Instant.now());
            a.setStatus(AttemptStatus.TERMINE);
        }
        if ((e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE) && finished) {
            a.setCecrlLevel(NiveauCecrl.B1);
        }
        return a;
    }

    // ---- loadParentAndCheck (via get) ----

    @Test
    void get_parentIntrouvable_lanceNotFound() {
        UUID id = UUID.randomUUID();
        when(attemptManager.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.get(userId, id)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void get_parentAutreUtilisateur_lanceAccessDenied() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        p.getUser().setId(UUID.randomUUID()); // un autre user
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));

        assertThatThrownBy(() -> service.get(userId, id)).isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void get_pasUnExamenComplet_lanceBusiness() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        p.setEpreuve(EpreuveType.TCF_CO);
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));

        assertThatThrownBy(() -> service.get(userId, id)).isInstanceOf(BusinessException.class);
    }

    // ---- markSubAttemptDone ----

    @Test
    void markSubAttemptDone_epreuveNonProductive_refuse() {
        UUID id = UUID.randomUUID();
        when(attemptManager.findById(id)).thenReturn(Optional.of(parent(id)));

        assertThatThrownBy(() -> service.markSubAttemptDone(userId, id, EpreuveType.TCF_CO))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void markSubAttemptDone_marqueLeSousAttemptTermine() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        Attempt ee = sub(EpreuveType.TCF_EE, false);
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of(
                sub(EpreuveType.TCF_CO, true), sub(EpreuveType.TCF_CE, true),
                ee, sub(EpreuveType.TCF_EO, true)));

        service.markSubAttemptDone(userId, id, EpreuveType.TCF_EE);

        assertThat(ee.getFinishedAt()).isNotNull();
        assertThat(ee.getStatus()).isEqualTo(AttemptStatus.TERMINE);
        verify(attemptManager).save(ee);
    }

    @Test
    void markSubAttemptDone_sousAttemptIntrouvable_lanceNotFound() {
        UUID id = UUID.randomUUID();
        when(attemptManager.findById(id)).thenReturn(Optional.of(parent(id)));
        // Aucun sous-attempt EE dans la liste.
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of(sub(EpreuveType.TCF_CO, true)));

        assertThatThrownBy(() -> service.markSubAttemptDone(userId, id, EpreuveType.TCF_EE))
                .isInstanceOf(NotFoundException.class);
    }

    // ---- beginEpreuve ----

    @Test
    void beginEpreuve_ancreLesChronosParentEtSousEpreuve() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        Attempt co = sub(EpreuveType.TCF_CO, false);
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of(co));

        service.beginEpreuve(userId, id, EpreuveType.TCF_CO);

        assertThat(p.getTimerStartedAt()).isNotNull();
        assertThat(co.getTimerStartedAt()).isNotNull();
        assertThat(co.getStartedAt()).isNotNull();
    }

    @Test
    void beginEpreuve_idempotent_neReinitialisePasLeChronoParent() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        Instant fixed = Instant.now().minusSeconds(120);
        p.setTimerStartedAt(fixed);
        Attempt co = sub(EpreuveType.TCF_CO, false);
        co.setTimerStartedAt(fixed); // déjà commencé → pas retouché
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of(co));

        service.beginEpreuve(userId, id, EpreuveType.TCF_CO);

        assertThat(p.getTimerStartedAt()).isEqualTo(fixed);
        assertThat(co.getTimerStartedAt()).isEqualTo(fixed);
    }

    @Test
    void beginEpreuve_parentDejaTermine_neMuteRien() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        p.setFinishedAt(Instant.now());
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of(sub(EpreuveType.TCF_CO, true)));

        service.beginEpreuve(userId, id, EpreuveType.TCF_CO);

        assertThat(p.getTimerStartedAt()).isNull();
    }

    // ---- finish ----

    @Test
    void finish_sousAttemptNonTermine_refuse() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of(
                sub(EpreuveType.TCF_CO, true), sub(EpreuveType.TCF_CE, false)));

        assertThatThrownBy(() -> service.finish(userId, id)).isInstanceOf(BusinessException.class);
        assertThat(p.getFinishedAt()).isNull();
    }

    @Test
    void finish_tousTermines_marqueTermineEtPersisteCecrl() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        List<Attempt> subs = List.of(
                sub(EpreuveType.TCF_CO, true), sub(EpreuveType.TCF_CE, true),
                sub(EpreuveType.TCF_EE, true), sub(EpreuveType.TCF_EO, true));
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));
        when(attemptManager.findSubAttempts(id)).thenReturn(subs);

        FullTcfExamResponse r = service.finish(userId, id);

        assertThat(p.getFinishedAt()).isNotNull();
        assertThat(p.getStatus()).isEqualTo(AttemptStatus.TERMINE);
        assertThat(r.status()).isEqualTo(FullTcfExamResponse.FullTcfExamStatus.COMPLETED);
        assertThat(p.getFinalCecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(r.subAttempts()).hasSize(4);
    }

    // ---- listMine / findLatestForUser ----

    @Test
    void listMine_mappeLesParents() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        p.setSlotNumber(2);
        when(attemptManager.findByUserAndEpreuve(userId, EpreuveType.TCF_COMPLET, 20))
                .thenReturn(List.of(p));
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of());

        List<FullTcfExamSummaryResponse> list = service.listMine(userId, 20);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).id()).isEqualTo(id);
        assertThat(list.get(0).slotNumber()).isEqualTo(2);
    }

    @Test
    void findLatestForUser_aucunExamen_renvoieNull() {
        when(attemptManager.findByUserAndEpreuve(userId, EpreuveType.TCF_COMPLET, 1))
                .thenReturn(List.of());

        assertThat(service.findLatestForUser(userId)).isNull();
        verify(attemptManager, never()).findSubAttempts(any());
    }

    @Test
    void findLatestForUser_renvoieLeDernier() {
        UUID id = UUID.randomUUID();
        when(attemptManager.findByUserAndEpreuve(userId, EpreuveType.TCF_COMPLET, 1))
                .thenReturn(List.of(parent(id)));
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of());

        FullTcfExamResponse r = service.findLatestForUser(userId);

        assertThat(r).isNotNull();
        assertThat(r.id()).isEqualTo(id);
        verify(attemptManager, atLeastOnce()).findSubAttempts(id);
    }
}
