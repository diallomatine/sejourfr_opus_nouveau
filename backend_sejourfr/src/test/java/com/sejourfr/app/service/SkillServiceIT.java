package com.sejourfr.app.service;

import com.sejourfr.app.dto.SkillDetailDto;
import com.sejourfr.app.dto.SkillPromptSummaryDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.mapper.SkillMapper;
import com.sejourfr.app.mapper.SkillPromptMapper;
import com.sejourfr.app.mapper.SkillReferenceMapper;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * {@code GET /api/skills/{id}} contre la <b>vraie base</b>, sur le point qui
 * coute cher : le <b>nombre de requetes</b>.
 *
 * <p>Une liste de competence, c'est 15 sujets, et les ecrans en enchainent 24 :
 * si {@code lastAttemptId} avait ete resolu sujet par sujet, la regression
 * serait restee invisible en unitaire et couteuse en production. On compte donc
 * les requetes reellement preparees par Hibernate — technique de
 * {@link SkillMasteryResolverIT} — et on verifie que le total <b>ne bouge pas</b>
 * quand le nombre de sujets passe de 1 a 15.
 *
 * <p>Le service est construit a la main autour des beans reels : seul
 * {@link CurrentUser} est double, parce qu'il lit le {@code SecurityContext} et
 * n'a rien a voir avec ce qu'on mesure ici.
 */
class SkillServiceIT extends AbstractIntegrationTest {

    /** Ce que publie une competence reelle (cf. {@code SkillSeedIT}). */
    private static final int PROMPTS_PER_SKILL = 15;

    @Autowired private TestData data;
    @Autowired private EntityManager entityManager;
    @Autowired private SkillManager skillManager;
    @Autowired private SkillPromptManager promptManager;
    @Autowired private UserSkillAttemptManager attemptManager;
    @Autowired private SkillStatusResolver statusResolver;
    @Autowired private SkillAccessService accessService;
    @Autowired private SkillMasteryResolver masteryResolver;
    @Autowired private SkillMapper skillMapper;
    @Autowired private SkillPromptMapper promptMapper;
    @Autowired private SkillReferenceMapper referenceMapper;

    private CurrentUser currentUser;
    private SkillService service;

    @BeforeEach
    void setUp() {
        currentUser = Mockito.mock(CurrentUser.class);
        service = new SkillService(skillManager, promptManager, attemptManager, statusResolver,
                accessService, masteryResolver, skillMapper, promptMapper, referenceMapper,
                currentUser);
    }

    @Test
    @DisplayName("La derniere tentative de chaque sujet est servie avec la liste")
    void laDerniereTentativeEstServieAvecLaListe() {
        User user = data.user();
        Mockito.when(currentUser.getId()).thenReturn(user.getId());
        Skill skill = data.skill();
        SkillPrompt traite = data.skillPrompt(skill);
        SkillPrompt jamaisTente = data.skillPrompt(skill);
        UserSkillAttempt derniere = data.userSkillAttempt(user, traite);
        entityManager.flush();
        entityManager.clear();

        SkillDetailDto detail = service.detail(skill.getId());

        SkillPromptSummaryDto premier = byId(detail, traite.getId());
        SkillPromptSummaryDto second = byId(detail, jamaisTente.getId());
        assertThat(premier.lastAttemptId()).isEqualTo(derniere.getId());
        assertThat(premier.lastAttemptAt()).isNotNull();
        // Jamais tente : rien a relire. Les fronts entrent alors directement en
        // production, sans proposer de choix.
        assertThat(second.lastAttemptId()).isNull();
        assertThat(second.lastAttemptAt()).isNull();
    }

    @Test
    @DisplayName("C'est la DERNIERE tentative qui est servie, pas la premiere")
    void cEstLaDerniereTentativeQuiEstServie() {
        User user = data.user();
        Mockito.when(currentUser.getId()).thenReturn(user.getId());
        Skill skill = data.skill();
        SkillPrompt prompt = data.skillPrompt(skill);
        // Deux productions sur le meme sujet : c'est le rapport de la SECONDE
        // que le candidat veut relire, pas celui de son premier essai.
        tentativeIlYA(user, prompt, 600);
        UserSkillAttempt derniere = tentativeIlYA(user, prompt, 60);
        entityManager.flush();
        entityManager.clear();

        SkillDetailDto detail = service.detail(skill.getId());

        assertThat(byId(detail, prompt.getId()).lastAttemptId()).isEqualTo(derniere.getId());
        assertThat(byId(detail, prompt.getId()).attemptCount()).isEqualTo(2);
    }

    @Test
    @DisplayName("15 sujets tentes ne coutent pas une requete de plus qu'un seul")
    void leChargementNeCoutePasUneRequeteParSujet() {
        User user = data.user();
        Mockito.when(currentUser.getId()).thenReturn(user.getId());

        Skill unSeulSujet = data.skill();
        data.userSkillAttempt(user, data.skillPrompt(unSeulSujet));

        Skill quinzeSujets = data.skill();
        List<SkillPrompt> prompts = new ArrayList<>();
        for (int i = 0; i < PROMPTS_PER_SKILL; i++) {
            SkillPrompt prompt = data.skillPrompt(quinzeSujets);
            prompts.add(prompt);
            data.userSkillAttempt(user, prompt);
        }
        entityManager.flush();
        entityManager.clear();

        long pourUnSujet = compte(unSeulSujet.getId());
        entityManager.clear();
        long pourQuinzeSujets = compte(quinzeSujets.getId());

        assertThat(prompts).hasSize(PROMPTS_PER_SKILL);
        assertThat(service.detail(quinzeSujets.getId()).prompts())
                .hasSize(PROMPTS_PER_SKILL)
                .allSatisfy(prompt -> assertThat(prompt.lastAttemptId()).isNotNull());
        assertThat(pourQuinzeSujets).isEqualTo(pourUnSujet);
    }

    /**
     * Tentative datee dans le passe. {@code created_at} est {@code updatable =
     * false} : il doit etre pose AVANT le premier INSERT, sinon les deux
     * tentatives d'un meme test partagent quasiment le meme instant et
     * « la derniere » devient indecidable.
     */
    private UserSkillAttempt tentativeIlYA(User user, SkillPrompt prompt, long secondes) {
        UserSkillAttempt a = new UserSkillAttempt();
        a.setUser(user);
        a.setSkillPrompt(prompt);
        a.setWrittenProduction("Reponse datee a -" + secondes + "s");
        a.setWordsCount(6);
        a.setStatut(SkillAttemptStatut.RECORDED);
        a.setCreatedAt(Instant.now().minus(secondes, ChronoUnit.SECONDS));
        return attemptManager.save(a);
    }

    /** Requetes reellement preparees par un {@code detail()} complet. */
    private long compte(UUID skillId) {
        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();
        service.detail(skillId);
        return statistics.getPrepareStatementCount();
    }

    private static SkillPromptSummaryDto byId(SkillDetailDto detail, UUID promptId) {
        return detail.prompts().stream()
                .filter(p -> p.id().equals(promptId))
                .findFirst()
                .orElseThrow();
    }
}
