package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.exception.ConstraintViolationException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * L'idempotence des soumissions payantes (V046), verifiee contre les VRAIES
 * contraintes de la base.
 *
 * <p>Ce qui est en jeu : sans elle, une perte de reseau en fin de soumission
 * fait payer DEUX corrections LLM pour une seule production, et vide deux fois
 * le quota gratuit du candidat. La garde applicative ne suffit pas — deux
 * requetes concurrentes ne se voient pas l'une l'autre. C'est l'index unique
 * qui tranche, et c'est lui qu'on verifie ici.
 */
class IdempotenceSoumissionIT extends AbstractIntegrationTest {

    @Autowired
    private TestData testData;
    @Autowired
    private ProductionSubmissionManager submissionManager;
    @Autowired
    private UserSkillAttemptManager skillAttemptManager;
    @Autowired
    private EntityManager entityManager;

    // ------------------------------------------------------------------------
    // Productions completes EE/EO
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Deux soumissions du même utilisateur sous la même clé : la base refuse la seconde")
    void deuxSoumissionsMemeCleMemeUtilisateur() {
        User user = testData.user();
        ProductionTask task = testData.productionTask();
        Attempt attempt = testData.attempt(user);
        UUID cle = UUID.randomUUID();

        ProductionSubmission premiere = testData.productionSubmission(attempt, task, user);
        premiere.setClientSubmissionId(cle);
        submissionManager.save(premiere);
        entityManager.flush();

        ProductionSubmission seconde = new ProductionSubmission();
        seconde.setAttempt(attempt);
        seconde.setProductionTask(task);
        seconde.setUser(user);
        seconde.setTexteSoumis("La meme production, renvoyee apres une coupure reseau.");
        seconde.setClientSubmissionId(cle);

        // Le type exact du wrapper depend du moment ou la violation remonte :
        // dans le code de production, `save()` a sa PROPRE transaction (le
        // service n'est pas @Transactional), Spring traduit donc en
        // DataIntegrityViolationException — ce que le service attrape. Ici le
        // test est transactionnel et le flush explicite laisse remonter
        // l'exception Hibernate. Ce qui doit etre verrouille est le meme dans
        // les deux cas : la BASE refuse, en nommant son index.
        assertThatThrownBy(() -> {
            submissionManager.save(seconde);
            entityManager.flush();
        })
                .isInstanceOfAny(DataIntegrityViolationException.class,
                        ConstraintViolationException.class)
                .hasMessageContaining("uq_prod_submission_client_key");
    }

    /**
     * 🛑 L'unicite est bornee a l'utilisateur, et ce test est la raison d'etre
     * de cette borne. La cle est tiree par le CLIENT : rien n'empeche deux
     * appareils de tirer la meme UUID. Avec une unicite globale — celle que la
     * spec proposait — la soumission d'un candidat ferait echouer celle d'un
     * inconnu.
     */
    @Test
    @DisplayName("La même clé chez deux utilisateurs différents ne pose aucun problème")
    void memeCleChezDeuxUtilisateurs() {
        UUID cle = UUID.randomUUID();
        ProductionTask task = testData.productionTask();

        User premier = testData.user("premier-" + UUID.randomUUID() + "@sejourfr.fr");
        ProductionSubmission a = testData.productionSubmission(testData.attempt(premier), task, premier);
        a.setClientSubmissionId(cle);
        submissionManager.save(a);

        User second = testData.user("second-" + UUID.randomUUID() + "@sejourfr.fr");
        ProductionSubmission b = testData.productionSubmission(testData.attempt(second), task, second);
        b.setClientSubmissionId(cle);
        submissionManager.save(b);

        entityManager.flush();

        assertThat(submissionManager.findByClientKey(premier.getId(), cle))
                .map(ProductionSubmission::getId)
                .contains(a.getId());
        assertThat(submissionManager.findByClientKey(second.getId(), cle))
                .map(ProductionSubmission::getId)
                .contains(b.getId());
    }

    /**
     * NULL n'est pas une valeur : autant de soumissions sans cle que voulu.
     * C'est ce qui permet aux applications deja installees de continuer.
     */
    @Test
    @DisplayName("Plusieurs soumissions sans clé cohabitent, la migration ne casse rien")
    void plusieursSoumissionsSansCle() {
        User user = testData.user();
        ProductionTask task = testData.productionTask();
        Attempt attempt = testData.attempt(user);

        testData.productionSubmission(attempt, task, user);
        testData.productionSubmission(attempt, task, user);
        testData.productionSubmission(attempt, task, user);
        entityManager.flush();

        assertThat(submissionManager.findByAttemptId(attempt.getId())).hasSize(3);
        assertThat(submissionManager.findByClientKey(user.getId(), null)).isEmpty();
    }

    @Test
    @DisplayName("Une clé jamais vue ne retrouve rien, et ce n'est pas une erreur")
    void cleInconnue() {
        User user = testData.user();
        assertThat(submissionManager.findByClientKey(user.getId(), UUID.randomUUID()))
                .isEmpty();
    }

    // ------------------------------------------------------------------------
    // Petits sujets de competence
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Les petits sujets sont protégés par la même contrainte")
    void deuxProductionsDeCompetenceMemeCle() {
        User user = testData.user();
        Skill skill = testData.skill();
        SkillPrompt prompt = testData.skillPrompt(skill);
        UUID cle = UUID.randomUUID();

        skillAttemptManager.save(attemptDe(user, prompt, cle));
        entityManager.flush();

        assertThatThrownBy(() -> {
            skillAttemptManager.save(attemptDe(user, prompt, cle));
            entityManager.flush();
        })
                .isInstanceOfAny(DataIntegrityViolationException.class,
                        ConstraintViolationException.class)
                .hasMessageContaining("uq_skill_attempt_client_key");
    }

    @Test
    @DisplayName("Le rejeu d'un petit sujet retrouve exactement la production d'origine")
    void rejeuRetrouveLaProductionDorigine() {
        User user = testData.user();
        SkillPrompt prompt = testData.skillPrompt(testData.skill());
        UUID cle = UUID.randomUUID();

        UserSkillAttempt origine = skillAttemptManager.save(attemptDe(user, prompt, cle));
        entityManager.flush();

        Optional<UserSkillAttempt> retrouvee = skillAttemptManager.findByClientKey(user.getId(), cle);

        assertThat(retrouvee).map(UserSkillAttempt::getId).contains(origine.getId());
    }

    private UserSkillAttempt attemptDe(User user, SkillPrompt prompt, UUID cle) {
        UserSkillAttempt a = new UserSkillAttempt();
        a.setUser(user);
        a.setSkillPrompt(prompt);
        a.setWrittenProduction("Bonjour Madame, je vous ecris au sujet du bruit.");
        a.setWordsCount(9);
        a.setStatut(SkillAttemptStatut.RECORDED);
        a.setClientSubmissionId(cle);
        return a;
    }
}
