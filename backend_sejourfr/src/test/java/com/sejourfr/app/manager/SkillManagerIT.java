package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.repository.SkillRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * La table {@code skills} est pre-remplie par le seed des 48 competences.
 * Toutes les assertions sont donc <b>seed-tolerantes</b> : on filtre sur les
 * ids crees dans le test, ou on raisonne en delta par rapport a un baseline
 * capture avant l'insertion. Jamais de total exact — le compte exact du contenu
 * publie, c'est {@code SkillSeedIT} qui le fige.
 *
 * <p>Les competences de test se rangent AU-DESSUS du seed (rangs 9 et suivants,
 * la borne du {@code CHECK} etant a 50) : aucun test n'a plus a supprimer une
 * competence seedee pour se faire de la place.
 */
class SkillManagerIT extends AbstractIntegrationTest {

    @Autowired
    private SkillManager manager;

    @Autowired
    private SkillRepository repository;

    @Autowired
    private TestData testData;

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findActiveByIdFiltersInactive() {
        Skill active = testData.skill(SkillTaskCode.EE1);
        Skill inactive = testData.skill(SkillTaskCode.EE1);
        inactive.setActive(false);
        repository.saveAndFlush(inactive);

        assertThat(manager.findActiveById(active.getId())).isPresent();
        assertThat(manager.findActiveById(inactive.getId())).isEmpty();
    }

    @Test
    void findByCodeReturnsTheSkill() {
        Skill skill = testData.skill(SkillTaskCode.EE2);

        assertThat(manager.findByCode(skill.getCode()))
                .get()
                .extracting(Skill::getId)
                .isEqualTo(skill.getId());
        assertThat(manager.findByCode("code-inexistant-" + UUID.randomUUID())).isEmpty();
    }

    @Test
    void findActiveByTaskCodeExcludesInactiveAndOtherTasks() {
        Skill mine = testData.skill(SkillTaskCode.EE3);
        Skill otherTask = testData.skill(SkillTaskCode.EO1);
        Skill inactive = testData.skill(SkillTaskCode.EE3);
        inactive.setActive(false);
        repository.saveAndFlush(inactive);

        List<Skill> result = manager.findActiveByTaskCode(SkillTaskCode.EE3);

        assertThat(result).extracting(Skill::getId)
                .contains(mine.getId())
                .doesNotContain(otherTask.getId(), inactive.getId());
        assertThat(result).allMatch(s -> s.getTaskCode() == SkillTaskCode.EE3 && s.isActive());
    }

    @Test
    void findActiveByTaskCodeOrdersByDisplayOrder() {
        List<Skill> result = manager.findActiveByTaskCode(SkillTaskCode.EO2);

        assertThat(result).isSortedAccordingTo(
                (a, b) -> Short.compare(a.getDisplayOrder(), b.getDisplayOrder()));
    }

    @Test
    void findActiveBySectionCoversTheThreeTasksAndExcludesTheOtherSection() {
        Skill ee = testData.skill(SkillTaskCode.EE1);
        Skill eo = testData.skill(SkillTaskCode.EO1);

        List<Skill> result = manager.findActiveBySection(SkillSection.EE);

        assertThat(result).extracting(Skill::getId)
                .contains(ee.getId())
                .doesNotContain(eo.getId());
        assertThat(result).allMatch(s -> s.getSection() == SkillSection.EE);
    }

    @Test
    void countActiveByTaskCodeAlwaysReturnsTheThreeTasksOfTheSection() {
        List<SkillTaskCode> scope = SkillTaskCode.of(SkillSection.EO);

        Map<SkillTaskCode, Long> counts = manager.countActiveByTaskCode(scope);

        // Les 3 taches de l'epreuve sont TOUJOURS presentes, meme a zero : une
        // tache sans contenu doit s'afficher, pas disparaitre de l'ecran.
        assertThat(counts).containsOnlyKeys(SkillTaskCode.EO1, SkillTaskCode.EO2, SkillTaskCode.EO3);
        // Le compte agrege doit dire exactement la meme chose que la liste.
        for (SkillTaskCode code : scope) {
            assertThat(counts.get(code))
                    .isEqualTo(manager.findActiveByTaskCode(code).size());
        }
    }

    @Test
    void countActiveByTaskCodeIgnoresInactive() {
        List<SkillTaskCode> scope = List.of(SkillTaskCode.EE2);
        long before = manager.countActiveByTaskCode(scope).get(SkillTaskCode.EE2);
        Skill skill = testData.skill(SkillTaskCode.EE2);
        assertThat(manager.countActiveByTaskCode(scope).get(SkillTaskCode.EE2))
                .isEqualTo(before + 1);

        skill.setActive(false);
        repository.saveAndFlush(skill);

        // Desactivee, la competence sort du compte : on retombe sur le baseline.
        // Elle existe toujours en base — c'est bien `is_active` qui est filtre,
        // pas la ligne qui a disparu.
        assertThat(manager.countActiveByTaskCode(scope).get(SkillTaskCode.EE2)).isEqualTo(before);
        assertThat(repository.findById(skill.getId())).isPresent();
    }

    @Test
    void sectionMustMatchTaskCode() {
        // 'EO' avec un task_code 'EE1' : interdit par chk_skills_section_matches_task,
        // le garde-fou qui rend la denormalisation de `section` sure.
        Skill invalid = candidate(SkillTaskCode.EE1, freeDisplayOrder(SkillTaskCode.EE1));
        invalid.setSection(SkillSection.EO);

        // Le nom de la contrainte est verifie, et le rang choisi est LIBRE :
        // sinon une simple collision d'unicite ferait passer le test pour de
        // mauvaises raisons.
        assertThatThrownBy(() -> repository.saveAndFlush(invalid))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_skills_section_matches_task");
    }

    @Test
    void displayOrderOutOfBoundsIsRejectedByDatabase() {
        // 51 et non 9 : la borne haute a ete portee a 50 pour que l'admin puisse
        // encore creer une competence alors que le seed occupe deja les rangs
        // 1..8 de chaque tache. Le CHECK ne garde plus qu'une valeur
        // manifestement fausse hors de la base.
        Skill invalid = candidate(SkillTaskCode.EE1, (short) 51);

        assertThatThrownBy(() -> repository.saveAndFlush(invalid))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_skills_display_order");
    }

    @Test
    void duplicateCodeIsRejectedByDatabase() {
        Skill existing = testData.skill(SkillTaskCode.EE1);

        Skill duplicate = candidate(SkillTaskCode.EO1, freeDisplayOrder(SkillTaskCode.EO1));
        duplicate.setCode(existing.getCode());

        assertThatThrownBy(() -> repository.saveAndFlush(duplicate))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("uq_skills_code");
    }

    /** Competence VALIDE : chaque test n'en casse ensuite qu'un seul aspect. */
    private static Skill candidate(SkillTaskCode taskCode, short displayOrder) {
        Skill skill = new Skill();
        skill.setSection(taskCode.getSection());
        skill.setTaskCode(taskCode);
        skill.setCode("BAD-" + UUID.randomUUID().toString().substring(0, 8));
        skill.setTitle("Competence candidate");
        skill.setDescription("Ce que cette competence apporte au TCF.");
        skill.setGeneralCriterion("Le critere general travaille par cette competence.");
        skill.setTargetLevel("A2");
        skill.setDisplayOrder(displayOrder);
        skill.setActive(true);
        return skill;
    }

    /** Rang au-dessus du seed : garantit que seule la contrainte visee peut echouer. */
    private short freeDisplayOrder(SkillTaskCode taskCode) {
        short max = 0;
        for (Skill existing : repository.findByTaskCodeOrderByDisplayOrderAsc(taskCode)) {
            if (existing.getDisplayOrder() > max) max = existing.getDisplayOrder();
        }
        return (short) (max + 1);
    }

    @Test
    void saveUpdatesTheSkill() {
        Skill skill = testData.skill(SkillTaskCode.EE1);
        skill.setTitle("Titre revise");

        manager.save(skill);

        assertThat(manager.findById(skill.getId()))
                .get()
                .extracting(Skill::getTitle)
                .isEqualTo("Titre revise");
    }
}
