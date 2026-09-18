package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.FreeEntitlementUsage;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.FreeEntitlementCode;
import com.sejourfr.app.manager.FreeEntitlementUsageManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * <b>Les deux examens blancs de production offerts a vie</b> — D-17 et D-17 bis
 * (2026-09-18).
 *
 * <p>Ce que ce test verrouille : <b>quand</b> la gratuite se consomme, et
 * <b>quand elle ne se consomme pas</b>. C'est le point le plus cher de
 * l'arbitrage : une gratuite consommee a tort fait perdre au candidat une
 * correction LLM complete qu'il n'a jamais recue.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class FreeExamEntitlementServiceTest {

    @Mock private FreeEntitlementUsageManager ledger;
    @Mock private SubscriptionService subscriptionService;
    @Mock private ProductionSubmissionManager submissionManager;

    private FreeExamEntitlementService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID submissionId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new FreeExamEntitlementService(ledger, subscriptionService, submissionManager);
        when(ledger.find(any(), any())).thenReturn(Optional.empty());
    }

    // ------------------------------------------------------------------- lecture

    @Test
    @DisplayName("Gratuite intacte : l'analyse offerte est possible")
    void gratuiteIntacte() {
        assertThat(service.analyseOffertePossible(
                userId, EpreuveType.TCF_EE, UUID.randomUUID())).isTrue();
    }

    /**
     * 🛑 <b>Un examen, c'est 3 taches.</b> La gratuite est ecrite des la
     * premiere analyse rendue ; les deux taches suivantes <b>du meme attempt</b>
     * restent dues au titre de la meme gratuite. C'est a cela que sert
     * {@code source_attempt_id}.
     */
    @Test
    @DisplayName("Les 2 taches restantes du MEME examen restent offertes")
    void lesTachesRestantesDuMemeExamenRestentOffertes() {
        Attempt examen = examSession(EpreuveType.TCF_EE);
        when(ledger.find(userId, FreeEntitlementCode.EXAM_BLANC_EE))
                .thenReturn(Optional.of(usage(examen)));

        assertThat(service.analyseOffertePossible(
                userId, EpreuveType.TCF_EE, examen.getId())).isTrue();
    }

    /** Un AUTRE examen de la meme epreuve : c'est un rejeu, il est premium. */
    @Test
    @DisplayName("Un rejeu — autre attempt — n'a plus droit a l'analyse offerte")
    void unRejeuNAPlusDroitALAnalyseOfferte() {
        when(ledger.find(userId, FreeEntitlementCode.EXAM_BLANC_EE))
                .thenReturn(Optional.of(usage(examSession(EpreuveType.TCF_EE))));

        assertThat(service.analyseOffertePossible(
                userId, EpreuveType.TCF_EE, UUID.randomUUID())).isFalse();
    }

    /** CO / CE / TCF_COMPLET ne portent aucune gratuite de ce ledger. */
    @Test
    @DisplayName("Une epreuve sans gratuite nommee ne peut pas en consommer")
    void uneEpreuveSansGratuiteNommee() {
        assertThat(service.estConsomme(userId, EpreuveType.TCF_CO)).isFalse();
        assertThat(service.analyseOffertePossible(
                userId, EpreuveType.TCF_COMPLET, UUID.randomUUID())).isFalse();
        verify(ledger, never()).estConsomme(any(), any());
    }

    // --------------------------------------------------------------- ecriture

    /** Le cas nominal : examen blanc EE d'un compte gratuit, analyse rendue. */
    @Test
    @DisplayName("D-17 — l'analyse rendue d'un examen blanc EE consomme la gratuite EE")
    void lAnalyseRendueConsommeLaGratuiteDeSonEpreuve() {
        ProductionSubmission submission = submission(examSession(EpreuveType.TCF_EE), false);
        when(submissionManager.findByIdWithTaskAndUser(submissionId))
                .thenReturn(Optional.of(submission));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        service.consommerApresAnalyse(submissionId);

        verify(ledger).consommer(
                eq(submission.getUser()), eq(FreeEntitlementCode.EXAM_BLANC_EE), any());
    }

    /**
     * D-17 bis — <b>deux gratuites nominatives</b> : un examen EO consomme
     * {@code EXAM_BLANC_EO}, et laisse {@code EXAM_BLANC_EE} intacte.
     */
    @Test
    @DisplayName("D-17 bis — EE et EO sont INDEPENDANTES")
    void eeEtEoSontIndependantes() {
        ProductionSubmission submission = submission(examSession(EpreuveType.TCF_EO), false);
        when(submissionManager.findByIdWithTaskAndUser(submissionId))
                .thenReturn(Optional.of(submission));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        service.consommerApresAnalyse(submissionId);

        verify(ledger).consommer(any(), eq(FreeEntitlementCode.EXAM_BLANC_EO), any());
        verify(ledger, never()).consommer(any(), eq(FreeEntitlementCode.EXAM_BLANC_EE), any());
    }

    /**
     * Le ledger dit « ceci lui a ete <b>offert</b> ». Un abonne n'a rien recu en
     * cadeau : lui ecrire une ligne lui confisquerait sa gratuite pour le jour ou
     * il se desabonnerait.
     */
    @Test
    @DisplayName("Un abonne ne consomme AUCUNE gratuite")
    void unAbonneNeConsommeAucuneGratuite() {
        ProductionSubmission submission = submission(examSession(EpreuveType.TCF_EE), false);
        when(submissionManager.findByIdWithTaskAndUser(submissionId))
                .thenReturn(Optional.of(submission));
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        service.consommerApresAnalyse(submissionId);

        verify(ledger, never()).consommer(any(), any(), any());
    }

    /**
     * Un entrainement libre (ni slot, ni parent) n'est pas un examen blanc : il
     * n'a rien a consommer — et depuis D-17 il est de toute facon premium.
     */
    @Test
    @DisplayName("Un entrainement libre ne consomme rien")
    void unEntrainementLibreNeConsommeRien() {
        Attempt libre = new Attempt();
        libre.setId(UUID.randomUUID());
        libre.setEpreuve(EpreuveType.TCF_EE);
        ProductionSubmission submission = submission(libre, false);
        when(submissionManager.findByIdWithTaskAndUser(submissionId))
                .thenReturn(Optional.of(submission));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        service.consommerApresAnalyse(submissionId);

        verify(ledger, never()).consommer(any(), any(), any());
    }

    /**
     * 🛑 Le <b>diagnostic rapide est gratuit par lui-meme</b> : il ne consomme
     * jamais une gratuite d'examen blanc. Meme discipline que le filtre
     * {@code tcfDiagnostic IS NULL} des six autres requetes.
     */
    @Test
    @DisplayName("Une production de DIAGNOSTIC ne consomme aucune gratuite")
    void uneProductionDeDiagnosticNeConsommeRien() {
        ProductionSubmission submission = submission(examSession(EpreuveType.TCF_EE), true);
        when(submissionManager.findByIdWithTaskAndUser(submissionId))
                .thenReturn(Optional.of(submission));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        service.consommerApresAnalyse(submissionId);

        verify(ledger, never()).consommer(any(), any(), any());
    }

    /**
     * L'ecriture est un enrichissement de fin de pipeline : elle ne doit
     * <b>jamais</b> degrader une analyse deja rendue. Le candidat a recu sa
     * correction, c'est ce qui compte.
     */
    @Test
    @DisplayName("Une erreur d'ecriture ne remonte jamais a l'appelant")
    void uneErreurDEcritureEstAvalee() {
        when(submissionManager.findByIdWithTaskAndUser(submissionId))
                .thenThrow(new IllegalStateException("base indisponible"));

        service.consommerApresAnalyse(submissionId);
    }

    // ------------------------------------------------------------- fabriques

    private Attempt examSession(EpreuveType epreuve) {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setEpreuve(epreuve);
        attempt.setSlotNumber(1);
        return attempt;
    }

    private ProductionSubmission submission(Attempt attempt, boolean diagnostic) {
        User user = new User();
        user.setId(userId);
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(attempt.getEpreuve());
        if (diagnostic) {
            task.setDiagnosticCode("INITIAL_TCF");
            task.setDiagnosticVersion(1);
        }
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(submissionId);
        submission.setUser(user);
        submission.setAttempt(attempt);
        submission.setProductionTask(task);
        submission.setDiagnostic(diagnostic);
        return submission;
    }

    private FreeEntitlementUsage usage(Attempt source) {
        FreeEntitlementUsage usage = new FreeEntitlementUsage();
        usage.setId(UUID.randomUUID());
        usage.setCode(FreeEntitlementCode.EXAM_BLANC_EE);
        usage.setSourceAttempt(source);
        return usage;
    }
}
