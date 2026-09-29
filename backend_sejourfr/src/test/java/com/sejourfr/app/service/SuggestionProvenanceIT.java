package com.sejourfr.app.service;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Un verdict dit ce qui a ete decide ; {@code review_source} dit PAR QUI (V062).
 *
 * <p>🛑 <b>Pourquoi ca compte.</b> La precision du pre-tagging se mesure en
 * comparant la proposition du modele a une relecture HUMAINE. Y meler des
 * verdicts rendus par un agent qui lit le meme referentiel, c'est mesurer le
 * modele contre lui-meme : le chiffre monte et ne veut plus rien dire. Les 157
 * verdicts de la derniere tranche ont ete arbitres par un agent sous
 * delegation, et rien ne les distinguait d'une relecture du proprietaire.
 *
 * <p>Trois provenances : {@code OWNER_REVIEW}, {@code AGENT_REVIEW},
 * {@code AUTO_THRESHOLD}. Seule la premiere est une reference de mesure.
 */
class SuggestionProvenanceIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("🛑 Un verdict SANS provenance est refuse par la base")
    void unVerdictSansProvenanceEstRefuse() {
        UUID id = suggestion();

        assertThatThrownBy(() -> jdbc.update("""
                UPDATE question_notion_suggestions
                   SET review_verdict = 'VALIDATED', reviewed_at = now()
                 WHERE id = ?
                """, id))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Une provenance hors des trois valeurs connues est refusee")
    void uneProvenanceInconnueEstRefusee() {
        UUID id = suggestion();

        assertThatThrownBy(() -> jdbc.update(
                "UPDATE question_notion_suggestions SET review_source = 'MOI' WHERE id = ?", id))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Un verdict accompagne de sa provenance passe, et reste lisible")
    void unVerdictAvecSaProvenancePasse() {
        UUID id = suggestion();

        jdbc.update("""
                UPDATE question_notion_suggestions
                   SET review_verdict = 'VALIDATED', reviewed_at = now(),
                       review_source = 'AGENT_REVIEW'
                 WHERE id = ?
                """, id);

        assertThat(jdbc.queryForObject(
                "SELECT review_source FROM question_notion_suggestions WHERE id = ?",
                String.class, id)).isEqualTo("AGENT_REVIEW");
    }

    @Test
    @DisplayName("🛑 AUTO_THRESHOLD vit SANS verdict : un seuil n'est pas une relecture")
    void auto_thresholdVitSansVerdict() {
        UUID id = suggestion();

        // La reciproque de la contrainte est fausse, et c'est voulu : un tag
        // pose par le seuil de confiance porte une provenance mais aucun
        // verdict, puisque personne ne l'a relu.
        jdbc.update("UPDATE question_notion_suggestions SET review_source = 'AUTO_THRESHOLD' WHERE id = ?", id);

        assertThat(jdbc.queryForObject("""
                SELECT review_verdict IS NULL FROM question_notion_suggestions WHERE id = ?
                """, Boolean.class, id)).isTrue();
    }

    private UUID suggestion() {
        Question question = data.question();
        entityManager.flush();
        jdbc.update("""
                INSERT INTO question_notion_suggestions
                    (question_id, notion_id, confidence, prompt_version, batch_id)
                VALUES (?, NULL, 0.8, 'PROMPT_TAG_NOTION_v4', ?)
                """, question.getId(), UUID.randomUUID());
        return jdbc.queryForObject(
                "SELECT id FROM question_notion_suggestions WHERE question_id = ?",
                UUID.class, question.getId());
    }
}
