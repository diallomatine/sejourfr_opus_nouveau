package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.dto.TcfDiagnosticDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Le parcours du diagnostic TCF, contre la vraie base.
 *
 * <p>Ce qui est verrouille ici : l'idempotence de l'ouverture, le verrou
 * freemium, et surtout <b>l'etancheite avec les examens blancs</b> — la
 * regression qui coute le plus cher si elle passe.
 */
class TcfDiagnosticServiceIT extends AbstractIntegrationTest {

    @Autowired
    private TestData testData;
    @Autowired
    private TcfDiagnosticService service;
    @Autowired
    private TcfDiagnosticViewService viewService;
    @Autowired
    private AttemptManager attemptManager;
    @Autowired
    private EntityManager entityManager;
    @Autowired
    private TcfDiagnosticSectionStarter sectionStarter;

    @Test
    @DisplayName("Ouvrir crée un parent et ses sections, toutes « à faire »")
    void ouvrirCreeLesSections() {
        User user = testData.user();

        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        assertThat(session.getId()).isNotNull();
        assertThat(session.getParentAttempt().getEpreuve()).isEqualTo(EpreuveType.TCF_COMPLET);
        // 🛑 Pas de slot : un diagnostic n'entre pas dans la grille des 20
        // examens blancs.
        assertThat(session.getParentAttempt().getSlotNumber()).isNull();

        TcfDiagnosticDto vue = viewService.vue(session);
        assertThat(vue.sections()).hasSize(4);
        assertThat(vue.sections()).allSatisfy(s ->
                assertThat(s.etat()).isEqualTo(TcfDiagnosticSectionState.A_FAIRE));
        assertThat(vue.sections()).extracting(s -> s.epreuve())
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                        EpreuveType.TCF_EE, EpreuveType.TCF_EO);
    }

    @Test
    @DisplayName("🛑 Les deux appuis sur « Commencer » ne créent qu'un diagnostic")
    void ouvertureIdempotente() {
        User user = testData.user();

        TcfDiagnosticSession premier = service.ouvrir(user.getId());
        TcfDiagnosticSession second = service.ouvrir(user.getId());
        entityManager.flush();

        assertThat(second.getId()).isEqualTo(premier.getId());
    }

    /**
     * 🛑 LE test d'etancheite. Le diagnostic partage le parent
     * {@code TCF_COMPLET} avec l'examen blanc : sans le discriminant
     * {@code tcf_diagnostic_id}, il occuperait un slot de la grille des 20
     * examens et fausserait « examens blancs passés ».
     */
    @Test
    @DisplayName("🛑 Un diagnostic ne remonte JAMAIS dans les examens blancs complets")
    void etancheAvecLesExamensBlancs() {
        User user = testData.user();
        service.ouvrir(user.getId());
        entityManager.flush();
        entityManager.clear();

        List<Attempt> examensBlancs = attemptManager.findByUserAndEpreuve(
                user.getId(), EpreuveType.TCF_COMPLET, 50);

        assertThat(examensBlancs)
                .as("le parent du diagnostic doit être invisible dans la grille des examens")
                .isEmpty();
    }

    @Test
    @DisplayName("🛑 Un diagnostic n'est pas compté comme un examen blanc passé")
    void nonCompteDansLesExamensPasses() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        service.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();

        long examens = attemptManager.countFinishedMockExams(user.getId());

        assertThat(examens).isZero();
    }

    @Test
    @DisplayName("Le second diagnostic est refusé à un compte gratuit, en nommant la raison")
    void secondDiagnosticRefuseEnGratuit() {
        User user = testData.user();
        TcfDiagnosticSession premier = service.ouvrir(user.getId());
        service.cloturer(user.getId(), premier.getId());
        entityManager.flush();

        assertThatThrownBy(() -> service.ouvrir(user.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("déjà été réalisé");
    }

    @Test
    @DisplayName("Lancer une section pose son chrono, et le relancer ne le remet pas à zéro")
    void lancerSectionEstIdempotent() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        Attempt premier = attemptManager.findSubAttempts(session.getParentAttempt().getId())
                .stream().filter(a -> a.getEpreuve() == EpreuveType.TCF_CE).findFirst().orElseThrow();
        assertThat(premier.getTimerStartedAt()).isNull();

        Attempt lance = serviceLancer(session);
        var ancre = lance.getTimerStartedAt();
        assertThat(ancre).isNotNull();

        Attempt relance = serviceLancer(session);
        assertThat(relance.getTimerStartedAt())
                .as("relancer ne doit pas rendre du temps au candidat")
                .isEqualTo(ancre);
    }

    private Attempt serviceLancer(TcfDiagnosticSession session) {
        return sectionStarter.lancerSection(session, EpreuveType.TCF_CE);
    }

    @Test
    @DisplayName("La section de compréhension tire ses items par palier, chrono réduit à l'avenant")
    void tirageEtChronoReduits() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        Attempt ce = attemptManager.findSubAttempts(session.getParentAttempt().getId())
                .stream().filter(a -> a.getEpreuve() == EpreuveType.TCF_CE).findFirst().orElseThrow();

        // Le chrono suit le nombre d'items REELLEMENT poses : jamais celui de
        // l'epreuve entiere, ce serait malhonnete sur un format reduit.
        int attendu = TcfDiagnosticSectionStarter.dureeReduite(
                QuestionType.CE, ce.getTotalQuestions());
        assertThat(ce.getTimeLimitSeconds()).isEqualTo(attendu);
        assertThat(ce.getModule()).isEqualTo(Module.TCF);
    }

    @Test
    @DisplayName("Un résultat demandé sans avoir rien passé ne conclut rien — et ne plante pas")
    void resultatSansAucuneSection() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        var resultat = viewService.resultat(
                service.cloturer(user.getId(), session.getId()),
                service.cible(user).orElse(null));

        // 🛑 Aucune epreuve evaluee ⇒ pas de niveau global. Jamais un A1.
        assertThat(resultat.niveauGlobal()).isNull();
        assertThat(resultat.epreuves()).hasSize(4);
        assertThat(resultat.epreuves()).allSatisfy(e -> assertThat(e.niveau()).isNull());
        assertThat(resultat.priorites()).isEmpty();
        assertThat(resultat.dejaAuNiveau()).isEmpty();
    }
}
