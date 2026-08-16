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
                attemptManager, mock(com.sejourfr.app.manager.AnswerManager.class),
                productionSubmissionManager, levelEstimator, productionBilanService);
        // Le verrou EE/EO d'un examen complet vit desormais dans
        // ProductionAccessService, qui le sert AUSSI en lecture au jalon du
        // Plan. On le construit ICI POUR DE VRAI, sur les memes mocks : c'est ce
        // qui garantit que le cadenas affiche et le verrou applique restent la
        // meme regle.
        ProductionAccessService productionAccessService = new ProductionAccessService(
                subscriptionService, attemptManager, productionSubmissionManager,
                mock(com.sejourfr.app.manager.DiagnosticSessionManager.class));
        service = new FullTcfExamService(
                attemptManager, userManager, attemptService,
                mock(com.sejourfr.app.service.attempt.AttemptInteractionService.class),
                productionAccessService, responseBuilder);

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

    /**
     * Sous-épreuve <b>lancée</b> par le candidat ({@code timerStartedAt} posé,
     * la seule ancre d'une sous-épreuve), terminée ou non. Sans cette ancre et
     * sans rien de rendu, elle serait « jamais ouverte » et n'aurait aucun
     * niveau — cf. {@link #jamaisOuverte}.
     */
    private Attempt sub(EpreuveType e, boolean finished) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        a.setTimerStartedAt(Instant.now().minusSeconds(1800));
        if (finished) {
            a.setFinishedAt(Instant.now());
            a.setStatus(AttemptStatus.TERMINE);
        }
        if ((e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE) && finished) {
            a.setCecrlLevel(NiveauCecrl.B1);
        }
        return a;
    }

    /**
     * Sous-épreuve <b>jamais ouverte</b> : aucune ancre de chrono, rien de
     * rendu. C'est l'état des EE/EO d'un candidat qui quitte après la CE.
     */
    private Attempt jamaisOuverte(EpreuveType e) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        return a;
    }

    // ---- loadParentAndCheck (via get) ----

    @Test
    void get_parentIntrouvable_lanceNotFound() {
        UUID id = UUID.randomUUID();
        when(attemptManager.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.get(userId, id)).isInstanceOf(NotFoundException.class);
    }

    /**
     * L'examen d'autrui répond « introuvable », pas « interdit » : un 403
     * confirmait l'EXISTENCE de l'id à qui ne le possède pas. Aligné sur les
     * endpoints voisins.
     */
    @Test
    void get_parentAutreUtilisateur_lanceNotFound() {
        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        p.getUser().setId(UUID.randomUUID()); // un autre user
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));

        assertThatThrownBy(() -> service.get(userId, id)).isInstanceOf(NotFoundException.class);
    }

    /** Même réponse que pour un id inexistant : rien ne distingue les deux cas. */
    @Test
    void get_parentAutreUtilisateur_memeReponseQuUnIdInexistant() {
        UUID mien = UUID.randomUUID();
        UUID autrui = UUID.randomUUID();
        Attempt p = parent(autrui);
        p.getUser().setId(UUID.randomUUID());
        when(attemptManager.findById(mien)).thenReturn(Optional.empty());
        when(attemptManager.findById(autrui)).thenReturn(Optional.of(p));

        Class<?> inexistant = catchClass(() -> service.get(userId, mien));
        Class<?> dAutrui = catchClass(() -> service.get(userId, autrui));

        assertThat(dAutrui).isEqualTo(inexistant);
    }

    private static Class<?> catchClass(Runnable r) {
        try {
            r.run();
            throw new AssertionError("Exception attendue");
        } catch (RuntimeException e) {
            return e.getClass();
        }
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
        // Épreuve pas encore lancée : c'est justement ce que beginEpreuve ancre.
        Attempt co = jamaisOuverte(EpreuveType.TCF_CO);
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

    /**
     * Le scénario réel du défaut : le candidat termine la CO (A2) et la CE
     * (A1), puis quitte. Les fronts clôturent l'EE et l'EO — jamais lancées,
     * zéro soumission — parce que {@code finish} refuse tant qu'un
     * sous-attempt n'est pas terminé, et l'abandon volontaire est un geste
     * valide (aucun refus posé sur {@code markSubAttemptDone}).
     *
     * <p>Avant correction, ces deux épreuves valaient A1_NON_ATTEINT : le
     * plancher tombait au plus bas, écrasait la CO et la CE, et
     * {@code finalLevelPartial} restait false — l'écran affirmait un bilan
     * complet sur 4 épreuves. Désormais elles n'ont aucun niveau, le plancher
     * ne porte que sur les deux épreuves réellement jouées, et le bilan le dit.
     */
    @Test
    void finish_epreuvesJamaisOuvertes_neFondentPasLeNiveauFinal() {
        TcfLevelEstimatorService reel = new TcfLevelEstimatorService();
        when(levelEstimator.min(any(), any()))
                .thenAnswer(inv -> reel.min(inv.getArgument(0), inv.getArgument(1)));

        UUID id = UUID.randomUUID();
        Attempt p = parent(id);
        Attempt co = sub(EpreuveType.TCF_CO, true);
        co.setCecrlLevel(NiveauCecrl.A2);
        Attempt ce = sub(EpreuveType.TCF_CE, true);
        ce.setCecrlLevel(NiveauCecrl.A1);
        Attempt ee = jamaisOuverte(EpreuveType.TCF_EE);
        Attempt eo = jamaisOuverte(EpreuveType.TCF_EO);
        when(attemptManager.findById(id)).thenReturn(Optional.of(p));
        when(attemptManager.findSubAttempts(id)).thenReturn(List.of(co, ce, ee, eo));

        // Abandon volontaire : les fronts clôturent les épreuves restantes
        // AVANT d'appeler finish. Aucun refus ici — c'est le verdict qui était
        // faux, pas le geste.
        service.markSubAttemptDone(userId, id, EpreuveType.TCF_EE);
        service.markSubAttemptDone(userId, id, EpreuveType.TCF_EO);
        assertThat(ee.getFinishedAt()).isNotNull();

        FullTcfExamResponse r = service.finish(userId, id);

        assertThat(r.subAttempts()).hasSize(4);
        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).cecrlLevel()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isFalse();
        // Plancher des seules épreuves passées : min(A2, A1) = A1.
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.A1);
        assertThat(p.getFinalCecrlLevel()).isEqualTo(NiveauCecrl.A1);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(2);
        assertThat(r.epreuvesExpected()).isEqualTo(4);
        assertThat(r.finalLevelPartial()).isTrue();
        // Aucun bilan de production n'est même calculé sur une épreuve absente.
        verify(productionBilanService, never()).bilanEpreuveTerminee(any());
    }

    private static FullTcfExamResponse.SubAttempt subOf(FullTcfExamResponse r, EpreuveType e) {
        return r.subAttempts().stream().filter(s -> s.epreuve() == e).findFirst().orElseThrow();
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
