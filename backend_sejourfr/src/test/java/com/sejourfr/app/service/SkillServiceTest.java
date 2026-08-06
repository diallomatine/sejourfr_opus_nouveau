package com.sejourfr.app.service;

import com.sejourfr.app.dto.SkillDetailDto;
import com.sejourfr.app.dto.SkillDto;
import com.sejourfr.app.dto.SkillPromptDto;
import com.sejourfr.app.dto.SkillReferenceDto;
import com.sejourfr.app.dto.SkillTaskProgressDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.SkillReference;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillPromptStatus;
import com.sejourfr.app.enums.SkillReferenceLevel;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.mapper.SkillMapper;
import com.sejourfr.app.mapper.SkillPromptMapper;
import com.sejourfr.app.mapper.SkillReferenceMapper;
import com.sejourfr.app.security.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/**
 * Lecture du catalogue : garde des references, derivation des compteurs et
 * navigation vers le sujet suivant.
 *
 * <p>Les mappers et le resolveur de statut sont utilises pour de vrai (ils sont
 * purs) : ce qui est teste ici, ce sont les regles du service, pas des
 * interactions avec des doublures.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillServiceTest {

    @Mock private SkillManager skillManager;
    @Mock private SkillPromptManager promptManager;
    @Mock private UserSkillAttemptManager attemptManager;
    @Mock private CurrentUser currentUser;

    private SkillService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new SkillService(skillManager, promptManager, attemptManager,
                new SkillStatusResolver(), new SkillMapper(), new SkillPromptMapper(),
                new SkillReferenceMapper(), currentUser);
        when(currentUser.getId()).thenReturn(userId);
    }

    // ------------------------------------------------------------------------
    // Garde des references
    // ------------------------------------------------------------------------

    @Test
    void referencesAreForbiddenBeforeTheCandidateHasProduced() {
        Skill skill = skill(SkillTaskCode.EE1);
        SkillPrompt prompt = prompt(skill, 1);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(attemptManager.hasAttempted(userId, prompt.getId())).thenReturn(false);

        assertThatThrownBy(() -> service.references(prompt.getId()))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("après votre propre réponse");
    }

    @Test
    void referencesAreServedOnceTheCandidateHasProduced() {
        Skill skill = skill(SkillTaskCode.EE1);
        SkillPrompt prompt = prompt(skill, 1);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(attemptManager.hasAttempted(userId, prompt.getId())).thenReturn(true);
        when(promptManager.findReferencesByPromptId(prompt.getId())).thenReturn(List.of(
                reference(prompt, SkillReferenceLevel.INSUFFICIENT),
                reference(prompt, SkillReferenceLevel.EXPECTED),
                reference(prompt, SkillReferenceLevel.EXCELLENT)));

        List<SkillReferenceDto> result = service.references(prompt.getId());

        assertThat(result).extracting(SkillReferenceDto::level).containsExactly(
                SkillReferenceLevel.INSUFFICIENT,
                SkillReferenceLevel.EXPECTED,
                SkillReferenceLevel.EXCELLENT);
    }

    @Test
    void referencesOfAnUnknownPromptAreNotFound() {
        UUID promptId = UUID.randomUUID();
        when(promptManager.findActiveByIdWithSkill(promptId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.references(promptId)).isInstanceOf(NotFoundException.class);
    }

    // ------------------------------------------------------------------------
    // Detail d'une competence
    // ------------------------------------------------------------------------

    @Test
    void detailDerivesEachPromptStatusAndAggregatesTheCounters() {
        Skill skill = skill(SkillTaskCode.EE1);
        SkillPrompt validated = prompt(skill, 1);
        SkillPrompt toReinforce = prompt(skill, 2);
        SkillPrompt treated = prompt(skill, 3);
        SkillPrompt todo = prompt(skill, 4);

        when(skillManager.findActiveById(skill.getId())).thenReturn(Optional.of(skill));
        when(promptManager.findActiveBySkillId(skill.getId()))
                .thenReturn(List.of(validated, toReinforce, treated, todo));
        when(attemptManager.findLatestPerPromptBySkill(userId, skill.getId())).thenReturn(Map.of(
                validated.getId(), analysed(validated, SkillCriterionStatus.VALIDATED),
                toReinforce.getId(), analysed(toReinforce, SkillCriterionStatus.PARTIAL),
                treated.getId(), recorded(treated)));
        when(attemptManager.countPerPromptBySkill(userId, skill.getId()))
                .thenReturn(Map.of(validated.getId(), 2L, toReinforce.getId(), 1L, treated.getId(), 1L));

        SkillDetailDto detail = service.detail(skill.getId());

        assertThat(detail.prompts()).extracting("status").containsExactly(
                SkillPromptStatus.VALIDATED,
                SkillPromptStatus.TO_REINFORCE,
                SkillPromptStatus.TREATED,
                SkillPromptStatus.TODO);
        assertThat(detail.prompts().get(0).attemptCount()).isEqualTo(2);
        assertThat(detail.prompts().get(3).attemptCount()).isZero();

        assertThat(detail.skill().promptCount()).isEqualTo(4);
        // « Traite » compte TOUT ce qui a recu une production, verdict ou non.
        assertThat(detail.skill().attemptedCount()).isEqualTo(3);
        assertThat(detail.skill().validatedCount()).isEqualTo(1);
        assertThat(detail.skill().toReinforceCount()).isEqualTo(1);
    }

    @Test
    void detailOfAnInactiveSkillIsNotFound() {
        UUID skillId = UUID.randomUUID();
        when(skillManager.findActiveById(skillId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.detail(skillId)).isInstanceOf(NotFoundException.class);
    }

    // ------------------------------------------------------------------------
    // Sujet complet
    // ------------------------------------------------------------------------

    @Test
    void promptPointsToTheFirstRemainingTodoOfTheSameSkill() {
        Skill skill = skill(SkillTaskCode.EE1);
        SkillPrompt current = prompt(skill, 1);
        SkillPrompt alreadyDone = prompt(skill, 2);
        SkillPrompt nextTodo = prompt(skill, 3);

        when(promptManager.findActiveByIdWithSkill(current.getId())).thenReturn(Optional.of(current));
        when(promptManager.findActiveBySkillId(skill.getId()))
                .thenReturn(List.of(current, alreadyDone, nextTodo));
        when(attemptManager.findLatestPerPromptBySkill(userId, skill.getId()))
                .thenReturn(Map.of(alreadyDone.getId(), recorded(alreadyDone)));
        when(attemptManager.countByUserAndPrompt(userId, current.getId())).thenReturn(0L);

        SkillPromptDto dto = service.prompt(current.getId());

        assertThat(dto.nextPromptId()).isEqualTo(nextTodo.getId());
        assertThat(dto.status()).isEqualTo(SkillPromptStatus.TODO);
        assertThat(dto.lastAttemptId()).isNull();
        assertThat(dto.taskTitle()).isEqualTo(SkillTaskCode.EE1.getTitle());
    }

    @Test
    void promptNeverPointsToItselfAsTheNextSubject() {
        Skill skill = skill(SkillTaskCode.EE1);
        SkillPrompt only = prompt(skill, 1);
        when(promptManager.findActiveByIdWithSkill(only.getId())).thenReturn(Optional.of(only));
        when(promptManager.findActiveBySkillId(skill.getId())).thenReturn(List.of(only));
        when(attemptManager.findLatestPerPromptBySkill(userId, skill.getId())).thenReturn(Map.of());
        when(attemptManager.countByUserAndPrompt(userId, only.getId())).thenReturn(0L);

        // Seul sujet, jamais traite : il reste TODO mais ne peut pas etre son
        // propre « sujet suivant ». Le bouton se desactive.
        assertThat(service.prompt(only.getId()).nextPromptId()).isNull();
    }

    @Test
    void promptExposesTheLastAttemptSoTheCandidateCanResumeIt() {
        Skill skill = skill(SkillTaskCode.EE1);
        SkillPrompt current = prompt(skill, 1);
        UserSkillAttempt latest = recorded(current);

        when(promptManager.findActiveByIdWithSkill(current.getId())).thenReturn(Optional.of(current));
        when(promptManager.findActiveBySkillId(skill.getId())).thenReturn(List.of(current));
        when(attemptManager.findLatestPerPromptBySkill(userId, skill.getId()))
                .thenReturn(Map.of(current.getId(), latest));
        when(attemptManager.countByUserAndPrompt(userId, current.getId())).thenReturn(3L);

        SkillPromptDto dto = service.prompt(current.getId());

        assertThat(dto.lastAttemptId()).isEqualTo(latest.getId());
        assertThat(dto.attemptCount()).isEqualTo(3);
        assertThat(dto.status()).isEqualTo(SkillPromptStatus.TREATED);
    }

    // ------------------------------------------------------------------------
    // Liste des competences : arbitrage des deux filtres
    // ------------------------------------------------------------------------

    @Test
    void listWithoutAnyFilterIsRefused() {
        // Sans filtre la route rendrait les 48 competences des deux epreuves :
        // aucun ecran ne consomme cela, on refuse plutot que de le servir.
        assertThatThrownBy(() -> service.list(null, null))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Précisez l'épreuve");
    }

    @Test
    void listWithContradictoryFiltersIsRefused() {
        // Une liste vide se lirait cote front comme « pas encore de contenu ».
        assertThatThrownBy(() -> service.list(SkillSection.EE, SkillTaskCode.EO2))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Filtres incompatibles");
    }

    @Test
    void listWithBothConsistentFiltersHonoursTheTaskCode() {
        Skill onlyOfEe1 = skill(SkillTaskCode.EE1);
        when(skillManager.findActiveByTaskCode(SkillTaskCode.EE1)).thenReturn(List.of(onlyOfEe1));
        when(promptManager.countActiveBySkillForTaskCodes(List.of(SkillTaskCode.EE1)))
                .thenReturn(Map.of(onlyOfEe1.getId(), 5L));
        when(attemptManager.findLatestPerPromptByTaskCodes(userId, List.of(SkillTaskCode.EE1)))
                .thenReturn(Map.of());

        List<SkillDto> both = service.list(SkillSection.EE, SkillTaskCode.EE1);
        List<SkillDto> taskOnly = service.list(null, SkillTaskCode.EE1);

        // findActiveBySection n'est jamais stubbe : si la branche epreuve avait
        // ete prise, la liste serait vide. Le filtre le plus precis l'emporte.
        assertThat(both).extracting(SkillDto::id).containsExactly(onlyOfEe1.getId());
        assertThat(both).usingRecursiveComparison().isEqualTo(taskOnly);
    }

    @Test
    void listBySectionCoversTheThreeTasksInOneCatalogueRead() {
        List<SkillTaskCode> scope = SkillTaskCode.of(SkillSection.EE);
        Skill ee1 = skill(SkillTaskCode.EE1);
        Skill ee2 = skill(SkillTaskCode.EE2);
        Skill ee3 = skill(SkillTaskCode.EE3);

        when(skillManager.findActiveBySection(SkillSection.EE)).thenReturn(List.of(ee1, ee2, ee3));
        when(promptManager.countActiveBySkillForTaskCodes(scope))
                .thenReturn(Map.of(ee1.getId(), 5L, ee2.getId(), 5L, ee3.getId(), 5L));
        when(attemptManager.findLatestPerPromptByTaskCodes(userId, scope)).thenReturn(Map.of());

        List<SkillDto> result = service.list(SkillSection.EE, null);

        assertThat(result).extracting(SkillDto::taskCode)
                .containsExactly(SkillTaskCode.EE1, SkillTaskCode.EE2, SkillTaskCode.EE3);
        assertThat(result).allMatch(dto -> dto.promptCount() == 5);
    }

    @Test
    void listBySectionKeepsEachSkillProgressionAttachedToItsOwnSkill() {
        List<SkillTaskCode> scope = SkillTaskCode.of(SkillSection.EE);
        Skill ee1 = skill(SkillTaskCode.EE1);
        Skill ee2 = skill(SkillTaskCode.EE2);
        SkillPrompt validatedOfEe1 = prompt(ee1, 1);
        SkillPrompt toReinforceOfEe2 = prompt(ee2, 1);
        SkillPrompt retiredOfEe2 = prompt(ee2, 2);
        retiredOfEe2.setActive(false);

        when(skillManager.findActiveBySection(SkillSection.EE)).thenReturn(List.of(ee1, ee2));
        when(promptManager.countActiveBySkillForTaskCodes(scope))
                .thenReturn(Map.of(ee1.getId(), 5L, ee2.getId(), 5L));
        when(attemptManager.findLatestPerPromptByTaskCodes(userId, scope)).thenReturn(Map.of(
                validatedOfEe1.getId(), analysed(validatedOfEe1, SkillCriterionStatus.VALIDATED),
                toReinforceOfEe2.getId(), analysed(toReinforceOfEe2, SkillCriterionStatus.PARTIAL),
                retiredOfEe2.getId(), recorded(retiredOfEe2)));

        List<SkillDto> result = service.list(SkillSection.EE, null);

        // Le piege de l'elargissement : les tentatives de 3 taches arrivent dans
        // le meme lot, chacune doit rester rattachee a SA competence.
        assertThat(result.get(0).validatedCount()).isEqualTo(1);
        assertThat(result.get(0).toReinforceCount()).isZero();
        assertThat(result.get(0).attemptedCount()).isEqualTo(1);
        assertThat(result.get(1).validatedCount()).isZero();
        assertThat(result.get(1).toReinforceCount()).isEqualTo(1);
        // Le sujet retire du catalogue ne gonfle pas le compteur de sa competence.
        assertThat(result.get(1).attemptedCount()).isEqualTo(1);
    }

    // ------------------------------------------------------------------------
    // Progression par epreuve
    // ------------------------------------------------------------------------

    @Test
    void progressAlwaysReturnsTheThreeTasksEvenWithoutAnyContent() {
        when(skillManager.countActiveByTaskCode(SkillTaskCode.of(SkillSection.EE)))
                .thenReturn(Map.of(SkillTaskCode.EE1, 0L, SkillTaskCode.EE2, 0L, SkillTaskCode.EE3, 0L));
        when(promptManager.countActiveBySkillForTaskCodes(SkillTaskCode.of(SkillSection.EE)))
                .thenReturn(Map.of());
        when(attemptManager.findLatestPerPromptByTaskCodes(userId, SkillTaskCode.of(SkillSection.EE)))
                .thenReturn(Map.of());
        when(skillManager.findActiveBySection(SkillSection.EE)).thenReturn(List.of());

        List<SkillTaskProgressDto> progress = service.progress(SkillSection.EE);

        // Une tache vide s'affiche a zero, elle ne disparait pas de l'ecran.
        assertThat(progress).extracting(SkillTaskProgressDto::taskCode)
                .containsExactly(SkillTaskCode.EE1, SkillTaskCode.EE2, SkillTaskCode.EE3);
        assertThat(progress).allMatch(p -> p.promptCount() == 0 && p.attemptedCount() == 0);
        assertThat(progress.get(0).title()).isEqualTo(SkillTaskCode.EE1.getTitle());
        assertThat(progress.get(0).targetLevel()).isEqualTo(SkillTaskCode.EE1.getTargetLevel());
    }

    @Test
    void progressSumsPromptsOfTheTaskAndTalliesStatuses() {
        List<SkillTaskCode> scope = SkillTaskCode.of(SkillSection.EE);
        Skill skillA = skill(SkillTaskCode.EE1);
        Skill skillB = skill(SkillTaskCode.EE1);
        SkillPrompt validated = prompt(skillA, 1);
        SkillPrompt toReinforce = prompt(skillB, 1);

        when(skillManager.countActiveByTaskCode(scope))
                .thenReturn(Map.of(SkillTaskCode.EE1, 2L, SkillTaskCode.EE2, 0L, SkillTaskCode.EE3, 0L));
        when(skillManager.findActiveBySection(SkillSection.EE)).thenReturn(List.of(skillA, skillB));
        when(promptManager.countActiveBySkillForTaskCodes(scope))
                .thenReturn(Map.of(skillA.getId(), 5L, skillB.getId(), 5L));
        when(attemptManager.findLatestPerPromptByTaskCodes(userId, scope)).thenReturn(Map.of(
                validated.getId(), analysed(validated, SkillCriterionStatus.VALIDATED),
                toReinforce.getId(), analysed(toReinforce, SkillCriterionStatus.NOT_VALIDATED)));

        SkillTaskProgressDto ee1 = service.progress(SkillSection.EE).get(0);

        assertThat(ee1.skillCount()).isEqualTo(2);
        assertThat(ee1.promptCount()).isEqualTo(10);
        assertThat(ee1.attemptedCount()).isEqualTo(2);
        assertThat(ee1.validatedCount()).isEqualTo(1);
        assertThat(ee1.toReinforceCount()).isEqualTo(1);
    }

    @Test
    void progressIgnoresAttemptsOnDeactivatedPrompts() {
        List<SkillTaskCode> scope = SkillTaskCode.of(SkillSection.EE);
        Skill skill = skill(SkillTaskCode.EE1);
        SkillPrompt retired = prompt(skill, 1);
        retired.setActive(false);

        when(skillManager.countActiveByTaskCode(scope))
                .thenReturn(Map.of(SkillTaskCode.EE1, 1L, SkillTaskCode.EE2, 0L, SkillTaskCode.EE3, 0L));
        when(skillManager.findActiveBySection(SkillSection.EE)).thenReturn(List.of(skill));
        when(promptManager.countActiveBySkillForTaskCodes(scope)).thenReturn(Map.of(skill.getId(), 0L));
        when(attemptManager.findLatestPerPromptByTaskCodes(userId, scope))
                .thenReturn(Map.of(retired.getId(), recorded(retired)));

        // Le sujet a ete retire du catalogue : il sort du denominateur, donc il
        // doit aussi sortir du numerateur — sinon « 1 sujet traite sur 0 ».
        assertThat(service.progress(SkillSection.EE).get(0).attemptedCount()).isZero();
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

    private static Skill skill(SkillTaskCode taskCode) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(taskCode.getSection());
        skill.setTaskCode(taskCode);
        skill.setCode("EE1-C1");
        skill.setTitle("Adapter le message au destinataire");
        skill.setDescription("Choisir un ton adapté.");
        skill.setTargetLevel(taskCode.getTargetLevel());
        skill.setDisplayOrder((short) 1);
        skill.setActive(true);
        return skill;
    }

    private static SkillPrompt prompt(Skill skill, int order) {
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(skill.getSection());
        prompt.setCode("EE1-C1-S" + order);
        prompt.setTitle("Sujet " + order);
        prompt.setContext("Contexte.");
        prompt.setInstruction("Consigne.");
        prompt.setUniqueCriterion("Critère unique.");
        prompt.setDisplayOrder((short) order);
        prompt.setActive(true);
        return prompt;
    }

    private static SkillReference reference(SkillPrompt prompt, SkillReferenceLevel level) {
        SkillReference reference = new SkillReference();
        reference.setId(UUID.randomUUID());
        reference.setSkillPrompt(prompt);
        reference.setLevel(level);
        reference.setText("Texte " + level);
        reference.setPedagogicalNote("Note " + level);
        return reference;
    }

    private static UserSkillAttempt recorded(SkillPrompt prompt) {
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.RECORDED);
        attempt.setAnalysisRequested(false);
        return attempt;
    }

    private static UserSkillAttempt analysed(SkillPrompt prompt, SkillCriterionStatus criterion) {
        UserSkillAttempt attempt = recorded(prompt);
        attempt.setAnalysisRequested(true);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setCriterionStatus(criterion);
        return attempt;
    }
}
