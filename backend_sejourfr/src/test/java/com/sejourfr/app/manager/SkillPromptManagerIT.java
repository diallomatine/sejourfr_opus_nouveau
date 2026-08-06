package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillConstraintTag;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.SkillReference;
import com.sejourfr.app.enums.SkillConstraintIcon;
import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillReferenceLevel;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.repository.SkillPromptRepository;
import com.sejourfr.app.repository.SkillReferenceRepository;
import com.sejourfr.app.repository.SkillRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Les tables {@code skill_prompts} et {@code skill_references} seront
 * pre-remplies par le seed (240 sujets, 720 references). Les assertions sont
 * donc <b>seed-tolerantes</b> : filtrage sur les ids crees dans le test, ou
 * delta par rapport a un baseline. Jamais de total exact.
 */
class SkillPromptManagerIT extends AbstractIntegrationTest {

    @Autowired
    private SkillPromptManager manager;

    @Autowired
    private SkillPromptRepository repository;

    @Autowired
    private SkillRepository skillRepository;

    @Autowired
    private SkillReferenceRepository referenceRepository;

    @Autowired
    private TestData testData;

    @Autowired
    private EntityManager em;

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    /**
     * Les deux colonnes de guidage sont du {@code jsonb} : leur forme Java
     * (liste de chaines, liste d'objets {@code {label, icon}}) ne vit que dans
     * le mapping Hibernate, pas dans le schema. Le contexte de persistance est
     * donc vide avant la relecture — sans cela le test relirait l'objet ecrit,
     * et une serialisation cassee passerait inapercue.
     */
    @Test
    void guidanceSurvivesTheJsonbRoundTrip() {
        SkillPrompt prompt = testData.skillPrompt(testData.skill(SkillTaskCode.EE1));
        prompt.setChecklist(List.of("Saluez votre voisine", "Écrivez deux phrases"));
        prompt.setConstraintTags(List.of(
                new SkillConstraintTag("Vouvoiement", SkillConstraintIcon.PERSON),
                new SkillConstraintTag("Ton poli", SkillConstraintIcon.TONE)));
        prompt.setAnswerStarter("Bonjour Madame, je suis votre voisin du…");
        prompt.setTip("commencez par bonjour");
        manager.save(prompt);
        em.flush();
        em.clear();

        assertThat(manager.findById(prompt.getId())).get().satisfies(reloaded -> {
            assertThat(reloaded.getChecklist())
                    .containsExactly("Saluez votre voisine", "Écrivez deux phrases");
            assertThat(reloaded.getConstraintTags()).containsExactly(
                    new SkillConstraintTag("Vouvoiement", SkillConstraintIcon.PERSON),
                    new SkillConstraintTag("Ton poli", SkillConstraintIcon.TONE));
            assertThat(reloaded.getAnswerStarter()).isEqualTo("Bonjour Madame, je suis votre voisin du…");
            assertThat(reloaded.getTip()).isEqualTo("commencez par bonjour");
        });
    }

    /**
     * Les quatre colonnes sont nullables (V026) : un sujet cree depuis la
     * console peut naitre sans guidage, et sa relecture ne doit pas echouer.
     */
    @Test
    void promptWithoutGuidanceIsReloadedWithNulls() {
        SkillPrompt prompt = testData.skillPrompt(testData.skill(SkillTaskCode.EE1));
        prompt.setChecklist(null);
        prompt.setConstraintTags(null);
        prompt.setAnswerStarter(null);
        prompt.setTip(null);
        manager.save(prompt);
        em.flush();
        em.clear();

        assertThat(manager.findById(prompt.getId())).get().satisfies(reloaded -> {
            assertThat(reloaded.getChecklist()).isNull();
            assertThat(reloaded.getConstraintTags()).isNull();
            assertThat(reloaded.getAnswerStarter()).isNull();
            assertThat(reloaded.getTip()).isNull();
        });
    }

    @Test
    void findActiveByIdWithSkillLoadsTheParentSkill() {
        Skill skill = testData.skill(SkillTaskCode.EE1);
        SkillPrompt prompt = testData.skillPrompt(skill);

        assertThat(manager.findActiveByIdWithSkill(prompt.getId()))
                .get()
                .extracting(p -> p.getSkill().getCode())
                .isEqualTo(skill.getCode());
    }

    @Test
    void findActiveByIdWithSkillFiltersInactivePrompt() {
        SkillPrompt prompt = testData.skillPrompt();
        prompt.setActive(false);
        repository.saveAndFlush(prompt);

        assertThat(manager.findActiveByIdWithSkill(prompt.getId())).isEmpty();
        // La variante non filtrante reste disponible pour l'admin.
        assertThat(manager.findByIdWithSkill(prompt.getId())).isPresent();
    }

    @Test
    void findActiveByIdWithSkillFiltersPromptsOfAnInactiveSkill() {
        Skill skill = testData.skill(SkillTaskCode.EE2);
        SkillPrompt prompt = testData.skillPrompt(skill);
        skill.setActive(false);
        skillRepository.saveAndFlush(skill);

        // Desactiver une competence doit retirer ses sujets de la vue candidat
        // sans avoir a desactiver les cinq lignes une par une.
        assertThat(manager.findActiveByIdWithSkill(prompt.getId())).isEmpty();
    }

    @Test
    void findActiveBySkillIdOrdersByDisplayOrderAndExcludesInactive() {
        Skill skill = testData.skill(SkillTaskCode.EE3);
        SkillPrompt first = testData.skillPrompt(skill);
        SkillPrompt second = testData.skillPrompt(skill);
        SkillPrompt inactive = testData.skillPrompt(skill);
        inactive.setActive(false);
        repository.saveAndFlush(inactive);
        SkillPrompt otherSkill = testData.skillPrompt();

        List<SkillPrompt> result = manager.findActiveBySkillId(skill.getId());

        assertThat(result).extracting(SkillPrompt::getId)
                .containsExactly(first.getId(), second.getId())
                .doesNotContain(inactive.getId(), otherSkill.getId());
    }

    @Test
    void findByCodeReturnsThePrompt() {
        SkillPrompt prompt = testData.skillPrompt();

        assertThat(manager.findByCode(prompt.getCode()))
                .get()
                .extracting(SkillPrompt::getId)
                .isEqualTo(prompt.getId());
        assertThat(manager.findByCode("inexistant-" + UUID.randomUUID())).isEmpty();
    }

    @Test
    void countActiveBySkillCountsInDeltaAndIgnoresInactive() {
        Skill skill = testData.skill(SkillTaskCode.EO1);
        List<SkillTaskCode> scope = List.of(SkillTaskCode.EO1);

        long before = manager.countActiveBySkillForTaskCodes(scope)
                .getOrDefault(skill.getId(), 0L);

        testData.skillPrompt(skill);
        testData.skillPrompt(skill);
        SkillPrompt inactive = testData.skillPrompt(skill);
        inactive.setActive(false);
        repository.saveAndFlush(inactive);

        Map<UUID, Long> after = manager.countActiveBySkillForTaskCodes(scope);

        assertThat(after.get(skill.getId())).isEqualTo(before + 2);
    }

    @Test
    void countActiveBySkillIgnoresPromptsOfAnInactiveSkill() {
        Skill skill = testData.skill(SkillTaskCode.EO2);
        testData.skillPrompt(skill);
        skill.setActive(false);
        skillRepository.saveAndFlush(skill);

        assertThat(manager.countActiveBySkillForTaskCodes(List.of(SkillTaskCode.EO2)))
                .doesNotContainKey(skill.getId());
    }

    @Test
    void countActiveBySkillWithEmptyScopeDoesNotHitTheDatabase() {
        // Un IN vide est un SQL invalide : le manager doit court-circuiter.
        assertThat(manager.countActiveBySkillForTaskCodes(List.of())).isEmpty();
    }

    @Test
    void referencesAreReturnedInPedagogicalOrderNotAlphabetical() {
        SkillPrompt prompt = testData.skillPrompt();
        // Insertion volontairement en desordre : c'est le tri du manager qui doit
        // remettre l'ordre pedagogique. Alphabetiquement, EXCELLENT precederait
        // EXPECTED — donc le meilleur modele avant l'attendu.
        testData.skillReference(prompt, SkillReferenceLevel.EXCELLENT);
        testData.skillReference(prompt, SkillReferenceLevel.INSUFFICIENT);
        testData.skillReference(prompt, SkillReferenceLevel.EXPECTED);

        List<SkillReference> result = manager.findReferencesByPromptId(prompt.getId());

        assertThat(result).extracting(SkillReference::getLevel)
                .containsExactly(
                        SkillReferenceLevel.INSUFFICIENT,
                        SkillReferenceLevel.EXPECTED,
                        SkillReferenceLevel.EXCELLENT);
    }

    @Test
    void twoReferencesOfTheSameLevelAreRejectedByDatabase() {
        SkillPrompt prompt = testData.skillPrompt();
        testData.skillReference(prompt, SkillReferenceLevel.EXPECTED);

        SkillReference duplicate = new SkillReference();
        duplicate.setSkillPrompt(prompt);
        duplicate.setLevel(SkillReferenceLevel.EXPECTED);
        duplicate.setText("Deuxieme reference du meme niveau");
        duplicate.setPedagogicalNote("Interdit : une seule par niveau et par sujet.");

        // saveAndFlush : un simple save() differe l'INSERT et la contrainte ne
        // parlerait qu'au commit — que le test annule.
        assertThatThrownBy(() -> referenceRepository.saveAndFlush(duplicate))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void deleteReferencesRemovesThemAll() {
        SkillPrompt prompt = testData.skillPrompt();
        testData.skillReference(prompt, SkillReferenceLevel.INSUFFICIENT);
        testData.skillReference(prompt, SkillReferenceLevel.EXPECTED);
        assertThat(manager.countReferencesByPromptId(prompt.getId())).isEqualTo(2);

        manager.deleteReferencesByPromptId(prompt.getId());

        assertThat(manager.countReferencesByPromptId(prompt.getId())).isZero();
        assertThat(manager.findReferencesByPromptId(prompt.getId())).isEmpty();
    }

    @Test
    void writtenPromptWithoutWordBoundsIsRejectedByDatabase() {
        // chk_skill_prompts_ee_eo_coherence : un sujet ecrit se mesure en mots.
        SkillPrompt invalid = basePrompt(testData.skill(SkillTaskCode.EE1), SkillSection.EE);
        invalid.setRecommendedDurationSeconds(45);

        assertThatThrownBy(() -> repository.saveAndFlush(invalid))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void oralPromptWithWordBoundsIsRejectedByDatabase() {
        // ... et un sujet oral en secondes. Jamais les deux, jamais aucun.
        SkillPrompt invalid = basePrompt(testData.skill(SkillTaskCode.EO1), SkillSection.EO);
        invalid.setRecommendedMinWords(15);
        invalid.setRecommendedMaxWords(50);

        assertThatThrownBy(() -> repository.saveAndFlush(invalid))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void invertedWordBoundsAreRejectedByDatabase() {
        SkillPrompt invalid = basePrompt(testData.skill(SkillTaskCode.EE1), SkillSection.EE);
        invalid.setRecommendedMinWords(50);
        invalid.setRecommendedMaxWords(15);

        assertThatThrownBy(() -> repository.saveAndFlush(invalid))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void sectionThatContradictsTheParentSkillIsRejectedByDatabase() {
        // La FK COMPOSITE (skill_id, section) -> skills(id, section) est ce qui
        // empeche la colonne denormalisee de mentir.
        SkillPrompt invalid = basePrompt(testData.skill(SkillTaskCode.EE1), SkillSection.EO);
        invalid.setRecommendedDurationSeconds(45);

        assertThatThrownBy(() -> repository.saveAndFlush(invalid))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private SkillPrompt basePrompt(Skill skill, SkillSection section) {
        SkillPrompt p = new SkillPrompt();
        p.setSkill(skill);
        p.setSection(section);
        p.setCode("BAD-" + UUID.randomUUID().toString().substring(0, 12));
        p.setTitle("Sujet invalide");
        p.setContext("Contexte.");
        p.setInstruction("Consigne.");
        p.setUniqueCriterion("Critere.");
        p.setDifficultyLevel(SkillDifficulty.EASY);
        p.setDisplayOrder((short) 19);
        p.setActive(true);
        return p;
    }
}
