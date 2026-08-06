package com.sejourfr.app.service;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.dto.SkillAnalysisQuotaDto;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.access.AccessDeniedException;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Budget freemium des analyses IA.
 *
 * <p>Ce qui est verifie : premium illimite, 3 analyses offertes puis refus, et
 * surtout que le compteur porte sur les analyses DEMANDEES — c'est ce qui
 * empeche un retry gratuit apres echec d'en offrir une de plus.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillAnalysisAccessServiceTest {

    @Mock
    private SubscriptionService subscriptionService;
    @Mock
    private UserSkillAttemptManager attemptManager;

    private final CompetenceProperties props = new CompetenceProperties();

    private SkillAnalysisAccessService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new SkillAnalysisAccessService(subscriptionService, attemptManager, props);
    }

    @Test
    void premiumIsUnlimitedAndNeverCounted() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        assertThatCode(() -> service.assertCanAnalyse(userId)).doesNotThrowAnyException();
        // Aucun comptage : inutile de payer une requete pour un acces illimite.
        verify(attemptManager, never()).countAnalysesRequested(userId);
    }

    @Test
    void freeAccountIsAllowedUpToTheThirdAnalysis() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(2L);

        // 2 deja consommees : la 3e passe.
        assertThatCode(() -> service.assertCanAnalyse(userId)).doesNotThrowAnyException();
    }

    @Test
    void freeAccountIsRefusedOnTheFourthAnalysis() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(3L);

        assertThatThrownBy(() -> service.assertCanAnalyse(userId))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("3 analyses offertes");
    }

    @Test
    void refusalMentionsThatTrainingStaysFree() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(5L);

        // Le message ne doit pas laisser croire que le module entier se ferme :
        // produire et lire les references restent gratuits.
        assertThatThrownBy(() -> service.assertCanAnalyse(userId))
                .hasMessageContaining("entraîner");
    }

    @Test
    void quotaOfAPremiumAccountIsUnlimited() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(42L);

        SkillAnalysisQuotaDto quota = service.quota(userId);

        assertThat(quota.premium()).isTrue();
        assertThat(quota.unlimited()).isTrue();
        assertThat(quota.remaining()).isEqualTo(SkillAnalysisAccessService.UNLIMITED);
        assertThat(quota.freeAnalysesTotal()).isEqualTo(3);
    }

    @Test
    void quotaOfAFreeAccountReportsWhatIsLeft() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(1L);

        SkillAnalysisQuotaDto quota = service.quota(userId);

        assertThat(quota.premium()).isFalse();
        assertThat(quota.unlimited()).isFalse();
        assertThat(quota.freeAnalysesUsed()).isEqualTo(1);
        assertThat(quota.remaining()).isEqualTo(2);
    }

    @Test
    void remainingNeverGoesNegative() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        // Peut arriver si le nombre offert est reduit apres coup.
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(9L);

        assertThat(service.quota(userId).remaining()).isZero();
    }

    @Test
    void theNumberOfFreeAnalysesComesFromConfiguration() {
        props.getAnalysis().setFreeAnalyses(1);
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(1L);

        assertThatThrownBy(() -> service.assertCanAnalyse(userId))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("1 analyses offertes");
    }
}
