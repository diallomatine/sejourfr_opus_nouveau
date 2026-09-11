package com.sejourfr.app.service;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Deux campagnes de pre-tagging coexistent sur une meme question (V290).
 *
 * <p>🛑 <b>Ce que ces tests protegent.</b> L'unicite portait sur
 * {@code (question_id, notion_id)} : une campagne ecrasait donc la proposition
 * identique de la precedente, et « aucune notion » — qui n'a pas de notion —
 * entrait en collision avec elle-meme. Mesure du 2026-09-11 : trois lignes
 * d'une campagne close ont disparu en silence, dont une ecrasee par une simple
 * ALTERNATIVE de la campagne suivante. La campagne mesurait 791 questions puis
 * 788, sans que rien ne le dise.
 *
 * <p>🛑 <b>Et ce que la coexistence oblige a faire.</b> Une question portant
 * deux campagnes, l'ecran n'en montre qu'une et le verdict humain ne qualifie
 * que celle-la. La « campagne courante » est la plus recente parmi les
 * applicables. Sans ce second filtre, valider la nouvelle proposition
 * tamponnait l'ancienne — ce qui faisait lire, sur une campagne terminee, des
 * verdicts que personne n'avait rendus.
 *
 * <p>⚠️ {@code created_at} est pose explicitement : dans une transaction
 * unique, {@code now()} est constant en PostgreSQL, et deux campagnes inserees
 * a la suite se retrouveraient a la meme date. En production elles arrivent
 * dans des transactions distinctes.
 */
class SuggestionParCampagneIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private CivicNotionService service;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("Deux campagnes gardent la MEME notion sur la meme question")
    void memeNotionDansDeuxCampagnes() {
        Question question = data.question();
        entityManager.flush();
        UUID notion = notion("pv_laicite");

        inserer(question.getId(), notion, UUID.randomUUID(), 0.70, il_y_a(2));
        inserer(question.getId(), notion, UUID.randomUUID(), 0.95, il_y_a(1));

        assertThat(lignes(question.getId())).isEqualTo(2);
    }

    @Test
    @DisplayName("🛑 « Aucune notion » dans deux campagnes : deux lignes, pas un ecrasement")
    void aucuneNotionDansDeuxCampagnes() {
        Question question = data.question();
        entityManager.flush();

        inserer(question.getId(), null, UUID.randomUUID(), 0.60, il_y_a(2));
        inserer(question.getId(), null, UUID.randomUUID(), 0.85, il_y_a(1));

        // C'est LE cas que l'ancienne cle ne pouvait pas distinguer : sans
        // notion, les deux lignes avaient la meme cle.
        assertThat(lignes(question.getId())).isEqualTo(2);
    }

    @Test
    @DisplayName("🛑 Valider la campagne courante ne touche JAMAIS la precedente")
    void validerLaSecondeNeTouchePasLaPremiere() {
        Question question = data.question();
        User relecteur = data.admin();
        entityManager.flush();
        UUID ancienne = UUID.randomUUID();
        UUID nouvelle = UUID.randomUUID();
        UUID notion = notion("pv_laicite");

        // Campagne close : « aucune notion ne convient ».
        inserer(question.getId(), null, ancienne, 0.80, il_y_a(2));
        // Campagne courante, meme theme : une notion est proposee.
        inserer(question.getId(), notion, nouvelle, 0.95, il_y_a(1));
        entityManager.flush();
        entityManager.clear();

        service.relire(question.getId(), "pv_laicite", null, relecteur.getId());

        assertThat(verdict(question.getId(), nouvelle)).isEqualTo("VALIDATED");
        // 🛑 La campagne close reste vierge : sa mesure ne se relit pas apres
        // coup, et surtout pas pour y lire un verdict qu'on n'a pas rendu.
        assertThat(verdict(question.getId(), ancienne)).isNull();
    }

    @Test
    @DisplayName("🛑 Deux campagnes dans le MEME theme : seule la plus recente est servie et jugee")
    void deuxCampagnesDansLeMemeTheme() {
        Question question = data.question();
        User relecteur = data.admin();
        entityManager.flush();
        UUID ancienne = UUID.randomUUID();
        UUID nouvelle = UUID.randomUUID();

        // Le filtre par THEME ne suffit pas ici : les deux campagnes ont ete
        // faites dans le meme theme. Seul le batch les separe.
        inserer(question.getId(), notion("pv_laicite"), ancienne, 0.99, il_y_a(2));
        inserer(question.getId(), notion("pv_symboles_devise"), nouvelle, 0.60, il_y_a(1));
        entityManager.flush();
        entityManager.clear();

        service.relire(question.getId(), "pv_symboles_devise", null, relecteur.getId());

        // VALIDATED et non CORRECTED : la reference est la proposition de la
        // campagne COURANTE (0,60), pas celle de l'ancienne, pourtant plus sure.
        assertThat(verdict(question.getId(), nouvelle)).isEqualTo("VALIDATED");
        assertThat(verdict(question.getId(), ancienne)).isNull();
    }

    @Test
    @DisplayName("Un changement de theme rend la campagne precedente inapplicable")
    void changementDeThemeEcarteLaCampagnePrecedente() {
        Theme origine = data.theme();
        Question question = data.question(origine);
        User relecteur = data.admin();
        entityManager.flush();
        UUID ancienne = UUID.randomUUID();
        inserer(question.getId(), null, ancienne, 0.90, il_y_a(2));

        Theme arrivee = data.theme();
        entityManager.flush();
        jdbc.update("UPDATE questions SET theme_id = ? WHERE id = ?",
                arrivee.getId(), question.getId());

        UUID nouvelle = UUID.randomUUID();
        inserer(question.getId(), notion("pv_laicite"), nouvelle, 0.55, il_y_a(1));
        entityManager.flush();
        entityManager.clear();

        service.relire(question.getId(), "pv_laicite", null, relecteur.getId());

        assertThat(verdict(question.getId(), nouvelle)).isEqualTo("VALIDATED");
        assertThat(verdict(question.getId(), ancienne)).isNull();
    }

    @Test
    @DisplayName("🛑 Repersister le MEME lot est idempotent ; un lot NEUF ajoute une campagne")
    void repersisterLeMemeLotNeDuplique() {
        Question question = data.question();
        entityManager.flush();
        UUID notion = notion("pv_laicite");
        UUID lot = UUID.randomUUID();

        // Le cas reel : un lot rejoue apres une coupure, ou une reprise de
        // `./persister.sh` sur le meme fichier de reponse.
        upsert(question.getId(), notion, lot, 0.70);
        upsert(question.getId(), notion, lot, 0.90);
        upsert(question.getId(), null, lot, 0.40);
        upsert(question.getId(), null, lot, 0.55);

        // Une ligne par (question, lot, notion) — la notion nommee et
        // « aucune notion » cohabitent, mais aucune ne se duplique.
        assertThat(lignes(question.getId())).isEqualTo(2);
        assertThat(confiance(question.getId(), lot, notion)).isEqualTo(0.900);
        assertThat(confiance(question.getId(), lot, null)).isEqualTo(0.550);

        // 🛑 Un lot NEUF n'est pas un rejeu : il ouvre une campagne a part, et
        // c'est exactement ce que l'ancienne cle empechait.
        UUID autreLot = UUID.randomUUID();
        upsert(question.getId(), notion, autreLot, 0.30);
        upsert(question.getId(), null, autreLot, 0.20);

        assertThat(lignes(question.getId())).isEqualTo(4);
        // L'ancienne campagne garde ses valeurs : une reprise ne la relit pas.
        assertThat(confiance(question.getId(), lot, notion)).isEqualTo(0.900);
    }

    /**
     * L'ecriture exacte de {@code scripts/pre-tagging/persister.sh}.
     *
     * <p>🛑 Recopiee a l'identique, cle de conflit comprise : c'est CETTE
     * requete qui a fait disparaitre trois lignes d'une campagne close le
     * 2026-09-11, et un test qui en ecrirait une version simplifiee ne
     * protegerait de rien.
     */
    private void upsert(UUID questionId, UUID notionId, UUID batchId, double confiance) {
        jdbc.update("""
                INSERT INTO question_notion_suggestions
                    (question_id, notion_id, confidence, model, prompt_version, rationale, batch_id)
                VALUES (?, ?, ?, 'claude-sonnet-5', 'PROMPT_TAG_NOTION_v4', 'Parce que.', ?)
                ON CONFLICT (question_id, batch_id, notion_id) DO UPDATE
                    SET confidence = EXCLUDED.confidence,
                        rationale  = EXCLUDED.rationale,
                        created_at = now()
                WHERE question_notion_suggestions.review_verdict IS NULL
                """, questionId, notionId, confiance, batchId);
    }

    private double confiance(UUID questionId, UUID batchId, UUID notionId) {
        return jdbc.queryForObject("""
                SELECT confidence FROM question_notion_suggestions
                 WHERE question_id = ? AND batch_id = ?
                   AND notion_id IS NOT DISTINCT FROM ?
                """, Double.class, questionId, batchId, notionId);
    }

    private Instant il_y_a(int heures) {
        return Instant.now().minus(heures, ChronoUnit.HOURS);
    }

    private UUID notion(String code) {
        return jdbc.queryForObject(
                "SELECT id FROM civic_notions WHERE code = ?", UUID.class, code);
    }

    private void inserer(UUID questionId, UUID notionId, UUID batchId,
                         double confiance, Instant quand) {
        jdbc.update("""
                INSERT INTO question_notion_suggestions
                    (question_id, notion_id, confidence, prompt_version, batch_id, created_at)
                VALUES (?, ?, ?, 'PROMPT_TAG_NOTION_v4', ?, ?)
                """, questionId, notionId, confiance, batchId, java.sql.Timestamp.from(quand));
    }

    private int lignes(UUID questionId) {
        return jdbc.queryForObject(
                "SELECT count(*) FROM question_notion_suggestions WHERE question_id = ?",
                Integer.class, questionId);
    }

    private String verdict(UUID questionId, UUID batchId) {
        return jdbc.queryForObject("""
                SELECT review_verdict FROM question_notion_suggestions
                 WHERE question_id = ? AND batch_id = ?
                """, String.class, questionId, batchId);
    }
}
