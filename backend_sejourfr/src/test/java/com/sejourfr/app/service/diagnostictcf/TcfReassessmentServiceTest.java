package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.dto.TcfReassessmentEligibilityDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.enums.TcfReassessmentBlocker;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.service.LearningPlanPriorityResolver;
import com.sejourfr.app.service.SkillMasteryEngine;
import com.sejourfr.app.service.SkillMasteryResolver;
import com.sejourfr.app.service.SubscriptionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * La boucle de reevaluation (L7, 10_ §4.6).
 *
 * <p>Ce qui est verrouille ici : les trois portes et leur <b>nature</b> (payer
 * ouvre la premiere, jamais la seconde), la derogation du Plan, et le fait que
 * le garde d'ouverture et l'ecran disent <b>la meme chose</b>.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TcfReassessmentServiceTest {

    @Mock private TcfDiagnosticSessionManager sessionManager;
    @Mock private SubscriptionService subscriptionService;
    @Mock private TcfDiagnosticReadService readService;
    @Mock private LearningPlanObservationManager observationManager;
    @Mock private LearningPlanPriorityResolver priorityResolver;
    @Mock private SkillMasteryResolver masteryResolver;

    private final TcfDiagnosticProperties props = new TcfDiagnosticProperties();
    private TcfReassessmentService service;

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-09-10T12:00:00Z");

    @BeforeEach
    void setUp() {
        service = new TcfReassessmentService(sessionManager, subscriptionService,
                readService, observationManager, priorityResolver, masteryResolver, props);
        when(observationManager.findAllByUserWithSkill(USER)).thenReturn(List.of());
        when(readService.sections(any())).thenReturn(List.of());
        when(readService.niveauGlobal(any())).thenReturn(Optional.empty());
    }

    private TcfDiagnosticSession session(TcfDiagnosticStatus status, Instant startedAt) {
        TcfDiagnosticSession s = new TcfDiagnosticSession();
        s.setId(UUID.randomUUID());
        User u = new User();
        u.setId(USER);
        s.setUser(u);
        s.setStatus(status);
        s.setStartedAt(startedAt);
        if (status == TcfDiagnosticStatus.COMPLETED) {
            s.setCompletedAt(startedAt.plus(1, ChronoUnit.HOURS));
        }
        return s;
    }

    @Test
    @DisplayName("Aucun diagnostic : le premier est offert, et ce n'est PAS une réévaluation")
    void premierOffert() {
        when(sessionManager.findLatest(USER)).thenReturn(Optional.empty());

        TcfReassessmentEligibilityDto e = service.eligibilite(USER, NOW);

        assertThat(e.canStart()).isTrue();
        assertThat(e.first()).isTrue();
        assertThat(e.blocker()).isNull();
        assertThat(e.locked()).isFalse();
        assertThat(e.lastSessionId()).isNull();
        // 🛑 Aucun abonnement n'est consulte : le premier ne se paye pas.
        verify(subscriptionService, never()).hasTcf(any());
    }

    @Test
    @DisplayName("Un diagnostic en cours : « Reprendre », sans porte ni délai")
    void enCoursSeReprend() {
        when(sessionManager.findLatest(USER))
                .thenReturn(Optional.of(session(TcfDiagnosticStatus.IN_PROGRESS,
                        NOW.minus(2, ChronoUnit.DAYS))));

        TcfReassessmentEligibilityDto e = service.eligibilite(USER, NOW);

        assertThat(e.canStart()).isTrue();
        assertThat(e.inProgress()).isTrue();
        assertThat(e.first()).isFalse();
        assertThat(e.blocker()).isNull();
        // 🛑 Aucun niveau n'est servi d'un diagnostic non clos : 10_ §4.2
        // interdit tout resultat partiel.
        assertThat(e.lastNiveauGlobal()).isNull();
    }

    @Test
    @DisplayName("Diagnostic consommé, pas d'accès TCF : porte COMMERCIALE, locked")
    void secondSansAcces() {
        when(sessionManager.findLatest(USER))
                .thenReturn(Optional.of(session(TcfDiagnosticStatus.COMPLETED,
                        NOW.minus(60, ChronoUnit.DAYS))));
        when(subscriptionService.hasTcf(USER)).thenReturn(false);

        TcfReassessmentEligibilityDto e = service.eligibilite(USER, NOW);

        assertThat(e.canStart()).isFalse();
        assertThat(e.blocker()).isEqualTo(TcfReassessmentBlocker.PREMIUM_REQUIRED);
        assertThat(e.locked()).isTrue();
        assertThat(e.message()).isEqualTo(TcfReassessmentService.MESSAGE_PREMIUM);
        // Le délai n'est pas le sujet : ne rien promettre.
        assertThat(e.availableAt()).isNull();
        assertThat(e.daysUntilAvailable()).isNull();
    }

    @Test
    @DisplayName("🛑 Délai non écoulé : ce n'est PAS un cadenas — payer ne l'ouvre pas")
    void delaiNonEcouleNestPasUnCadenas() {
        when(sessionManager.findLatest(USER))
                .thenReturn(Optional.of(session(TcfDiagnosticStatus.COMPLETED,
                        NOW.minus(3, ChronoUnit.DAYS))));
        when(subscriptionService.hasTcf(USER)).thenReturn(true);

        TcfReassessmentEligibilityDto e = service.eligibilite(USER, NOW);

        assertThat(e.canStart()).isFalse();
        assertThat(e.blocker()).isEqualTo(TcfReassessmentBlocker.INTERVAL_NOT_ELAPSED);
        assertThat(e.locked()).isFalse();
        assertThat(e.intervalDays()).isEqualTo(14);
        assertThat(e.daysUntilAvailable()).isEqualTo(11);
        assertThat(e.availableAt()).isEqualTo(NOW.plus(11, ChronoUnit.DAYS));
        assertThat(e.message()).contains("14 jours").contains("11 jours");
    }

    @Test
    @DisplayName("Délai écoulé et accès TCF : la réévaluation s'ouvre")
    void delaiEcoule() {
        when(sessionManager.findLatest(USER))
                .thenReturn(Optional.of(session(TcfDiagnosticStatus.COMPLETED,
                        NOW.minus(20, ChronoUnit.DAYS))));
        when(subscriptionService.hasTcf(USER)).thenReturn(true);

        TcfReassessmentEligibilityDto e = service.eligibilite(USER, NOW);

        assertThat(e.canStart()).isTrue();
        assertThat(e.blocker()).isNull();
        assertThat(e.triggeredByPlan()).isFalse();
    }

    @Test
    @DisplayName("Une priorité terminée depuis le diagnostic ouvre AVANT le délai (10_ §4.6)")
    void declencheParLePlan() {
        TcfDiagnosticSession dernier =
                session(TcfDiagnosticStatus.COMPLETED, NOW.minus(3, ChronoUnit.DAYS));
        when(sessionManager.findLatest(USER)).thenReturn(Optional.of(dernier));
        when(subscriptionService.hasTcf(USER)).thenReturn(true);
        etapeFranchieLe(NOW.minus(1, ChronoUnit.DAYS));

        TcfReassessmentEligibilityDto e = service.eligibilite(USER, NOW);

        assertThat(e.canStart()).isTrue();
        assertThat(e.triggeredByPlan()).isTrue();
        // La date reste servie : l'ecran doit pouvoir dire POURQUOI c'est ouvert
        // en avance, au lieu d'un bouton qui apparait sans raison.
        assertThat(e.availableAt()).isNotNull();
    }

    @Test
    @DisplayName("Une étape franchie AVANT le dernier diagnostic ne rouvre rien : elle y est déjà mesurée")
    void etapeAnterieureNeDeclenchePas() {
        TcfDiagnosticSession dernier =
                session(TcfDiagnosticStatus.COMPLETED, NOW.minus(3, ChronoUnit.DAYS));
        when(sessionManager.findLatest(USER)).thenReturn(Optional.of(dernier));
        when(subscriptionService.hasTcf(USER)).thenReturn(true);
        etapeFranchieLe(NOW.minus(10, ChronoUnit.DAYS));

        TcfReassessmentEligibilityDto e = service.eligibilite(USER, NOW);

        assertThat(e.canStart()).isFalse();
        assertThat(e.triggeredByPlan()).isFalse();
        assertThat(e.blocker()).isEqualTo(TcfReassessmentBlocker.INTERVAL_NOT_ELAPSED);
    }

    @Test
    @DisplayName("🛑 Le Plan ne dispense JAMAIS de l'accès TCF : il n'ouvre que la porte du délai")
    void lePlanNouvrePasLaPorteCommerciale() {
        when(sessionManager.findLatest(USER))
                .thenReturn(Optional.of(session(TcfDiagnosticStatus.COMPLETED,
                        NOW.minus(3, ChronoUnit.DAYS))));
        when(subscriptionService.hasTcf(USER)).thenReturn(false);
        etapeFranchieLe(NOW.minus(1, ChronoUnit.DAYS));

        TcfReassessmentEligibilityDto e = service.eligibilite(USER, NOW);

        assertThat(e.canStart()).isFalse();
        assertThat(e.blocker()).isEqualTo(TcfReassessmentBlocker.PREMIUM_REQUIRED);
    }

    @Test
    @DisplayName("Le garde d'ouverture rend EXACTEMENT le message servi à l'écran")
    void gardeEtEcranDisentLaMemeChose() {
        when(sessionManager.findLatest(USER))
                .thenReturn(Optional.of(session(TcfDiagnosticStatus.COMPLETED,
                        NOW.minus(60, ChronoUnit.DAYS))));
        when(subscriptionService.hasTcf(USER)).thenReturn(false);

        String servi = service.eligibilite(USER).message();

        assertThatThrownBy(() -> service.assertPeutOuvrirUnNouveau(USER))
                .isInstanceOf(BusinessException.class)
                .hasMessage(servi);
    }

    /** Une etape franchie a cette date, telle que le Plan la voit. */
    private void etapeFranchieLe(Instant quand) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode("ee_argumenter");
        LearningPlanObservation o = new LearningPlanObservation();
        o.setSkill(skill);
        o.setObservedAt(quand);
        List<LearningPlanObservation> historique = List.of(o);

        when(observationManager.findAllByUserWithSkill(USER)).thenReturn(historique);
        when(priorityResolver.latestObservedBySkill(historique))
                .thenReturn(Map.of(skill.getId(), o));
        Map<UUID, SkillMasteryEngine.SkillMastery> mastery = Map.of();
        when(masteryResolver.fromObservations(anyCollection(), anyCollection()))
                .thenReturn(mastery);
        when(priorityResolver.franchies(historique, mastery)).thenReturn(historique);
    }
}
