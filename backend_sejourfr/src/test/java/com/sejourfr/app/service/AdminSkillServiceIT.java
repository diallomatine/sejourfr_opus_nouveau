package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminSkillCreateRequest;
import com.sejourfr.app.dto.AdminSkillDetailDto;
import com.sejourfr.app.dto.AdminSkillDto;
import com.sejourfr.app.dto.AdminSkillPromptCreateRequest;
import com.sejourfr.app.dto.AdminSkillPromptDto;
import com.sejourfr.app.dto.AdminSkillPromptUpdateRequest;
import com.sejourfr.app.dto.AdminSkillReferencesRequest;
import com.sejourfr.app.dto.AdminSkillStatsDto;
import com.sejourfr.app.dto.AdminSkillUpdateRequest;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillReferenceLevel;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Le CRUD admin contre le VRAI schema : ce sont les contraintes de la base
 * ({@code NOT NULL} sur le critere general, cle etrangere composite de la
 * section, unicite des rangs, cascade des references) qui donnent son interet a
 * ce test — un service mocke ne les voit pas.
 *
 * <p>La table {@code skills} est pre-remplie par le seed des 48 competences :
 * toutes les assertions sont <b>seed-tolerantes</b>. On filtre sur les ids
 * crees dans le test, ou on cherche un code volontairement unique. Jamais de
 * total exact — c'est {@code SkillSeedIT} qui fige le compte du contenu publie.
 */
class AdminSkillServiceIT extends AbstractIntegrationTest {

    @Autowired
    private AdminSkillService service;

    @Autowired
    private SkillPromptManager promptManager;

    @Autowired
    private TestData testData;

    @PersistenceContext
    private EntityManager em;

    // ------------------------------------------------------------------------
    // Liste et filtres (Specification)
    // ------------------------------------------------------------------------

    @Test
    void searchMatchesCodeTitleAndDescriptionRegardlessOfCase() {
        Skill skill = testData.skill(SkillTaskCode.EE2);
        String needle = "zorglub" + UUID.randomUUID().toString().replace("-", "");
        service.updateSkill(skill.getId(), new AdminSkillUpdateRequest(
                null, "Une description contenant " + needle + " et rien d'autre.",
                null, null, null, null));

        // Recherche en majuscules sur un mot present dans la seule description :
        // le filtre est insensible a la casse et ne regarde pas que le titre.
        PageResponse<AdminSkillDto> page =
                service.list(null, null, null, needle.toUpperCase(), 0, 20);

        assertThat(page.content()).extracting(AdminSkillDto::id).containsExactly(skill.getId());
    }

    @Test
    void filtersCombineAndAreAppliedInSql() {
        Skill visible = testData.skill(SkillTaskCode.EE3);
        Skill hidden = testData.skill(SkillTaskCode.EE3);
        service.updateSkill(hidden.getId(),
                new AdminSkillUpdateRequest(null, null, null, null, null, false));

        PageResponse<AdminSkillDto> page =
                service.list(SkillSection.EE, SkillTaskCode.EE3, true, null, 0, 100);

        List<UUID> ids = page.content().stream().map(AdminSkillDto::id).toList();
        assertThat(ids).contains(visible.getId()).doesNotContain(hidden.getId());
        // Delta, jamais de total exact : la tache EE3 porte deja 8 competences seedees.
        assertThat(page.content()).allSatisfy(dto -> {
            assertThat(dto.taskCode()).isEqualTo(SkillTaskCode.EE3);
            assertThat(dto.active()).isTrue();
        });
    }

    @Test
    void listIsOrderedByTaskThenDisplayOrder() {
        PageResponse<AdminSkillDto> page = service.list(SkillSection.EO, null, null, null, 0, 100);

        assertThat(page.content()).isSortedAccordingTo((a, b) -> {
            int byTask = a.taskCode().compareTo(b.taskCode());
            return byTask != 0 ? byTask : Integer.compare(a.displayOrder(), b.displayOrder());
        });
    }

    // ------------------------------------------------------------------------
    // Ecriture contre les contraintes reelles
    // ------------------------------------------------------------------------

    @Test
    void createdSkillSatisfiesTheNotNullGeneralCriterion() {
        String code = "TST-" + UUID.randomUUID().toString().substring(0, 8);
        AdminSkillDto dto = service.createSkill(new AdminSkillCreateRequest(
                null, SkillTaskCode.EO1, code, "Titre", "Description",
                "Le critère général travaillé.", "A2", 42, true));

        AdminSkillDetailDto reloaded = service.getSkill(dto.id());
        assertThat(reloaded.skill().generalCriterion()).isEqualTo("Le critère général travaillé.");
        assertThat(reloaded.skill().section()).isEqualTo(SkillSection.EO);
        assertThat(reloaded.prompts()).isEmpty();
    }

    @Test
    void createdPromptInheritsTheSectionOfItsParentSkill() {
        Skill oral = testData.skill(SkillTaskCode.EO2);
        String code = "TST-" + UUID.randomUUID().toString().substring(0, 12);

        AdminSkillPromptDto dto = service.createPrompt(new AdminSkillPromptCreateRequest(
                oral.getId(), code, "Titre", "Contexte", "Consigne", "Critère unique",
                null, null, null, null,
                null, null, 45, SkillDifficulty.MEDIUM, 15, true));

        // La cle etrangere composite (skill_id, section) refuserait toute autre
        // valeur : la section n'a donc pas a etre demandee au client.
        assertThat(dto.section()).isEqualTo(SkillSection.EO);
        assertThat(promptManager.findById(dto.id())).get()
                .extracting(SkillPrompt::getSection).isEqualTo(SkillSection.EO);
    }

    @Test
    void patchReplacesWordBoundsRatherThanMergingThem() {
        Skill written = testData.skill(SkillTaskCode.EE1);
        SkillPrompt prompt = testData.skillPrompt(written);
        assertThat(prompt.getRecommendedMinWords()).isEqualTo(15);

        AdminSkillPromptDto dto = service.updatePrompt(prompt.getId(),
                new AdminSkillPromptUpdateRequest(null, null, null, null,
                        null, null, null, null,
                        30, 80, null, null, null, null));

        assertThat(dto.recommendedMinWords()).isEqualTo(30);
        assertThat(dto.recommendedMaxWords()).isEqualTo(80);
        assertThat(dto.recommendedDurationSeconds()).isNull();
    }

    @Test
    void patchWithANullBoundIsRefusedInsteadOfSilentlyKeepingTheOldOne() {
        SkillPrompt prompt = testData.skillPrompt(testData.skill(SkillTaskCode.EE1));

        // Sous une semantique de fusion, l'ancien minimum serait conserve et
        // l'appel passerait sans bruit. Le refus est la preuve que le nul a bien
        // ete lu comme « efface » — et c'est le CHECK
        // chk_skill_prompts_ee_eo_coherence qui serait tombe en 500 sans lui.
        assertThatThrownBy(() -> service.updatePrompt(prompt.getId(),
                new AdminSkillPromptUpdateRequest(null, null, null, null,
                        null, null, null, null,
                        null, 80, null, null, null, null)))
                .isInstanceOf(com.sejourfr.app.exception.BusinessException.class);

        assertThat(promptManager.findById(prompt.getId())).get()
                .extracting(SkillPrompt::getRecommendedMinWords).isEqualTo(15);
    }

    // ------------------------------------------------------------------------
    // References : remplacement atomique
    // ------------------------------------------------------------------------

    @Test
    void replaceReferencesSwapsTheThreeLinesAtomically() {
        SkillPrompt prompt = testData.skillPrompt();
        testData.skillReference(prompt, SkillReferenceLevel.INSUFFICIENT);
        testData.skillReference(prompt, SkillReferenceLevel.EXPECTED);
        testData.skillReference(prompt, SkillReferenceLevel.EXCELLENT);

        AdminSkillPromptDto dto = service.replaceReferences(prompt.getId(),
                new AdminSkillReferencesRequest(List.of(
                        new AdminSkillReferencesRequest.Item(
                                SkillReferenceLevel.EXCELLENT, "Très réussi", "Note 3"),
                        new AdminSkillReferencesRequest.Item(
                                SkillReferenceLevel.INSUFFICIENT, "Insuffisant", "Note 1"),
                        new AdminSkillReferencesRequest.Item(
                                SkillReferenceLevel.EXPECTED, "Attendu", "Note 2"))));

        // Trois lignes, pas six : l'ancien jeu a bien ete remplace, pas complete.
        assertThat(dto.references()).hasSize(3);
        // Et l'ordre pedagogique est retabli quel que soit l'ordre d'envoi.
        assertThat(dto.references()).extracting(r -> r.level().name())
                .containsExactly("INSUFFICIENT", "EXPECTED", "EXCELLENT");
        assertThat(dto.references()).extracting(r -> r.text())
                .containsExactly("Insuffisant", "Attendu", "Très réussi");
    }

    // ------------------------------------------------------------------------
    // Suppression : on ne detruit jamais d'historique candidat
    // ------------------------------------------------------------------------

    @Test
    void deletingAPromptWorkedOnByACandidateIsRefused() {
        SkillPrompt prompt = testData.skillPrompt();
        testData.userSkillAttempt(testData.user(), prompt);

        assertThatThrownBy(() -> service.deletePrompt(prompt.getId()))
                .isInstanceOf(IllegalStateException.class);
        assertThat(promptManager.findById(prompt.getId())).isPresent();
    }

    @Test
    void deletingASkillWorkedOnThroughOneOfItsPromptsIsRefused() {
        Skill skill = testData.skill(SkillTaskCode.EE1);
        SkillPrompt untouched = testData.skillPrompt(skill);
        SkillPrompt worked = testData.skillPrompt(skill);
        testData.userSkillAttempt(testData.user(), worked);

        // La competence n'est pas visee directement : c'est la cascade sur ses
        // sujets qui emporterait l'historique.
        assertThatThrownBy(() -> service.deleteSkill(skill.getId()))
                .isInstanceOf(IllegalStateException.class);
        assertThat(promptManager.findById(untouched.getId())).isPresent();
    }

    @Test
    void deletingAnUntouchedSkillCascadesToItsPrompts() {
        Skill skill = testData.skill(SkillTaskCode.EE2);
        UUID promptId = testData.skillPrompt(skill).getId();

        // La cascade est faite par la BASE (ON DELETE CASCADE), pas par JPA. Il
        // faut donc sortir le sujet de la session AVANT : sinon il y reste
        // attache a une competence que la suppression rend transiente, et le
        // flush suivant echoue au lieu de laisser Postgres cascader.
        em.flush();
        em.clear();

        service.deleteSkill(skill.getId());

        em.flush();
        em.clear();
        assertThat(promptManager.findById(promptId)).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Statistiques
    // ------------------------------------------------------------------------

    @Test
    void statsReportNoRateWhenNothingHasBeenAnalysed() {
        Skill skill = testData.skill(SkillTaskCode.EO3);
        SkillPrompt prompt = testData.skillPrompt(skill);
        testData.userSkillAttempt(testData.user(), prompt);

        AdminSkillStatsDto stats = service.stats(SkillSection.EO).stream()
                .filter(s -> s.skillId().equals(skill.getId()))
                .findFirst()
                .orElseThrow();

        assertThat(stats.promptCount()).isEqualTo(1);
        assertThat(stats.attemptCount()).isEqualTo(1);
        assertThat(stats.analysedCount()).isZero();
        assertThat(stats.validatedRate()).isNull();
    }
}
