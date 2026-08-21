package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminSkillCreateRequest;
import com.sejourfr.app.dto.AdminSkillDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Le referentiel de COMPREHENSION contre le vrai schema.
 *
 * <p>Ce qui ne se teste que la : V039 rend {@code skills.task_code} nullable,
 * mais pose en meme temps trois garde-fous que seule la base applique —
 * l'equivalence « section d'expression &hArr; tache presente », l'unicite du rang
 * a l'interieur d'un domaine, et l'impossibilite structurelle de rattacher un
 * petit sujet a une competence de comprehension. Le Postgres embarque rejoue
 * les vraies migrations Flyway : les six lignes de V318 sont donc reellement en
 * base, et les contraintes reellement opposables.
 */
class SkillComprehensionIT extends AbstractIntegrationTest {

    @Autowired
    private SkillManager skillManager;

    @Autowired
    private AdminSkillService adminSkillService;

    @Autowired
    private SkillAccessService accessService;

    @Autowired
    private TestData data;

    @Autowired
    private JdbcTemplate jdbc;

    @PersistenceContext
    private EntityManager em;

    // ------------------------------------------------------------------------
    // Le contenu publie
    // ------------------------------------------------------------------------

    @Test
    void theSixComprehensionSkillsAreSeededWithoutAnyTaskCode() {
        for (String code : new String[]{"CO-A2", "CO-B1", "CO-B2", "CE-A2", "CE-B1", "CE-B2"}) {
            Skill skill = skillManager.findByCode(code).orElseThrow();
            assertThat(skill.getTaskCode()).as("%s ne porte aucune tache", code).isNull();
            assertThat(skill.getSection().isComprehension()).isTrue();
            assertThat(skill.getTargetLevel()).isEqualTo(code.substring(3));
            assertThat(skill.isActive()).isTrue();
        }
    }

    /**
     * Les UUID sont deterministes (uuid5 sur le code metier), meme convention
     * que le generateur des competences d'expression. C'est ce qui permet aux
     * observations du Plan de survivre a une republication du contenu : les
     * figer ici, c'est interdire de les regenerer par accident.
     */
    @Test
    void theirIdentifiersAreDeterministicAndMustNotChange() {
        assertThat(skillManager.findByCode("CO-A2").orElseThrow().getId())
                .isEqualTo(UUID.fromString("cf10ca00-0522-5cf5-8fde-458d44f8a298"));
        assertThat(skillManager.findByCode("CE-B2").orElseThrow().getId())
                .isEqualTo(UUID.fromString("77f9cc04-95cc-5f04-aaee-db07712a4774"));
    }

    /** Le domaine se lit sur la section, jamais sur une tache absente. */
    @Test
    void aComprehensionDomainIsReadableByItsSectionAlone() {
        assertThat(skillManager.findActiveBySection(SkillSection.CO))
                .extracting(Skill::getCode)
                .contains("CO-A2", "CO-B1", "CO-B2")
                .doesNotContain("CE-A2");
    }

    // ------------------------------------------------------------------------
    // Ce que la base refuse
    // ------------------------------------------------------------------------

    /**
     * {@code chk_skills_task_code_presence} : une competence d'expression sans
     * tache serait un troisieme cas, et tout code lisant {@code task_code}
     * devrait alors deviner pourquoi il manque.
     */
    @Test
    void anExpressionSkillWithoutATaskIsRejectedByTheDatabase() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO skills (id, section, task_code, code, title, description,
                                    general_criterion, target_level, display_order, is_active)
                VALUES (?, 'EE', NULL, 'TST-XEE', 't', 'd', 'g', 'A2', 49, true)
                """, UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_skills_task_code_presence");
    }

    /** Et l'inverse : une competence de comprehension ne s'attribue pas de tache. */
    @Test
    void aComprehensionSkillCarryingATaskIsRejectedByTheDatabase() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO skills (id, section, task_code, code, title, description,
                                    general_criterion, target_level, display_order, is_active)
                VALUES (?, 'CO', 'EE1', 'TST-XCO', 't', 'd', 'g', 'A2', 49, true)
                """, UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    /**
     * {@code uq_skills_section_order_comprehension} : sans cet index PARTIEL,
     * {@code uq_skills_task_order} ne contraindrait plus rien pour ces lignes
     * (Postgres tient deux NULL pour distincts) et six competences pourraient
     * partager le rang 1.
     */
    @Test
    void twoComprehensionSkillsCannotShareARankInsideTheSameDomain() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO skills (id, section, task_code, code, title, description,
                                    general_criterion, target_level, display_order, is_active)
                VALUES (?, 'CO', NULL, 'TST-XDUP', 't', 'd', 'g', 'A2', 1, true)
                """, UUID.randomUUID()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    /**
     * Le meme rang dans l'AUTRE domaine reste legal : CO-A2 et CE-A2 sont tous
     * deux au rang 1. Sans ce test, un index unique pose sur le seul
     * {@code display_order} passerait inapercu.
     */
    @Test
    void thesameRankIsLegalInTheOtherDomain() {
        Skill co = skillManager.findByCode("CO-A2").orElseThrow();
        Skill ce = skillManager.findByCode("CE-A2").orElseThrow();
        assertThat(co.getDisplayOrder()).isEqualTo(ce.getDisplayOrder());
    }

    // ------------------------------------------------------------------------
    // Console admin
    // ------------------------------------------------------------------------

    @Test
    void theConsoleCreatesAComprehensionSkillFromItsDomainAlone() {
        AdminSkillDto created = adminSkillService.createSkill(new AdminSkillCreateRequest(
                SkillSection.CE, null, "TST-CE9", "Titre", "Description",
                "Critère général", "B2", 40, true));

        assertThat(created.taskCode()).isNull();
        assertThat(created.section()).isEqualTo(SkillSection.CE);

        // Le rang est verifie DANS le domaine : 40 est libre en CE, 1 ne l'est pas.
        assertThatThrownBy(() -> adminSkillService.createSkill(new AdminSkillCreateRequest(
                SkillSection.CE, null, "TST-CE8", "Titre", "Description",
                "Critère général", "B2", 1, true)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("CE-A2");
    }

    @Test
    void theConsoleRefusesAnExpressionSkillWithoutATask() {
        assertThatThrownBy(() -> adminSkillService.createSkill(new AdminSkillCreateRequest(
                SkillSection.EE, null, "TST-EE9", "Titre", "Description",
                "Critère général", "B2", 40, true)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("taskCode");
    }

    // ------------------------------------------------------------------------
    // Freemium
    // ------------------------------------------------------------------------

    /**
     * La regle retenue pour la comprehension : le rang actif le plus bas de
     * chaque domaine — le A2 sur le contenu publie — est ouvert, B1 et B2 sont
     * verrouilles. Elle est ici mesuree contre la vraie requete et le vrai seed,
     * pas contre une doublure.
     */
    @Test
    void aFreeAccountOpensTheLowestLevelOfEachComprehensionDomainAndNothingElse() {
        User user = data.user();

        SkillAccessService.SkillAccess access = accessService.resolve(user.getId());

        assertThat(access.unlimited()).isFalse();
        assertThat(access.isSkillLocked(skillManager.findByCode("CO-A2").orElseThrow().getId()))
                .isFalse();
        assertThat(access.isSkillLocked(skillManager.findByCode("CE-A2").orElseThrow().getId()))
                .isFalse();
        assertThat(access.isSkillLocked(skillManager.findByCode("CO-B1").orElseThrow().getId()))
                .isTrue();
        assertThat(access.isSkillLocked(skillManager.findByCode("CO-B2").orElseThrow().getId()))
                .isTrue();
        assertThat(access.isSkillLocked(skillManager.findByCode("CE-B1").orElseThrow().getId()))
                .isTrue();
    }

    /**
     * « Rang le plus bas encore ACTIF », et non litteralement 1 : desactiver le
     * A2 depuis la console ne doit pas fermer le domaine entier a un compte
     * gratuit — c'est exactement la lecon deja tiree cote taches.
     */
    @Test
    void deactivatingTheLowestLevelOpensTheNextOneInsteadOfClosingTheDomain() {
        User user = data.user();
        Skill coA2 = skillManager.findByCode("CO-A2").orElseThrow();
        coA2.setActive(false);
        skillManager.save(coA2);
        em.flush();

        SkillAccessService.SkillAccess access = accessService.resolve(user.getId());

        assertThat(access.isSkillLocked(skillManager.findByCode("CO-B1").orElseThrow().getId()))
                .isFalse();
        assertThat(access.isSkillLocked(skillManager.findByCode("CO-B2").orElseThrow().getId()))
                .isTrue();
        // L'autre domaine n'a pas bouge.
        assertThat(access.isSkillLocked(skillManager.findByCode("CE-A2").orElseThrow().getId()))
                .isFalse();
    }

    /**
     * Une competence de comprehension ouverte n'ouvre aucun petit sujet : elle
     * n'en a pas, et le verrou d'expression n'en compte donc pas un de plus.
     * C'est la garantie que les deux familles ne se contaminent pas.
     */
    @Test
    void openingAComprehensionDomainOpensNoPrompt() {
        User user = data.user();

        SkillAccessService.SkillAccess access = accessService.resolve(user.getId());

        assertThat(access.openPromptIds())
                .hasSize(SkillTaskCode.values().length * SkillAccessService.FREE_PROMPTS_PER_SKILL);
    }
}
