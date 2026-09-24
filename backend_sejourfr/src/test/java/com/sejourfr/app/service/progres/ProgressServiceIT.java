package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * « Où vous en êtes » de l'ACCUEIL ({@code GET /api/me/progress}), contre la
 * vraie base. ⚠️ Les tests de l'activité, de la courbe des diagnostics et des
 * compteurs (compétences, civique) sont partis le 2026-09-24 avec l'ancien
 * écran « Votre progression », leur seul lecteur.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>🛑 <b>sans diagnostic, on n'invente rien</b> ;</li>
 *   <li>🛑 <b>les 4 épreuves sont TOUJOURS servies</b>, évaluées ou non. Une
 *       épreuve absente de la liste disparaîtrait de l'écran au lieu de se dire
 *       « non évaluée » ;</li>
 *   <li>🛑 <b>{@code INCONNUE} n'est pas {@code STABLE}</b> : une épreuve non
 *       comparable n'a ni progressé ni tenu. Les confondre déguiserait
 *       l'incident V040/V041/V042 en bonne nouvelle ;</li>
 * </ul>
 */
class ProgressServiceIT extends AbstractIntegrationTest {

    @Autowired private ProgressService service;
    @Autowired private TcfProfileService tcfProfileService;
    @Autowired private CivicDiagnosticService civicDiagnosticService;
    @Autowired private TestData testData;
    @Autowired private EntityManager entityManager;
    @Autowired private JdbcTemplate jdbc;

    private CivicDiagnosticSession diagnosticCiviqueTermine(User user) {
        CivicDiagnosticSession session = civicDiagnosticService.ouvrir(user.getId());
        entityManager.flush();
        List<UUID> aqs = jdbc.queryForList(
                "SELECT id FROM attempt_questions WHERE attempt_id = ? ORDER BY position",
                UUID.class, session.getAttempt().getId());
        for (UUID aq : aqs) {
            jdbc.update("""
                    INSERT INTO answers (id, attempt_question_id, user_id, selected_choice_ids,
                                         is_correct, answered_at)
                    SELECT gen_random_uuid(), ?, a.user_id, '[]'::jsonb, false, now()
                    FROM attempt_questions aq JOIN attempts a ON a.id = aq.attempt_id
                    WHERE aq.id = ?
                    """, aq, aq);
        }
        civicDiagnosticService.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();
        return session;
    }

    @Test
    @DisplayName("🛑 Sans aucun diagnostic, on n'invente rien")
    void sansDiagnostic() {
        User user = testData.user();

        ProgressDto progres = service.progres(user.getId());

        assertThat(progres.tcf().epreuves()).allSatisfy(e -> assertThat(e.niveau()).isNull());
        assertThat(progres.civique().historique()).isEmpty();
        assertThat(progres.civique().themes()).isEmpty();
    }

    /**
     * 🛑 <b>2026-09-16 — les 4 épreuves ne dépendent plus du diagnostic.</b>
     * Elles étaient servies <b>vides</b> tant qu'aucun diagnostic 4 épreuves
     * n'était clos, ce qui masquait la section « Où vous en êtes » de l'Accueil
     * en entier — y compris chez un candidat dont la CO était déjà mesurée par
     * un examen de module. Le palier vient du profil TCF, pas du diagnostic.
     */
    @Test
    @DisplayName("🛑 Les 4 épreuves TCF sont toujours servies, et INCONNUE n'est pas STABLE")
    void quatreEpreuvesToujoursServies() {
        User user = testData.user();

        ProgressDto.Tcf tcf = service.progres(user.getId()).tcf();

        // Aucun diagnostic clos, et pourtant les 4 cartes existent.
        assertThat(tcf.epreuves())
                .extracting(ProgressDto.Epreuve::epreuve)
                .containsExactly(
                        EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                        EpreuveType.TCF_EE, EpreuveType.TCF_EO);
        // 🛑 Rien n'a été mesuré : `null` = inconnu, jamais A1. Et pas de
        // palier INITIAL faute de diagnostic, donc INCONNUE, jamais STABLE.
        assertThat(tcf.epreuves()).allSatisfy(e -> {
            assertThat(e.niveau()).isNull();
            assertThat(e.niveauInitial()).isNull();
            assertThat(e.evolution()).isEqualTo(NiveauEvolution.INCONNUE);
            // 🛑 Et chacune porte DE QUOI se faire mesurer : c'est ce que le
            // CTA « Faire un exercice » de l'Accueil lance, par le lanceur du
            // Plan. Aucune carte ne reste sans issue.
            assertThat(e.evaluation()).isNotNull();
            assertThat(e.evaluation().epreuve()).isEqualTo(e.epreuve());
        });
        // Les quatre épreuves → un examen blanc, sur le slot OFFERT : examen de
        // module en CO/CE, examen de production (3 tâches) en EE/EO.
        Map<EpreuveType, PlanDomainAssessmentDto> mesures = tcf.epreuves().stream()
                .collect(java.util.stream.Collectors.toMap(
                        ProgressDto.Epreuve::epreuve, ProgressDto.Epreuve::evaluation));
        assertThat(mesures.get(EpreuveType.TCF_CO).kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        assertThat(mesures.get(EpreuveType.TCF_CO).slotNumber()).isEqualTo(1);
        assertThat(mesures.get(EpreuveType.TCF_CE).kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        assertThat(mesures.get(EpreuveType.TCF_EE).kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(mesures.get(EpreuveType.TCF_EE).slotNumber()).isEqualTo(1);
        assertThat(mesures.get(EpreuveType.TCF_EO).kind())
                .isEqualTo(PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM);
        assertThat(mesures.get(EpreuveType.TCF_EO).slotNumber()).isEqualTo(1);
    }

    /**
     * 🛑 <b>LE test de l'arbitrage du 2026-09-16</b>, et le plus important de
     * cet écran : le <b>Plan</b> et l'<b>Accueil</b> peuvent dire deux choses
     * différentes de la même EO, et c'est voulu.
     *
     * <p>Un entraînement EO libre corrigé B1 par l'IA est une <b>observation</b>
     * : le Plan la voit ({@code TcfProfileService.levelProfile}), il en tire des
     * priorités et des compétences. Elle n'est pas pour autant une
     * <b>mesure d'épreuve</b> : l'Accueil affiche « à évaluer » et propose de
     * quoi se faire mesurer, parce qu'aucune épreuve d'EO n'a jamais été passée.
     *
     * <p>Le premier jet de cette règle avait restreint {@code levelProfile}
     * lui-même : le Plan perdait alors l'observation. C'est ce que la première
     * assertion empêche de revenir.
     */
    @Test
    @DisplayName("🛑 Un entrainement EO renseigne le PLAN, pas le niveau affiche sur l'ACCUEIL")
    void lEntrainementRenseigneLePlanPasLAccueil() {
        User user = testData.user();
        // Entrainement libre : l'attempt n'a ni slot ni parent, il n'est pas
        // termine — rien de ce qui fait une epreuve. Mais l'IA a bien note.
        ProductionSubmission soumission = testData.productionSubmission(
                testData.attempt(user), testData.productionTask(EpreuveType.TCF_EO), user);
        testData.aiEvaluation(soumission).setNiveauCecrl(NiveauCecrl.B1);
        entityManager.flush();
        entityManager.clear();

        // 🛑 Le PLAN voit B1 : c'est la lecture large, restauree le 2026-09-16
        // apres une passe qui l'avait restreinte par erreur.
        assertThat(tcfProfileService.levelProfile(user.getId()).eo())
                .isEqualTo(NiveauCecrl.B1);

        ProgressDto.Epreuve eo = epreuve(user, EpreuveType.TCF_EO);
        // ...et l'ACCUEIL n'affiche rien. `null` = inconnu, jamais A1.
        assertThat(eo.niveau()).isNull();
        // Corollaire : la carte porte DE QUOI se faire mesurer, au lieu de
        // proposer « Voir mes resultats » d'une epreuve jamais passee.
        assertThat(eo.evaluation()).isNotNull();

        // Une EPREUVE COMPLETE, elle, s'affiche — meme plus basse que
        // l'entrainement : c'est une mesure, l'autre n'en est pas une.
        testData.epreuveProductionPassee(user, EpreuveType.TCF_EO, NiveauCecrl.A2);
        entityManager.flush();
        entityManager.clear();

        assertThat(epreuve(user, EpreuveType.TCF_EO).niveau()).isEqualTo(NiveauCecrl.A2);
        assertThat(tcfProfileService.levelProfile(user.getId()).eo())
                .as("le PLAN garde son maximum, entrainement compris")
                .isEqualTo(NiveauCecrl.B1);
    }

    private ProgressDto.Epreuve epreuve(User user, EpreuveType epreuve) {
        return service.progres(user.getId()).tcf().epreuves().stream()
                .filter(e -> e.epreuve() == epreuve)
                .findFirst()
                .orElseThrow();
    }

    @Test
    @DisplayName("Le diagnostic civique clos alimente l'historique, comparable au seuil")
    void historiqueCivique() {
        User user = testData.user();
        CivicDiagnosticSession session = diagnosticCiviqueTermine(user);

        ProgressDto.Civique civique = service.progres(user.getId()).civique();

        assertThat(civique.historique()).hasSize(1);
        ProgressDto.Score score = civique.historique().getFirst();
        assertThat(score.sessionId()).isEqualTo(session.getId());
        assertThat(score.bonnes()).isZero();
        assertThat(score.posees()).isPositive();
        // 🛑 Le seuil et le format sont SERVIS : l'écran les dit sans les
        // connaître, et ne promet jamais la réussite.
        assertThat(score.seuil()).isEqualTo(32);
        assertThat(score.format()).isEqualTo(40);
    }

    /**
     * 🛑 Le détail par thème vient du <b>moteur du plan civique</b>, pas d'un
     * second calcul de maîtrise : les cinq thèmes sont servis, toujours, avec
     * leur état brut. Un thème sans état serait pire qu'un thème absent —
     * l'écran ne saurait pas quoi en dire.
     */
    @Test
    @DisplayName("Le détail civique par thème est servi, les 5 thèmes avec leur état brut")
    void detailCiviqueParTheme() {
        User user = testData.user();
        diagnosticCiviqueTermine(user);

        ProgressDto.Civique civique = service.progres(user.getId()).civique();

        assertThat(civique.themes()).hasSize(5);
        assertThat(civique.themes()).allSatisfy(ligne -> {
            assertThat(ligne.themeId()).isNotNull();
            assertThat(ligne.code()).isNotBlank();
            assertThat(ligne.label()).isNotBlank();
            // 🛑 L'état est SERVI, jamais dérivé d'un nombre côté front.
            assertThat(ligne.etat()).isNotNull();
        });
        // Toutes les réponses sont fausses et les cinq thèmes ont été interrogés
        // par le diagnostic : aucun n'est SOLIDE, aucun n'est NON_EVALUE.
        assertThat(civique.themes())
                .extracting(com.sejourfr.app.dto.CivicPlanDto.ThemeLigne::etat)
                .doesNotContain(CivicThemeState.SOLIDE, CivicThemeState.NON_EVALUE);
    }

    /** Sans diagnostic civique clos, on n'invente pas même une liste de thèmes. */
    @Test
    @DisplayName("Sans diagnostic civique, le détail par thème est vide")
    void detailCiviqueVideSansDiagnostic() {
        User user = testData.user();

        assertThat(service.progres(user.getId()).civique().themes()).isEmpty();
    }
}
