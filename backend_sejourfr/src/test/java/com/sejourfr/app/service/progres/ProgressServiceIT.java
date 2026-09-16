package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
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
 * L'ÉCRAN PROGRÈS (T28, {@code 30_} §7), contre la vraie base.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>🛑 <b>sans diagnostic, on n'invente ni palier ni courbe</b> — les deux
 *       moitiés disent {@code disponible: false}, et l'écran ouvre la porte qui
 *       débloque au lieu d'afficher des blocs vides ;</li>
 *   <li>🛑 <b>les 4 épreuves sont TOUJOURS servies</b>, évaluées ou non. Une
 *       épreuve absente de la liste disparaîtrait de l'écran au lieu de se dire
 *       « non évaluée » ;</li>
 *   <li>🛑 <b>{@code INCONNUE} n'est pas {@code STABLE}</b> : une épreuve non
 *       comparable n'a ni progressé ni tenu. Les confondre déguiserait
 *       l'incident V040/V041/V042 en bonne nouvelle ;</li>
 *   <li>🛑 <b>les compteurs de compétences sont servis MÊME verrouillés</b> :
 *       c'est le détail qui est premium, pas le fait d'avoir progressé ;</li>
 *   <li>l'activité est <b>transverse</b> et servie même sans aucun diagnostic —
 *       travailler est un fait, pas une conséquence d'une mesure.</li>
 * </ul>
 */
class ProgressServiceIT extends AbstractIntegrationTest {

    @Autowired private ProgressService service;
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
    @DisplayName("🛑 Sans aucun diagnostic, on n'invente ni palier ni courbe")
    void sansDiagnostic() {
        User user = testData.user();

        ProgressDto progres = service.progres(user.getId());

        assertThat(progres.tcf().disponible()).isFalse();
        assertThat(progres.tcf().niveauActuel()).isNull();
        assertThat(progres.tcf().historique()).isEmpty();
        assertThat(progres.civique().disponible()).isFalse();
        assertThat(progres.civique().historique()).isEmpty();

        // 🛑 L'activité, elle, est servie : travailler est un fait, pas une
        // conséquence d'une mesure. Et la frise existe même vide.
        assertThat(progres.activite()).isNotNull();
        assertThat(progres.activite().semaines()).hasSize(4);
        assertThat(progres.activite().fenetreJours()).isEqualTo(28);
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
        assertThat(tcf.disponible()).isFalse();
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
        // CO/CE → examen blanc de module sur le slot OFFERT ; EE/EO → le
        // diagnostic, qui n'a pas encore été passé.
        Map<EpreuveType, PlanDomainAssessmentDto> mesures = tcf.epreuves().stream()
                .collect(java.util.stream.Collectors.toMap(
                        ProgressDto.Epreuve::epreuve, ProgressDto.Epreuve::evaluation));
        assertThat(mesures.get(EpreuveType.TCF_CO).kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        assertThat(mesures.get(EpreuveType.TCF_CO).slotNumber()).isEqualTo(1);
        assertThat(mesures.get(EpreuveType.TCF_CE).kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        assertThat(mesures.get(EpreuveType.TCF_EE).kind())
                .isEqualTo(PlanDomainAssessmentKind.DIAGNOSTIC);
        assertThat(mesures.get(EpreuveType.TCF_EO).kind())
                .isEqualTo(PlanDomainAssessmentKind.DIAGNOSTIC);
    }

    @Test
    @DisplayName("Le diagnostic civique clos alimente l'historique, comparable au seuil")
    void historiqueCivique() {
        User user = testData.user();
        CivicDiagnosticSession session = diagnosticCiviqueTermine(user);

        ProgressDto.Civique civique = service.progres(user.getId()).civique();

        assertThat(civique.disponible()).isTrue();
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

    @Test
    @DisplayName("🛑 Les compteurs civiques comptent TOUTES les cibles, pas les 3 priorités servies")
    void compteursCiviquesNonTronques() {
        User user = testData.user();
        diagnosticCiviqueTermine(user);

        ProgressDto.Civique civique = service.progres(user.getId()).civique();

        // Cinq thèmes civiques : le compteur ne doit pas s'arrêter au plafond
        // d'affichage de trois priorités.
        assertThat(civique.travaillees()).isGreaterThan(3);
        assertThat(civique.maitrisees()).isNotNegative();
        // Tout est faux : rien n'est tenu, et un thème n'est de toute façon
        // jamais annoncé maîtrisé (L10).
        assertThat(civique.maitrisees()).isZero();
        assertThat(civique.grainNotion()).isFalse();
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

    @Test
    @DisplayName("🛑 Un compte gratuit garde ses compteurs de compétences, il perd le DÉTAIL")
    void competencesVerrouilleesGardentLeursCompteurs() {
        User user = testData.user();

        ProgressDto.Competences competences = service.progres(user.getId()).tcf().competences();

        assertThat(competences.locked()).isTrue();
        assertThat(competences.dernieres()).isEmpty();
        // Les compteurs existent quoi qu'il arrive : cacher le nombre
        // reviendrait à cacher au candidat ce qu'il a lui-même produit.
        assertThat(competences.travaillees()).isNotNegative();
        assertThat(competences.maitrisees()).isNotNegative();
    }

    @Test
    @DisplayName("Un abonné TCF n'a plus de verrou sur le détail de ses compétences")
    void abonneVoitLeDetail() {
        User user = testData.user();
        testData.userSubscription(user, testData.plan());
        entityManager.flush();
        entityManager.clear();

        assertThat(service.progres(user.getId()).tcf().competences().locked()).isFalse();
    }
}
