package com.sejourfr.app.migration;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.QuestionStatus;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * V089 rejouee : le SQL sous la sentinelle {@code @@ALIGNEMENT_STATUS@@} est lu
 * dans la migration REELLE (jamais recopie) et applique a des questions
 * fabriquees ici. Toute question {@code is_active} passe {@code ACTIVE} ; une
 * question inactive garde son statut ; rejouee, la migration ne touche plus rien.
 */
class QuestionStatusAlignementIT extends AbstractIntegrationTest {

    private static final String SENTINELLE = "-- @@ALIGNEMENT_STATUS@@";

    @Autowired private JdbcTemplate jdbc;
    @Autowired private TestData testData;
    @Autowired private QuestionRepository repository;
    @Autowired private EntityManager em;

    @Test
    void les_questions_actives_passent_ACTIVE_les_inactives_ne_bougent_pas() {
        Question activeDraft = question(true, QuestionStatus.DRAFT);
        Question activeArchivee = question(true, QuestionStatus.ARCHIVED);
        Question inactiveDraft = question(false, QuestionStatus.DRAFT);
        Question inactiveArchivee = question(false, QuestionStatus.ARCHIVED);

        int touchees = jdbc.update(sql());
        em.clear();

        assertThat(touchees).isGreaterThanOrEqualTo(2);
        assertThat(statut(activeDraft)).isEqualTo(QuestionStatus.ACTIVE);
        assertThat(statut(activeArchivee)).isEqualTo(QuestionStatus.ACTIVE);
        assertThat(statut(inactiveDraft)).isEqualTo(QuestionStatus.DRAFT);
        assertThat(statut(inactiveArchivee)).isEqualTo(QuestionStatus.ARCHIVED);
        assertThat(jdbc.update(sql())).as("idempotente").isZero();
    }

    private Question question(boolean active, QuestionStatus status) {
        Question q = testData.question();
        q.setActive(active);
        q.setStatus(status);
        return repository.saveAndFlush(q);
    }

    private QuestionStatus statut(Question q) {
        return repository.findById(q.getId()).orElseThrow().getStatus();
    }

    private static String sql() {
        ClassPathResource resource = new ClassPathResource(
                "db/migration/00_schema/V089__questions_status_aligne_sur_is_active.sql");
        String migration;
        try (var in = resource.getInputStream()) {
            migration = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Migration V089 introuvable", e);
        }
        int coupe = migration.indexOf(SENTINELLE);
        assertThat(coupe).as("sentinelle " + SENTINELLE + " absente de V089").isPositive();
        return migration.substring(coupe + SENTINELLE.length());
    }
}
