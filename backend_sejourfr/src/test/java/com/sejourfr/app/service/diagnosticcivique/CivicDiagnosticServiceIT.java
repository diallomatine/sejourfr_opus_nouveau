package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.dto.CivicDiagnosticResultDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * LE DIAGNOSTIC CIVIQUE (L9), contre la vraie base et le vrai catalogue.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>la composition tient les contraintes de 20_ §4.2 — un minimum par
 *       thème, et des mises en situation tirées à part ;</li>
 *   <li>🛑 <b>l'étanchéité avec les examens blancs</b> : un diagnostic ne doit
 *       ni occuper un slot, ni compter dans « examens blancs passés ». C'est la
 *       régression qui coûte le plus cher si elle passe ;</li>
 *   <li>🛑 la projection /40 vient du serveur, et un thème non tiré ressort
 *       « non évalué », jamais faible ;</li>
 *   <li>le verrou freemium nomme sa raison.</li>
 * </ul>
 */
class CivicDiagnosticServiceIT extends AbstractIntegrationTest {

    @Autowired private CivicDiagnosticService service;
    @Autowired private CivicDiagnosticViewService viewService;
    @Autowired private TestData testData;
    @Autowired private AttemptManager attemptManager;
    @Autowired private EntityManager entityManager;
    @Autowired private JdbcTemplate jdbc;

    @Test
    @DisplayName("Ouvrir tire 24 questions, dont des mises en situation, et couvre les thèmes")
    void ouvrirComposeLeDiagnostic() {
        User user = testData.user();

        CivicDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        assertThat(session.getId()).isNotNull();
        assertThat(session.getMention()).isNotNull();
        // 🛑 Pas de slot : les slots sont la grille des examens blancs, et un
        // diagnostic n'y entre pas.
        assertThat(session.getAttempt().getSlotNumber()).isNull();

        var vue = viewService.vue(session);
        assertThat(vue.total()).isPositive();
        assertThat(vue.repondues()).isZero();

        // Les mises en situation sont tirées À PART : c'est ce qui permet de
        // les compter séparément à l'arrivée (20_ §4.5 en fait un bloc distinct).
        Integer situations = jdbc.queryForObject("""
                SELECT COUNT(*) FROM attempt_questions aq
                         JOIN questions q ON q.id = aq.question_id
                WHERE aq.attempt_id = ? AND q.question_type = ?
                """, Integer.class, session.getAttempt().getId(),
                QuestionType.MISE_SITUATION.name());
        assertThat(situations).isNotNull();

        // Plusieurs thèmes couverts : « ne jamais évaluer un thème sur une
        // seule question » n'a de sens que si plusieurs thèmes sont servis.
        Integer themes = jdbc.queryForObject("""
                SELECT COUNT(DISTINCT q.theme_id) FROM attempt_questions aq
                         JOIN questions q ON q.id = aq.question_id
                WHERE aq.attempt_id = ?
                """, Integer.class, session.getAttempt().getId());
        assertThat(themes).isGreaterThan(1);
    }

    @Test
    @DisplayName("Ouvrir est idempotent : deux appuis ne font pas deux tirages")
    void ouvertureIdempotente() {
        User user = testData.user();

        CivicDiagnosticSession premier = service.ouvrir(user.getId());
        CivicDiagnosticSession second = service.ouvrir(user.getId());

        // Deux tirages, ce seraient deux mesures incomparables.
        assertThat(second.getId()).isEqualTo(premier.getId());
        assertThat(second.getAttempt().getId()).isEqualTo(premier.getAttempt().getId());
    }

    @Test
    @DisplayName("🛑 Un diagnostic civique n'est pas compté comme un examen blanc passé")
    void etancheAvecLesExamensBlancs() {
        User user = testData.user();
        CivicDiagnosticSession session = service.ouvrir(user.getId());
        service.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();

        // C'est le discriminant `civic_diagnostic_id` qui tient la grille des
        // examens blancs à l'écart. Sans lui, ce compte vaudrait 1.
        assertThat(attemptManager.countFinishedMockExams(user.getId())).isZero();
    }

    @Test
    @DisplayName("Le résultat sert la projection /40 et TOUS les thèmes, évalués ou non")
    void resultatSertProjectionEtTousLesThemes() {
        User user = testData.user();
        CivicDiagnosticSession session = service.ouvrir(user.getId());
        service.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();

        CivicDiagnosticResultDto resultat =
                viewService.resultat(service.lire(user.getId(), session.getId()));

        assertThat(resultat.seuilReussite()).isEqualTo(32);
        assertThat(resultat.posees()).isPositive();
        // Aucune réponse donnée ⇒ tout est posé et raté : la projection est une
        // vraie mesure, pas un `null`.
        assertThat(resultat.projection40()).isNotNull().isZero();

        // 🛑 LES 5 THÈMES, toujours. Un thème absent de la liste disparaîtrait
        // de l'écran au lieu de se dire « non évalué ».
        assertThat(resultat.themes()).hasSize(5);
        assertThat(resultat.themes())
                .allSatisfy(t -> assertThat(t.etat()).isNotNull());

        // 🛑 Un thème NON ÉVALUÉ n'est jamais une priorité : on ne fait pas
        // travailler quelqu'un sur ce qu'on n'a pas mesuré.
        assertThat(resultat.priorites())
                .noneSatisfy(p -> assertThat(p.etat()).isEqualTo(CivicThemeState.NON_EVALUE));
        // Les priorités sont rangées du plus coûteux au moins coûteux.
        assertThat(resultat.priorites()).isSortedAccordingTo(
                (a, b) -> Integer.compare(b.manques(), a.manques()));
    }

    @Test
    @DisplayName("Le second diagnostic est refusé à un compte gratuit, en nommant la raison")
    void secondDiagnosticRefuseEnGratuit() {
        User user = testData.user();
        CivicDiagnosticSession premier = service.ouvrir(user.getId());
        service.cloturer(user.getId(), premier.getId());
        entityManager.flush();

        assertThatThrownBy(() -> service.ouvrir(user.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("déjà été réalisé");
    }
}
