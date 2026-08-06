package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminSkillCreateRequest;
import com.sejourfr.app.dto.AdminSkillDto;
import com.sejourfr.app.dto.AdminSkillPromptCreateRequest;
import com.sejourfr.app.dto.AdminSkillPromptDto;
import com.sejourfr.app.dto.AdminSkillPromptUpdateRequest;
import com.sejourfr.app.dto.AdminSkillReferencesRequest;
import com.sejourfr.app.dto.AdminSkillStatsDto;
import com.sejourfr.app.dto.AdminSkillUpdateRequest;
import com.sejourfr.app.dto.SkillConstraintTagInput;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillConstraintTag;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.SkillReference;
import com.sejourfr.app.enums.SkillConstraintIcon;
import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillReferenceLevel;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager.SkillUsage;
import com.sejourfr.app.mapper.AdminSkillMapper;
import com.sejourfr.app.mapper.SkillReferenceMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Regles editoriales du CRUD admin : ce que le serveur refuse, ce qu'il deduit
 * et ce qu'il rend immuable.
 *
 * <p>Le mapper est utilise pour de vrai (il est pur) : ce sont les regles du
 * service qui sont testees, pas des interactions avec des doublures.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AdminSkillServiceTest {

    @Mock private SkillManager skillManager;
    @Mock private SkillPromptManager promptManager;
    @Mock private UserSkillAttemptManager attemptManager;

    private AdminSkillService service;

    @BeforeEach
    void setUp() {
        service = new AdminSkillService(skillManager, promptManager, attemptManager,
                new AdminSkillMapper(new SkillReferenceMapper()));

        when(skillManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(promptManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(skillManager.findAllByTaskCode(any())).thenReturn(List.of());
        when(promptManager.findAllBySkillId(any())).thenReturn(List.of());
        when(promptManager.findReferencesByPromptId(any())).thenReturn(List.of());
    }

    // ------------------------------------------------------------------------
    // Competences
    // ------------------------------------------------------------------------

    @Test
    void createSkillPersistsGeneralCriterionAndDerivesSection() {
        AdminSkillDto dto = service.createSkill(createSkillRequest());

        // La colonne est NOT NULL : sans ce champ, l'insertion echouerait en 500.
        assertThat(dto.generalCriterion()).isEqualTo("Adapter le ton au destinataire.");
        // La section vient de la tache, pas du client.
        assertThat(dto.section()).isEqualTo(SkillSection.EE);
        assertThat(dto.taskCode()).isEqualTo(SkillTaskCode.EE1);
        assertThat(dto.active()).isTrue();
    }

    @Test
    void createSkillRejectsSectionThatContradictsTaskCode() {
        AdminSkillCreateRequest req = new AdminSkillCreateRequest(
                SkillSection.EO, SkillTaskCode.EE1, "EE1-C9", "Titre", "Description",
                "Critere general", "A2", 9, true);

        assertThatThrownBy(() -> service.createSkill(req))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("EE1");
        verify(skillManager, never()).save(any());
    }

    @Test
    void createSkillRejectsDuplicateCode() {
        when(skillManager.existsByCode("EE1-C9")).thenReturn(true);

        assertThatThrownBy(() -> service.createSkill(createSkillRequest()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("EE1-C9");
    }

    @Test
    void createSkillRejectsDisplayOrderAlreadyTaken() {
        Skill existing = skill(SkillTaskCode.EE1, "EE1-C1", (short) 9);
        when(skillManager.findAllByTaskCode(SkillTaskCode.EE1)).thenReturn(List.of(existing));

        assertThatThrownBy(() -> service.createSkill(createSkillRequest()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("EE1-C1");
    }

    @Test
    void updateSkillNeverTouchesCodeSectionOrTaskCode() {
        Skill skill = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(skill.getId())).thenReturn(Optional.of(skill));

        AdminSkillDto dto = service.updateSkill(skill.getId(), new AdminSkillUpdateRequest(
                "Nouveau titre", "Nouvelle description", "Nouveau critere", "B1", 4, false));

        assertThat(dto.code()).isEqualTo("EE1-C1");
        assertThat(dto.section()).isEqualTo(SkillSection.EE);
        assertThat(dto.taskCode()).isEqualTo(SkillTaskCode.EE1);
        assertThat(dto.title()).isEqualTo("Nouveau titre");
        assertThat(dto.generalCriterion()).isEqualTo("Nouveau critere");
        assertThat(dto.targetLevel()).isEqualTo("B1");
        assertThat(dto.displayOrder()).isEqualTo(4);
        assertThat(dto.active()).isFalse();
    }

    @Test
    void updateSkillLeavesNotNullColumnsUntouchedWhenFieldIsAbsent() {
        Skill skill = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(skill.getId())).thenReturn(Optional.of(skill));

        AdminSkillDto dto = service.updateSkill(skill.getId(),
                new AdminSkillUpdateRequest(null, null, null, null, null, null));

        // Aucune de ces colonnes n'est nullable : un nul ne peut pas vouloir dire
        // « efface », il vaut « ne touche pas ».
        assertThat(dto.title()).isEqualTo("Titre seed");
        assertThat(dto.generalCriterion()).isEqualTo("Critere general seed");
        assertThat(dto.displayOrder()).isEqualTo(1);
        assertThat(dto.active()).isTrue();
    }

    @Test
    void deleteSkillIsRefusedWhenACandidateHasWorkedOnIt() {
        Skill skill = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(skill.getId())).thenReturn(Optional.of(skill));
        when(attemptManager.existsForSkill(skill.getId())).thenReturn(true);

        assertThatThrownBy(() -> service.deleteSkill(skill.getId()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("désactivée");
        verify(skillManager, never()).delete(any());
    }

    @Test
    void deleteSkillProceedsWhenNoAttemptExists() {
        Skill skill = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(skill.getId())).thenReturn(Optional.of(skill));
        when(attemptManager.existsForSkill(skill.getId())).thenReturn(false);

        service.deleteSkill(skill.getId());

        verify(skillManager).delete(skill);
    }

    // ------------------------------------------------------------------------
    // Petits sujets : coherence EE/EO
    // ------------------------------------------------------------------------

    @Test
    void createPromptDerivesSectionFromParentSkill() {
        Skill oral = skill(SkillTaskCode.EO2, "EO2-C1", (short) 1);
        when(skillManager.findById(oral.getId())).thenReturn(Optional.of(oral));

        AdminSkillPromptDto dto = service.createPrompt(promptRequest(oral.getId(), null, null, 45));

        assertThat(dto.section()).isEqualTo(SkillSection.EO);
        assertThat(dto.skillCode()).isEqualTo("EO2-C1");
    }

    @Test
    void createPromptRejectsWrittenSubjectWithoutWordBounds() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.createPrompt(promptRequest(written.getId(), null, null, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("nombre de mots");
    }

    @Test
    void createPromptRejectsWrittenSubjectCarryingADuration() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.createPrompt(promptRequest(written.getId(), 15, 50, 45)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("durée");
    }

    @Test
    void createPromptRejectsInvertedWordBounds() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.createPrompt(promptRequest(written.getId(), 50, 15, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("inférieur");
    }

    @Test
    void createPromptRejectsOralSubjectCarryingWordBounds() {
        Skill oral = skill(SkillTaskCode.EO1, "EO1-C1", (short) 1);
        when(skillManager.findById(oral.getId())).thenReturn(Optional.of(oral));

        assertThatThrownBy(() -> service.createPrompt(promptRequest(oral.getId(), 15, 50, 45)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("nombre de mots");
    }

    // ------------------------------------------------------------------------
    // Petits sujets : guidage de l'ecran de saisie
    // ------------------------------------------------------------------------

    @Test
    void createPromptStoresTheGuidanceAndNormalisesTheIconCase() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        AdminSkillPromptDto dto = service.createPrompt(promptRequest(written.getId(),
                List.of("  Saluez votre voisine  ", "Écrivez deux phrases"),
                List.of(new SkillConstraintTagInput("Vouvoiement", "person")),
                "  Bonjour Madame, je suis votre voisin du…  ",
                "  commencez par bonjour  "));

        assertThat(dto.checklist()).containsExactly("Saluez votre voisine", "Écrivez deux phrases");
        assertThat(dto.constraintTags())
                .containsExactly(new SkillConstraintTag("Vouvoiement", SkillConstraintIcon.PERSON));
        assertThat(dto.answerStarter()).isEqualTo("Bonjour Madame, je suis votre voisin du…");
        assertThat(dto.tip()).isEqualTo("commencez par bonjour");
    }

    /**
     * Une check-list a un seul geste ne decoupe rien, et au-dela de quatre elle
     * repousse la zone de saisie sous la ligne de flottaison — soit exactement
     * ce que la refonte de l'ecran corrige.
     */
    @Test
    void createPromptRejectsAChecklistOutsideItsBounds() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.createPrompt(promptRequest(written.getId(),
                List.of("Saluez votre voisine"), null, null, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("check-list");

        assertThatThrownBy(() -> service.createPrompt(promptRequest(written.getId(),
                List.of("Un", "Deux", "Trois", "Quatre", "Cinq"), null, null, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("entre 2 et 4");
    }

    @Test
    void createPromptRejectsMoreThanThreeConstraintTags() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.createPrompt(promptRequest(written.getId(), null,
                List.of(new SkillConstraintTagInput("Vouvoiement", "PERSON"),
                        new SkillConstraintTagInput("Ton poli", "TONE"),
                        new SkillConstraintTagInput("Passé composé", "TENSE"),
                        new SkillConstraintTagInput("Un exemple", "EXAMPLE")),
                null, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("entre 1 et 3");
    }

    /**
     * Hors de la liste fermee, aucun front ne saurait quoi dessiner : l'etiquette
     * s'afficherait muette. Le refus doit rester un 422 lisible en francais —
     * pas la violation d'une contrainte, pas un 400 du convertisseur JSON.
     */
    @Test
    void createPromptRejectsAnIconOutsideTheClosedListAndListsTheAcceptedOnes() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.createPrompt(promptRequest(written.getId(), null,
                List.of(new SkillConstraintTagInput("Vouvoiement", "SMILEY")), null, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("SMILEY")
                .hasMessageContaining("PERSON");

        verify(promptManager, never()).save(any());
    }

    @Test
    void createPromptRejectsAConstraintTagWithoutALabel() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        assertThatThrownBy(() -> service.createPrompt(promptRequest(written.getId(), null,
                List.of(new SkillConstraintTagInput("   ", "PERSON")), null, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("libellé");
    }

    /**
     * Le guidage est facultatif : la console doit pouvoir publier un sujet sans
     * lui, quitte a ce que les fronts retombent sur la consigne. L'exiger
     * fermerait la creation depuis la console, sans que le DDL ne l'ait jamais
     * demande.
     */
    @Test
    void createPromptWithoutAnyGuidanceIsAccepted() {
        Skill written = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findById(written.getId())).thenReturn(Optional.of(written));

        AdminSkillPromptDto dto = service.createPrompt(
                promptRequest(written.getId(), null, null, null, null));

        assertThat(dto.checklist()).isNull();
        assertThat(dto.constraintTags()).isNull();
        assertThat(dto.answerStarter()).isNull();
        assertThat(dto.tip()).isNull();
    }

    /**
     * Meme semantique que les bornes de longueur : un nul EFFACE. Sans cela, une
     * check-list posee par erreur serait ineffacable depuis la console, et il
     * faudrait un UPDATE en base pour retirer un guidage errone d'un sujet
     * publie.
     */
    @Test
    void patchWithoutGuidanceErasesTheExistingOne() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        prompt.setChecklist(List.of("Saluez votre voisine", "Écrivez deux phrases"));
        prompt.setConstraintTags(List.of(
                new SkillConstraintTag("Vouvoiement", SkillConstraintIcon.PERSON)));
        prompt.setAnswerStarter("Bonjour Madame…");
        prompt.setTip("commencez par bonjour");
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        AdminSkillPromptDto dto = service.updatePrompt(prompt.getId(), patch(15, 50, null));

        assertThat(dto.checklist()).isNull();
        assertThat(dto.constraintTags()).isNull();
        assertThat(dto.answerStarter()).isNull();
        assertThat(dto.tip()).isNull();
        assertThat(prompt.getChecklist()).isNull();
    }

    @Test
    void patchReplacesTheGuidanceWholesaleRatherThanMergingIt() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        prompt.setChecklist(List.of("Ancien geste 1", "Ancien geste 2", "Ancien geste 3"));
        prompt.setTip("ancienne astuce");
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        AdminSkillPromptDto dto = service.updatePrompt(prompt.getId(), patchGuidance(
                List.of("Saluez votre voisine", "Écrivez deux phrases"),
                List.of(new SkillConstraintTagInput("Ton poli", "TONE")),
                "Bonjour Madame…",
                null));

        assertThat(dto.checklist()).containsExactly("Saluez votre voisine", "Écrivez deux phrases");
        assertThat(dto.constraintTags())
                .containsExactly(new SkillConstraintTag("Ton poli", SkillConstraintIcon.TONE));
        // L'ancienne astuce n'est pas conservee : le champ absent vaut « efface ».
        assertThat(dto.tip()).isNull();
    }

    /** Une modification invalide ne doit rien ecrire du tout. */
    @Test
    void patchWithAnInvalidIconLeavesThePromptUntouched() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        prompt.setChecklist(List.of("Ancien geste 1", "Ancien geste 2"));
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.updatePrompt(prompt.getId(), patchGuidance(
                List.of("Saluez votre voisine", "Écrivez deux phrases"),
                List.of(new SkillConstraintTagInput("Ton poli", "COULEUR")),
                null, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("COULEUR");

        assertThat(prompt.getChecklist()).containsExactly("Ancien geste 1", "Ancien geste 2");
        verify(promptManager, never()).save(any());
    }

    // ------------------------------------------------------------------------
    // Petits sujets : semantique de remplacement du PATCH
    // ------------------------------------------------------------------------

    @Test
    void patchReplacesBoundsInsteadOfMergingThem() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        AdminSkillPromptDto dto = service.updatePrompt(prompt.getId(), patch(20, 60, null));

        assertThat(dto.recommendedMinWords()).isEqualTo(20);
        assertThat(dto.recommendedMaxWords()).isEqualTo(60);
        assertThat(dto.recommendedDurationSeconds()).isNull();
    }

    @Test
    void patchWithANullBoundErasesItRatherThanKeepingTheOldValue() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        // Sous une semantique de fusion, l'ancien 15 serait conserve et l'appel
        // passerait. Le refus prouve que le nul a bien ete lu comme « efface ».
        assertThatThrownBy(() -> service.updatePrompt(prompt.getId(), patch(null, 50, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("minimum et maximum");
    }

    @Test
    void patchKeepsNotNullFieldsWhenTheyAreAbsent() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        AdminSkillPromptDto dto = service.updatePrompt(prompt.getId(),
                new AdminSkillPromptUpdateRequest(null, null, null, null,
                        null, null, null, null, 15, 50, null, null, null, null));

        assertThat(dto.title()).isEqualTo("Sujet seed");
        assertThat(dto.code()).isEqualTo("EE1-C1-S1");
        assertThat(dto.difficultyLevel()).isEqualTo(SkillDifficulty.EASY);
        assertThat(dto.active()).isTrue();
    }

    @Test
    void deletePromptIsRefusedWhenACandidateHasWorkedOnIt() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(attemptManager.existsForPrompt(prompt.getId())).thenReturn(true);

        assertThatThrownBy(() -> service.deletePrompt(prompt.getId()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("désactivé");
        verify(promptManager, never()).delete(any());
    }

    @Test
    void deletePromptProceedsWhenNoAttemptExists() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(attemptManager.existsForPrompt(prompt.getId())).thenReturn(false);

        service.deletePrompt(prompt.getId());

        verify(promptManager).delete(prompt);
    }

    // ------------------------------------------------------------------------
    // References
    // ------------------------------------------------------------------------

    @Test
    void replaceReferencesRequiresTheThreeLevels() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        AdminSkillReferencesRequest req = new AdminSkillReferencesRequest(List.of(
                item(SkillReferenceLevel.INSUFFICIENT), item(SkillReferenceLevel.EXPECTED)));

        assertThatThrownBy(() -> service.replaceReferences(prompt.getId(), req))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("trois références");
        // Rien n'est supprime tant que l'entree n'est pas valide : le
        // remplacement est atomique, pas « efface puis on verra ».
        verify(promptManager, never()).deleteReferencesByPromptId(any());
    }

    @Test
    void replaceReferencesRejectsADuplicatedLevel() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        AdminSkillReferencesRequest req = new AdminSkillReferencesRequest(List.of(
                item(SkillReferenceLevel.INSUFFICIENT),
                item(SkillReferenceLevel.EXPECTED),
                item(SkillReferenceLevel.EXPECTED)));

        assertThatThrownBy(() -> service.replaceReferences(prompt.getId(), req))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("EXPECTED");
        verify(promptManager, never()).deleteReferencesByPromptId(any());
    }

    @Test
    void replaceReferencesDeletesThenWritesTheThreeLines() {
        SkillPrompt prompt = writtenPrompt(15, 50);
        when(promptManager.findByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.replaceReferences(prompt.getId(), new AdminSkillReferencesRequest(List.of(
                item(SkillReferenceLevel.INSUFFICIENT),
                item(SkillReferenceLevel.EXPECTED),
                item(SkillReferenceLevel.EXCELLENT))));

        verify(promptManager).deleteReferencesByPromptId(prompt.getId());
        verify(promptManager, org.mockito.Mockito.times(3)).saveReference(any(SkillReference.class));
    }

    // ------------------------------------------------------------------------
    // Statistiques
    // ------------------------------------------------------------------------

    @Test
    void validatedRateIsNullWhenNothingHasBeenAnalysed() {
        Skill skill = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findAllForAdmin(null)).thenReturn(List.of(skill));
        when(promptManager.countBySkillIds(any())).thenReturn(Map.of(skill.getId(), 5L));
        // 4 tentatives, aucune analysee : le taux n'existe pas.
        when(attemptManager.aggregateUsageBySkillIds(any()))
                .thenReturn(Map.of(skill.getId(), new SkillUsage(4, 0, 0)));

        AdminSkillStatsDto stats = service.stats(null).getFirst();

        assertThat(stats.attemptCount()).isEqualTo(4);
        assertThat(stats.analysedCount()).isZero();
        // Surtout pas 0.0 : « aucune analyse » et « 0 % de réussite » ne se
        // lisent pas pareil.
        assertThat(stats.validatedRate()).isNull();
    }

    @Test
    void validatedRateIsTheShareOfValidatedAmongAnalysed() {
        Skill skill = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        when(skillManager.findAllForAdmin(SkillSection.EE)).thenReturn(List.of(skill));
        when(promptManager.countBySkillIds(any())).thenReturn(Map.of(skill.getId(), 5L));
        when(attemptManager.aggregateUsageBySkillIds(any()))
                .thenReturn(Map.of(skill.getId(), new SkillUsage(10, 4, 3)));

        AdminSkillStatsDto stats = service.stats(SkillSection.EE).getFirst();

        assertThat(stats.validatedRate()).isEqualTo(0.75);
    }

    // ------------------------------------------------------------------------
    // Fabriques locales
    // ------------------------------------------------------------------------

    private static AdminSkillCreateRequest createSkillRequest() {
        return new AdminSkillCreateRequest(null, SkillTaskCode.EE1, "EE1-C9", "Titre",
                "Description", "Adapter le ton au destinataire.", "A2", 9, null);
    }

    private static AdminSkillPromptCreateRequest promptRequest(UUID skillId,
                                                               Integer min,
                                                               Integer max,
                                                               Integer duration) {
        return new AdminSkillPromptCreateRequest(skillId, "EE1-C1-S9", "Titre", "Contexte",
                "Consigne", "Critere unique", null, null, null, null,
                min, max, duration, SkillDifficulty.EASY, 9, null);
    }

    /** Creation portant le guidage de l'ecran de saisie. */
    private static AdminSkillPromptCreateRequest promptRequest(UUID skillId,
                                                               List<String> checklist,
                                                               List<SkillConstraintTagInput> tags,
                                                               String answerStarter,
                                                               String tip) {
        return new AdminSkillPromptCreateRequest(skillId, "EE1-C1-S9", "Titre", "Contexte",
                "Consigne", "Critere unique", checklist, tags, answerStarter, tip,
                15, 50, null, SkillDifficulty.EASY, 9, null);
    }

    private static AdminSkillPromptUpdateRequest patch(Integer min, Integer max, Integer duration) {
        return new AdminSkillPromptUpdateRequest("Titre", "Contexte", "Consigne", "Critere",
                null, null, null, null,
                min, max, duration, SkillDifficulty.MEDIUM, 1, true);
    }

    /** Modification portant le guidage, bornes de mots inchangees. */
    private static AdminSkillPromptUpdateRequest patchGuidance(List<String> checklist,
                                                               List<SkillConstraintTagInput> tags,
                                                               String answerStarter,
                                                               String tip) {
        return new AdminSkillPromptUpdateRequest("Titre", "Contexte", "Consigne", "Critere",
                checklist, tags, answerStarter, tip,
                15, 50, null, SkillDifficulty.MEDIUM, 1, true);
    }

    private static AdminSkillReferencesRequest.Item item(SkillReferenceLevel level) {
        return new AdminSkillReferencesRequest.Item(level, "Texte " + level, "Note " + level);
    }

    private static Skill skill(SkillTaskCode taskCode, String code, short order) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(taskCode.getSection());
        skill.setTaskCode(taskCode);
        skill.setCode(code);
        skill.setTitle("Titre seed");
        skill.setDescription("Description seed");
        skill.setGeneralCriterion("Critere general seed");
        skill.setTargetLevel(taskCode.getTargetLevel());
        skill.setDisplayOrder(order);
        skill.setActive(true);
        return skill;
    }

    private SkillPrompt writtenPrompt(Integer min, Integer max) {
        Skill skill = skill(SkillTaskCode.EE1, "EE1-C1", (short) 1);
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(SkillSection.EE);
        prompt.setCode("EE1-C1-S1");
        prompt.setTitle("Sujet seed");
        prompt.setContext("Contexte seed");
        prompt.setInstruction("Consigne seed");
        prompt.setUniqueCriterion("Critere unique seed");
        prompt.setRecommendedMinWords(min);
        prompt.setRecommendedMaxWords(max);
        prompt.setDifficultyLevel(SkillDifficulty.EASY);
        prompt.setDisplayOrder((short) 1);
        prompt.setActive(true);
        return prompt;
    }
}
