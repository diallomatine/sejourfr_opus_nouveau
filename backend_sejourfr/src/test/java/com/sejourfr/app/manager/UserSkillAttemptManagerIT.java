package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.repository.UserSkillAttemptRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * {@code user_skill_attempts} n'est jamais seedee (elle ne contient que des
 * productions de candidats), mais {@code skills} et {@code skill_prompts} le
 * seront. Les assertions restent donc filtrees sur les utilisateurs et les
 * sujets crees dans le test.
 */
class UserSkillAttemptManagerIT extends AbstractIntegrationTest {

    @Autowired
    private UserSkillAttemptManager manager;

    @Autowired
    private UserSkillAttemptRepository repository;

    @Autowired
    private TestData testData;

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findByIdWithPromptLoadsPromptAndSkill() {
        UserSkillAttempt attempt = testData.userSkillAttempt();

        assertThat(manager.findByIdWithPrompt(attempt.getId()))
                .get()
                .extracting(a -> a.getSkillPrompt().getSkill().getCode())
                .isNotNull();
    }

    @Test
    void countAnalysesRequestedCountsOnlyRequestedOnes() {
        User user = testData.user();
        SkillPrompt prompt = testData.skillPrompt();
        // Sans analyse : gratuit et illimite, ne consomme rien.
        testData.userSkillAttempt(user, prompt);
        testData.userSkillAttempt(user, prompt);
        // Analyse DEMANDEE : consomme, meme si elle finit en echec — sinon un
        // retry gratuit apres panne offrirait des analyses supplementaires.
        analysed(user, prompt, SkillAttemptStatut.FAILED, null);
        analysed(user, prompt, SkillAttemptStatut.EVALUATED, SkillCriterionStatus.VALIDATED);

        assertThat(manager.countAnalysesRequested(user.getId())).isEqualTo(2);
    }

    @Test
    void countAnalysesRequestedIsPerUser() {
        User user = testData.user();
        User other = testData.user();
        SkillPrompt prompt = testData.skillPrompt();
        analysed(user, prompt, SkillAttemptStatut.EVALUATED, SkillCriterionStatus.PARTIAL);

        assertThat(manager.countAnalysesRequested(other.getId())).isZero();
    }

    @Test
    void hasAttemptedGuardsTheReferences() {
        User user = testData.user();
        SkillPrompt prompt = testData.skillPrompt();
        SkillPrompt untouched = testData.skillPrompt();

        assertThat(manager.hasAttempted(user.getId(), prompt.getId())).isFalse();
        testData.userSkillAttempt(user, prompt);

        assertThat(manager.hasAttempted(user.getId(), prompt.getId())).isTrue();
        assertThat(manager.hasAttempted(user.getId(), untouched.getId())).isFalse();
    }

    /**
     * La garde des references est « AU MOINS UNE tentative », jamais « au moins
     * une tentative reussie ». Une analyse en echec doit donc ouvrir l'acces :
     * l'ecran de resultat d'une tentative {@code FAILED} est precisement le
     * moment ou le candidat a besoin des productions de reference — lui
     * repondre 403 la lui refuserait sans rien lui offrir a la place.
     */
    @Test
    void aFailedAnalysisStillOpensTheReferences() {
        User user = testData.user();
        SkillPrompt prompt = testData.skillPrompt();
        UserSkillAttempt attempt = testData.userSkillAttempt(user, prompt);
        attempt.setAnalysisRequested(true);
        attempt.setStatut(SkillAttemptStatut.FAILED);
        attempt.setErrorMessage("Fournisseur indisponible");
        repository.saveAndFlush(attempt);

        assertThat(manager.hasAttempted(user.getId(), prompt.getId())).isTrue();
    }

    @Test
    void findByUserAndPromptIsMostRecentFirstAndCapped() {
        User user = testData.user();
        SkillPrompt prompt = testData.skillPrompt();
        UserSkillAttempt old = attemptAt(user, prompt, 300);
        UserSkillAttempt middle = attemptAt(user, prompt, 200);
        UserSkillAttempt recent = attemptAt(user, prompt, 100);

        assertThat(manager.findByUserAndPrompt(user.getId(), prompt.getId(), 10))
                .extracting(UserSkillAttempt::getId)
                .containsExactly(recent.getId(), middle.getId(), old.getId());

        assertThat(manager.findByUserAndPrompt(user.getId(), prompt.getId(), 2))
                .extracting(UserSkillAttempt::getId)
                .containsExactly(recent.getId(), middle.getId());
    }

    @Test
    void findLatestByUserAndPromptReturnsTheMostRecent() {
        User user = testData.user();
        SkillPrompt prompt = testData.skillPrompt();
        attemptAt(user, prompt, 300);
        UserSkillAttempt recent = attemptAt(user, prompt, 10);

        assertThat(manager.findLatestByUserAndPrompt(user.getId(), prompt.getId()))
                .get()
                .extracting(UserSkillAttempt::getId)
                .isEqualTo(recent.getId());
    }

    @Test
    void findLatestPerPromptBySkillKeepsOneAttemptPerPrompt() {
        User user = testData.user();
        Skill skill = testData.skill(SkillTaskCode.EE1);
        SkillPrompt p1 = testData.skillPrompt(skill);
        SkillPrompt p2 = testData.skillPrompt(skill);
        SkillPrompt untouched = testData.skillPrompt(skill);

        attemptAt(user, p1, 500);
        UserSkillAttempt latestOnP1 = attemptAt(user, p1, 50);
        UserSkillAttempt latestOnP2 = attemptAt(user, p2, 80);

        Map<UUID, UserSkillAttempt> result =
                manager.findLatestPerPromptBySkill(user.getId(), skill.getId());

        assertThat(result).containsOnlyKeys(p1.getId(), p2.getId());
        assertThat(result.get(p1.getId()).getId()).isEqualTo(latestOnP1.getId());
        assertThat(result.get(p2.getId()).getId()).isEqualTo(latestOnP2.getId());
        assertThat(result).doesNotContainKey(untouched.getId());
    }

    @Test
    void findLatestPerPromptIsScopedToTheUser() {
        User user = testData.user();
        User other = testData.user();
        Skill skill = testData.skill(SkillTaskCode.EE2);
        SkillPrompt prompt = testData.skillPrompt(skill);
        testData.userSkillAttempt(other, prompt);

        assertThat(manager.findLatestPerPromptBySkill(user.getId(), skill.getId())).isEmpty();
    }

    @Test
    void findLatestPerPromptByTaskCodesCoversTheWholeTask() {
        User user = testData.user();
        Skill skillA = testData.skill(SkillTaskCode.EO3);
        Skill skillB = testData.skill(SkillTaskCode.EO3);
        SkillPrompt pa = testData.skillPrompt(skillA);
        SkillPrompt pb = testData.skillPrompt(skillB);
        SkillPrompt otherTask = testData.skillPrompt(testData.skill(SkillTaskCode.EO1));

        testData.userSkillAttempt(user, pa);
        testData.userSkillAttempt(user, pb);
        testData.userSkillAttempt(user, otherTask);

        Map<UUID, UserSkillAttempt> result = manager.findLatestPerPromptByTaskCodes(
                user.getId(), List.of(SkillTaskCode.EO3));

        assertThat(result).containsOnlyKeys(pa.getId(), pb.getId());
    }

    @Test
    void findLatestPerPromptByTaskCodesWithEmptyScopeDoesNotHitTheDatabase() {
        assertThat(manager.findLatestPerPromptByTaskCodes(testData.user().getId(), List.of()))
                .isEmpty();
    }

    @Test
    void countPerPromptCountsEveryAttemptNotJustTheLatest() {
        User user = testData.user();
        Skill skill = testData.skill(SkillTaskCode.EE3);
        SkillPrompt p1 = testData.skillPrompt(skill);
        SkillPrompt p2 = testData.skillPrompt(skill);
        testData.userSkillAttempt(user, p1);
        testData.userSkillAttempt(user, p1);
        testData.userSkillAttempt(user, p2);

        Map<UUID, Long> bySkill = manager.countPerPromptBySkill(user.getId(), skill.getId());
        assertThat(bySkill).containsEntry(p1.getId(), 2L).containsEntry(p2.getId(), 1L);

        Map<UUID, Long> byTask =
                manager.countPerPromptByTaskCodes(user.getId(), List.of(SkillTaskCode.EE3));
        assertThat(byTask).containsEntry(p1.getId(), 2L);
    }

    @Test
    void countByUserAndPromptIsScopedToTheUser() {
        User user = testData.user();
        User other = testData.user();
        SkillPrompt prompt = testData.skillPrompt();
        testData.userSkillAttempt(user, prompt);
        testData.userSkillAttempt(other, prompt);

        assertThat(manager.countByUserAndPrompt(user.getId(), prompt.getId())).isEqualTo(1);
    }

    @Test
    void existsForPromptBlocksDeletionOfATreatedPrompt() {
        SkillPrompt prompt = testData.skillPrompt();
        assertThat(manager.existsForPrompt(prompt.getId())).isFalse();

        testData.userSkillAttempt(testData.user(), prompt);

        assertThat(manager.existsForPrompt(prompt.getId())).isTrue();
    }

    @Test
    void attemptWithoutAnyProductionIsRejectedByDatabase() {
        // chk_user_skill_attempts_has_production : ni texte, ni transcription,
        // ni cle audio legacy = pas de production, donc pas de tentative.
        UserSkillAttempt invalid = new UserSkillAttempt();
        invalid.setUser(testData.user());
        invalid.setSkillPrompt(testData.skillPrompt());
        invalid.setStatut(SkillAttemptStatut.RECORDED);

        assertThatThrownBy(() -> repository.saveAndFlush(invalid))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    /**
     * LEGACY : les lignes ecrites quand l'audio etait encore stocke gardent leur
     * cle et doivent rester valides. Rien ne les migre, rien ne les purge.
     */
    @Test
    void aLegacyAudioKeyOnlyAttemptRemainsAccepted() {
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setUser(testData.user());
        attempt.setSkillPrompt(testData.skillPrompt());
        attempt.setAudioObjectKey("submissions/" + UUID.randomUUID() + ".webm");
        attempt.setAudioDurationSec(42);
        attempt.setStatut(SkillAttemptStatut.RECORDED);

        assertThat(repository.saveAndFlush(attempt).getId()).isNotNull();
    }

    /**
     * LA FORME NOMINALE depuis que l'audio n'est plus conserve (V033) : une
     * production orale, c'est sa TRANSCRIPTION, sans aucune cle de stockage. La
     * contrainte doit l'accepter — sinon aucune tentative orale ne serait plus
     * insérable.
     */
    @Test
    void aTranscriptOnlyOralAttemptIsAccepted() {
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setUser(testData.user());
        attempt.setSkillPrompt(testData.skillPrompt());
        attempt.setTranscript("je voudrais reserver une salle pour samedi");
        attempt.setAudioDurationSec(42);
        attempt.setStatut(SkillAttemptStatut.RECORDED);

        UserSkillAttempt saved = repository.saveAndFlush(attempt);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getAudioObjectKey()).isNull();
    }

    @Test
    void analysisJsonRoundTripsThroughJsonb() {
        User user = testData.user();
        SkillPrompt prompt = testData.skillPrompt();
        UserSkillAttempt attempt =
                analysed(user, prompt, SkillAttemptStatut.EVALUATED, SkillCriterionStatus.VALIDATED);
        attempt.setAnalysisJson(Map.of("verdict", "Le ton est adapté au destinataire."));
        manager.save(attempt);
        repository.flush();

        assertThat(manager.findById(attempt.getId()))
                .get()
                .extracting(a -> a.getAnalysisJson().get("verdict"))
                .isEqualTo("Le ton est adapté au destinataire.");
    }

    private UserSkillAttempt analysed(User user, SkillPrompt prompt,
                                      SkillAttemptStatut statut, SkillCriterionStatus criterion) {
        UserSkillAttempt attempt = testData.userSkillAttempt(user, prompt);
        attempt.setAnalysisRequested(true);
        attempt.setStatut(statut);
        attempt.setCriterionStatus(criterion);
        return manager.save(attempt);
    }

    /**
     * Tentative datee dans le passe. {@code createdAt} est {@code updatable =
     * false} : il doit donc etre pose AVANT le premier INSERT, sinon Hibernate
     * l'ignore et les trois tentatives d'un meme test partagent quasiment le
     * meme instant — l'ordre « plus recente d'abord » deviendrait indecidable.
     */
    private UserSkillAttempt attemptAt(User user, SkillPrompt prompt, long secondsAgo) {
        UserSkillAttempt a = new UserSkillAttempt();
        a.setUser(user);
        a.setSkillPrompt(prompt);
        a.setWrittenProduction("Reponse datee a -" + secondsAgo + "s");
        a.setWordsCount(6);
        a.setStatut(SkillAttemptStatut.RECORDED);
        a.setCreatedAt(Instant.now().minus(secondsAgo, ChronoUnit.SECONDS));
        return manager.save(a);
    }
}
