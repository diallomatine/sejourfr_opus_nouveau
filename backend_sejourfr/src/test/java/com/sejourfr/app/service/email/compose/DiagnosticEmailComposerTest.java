package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.LearningPlanService;
import com.sejourfr.app.service.email.EmailLinks;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DiagnosticEmailComposerTest {

    private final UUID userId = UUID.randomUUID();
    private final UUID sessionId = UUID.randomUUID();
    private UserManager userManager;
    private LearningPlanService learningPlanService;
    private CivicPlanService civicPlanService;
    private DiagnosticEmailComposer composer;

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        learningPlanService = mock(LearningPlanService.class);
        civicPlanService = mock(CivicPlanService.class);
        EmailLinks links = new EmailLinks("https://sejourfr.fr", "https://api.sejourfr.fr");
        composer = new DiagnosticEmailComposer(new AccountEmailComposer(userManager, links),
                learningPlanService, civicPlanService, links);
        User u = new User();
        u.setId(userId);
        u.setEmail("alice@example.com");
        u.setFirstName("Alice");
        when(userManager.findById(userId)).thenReturn(Optional.of(u));
    }

    private static LearningPlanPriorityDto priority(String title) {
        LearningPlanPriorityDto p = mock(LearningPlanPriorityDto.class);
        when(p.title()).thenReturn(title);
        return p;
    }

    @Test
    void auPlusTroisPrioritesServiesDansLOrdre() {
        LearningPlanDto plan = mock(LearningPlanDto.class);
        LearningPlanPriorityDto first = priority("Organiser un texte");
        List<LearningPlanPriorityDto> next = List.of(priority("Accorder le participe"),
                priority("Argumenter"), priority("Quatrieme"));
        when(plan.currentPriority()).thenReturn(first);
        when(plan.nextPriorities()).thenReturn(next);
        when(learningPlanService.get(userId)).thenReturn(plan);

        EmailRequest r = composer.planReady(userId, Module.TCF, sessionId, EmailRequest.Origin.EVENT).orElseThrow();

        assertThat(r.type()).isEqualTo(EmailType.DIAGNOSTIC_PLAN_READY);
        assertThat(r.deduplicationKey()).isEqualTo("DIAGNOSTIC_PLAN_READY:" + userId + ":TCF");
        assertThat(r.variables()).containsEntry("priority1", "Organiser un texte")
                .containsEntry("priority2", "Accorder le participe")
                .containsEntry("priority3", "Argumenter")
                .containsEntry("planUrl", "https://sejourfr.fr/plan?module=TCF")
                .containsEntry("diagnosticType", "TCF");
        assertThat(r.variables().values()).doesNotContain("Quatrieme");
    }

    @Test
    void unPlanAvecUneSeulePrioriteLaisseLesAutresVides() {
        CivicPlanDto plan = mock(CivicPlanDto.class);
        CivicPlanDto.Cible cible = mock(CivicPlanDto.Cible.class);
        when(cible.label()).thenReturn("La laïcité");
        when(plan.prioritesVisibles()).thenReturn(List.of(cible));
        when(civicPlanService.plan(userId)).thenReturn(plan);

        EmailRequest r = composer.planReady(userId, Module.CIVIQUE, sessionId, EmailRequest.Origin.EVENT).orElseThrow();

        assertThat(r.variables()).containsEntry("priority1", "La laïcité")
                .containsEntry("priority2", "").containsEntry("priority3", "")
                .containsEntry("diagnosticType", "civique");
    }

    @Test
    void unPlanIllisibleDonneUnMailSansPrioriteInventee() {
        when(learningPlanService.get(userId)).thenThrow(new IllegalStateException("boom"));

        EmailRequest r = composer.planReady(userId, Module.TCF, sessionId, EmailRequest.Origin.EVENT).orElseThrow();

        assertThat(r.variables()).containsEntry("prioritiesIntro", "")
                .containsEntry("priority1", "").containsEntry("priority2", "").containsEntry("priority3", "");
    }

    @Test
    void unCompteSupprimeNeRecoitRien() {
        User deleted = new User();
        deleted.setId(userId);
        deleted.setEmail("deleted@anon.sejourfr");
        deleted.setDeletedAt(Instant.now());
        when(userManager.findById(userId)).thenReturn(Optional.of(deleted));

        assertThat(composer.planReady(userId, Module.TCF, sessionId, EmailRequest.Origin.EVENT)).isEmpty();
    }
}
