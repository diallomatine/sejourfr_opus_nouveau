package com.sejourfr.app.progression;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.service.ProductiveEvidenceAdapter;
import com.sejourfr.app.progression.service.ProductiveEvidenceAdapter.ObservationCompetence;
import com.sejourfr.app.progression.service.ProgressionReadService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>T20, T21, T22 en conditions réelles</b> — le parcours d'une compétence
 * d'expression, du micro-sujet à l'acquis.
 *
 * <p>Ce que ce fichier interdit tient en une phrase : <b>on ne devient pas bon
 * en production en cochant des micro-consignes</b>. Le cap de confiance (§11.1)
 * et le {@code transferGate} (§17) sont là pour ça, et ils travaillent ensemble
 * — l'un empêche la masse de suffire, l'autre exige la preuve du transfert.
 *
 * <p><b>Hors transaction de test</b> ({@link Propagation#NOT_SUPPORTED}, même
 * montage que {@code ComprehensionObservationIT}) : l'adaptateur écrit dans sa
 * PROPRE transaction et ne verrait rien d'une transaction de test non commitée.
 * C'est précisément ce montage qu'on veut exercer — le neutraliser pour la
 * commodité du test reviendrait à ne pas le tester. Le ménage se fait donc à la
 * main.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class ProgressionProductiveIT extends AbstractIntegrationTest {

    @Autowired ProductiveEvidenceAdapter adapter;
    @Autowired ProgressionReadService readService;
    @Autowired AccountDeletionService accountDeletionService;
    @Autowired TestData data;

    private final List<User> crees = new ArrayList<>();

    private User utilisateur() {
        User user = data.user();
        crees.add(user);
        return user;
    }

    /**
     * Ménage explicite : hors transaction de test, rien ne s'annule tout seul.
     * Les quatre tables de progression sont en {@code ON DELETE CASCADE} sur
     * {@code users}, la suppression du compte suffit donc.
     */
    @AfterEach
    void nettoie() {
        crees.forEach(user -> accountDeletionService.deleteAccount(user.getId()));
        crees.clear();
    }

    private static final Instant T0 = Instant.parse("2026-03-01T09:00:00Z");
    private static final String COMPETENCE = "EE_CONNECTEURS_B1";

    /**
     * 🛑 Le test le plus important du fichier — T20.
     *
     * <p>Vingt micro-sujets parfaits : {@code masteryScore} vaut 1,0, et la
     * compétence n'est <b>toujours pas</b> acquise. C'est voulu. Le candidat a
     * montré qu'il sait appliquer une consigne isolée ; il n'a pas montré qu'il
     * sait produire.
     */
    @Test
    @DisplayName("T20 — vingt micro-sujets parfaits ne rendent jamais SOLID")
    void vingtMicroSujetsNeSuffisentPas() {
        User user = utilisateur();
        for (int i = 0; i < 20; i++) {
            adapter.ingererMicroSujet(user.getId(), UUID.randomUUID(), UUID.randomUUID(),
                    SkillSection.EE, COMPETENCE, SkillCriterionStatus.VALIDATED, true,
                    T0.plus(Duration.ofHours(i)));
        }

        ProgressionSnapshot etat = etat(user.getId(), T0.plus(Duration.ofDays(1)));

        assertThat(etat.masteryScore()).isEqualTo(1.0d);
        assertThat(etat.transferGate()).isFalse();
        assertThat(etat.status()).isNotEqualTo(ProgressionStatus.SOLID);
        // Le cap : la masse micro dépasse largement 0,80, la confiance non.
        assertThat(etat.microSumWeightEpoch()).isGreaterThan(0.80d);
        assertThat(etat.confidence()).isLessThan(0.60d);
    }

    @Test
    @DisplayName("T21 — quelques micro-sujets rendent la compétence prête à vérifier")
    void microSujetsMenentAPretAVerifier() {
        User user = utilisateur();
        for (int i = 0; i < 6; i++) {
            adapter.ingererMicroSujet(user.getId(), UUID.randomUUID(), UUID.randomUUID(),
                    SkillSection.EE, COMPETENCE, SkillCriterionStatus.VALIDATED, false,
                    T0.plus(Duration.ofHours(i)));
        }

        ProgressionSnapshot etat = etat(user.getId(), T0.plus(Duration.ofDays(1)));

        assertThat(etat.masteryScore()).isGreaterThanOrEqualTo(0.70d);
        assertThat(etat.confidence()).isGreaterThanOrEqualTo(0.50d);
        assertThat(etat.transferGate()).isFalse();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.READY_FOR_REASSESSMENT);
    }

    /**
     * T22 et invariant I28 — on n'impose pas les cinq micro-sujets à qui a déjà
     * prouvé le transfert. Deux vraies tâches suffisent.
     */
    @Test
    @DisplayName("T22 — deux vraies tâches rendent SOLID, sans un seul micro-sujet")
    void deuxVraiesTachesSuffisent() {
        User user = utilisateur();
        tacheComplete(user.getId(), UUID.randomUUID(), T0);
        tacheComplete(user.getId(), UUID.randomUUID(), T0.plus(Duration.ofDays(2)));

        ProgressionSnapshot etat = etat(user.getId(), T0.plus(Duration.ofDays(3)));

        assertThat(etat.transferGate()).isTrue();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.SOLID);
        assertThat(etat.visibleProgress()).isEqualTo(100);
    }

    /**
     * Le parcours nominal du module Compétences : les micro-sujets amènent à
     * « prêt à vérifier », la vraie tâche confirme.
     */
    @Test
    @DisplayName("Micro-sujets puis vraie tâche : la compétence bascule enfin en acquis")
    void leTransfertConfirmeLesMicroSujets() {
        User user = utilisateur();
        for (int i = 0; i < 6; i++) {
            adapter.ingererMicroSujet(user.getId(), UUID.randomUUID(), UUID.randomUUID(),
                    SkillSection.EE, COMPETENCE, SkillCriterionStatus.VALIDATED, false,
                    T0.plus(Duration.ofHours(i)));
        }
        assertThat(etat(user.getId(), T0.plus(Duration.ofDays(1))).status())
                .isEqualTo(ProgressionStatus.READY_FOR_REASSESSMENT);

        tacheComplete(user.getId(), UUID.randomUUID(), T0.plus(Duration.ofDays(1)));

        assertThat(etat(user.getId(), T0.plus(Duration.ofDays(2))).status())
                .isEqualTo(ProgressionStatus.SOLID);
    }

    /** Une compétence non observée reste invisible : rien n'est écrit. */
    @Test
    @DisplayName("Une production qui n'observe pas la compétence ne la fait pas exister")
    void nonObserveNeCreeRien() {
        User user = utilisateur();

        adapter.ingererProduction(user.getId(), UUID.randomUUID(), UUID.randomUUID(),
                SkillSection.EE, EvidenceSourceType.FULL_TASK, EvidenceEntryPoint.PLAN, T0,
                List.of(new ObservationCompetence(COMPETENCE, false,
                        LearningPlanSkillStatus.NOT_OBSERVED, ObservationConfidence.LOW)));

        ProgressionSnapshot etat = etat(user.getId(), T0.plus(Duration.ofDays(1)));
        assertThat(etat.status()).isEqualTo(ProgressionStatus.NOT_EVALUATED);
        assertThat(etat.masteryScore()).isNull();
        assertThat(etat.visibleProgress()).isNull();
    }

    private void tacheComplete(UUID userId, UUID sujetId, Instant quand) {
        adapter.ingererProduction(userId, UUID.randomUUID(), sujetId, SkillSection.EE,
                EvidenceSourceType.FULL_TASK, EvidenceEntryPoint.PLAN, quand,
                List.of(new ObservationCompetence(COMPETENCE, true,
                        LearningPlanSkillStatus.SOLID, ObservationConfidence.HIGH)));
    }

    private ProgressionSnapshot etat(UUID userId, Instant quand) {
        return readService.competence(userId, SkillSection.EE, COMPETENCE, quand);
    }
}
