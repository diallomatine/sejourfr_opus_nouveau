package com.sejourfr.app.service;

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
 * <b>L'analyse IA du module Competences est PREMIUM, point</b> — arbitrage
 * <b>D-17</b> du 2026-09-18.
 *
 * <h2>Ce que ce test verifiait, et qui est revoque</h2>
 * <p>Il verrouillait « 3 analyses offertes a vie puis refus », et que le
 * compteur porte sur les analyses <b>demandees</b> (pour qu'un retry gratuit
 * apres echec n'en offre pas une de plus). D-17 <b>supprime</b>
 * {@code sejourfr.competences.analysis.free-analyses: 3} et ne le remplace
 * <b>par rien</b> :
 * <blockquote>« les <b>3 analyses IA offertes a vie ne bougent pas</b> : un sujet
 * ouvert reste analysable dans la limite du quota existant » — revoque.</blockquote>
 *
 * <p>🛑 <b>Et aucun quota journalier ne le remplace</b> : le premier jet de la
 * spec proposait « 1 analyse IA / jour », l'arbitrage est plus simple.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillAnalysisAccessServiceTest {

    @Mock
    private SubscriptionService subscriptionService;
    @Mock
    private UserSkillAttemptManager attemptManager;

    private SkillAnalysisAccessService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new SkillAnalysisAccessService(subscriptionService, attemptManager);
    }

    @Test
    void premiumIsUnlimitedAndNeverCounted() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        assertThatCode(() -> service.assertCanAnalyse(userId)).doesNotThrowAnyException();
        // Aucun comptage : inutile de payer une requete pour un acces illimite.
        verify(attemptManager, never()).countAnalysesRequested(userId);
    }

    /**
     * D-17 — <b>la premiere analyse est deja refusee</b> : il n'y en a plus
     * aucune d'offerte, et le compteur n'est meme plus lu.
     */
    @Test
    void laPremiereAnalyseDUnCompteGratuitEstDejaRefusee_D17() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(0L);

        assertThatThrownBy(() -> service.assertCanAnalyse(userId))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage(SkillAnalysisAccessService.LOCKED_MESSAGE);
        verify(attemptManager, never()).countAnalysesRequested(userId);
    }

    /**
     * Le message reste <b>affichable tel quel</b> et nomme ce qui est encore
     * offert : les deux examens blancs de production, corriges en entier.
     */
    @Test
    void leRefusNommeLesDeuxExamensBlancsOfferts() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        assertThatThrownBy(() -> service.assertCanAnalyse(userId))
                .hasMessageContaining("accès TCF")
                .hasMessageContaining("expression écrite")
                .hasMessageContaining("expression orale");
    }

    @Test
    void quotaOfAPremiumAccountIsUnlimited() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(42L);

        SkillAnalysisQuotaDto quota = service.quota(userId);

        assertThat(quota.premium()).isTrue();
        assertThat(quota.unlimited()).isTrue();
        assertThat(quota.remaining()).isEqualTo(SkillAnalysisAccessService.UNLIMITED);
    }

    /**
     * D-17 — le contrat servi ne change pas de <b>forme</b> (les deux fronts le
     * lisent), mais ses valeurs sont devenues degenerees : aucune analyse
     * offerte, aucune restante. Seul {@code freeAnalysesUsed} reste un fait.
     */
    @Test
    void leQuotaServiEstDesormaisDegenere_D17() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countAnalysesRequested(userId)).thenReturn(1L);

        SkillAnalysisQuotaDto quota = service.quota(userId);

        assertThat(quota.premium()).isFalse();
        assertThat(quota.unlimited()).isFalse();
        assertThat(quota.freeAnalysesTotal()).isZero();
        assertThat(quota.freeAnalysesUsed()).isEqualTo(1);
        assertThat(quota.remaining()).isZero();
    }
}
