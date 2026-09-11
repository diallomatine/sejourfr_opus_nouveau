package com.sejourfr.app.service;

import com.sejourfr.app.dto.CivicNotionDto;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * LE RÉFÉRENTIEL DE NOTIONS CIVIQUES ET SON TAGGING (L8), contre la vraie base.
 *
 * <p>Ce que ce test verrouille :
 * <ul>
 *   <li>les notions du référentiel de travail sont bien seedées, réparties
 *       sur les cinq thèmes ;</li>
 *   <li>🛑 une question non taguée est <b>en attente</b>, pas hors programme —
 *       et le tag s'efface, parce que se tromper doit rester rattrapable ;</li>
 *   <li>🛑 la couverture est ventilée <b>par mention</b> : c'est la seule
 *       façon de voir qu'une notion pleine en NAT est vide en CSP ;</li>
 *   <li>🛑 une notion fusionnée ne se pose plus.</li>
 * </ul>
 */
class CivicNotionServiceIT extends AbstractIntegrationTest {

    @Autowired private CivicNotionService service;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("Les 41 notions du référentiel de travail sont seedées sur les 5 thèmes")
    void referentielSeede() {
        var referentiel = service.referentiel();

        // 40 notions de travail (V051) + `hg_fetes_jours_feries`, ouverte par
        // V055 : le référentiel n'est PAS figé, il s'ajuste à la porte de revue
        // quand le tagging montre un trou. Ce compte suit donc les migrations.
        assertThat(referentiel).hasSize(41);
        assertThat(referentiel).extracting(CivicNotionDto::themeCode).containsOnly(
                "CIV_PRINCIPES", "CIV_INSTITUTIONS", "CIV_DROITS_DEVOIRS",
                "CIV_HISTOIRE_GEO", "CIV_SOCIETE");
        // 🛑 Aucune n'est fusionnée au départ : les quatre couples « à
        // surveiller » de `50_` §6.1.1 restent séparés tant que le tagging n'a
        // pas parlé.
        assertThat(referentiel).allSatisfy(n -> {
            assertThat(n.active()).isTrue();
            assertThat(n.mergedIntoCode()).isNull();
        });
        assertThat(referentiel).extracting(CivicNotionDto::code)
                .contains("pv_laicite", "vs_laicite_quotidien",
                        "dd_logement", "vs_logement_pratique",
                        "hg_fetes_jours_feries");
    }

    @Test
    @DisplayName("🛑 Une question non taguée attend : couverture nulle, jamais « sans notion »")
    void questionNonTagueeAttend() {
        Question question = data.question();
        entityManager.flush();

        assertThat(notionDe(question.getId())).isNull();
        // Aucune notion ne la compte : elle n'est rattachée nulle part, et ce
        // n'est pas un verdict sur elle.
        assertThat(service.referentiel())
                .allSatisfy(n -> assertThat(n.questionsTaguees()).isZero());
    }

    @Test
    @DisplayName("Le tag se pose, se lit par mention, et s'efface")
    void leTagSePoseSeLitEtSEfface() {
        Question question = data.question();
        entityManager.flush();
        entityManager.clear();

        service.taguer(question.getId(), "pv_laicite");
        entityManager.clear();

        CivicNotionDto laicite = notion("pv_laicite");
        assertThat(laicite.questionsTaguees()).isEqualTo(1);
        // 🛑 Ventilée par mention : c'est ce qui permet de voir qu'une notion
        // pleine pour une démarche est vide pour une autre.
        assertThat(laicite.parMention()).singleElement()
                .satisfies(m -> assertThat(m.questions()).isEqualTo(1));

        // Se tromper doit rester rattrapable sans passer par la base.
        service.taguer(question.getId(), null);
        entityManager.clear();
        assertThat(notion("pv_laicite").questionsTaguees()).isZero();
    }

    @Test
    @DisplayName("Une notion inconnue est refusée en nommant la raison")
    void notionInconnueRefusee() {
        Question question = data.question();
        entityManager.flush();

        assertThatThrownBy(() -> service.taguer(question.getId(), "pv_inexistante"))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining("pv_inexistante");
    }

    @Test
    @DisplayName("🛑 Une notion FUSIONNÉE ne se pose plus : ce serait du travail à défaire")
    void notionFusionneeNeSePosePlus() {
        Question question = data.question();
        entityManager.flush();
        // Fusion telle que la porte de revue §6.1.3 la produirait : la notion
        // est désactivée et pointe vers celle qui la reprend. Elle n'est JAMAIS
        // supprimée — les questions déjà taguées gardent leur lien.
        jdbc.update("""
                UPDATE civic_notions
                SET is_active = false,
                    merged_into_id = (SELECT id FROM civic_notions WHERE code = 'pv_laicite')
                WHERE code = 'vs_laicite_quotidien'
                """);
        entityManager.clear();

        assertThatThrownBy(() -> service.taguer(question.getId(), "vs_laicite_quotidien"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("fusionnée");

        assertThat(notion("vs_laicite_quotidien").mergedIntoCode()).isEqualTo("pv_laicite");
    }

    @Test
    @DisplayName("La file de tagging rend ce qu'il reste, et le compte diminue quand on tague")
    void fileDeTagging() {
        var avant = service.fileDeTagging(null, false, false, 25, 0);

        // Le catalogue civique seedé n'est pas tagué : c'est exactement le
        // chantier que cet outil sert à mener.
        assertThat(avant.resteATaguer()).isPositive();
        assertThat(avant.questions()).isNotEmpty();
        // 🛑 Aucune suggestion : la table est créée VIDE et rien ne la remplit
        // sans une décision du propriétaire. Une file sans suggestion est
        // l'état NORMAL, pas une panne.
        assertThat(avant.questions()).allSatisfy(q -> {
            assertThat(q.notionCode()).isNull();
            assertThat(q.suggestions()).isEmpty();
        });

        UUID premiere = avant.questions().getFirst().questionId();
        service.taguer(premiere, "pv_symboles");
        entityManager.clear();

        var apres = service.fileDeTagging(null, false, false, 25, 0);
        assertThat(apres.resteATaguer()).isEqualTo(avant.resteATaguer() - 1);
        // Taguée, elle sort de la file de travail et entre dans l'autre.
        assertThat(apres.questions())
                .noneSatisfy(q -> assertThat(q.questionId()).isEqualTo(premiere));
        assertThat(service.fileDeTagging(null, true, false, 25, 0).questions())
                .anySatisfy(q -> {
                    assertThat(q.questionId()).isEqualTo(premiere);
                    assertThat(q.notionCode()).isEqualTo("pv_symboles");
                });
    }

    @Test
    @DisplayName("Le filtre par thème sert l'ordre de tagging recommandé (§6.1.2)")
    void filtreParTheme() {
        var file = service.fileDeTagging("CIV_HISTOIRE_GEO", false, false, 25, 0);

        assertThat(file.questions()).isNotEmpty();
        assertThat(file.questions())
                .allSatisfy(q -> assertThat(q.themeCode()).isEqualTo("CIV_HISTOIRE_GEO"));
    }

    private CivicNotionDto notion(String code) {
        return service.referentiel().stream()
                .filter(n -> n.code().equals(code))
                .findFirst()
                .orElseThrow();
    }

    private String notionDe(UUID questionId) {
        return jdbc.queryForObject(
                """
                SELECT n.code FROM questions q
                         LEFT JOIN civic_notions n ON n.id = q.civic_notion_id
                WHERE q.id = ?
                """, String.class, questionId);
    }
}
