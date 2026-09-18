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
                "Critère général", null, "B2", 40, true));

        assertThat(created.taskCode()).isNull();
        assertThat(created.section()).isEqualTo(SkillSection.CE);

        // Le rang est verifie DANS le domaine : 40 est libre en CE, 1 ne l'est pas.
        assertThatThrownBy(() -> adminSkillService.createSkill(new AdminSkillCreateRequest(
                SkillSection.CE, null, "TST-CE8", "Titre", "Description",
                "Critère général", null, "B2", 1, true)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("CE-A2");
    }

    @Test
    void theConsoleRefusesAnExpressionSkillWithoutATask() {
        assertThatThrownBy(() -> adminSkillService.createSkill(new AdminSkillCreateRequest(
                SkillSection.EE, null, "TST-EE9", "Titre", "Description",
                "Critère général", null, "B2", 40, true)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("taskCode");
    }

    // ------------------------------------------------------------------------
    // Freemium — D-18 (2026-09-18)
    // ------------------------------------------------------------------------

    /**
     * 🛑 <b>D-18 — travailler une competence est PREMIUM, sans exception</b>, et
     * « les rangs CO/CE sont traites dans la meme passe, coherents avec la meme
     * regle ».
     *
     * <p>Ce test verifiait la regle du 2026-08-10 : « le rang actif le plus bas
     * de chaque domaine — le A2 sur le contenu publie — est ouvert, B1 et B2
     * sont verrouilles », ainsi que son corollaire (desactiver le A2 depuis la
     * console ouvre le B1 au lieu de fermer le domaine). Les deux sont
     * <b>revoques</b> : il n'y a plus de rang ouvert a faire glisser.
     *
     * <p>Mesure contre le vrai seed de V318 et le vrai schema : les six lignes
     * sont bien en base, et <b>les six sont fermees</b>.
     */
    @Test
    void aFreeAccountOpensNothingAtAll_D18() {
        User user = data.user();

        SkillAccessService.SkillAccess access = accessService.resolve(user.getId());

        assertThat(access.unlimited()).isFalse();
        assertThat(access.openSkillIds()).isEmpty();
        assertThat(access.openPromptIds()).isEmpty();
        for (String code : new String[]{"CO-A2", "CO-B1", "CO-B2", "CE-A2", "CE-B1", "CE-B2"}) {
            assertThat(access.isSkillLocked(skillManager.findByCode(code).orElseThrow().getId()))
                    .as("%s est fermee a un compte gratuit (D-18)", code)
                    .isTrue();
        }
        // 🛑 Et rien n'est MASQUE pour autant : les six competences restent
        // lisibles dans le referentiel. On ferme l'execution, pas l'affichage.
        assertThat(skillManager.findActiveBySection(SkillSection.CO))
                .extracting(Skill::getCode)
                .contains("CO-A2", "CO-B1", "CO-B2");
    }

    /** Un abonne TCF, lui, n'a aucun verrou sur aucun des six niveaux. */
    @Test
    void aTcfSubscriberOpensEveryComprehensionLevel() {
        User subscriber = data.user();
        data.userSubscription(subscriber, data.plan());
        em.flush();

        SkillAccessService.SkillAccess access = accessService.resolve(subscriber.getId());

        assertThat(access.unlimited()).isTrue();
        for (String code : new String[]{"CO-A2", "CO-B1", "CO-B2", "CE-A2", "CE-B1", "CE-B2"}) {
            assertThat(access.isSkillLocked(skillManager.findByCode(code).orElseThrow().getId()))
                    .isFalse();
        }
    }
}
