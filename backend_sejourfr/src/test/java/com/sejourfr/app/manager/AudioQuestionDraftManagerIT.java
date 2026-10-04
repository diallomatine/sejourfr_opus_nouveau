package com.sejourfr.app.manager;

import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft.DraftChoice;
import com.sejourfr.app.audioquestion.repository.AudioQuestionDraftRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AudioQuestionDraftManagerIT extends AbstractIntegrationTest {

    /** Brouillon CO image n°1 de V802, seede sans cle {@code text}. */
    private static final UUID V802_1 = UUID.fromString("66666666-0023-1000-0000-000000000001");

    @Autowired private AudioQuestionDraftManager manager;
    @Autowired private AudioQuestionDraftRepository repository;
    @Autowired private TestData testData;
    @Autowired private EntityManager em;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void findExistingExternalIds_tous_statuts() {
        AudioQuestionDraft d = testData.audioQuestionDraft();
        d.setExternalId("co-mgr-connu");
        repository.saveAndFlush(d);

        assertThat(manager.findExistingExternalIds(List.of("co-mgr-connu", "co-mgr-neuf")))
                .containsExactly("co-mgr-connu");
        assertThat(manager.findExistingExternalIds(List.of())).isEmpty();
    }

    @Test
    void external_id_unique_ferme_la_course() {
        AudioQuestionDraft a = testData.audioQuestionDraft();
        a.setExternalId("co-mgr-course");
        repository.saveAndFlush(a);
        AudioQuestionDraft b = testData.audioQuestionDraft();
        b.setExternalId("co-mgr-course");

        assertThatThrownBy(() -> repository.saveAndFlush(b)).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void les_brouillons_V802_sans_text_se_lisent_a_l_identique() {
        AudioQuestionDraft d = repository.findById(V802_1).orElseThrow();

        assertThat(d.getChoices()).extracting(DraftChoice::label).containsExactly("A", "B", "C", "D");
        assertThat(d.getChoices()).extracting(DraftChoice::text).containsOnlyNulls();
        assertThat(d.getExternalId()).isNull();
    }

    @Test
    void text_persiste_et_absent_n_est_jamais_ecrit_a_null() {
        AudioQuestionDraft d = testData.audioQuestionDraft();
        d.setChoices(List.of(new DraftChoice("A", true, 1, "Venez manger."), new DraftChoice("B", false, 2)));
        manager.persistAll(List.of(d));
        manager.flush();
        em.clear();

        AudioQuestionDraft relu = repository.findById(d.getId()).orElseThrow();
        assertThat(relu.getChoices()).extracting(DraftChoice::text).containsExactly("Venez manger.", null);
        String json = jdbc.queryForObject("SELECT choices::text FROM audio_question_draft WHERE id = ?",
                String.class, d.getId());
        assertThat(json).contains("\"text\": \"Venez manger.\"").doesNotContain("null");
    }
}
