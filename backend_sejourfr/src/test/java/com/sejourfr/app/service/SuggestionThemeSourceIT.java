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
import org.springframework.jdbc.UncategorizedSQLException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Une suggestion memorise le theme de la question AU MOMENT ou elle a ete
 * produite (V061).
 *
 * <p>🛑 <b>Pourquoi ce champ existe.</b> Une suggestion n'a de sens que dans le
 * theme ou elle a ete faite : le modele ne recoit que les notions de ce
 * theme-la. Quand une question change de theme, sa suggestion devient caduque.
 * Pour une suggestion qui NOMME une notion, on pouvait le deduire — la notion
 * porte son theme. Pour « aucune notion ne convient », il n'y avait aucune
 * trace, et l'applicabilite ne se reconstituait qu'en lisant le NOM DES
 * FICHIERS d'une campagne. Mesure du 2026-09-11 : 34 questions ressortaient
 * eligibles a une reproposition la ou 20 l'etaient reellement.
 *
 * <p>🛑 <b>Pourquoi un trigger et pas une consigne.</b> Trois ecrivains
 * touchent cette table. Demander a chacun de penser au theme, c'est se
 * garantir qu'un jour l'un d'eux l'oubliera, et le trou resterait invisible
 * jusqu'au deplacement suivant. Ces tests gelent le fait que la base le
 * remplit seule, y compris contre une valeur fournie par l'appelant.
 */
class SuggestionThemeSourceIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private CivicNotionService service;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("Une suggestion « aucune notion » retient quand meme son theme d'origine")
    void aucuneNotionPorteSonTheme() {
        Theme theme = data.theme();
        Question question = data.question(theme);
        entityManager.flush();

        inserer(question.getId(), null, UUID.randomUUID());

        // 🛑 C'est LE cas que rien d'autre ne permettait de deduire : pas de
        // notion, donc pas de theme a en tirer.
        assertThat(themeSource(question.getId())).isEqualTo(theme.getCode());
    }

    @Test
    @DisplayName("🛑 Une valeur fournie par l'appelant est IGNOREE : le theme d'origine n'est pas une opinion")
    void valeurDeLAppelantIgnoree() {
        Question question = data.question();
        entityManager.flush();

        jdbc.update("""
                INSERT INTO question_notion_suggestions
                    (question_id, notion_id, confidence, prompt_version, source_theme_code)
                VALUES (?, NULL, 0.5, 'PROMPT_TAG_NOTION_v4', 'CIV_MENSONGE')
                """, question.getId());

        assertThat(themeSource(question.getId()))
                .isEqualTo(question.getTheme().getCode())
                .isNotEqualTo("CIV_MENSONGE");
    }

    @Test
    @DisplayName("Une question deplacee rend sa suggestion PERIMEE, sans que rien ne soit reecrit")
    void deplacementRendLaSuggestionPerimee() {
        Theme origine = data.theme();
        Question question = data.question(origine);
        entityManager.flush();
        inserer(question.getId(), null, UUID.randomUUID());

        Theme arrivee = data.theme();
        // 🛑 Le theme d'arrivee doit exister EN BASE avant que le JDBC ne le
        // reference : JPA ne l'a pas encore vide, et la cle etrangere tombe.
        // Melanger l'EntityManager et le JdbcTemplate demande ce flush.
        entityManager.flush();
        jdbc.update("UPDATE questions SET theme_id = ? WHERE id = ?",
                arrivee.getId(), question.getId());

        // La suggestion garde son theme d'origine : c'est ce qui la dit perimee.
        assertThat(themeSource(question.getId())).isEqualTo(origine.getCode());
        assertThat(themeSource(question.getId())).isNotEqualTo(arrivee.getCode());
    }

    @Test
    @DisplayName("🛑 Une REPROPOSITION recalcule le theme, un VERDICT ne le touche pas")
    void seuleUneRepropositionRecalcule() {
        Theme origine = data.theme();
        Question question = data.question(origine);
        entityManager.flush();
        inserer(question.getId(), null, UUID.randomUUID());

        // Un verdict humain n'est pas une nouvelle proposition : il ne doit pas
        // reecrire l'histoire de la mesure. ⚠️ Il est rendu AVANT le
        // deplacement, parce que depuis V292 la base refuse tout verdict sur
        // une suggestion devenue inapplicable — l'ancien montage de ce test,
        // qui jugeait apres coup, decrit une situation desormais impossible.
        jdbc.update("""
                UPDATE question_notion_suggestions
                   SET review_verdict = 'SKIPPED', reviewed_at = now()
                 WHERE question_id = ?
                """, question.getId());
        assertThat(themeSource(question.getId())).isEqualTo(origine.getCode());

        Theme arrivee = data.theme();
        entityManager.flush();
        jdbc.update("UPDATE questions SET theme_id = ? WHERE id = ?",
                arrivee.getId(), question.getId());

        // 🛑 Une reproposition, si : le script de persistance ecrit en
        // ON CONFLICT DO UPDATE, et sans ce recalcul la ligne garderait un
        // theme perime alors qu'elle porte une proposition toute neuve.
        jdbc.update("""
                UPDATE question_notion_suggestions
                   SET batch_id = ?, confidence = 0.9
                 WHERE question_id = ?
                """, UUID.randomUUID(), question.getId());
        assertThat(themeSource(question.getId())).isEqualTo(arrivee.getCode());
    }

    @Test
    @DisplayName("🛑 La BASE refuse un verdict sur une suggestion perimee, quel que soit l'appelant")
    void laBaseRefuseUnVerdictPerime() {
        Theme origine = data.theme();
        Question question = data.question(origine);
        entityManager.flush();
        inserer(question.getId(), null, UUID.randomUUID());

        Theme arrivee = data.theme();
        entityManager.flush();
        jdbc.update("UPDATE questions SET theme_id = ? WHERE id = ?",
                arrivee.getId(), question.getId());

        // 🛑 Ecriture DIRECTE, sans passer par le service : c'est tout l'objet
        // du garde-fou. Le code applicatif a deja ete corrige deux fois, et le
        // defaut est revenu par un exemplaire du serveur demarre avant le
        // correctif. Une regle qui ne vit que dans le code est vraie tant que
        // personne ne fait tourner une version d'avant.
        assertThatThrownBy(() -> jdbc.update("""
                UPDATE question_notion_suggestions
                   SET review_verdict = 'VALIDATED', reviewed_at = now()
                 WHERE question_id = ?
                """, question.getId()))
                // Un RAISE de PL/pgSQL remonte en SQLSTATE P0001, que Spring
                // ne sait pas classer : c'est un UncategorizedSQLException, pas
                // une violation d'integrite. Le message, lui, est explicite.
                .isInstanceOf(UncategorizedSQLException.class)
                .hasMessageContaining("Verdict VALIDATED refuse");

        // ⚠️ Pas de verification en base apres coup : l'exception du trigger
        // ABORTE la transaction du test, et toute requete suivante echoue en
        // 25P02. Le refus EST la garantie — l'UPDATE n'a jamais ete applique.
    }

    private void inserer(UUID questionId, UUID notionId, UUID batchId) {
        jdbc.update("""
                INSERT INTO question_notion_suggestions
                    (question_id, notion_id, confidence, prompt_version, batch_id)
                VALUES (?, ?, 0.5, 'PROMPT_TAG_NOTION_v4', ?)
                """, questionId, notionId, batchId);
    }

    private String themeSource(UUID questionId) {
        return jdbc.queryForObject(
                "SELECT source_theme_code FROM question_notion_suggestions WHERE question_id = ?",
                String.class, questionId);
    }
}
