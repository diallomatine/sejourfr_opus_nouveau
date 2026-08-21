package com.sejourfr.app.migration;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Fige le contenu qualifie {@code WRITTEN_QUESTION_SPOKEN_CHOICES} par le couple
 * {@code 00_schema/V037} (contrainte) + {@code 300_tcf/.../V590} (backfill).
 *
 * <p>Ces CO ont un document sonore qui <b>enonce les 4 propositions avec leurs
 * lettres</b> alors que l'ecran affiche <b>aussi leur texte</b> : les melanger
 * desynchronise la lettre dite de la lettre affichee, et le candidat qui entend
 * « B », retient B et clique B se trompe alors qu'il avait compris.
 *
 * <p>Le test verifie la <b>donnee</b>, pas seulement le compte : le mode et le
 * predicat qui l'a pose doivent designer exactement la meme population, et le
 * contenu de ces questions doit etre coherent avec {@code display_order} — c'est
 * ce qui rend l'exemption de melange legitime.
 *
 * <p>La fabrique {@code TestData} ne pose jamais ce mode ; les comptes sont donc
 * ceux du seed publie, et chaque test roule dans une transaction annulee.
 */
class CoAudioModePropositionsLuesIT extends AbstractIntegrationTest {

    /** Compte publie au moment de la bascule (V590). Une 21e ligne serait un contenu neuf a arbitrer. */
    private static final int QUESTIONS_QUALIFIEES = 20;

    private static final String MODE = "WRITTEN_QUESTION_SPOKEN_CHOICES";

    /** Le predicat du backfill, reecrit ici : deux formulations qui divergeraient seraient un bug. */
    private static final String PREDICAT = """
            q.question_type = 'CO'
              AND m.type = 'AUDIO'
              AND m.transcript ~ 'A\\.\\s.*\\sB\\.\\s.*\\sC\\.\\s.*\\sD\\.\\s'
              AND NOT EXISTS (
                  SELECT 1 FROM choices c
                  WHERE c.question_id = q.id AND length(trim(c.label)) <= 2)
            """;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void leBackfillQualifieExactementLesCoDontLAudioEnonceLesPropositions() {
        assertThat(compte("SELECT count(*) FROM questions WHERE audio_mode = '" + MODE + "'"))
                .isEqualTo(QUESTIONS_QUALIFIEES);
    }

    @Test
    void leModeEtLePredicatDesignentLaMemePopulation() {
        // Aucune question qualifiee par le predicat ne reste sans le mode…
        assertThat(compte("""
                SELECT count(*) FROM questions q JOIN medias m ON m.id = q.media_id
                WHERE q.audio_mode IS DISTINCT FROM '%s' AND %s
                """.formatted(MODE, PREDICAT))).isZero();

        // …et aucune question ne porte le mode sans satisfaire le predicat.
        assertThat(compte("""
                SELECT count(*) FROM questions q LEFT JOIN medias m ON m.id = q.media_id
                WHERE q.audio_mode = '%s' AND NOT (%s)
                """.formatted(MODE, PREDICAT))).isZero();
    }

    @Test
    void aucuneCoImageNiCoToutDansLAudioNEstTouchee() {
        assertThat(compte("""
                SELECT count(*) FROM questions
                WHERE audio_mode = '%s' AND question_type <> 'CO'
                """.formatted(MODE))).isZero();

        // Les CO dont l'ecran ne montre que des lettres restent FULL_AUDIO ou NULL.
        assertThat(compte("""
                SELECT count(*) FROM questions q
                WHERE q.audio_mode = '%s'
                  AND EXISTS (SELECT 1 FROM choices c
                              WHERE c.question_id = q.id AND length(trim(c.label)) <= 2)
                """.formatted(MODE))).isZero();

        // …et cette famille existe bien dans le seed : la ligne ci-dessus prouve
        // alors qu'aucune n'a ete requalifiee. (Le mode FULL_AUDIO lui-meme n'est
        // pose qu'a la publication d'un draft, jamais par une migration : on ne
        // peut donc pas le compter ici.)
        assertThat(compte("SELECT count(*) FROM questions q WHERE q.question_type = 'CO'"
                + " AND EXISTS (SELECT 1 FROM choices c WHERE c.question_id = q.id"
                + " AND length(trim(c.label)) <= 2)")).isGreaterThan(0);
    }

    /**
     * L'audio nomme chaque proposition a la lettre de son rang {@code display_order} :
     * c'est ce qui rend l'ordre {@code display_order} opposable, donc le melange
     * interdit. Sans cet invariant, ne pas melanger ne reparerait rien.
     */
    @Test
    void lAudioNommeChaquePropositionALaLettreDeSonRangDisplayOrder() {
        List<Map<String, Object>> ecarts = jdbc.queryForList("""
                WITH rangs AS (
                    SELECT q.id,
                           regexp_replace(m.transcript, '\\s+', ' ', 'g') AS tr,
                           c.label,
                           (row_number() OVER (PARTITION BY q.id ORDER BY c.display_order))::int AS rang
                    FROM questions q
                    JOIN medias m ON m.id = q.media_id
                    JOIN choices c ON c.question_id = q.id
                    WHERE q.audio_mode = ?
                )
                SELECT id, rang, label FROM rangs
                WHERE position(chr(64 + rang) || '. ' || rtrim(label, '.') IN tr) = 0
                """, MODE);

        assertThat(ecarts).isEmpty();
    }

    /**
     * Les explications sont redigees SUR {@code display_order} (« Seule B … »).
     * Le contenu etait juste, c'est l'affichage qui decalait : une fois le
     * melange retire, l'explication est servie intacte et reste vraie.
     */
    @Test
    void lExplicationCiteLaLettreDeLaBonneReponseDansLOrdreDisplayOrder() {
        List<Map<String, Object>> ecarts = jdbc.queryForList("""
                SELECT q.id
                FROM questions q
                JOIN choices c ON c.question_id = q.id AND c.is_correct
                WHERE q.audio_mode = ?
                  AND q.explanation NOT LIKE '%Seule ' || chr(64 + (
                          SELECT count(*)::int FROM choices c2
                          WHERE c2.question_id = q.id AND c2.display_order <= c.display_order)) || ' %'
                """, MODE);

        assertThat(ecarts).isEmpty();
    }

    @Test
    void laContrainteRefuseToujoursUnModeInconnu() {
        assertThatThrownBy(() -> jdbc.update("""
                UPDATE questions SET audio_mode = 'SPOKEN_SOMETHING'
                WHERE id = (SELECT id FROM questions WHERE audio_mode = ? LIMIT 1)
                """, MODE))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private int compte(String sql) {
        Integer n = jdbc.queryForObject(sql, Integer.class);
        return n == null ? 0 : n;
    }
}
