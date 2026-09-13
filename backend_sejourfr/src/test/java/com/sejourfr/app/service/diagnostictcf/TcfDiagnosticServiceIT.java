package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.dto.TcfDiagnosticDto;
import com.sejourfr.app.dto.TcfReassessmentEligibilityDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;
import com.sejourfr.app.enums.TcfReassessmentBlocker;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.attempt.AttemptCompositionService;
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
    @Autowired
    private com.sejourfr.app.manager.AttemptQuestionManager attemptQuestionManager;
    @Autowired
    private TcfReassessmentService reassessmentService;
    @Autowired
    private ProductionAccessService productionAccessService;

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
    @DisplayName("L7 — l'éligibilité servie dit la même chose que le refus d'ouverture")
    void eligibiliteEtRefusSontDaccord() {
        User user = testData.user();

        // Avant tout diagnostic : offert, et ce n'est pas une réévaluation.
        TcfReassessmentEligibilityDto avant = reassessmentService.eligibilite(user.getId());
        assertThat(avant.canStart()).isTrue();
        assertThat(avant.first()).isTrue();
        assertThat(avant.locked()).isFalse();

        TcfDiagnosticSession premier = service.ouvrir(user.getId());
        service.cloturer(user.getId(), premier.getId());
        entityManager.flush();
        entityManager.clear();

        TcfReassessmentEligibilityDto apres = reassessmentService.eligibilite(user.getId());
        assertThat(apres.canStart()).isFalse();
        assertThat(apres.locked()).isTrue();
        assertThat(apres.blocker()).isEqualTo(TcfReassessmentBlocker.PREMIUM_REQUIRED);
        assertThat(apres.lastSessionId()).isEqualTo(premier.getId());
        assertThat(apres.lastCompletedAt()).isNotNull();
        assertThat(apres.intervalDays()).isEqualTo(14);

        // 🛑 Le message servi et le message du refus sont le MEME : c'est
        // l'unique autorite de L7, et c'est ce que ce test verrouille.
        assertThatThrownBy(() -> service.ouvrir(user.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessage(apres.message());
    }

    @Test
    @DisplayName("L7 — un premier diagnostic n'a rien à comparer : progression null, jamais un « +0 »")
    void premierResultatSansProgression() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        service.cloturer(user.getId(), session.getId());
        entityManager.flush();

        assertThat(viewService.resultat(session, null).progression()).isNull();
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

    /**
     * 🛑 <b>Une section CLOSE rend son resultat</b> — arbitrage du proprietaire
     * du 2026-09-13, qui <b>revoque 10_ §4.2</b> (« aucun resultat detaille
     * avant la fin »). Une epreuve du diagnostic est un examen blanc de son
     * epreuve : elle en a la composition, la duree, le pipeline — elle en a
     * aussi la restitution.
     *
     * <p>Ce que ce test verrouille surtout, c'est la <b>frontiere</b> : une
     * section rend SON niveau, jamais le plancher des quatre ni une priorite.
     */
    @Test
    @DisplayName("🛑 Une section terminée rend son niveau et son score ; une section à faire ne rend rien")
    void uneSectionTermineeRendSonResultat() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        // Rien n'a ete commence : aucune section ne rend de resultat.
        assertThat(viewService.vue(session).sections())
                .as("null = non evaluee, jamais le palier le plus bas")
                .allSatisfy(s -> {
                    assertThat(s.niveau()).isNull();
                    assertThat(s.scoreCalibre()).isNull();
                    assertThat(s.analyseEnCours()).isFalse();
                });

        // La CE est lancee, REPONDUE, puis close : elle a mesure quelque chose,
        // donc elle rend son niveau. (Une section close sans AUCUNE reponse n'a
        // rien mesure — c'est le test voisin qui le verrouille.)
        Attempt ce = sub(session, EpreuveType.TCF_CE);
        sectionStarter.lancerSection(session, EpreuveType.TCF_CE);
        entityManager.flush();
        attemptQuestionManager.findByAttemptOrderedByPosition(ce.getId())
                .forEach(testData::answer);
        entityManager.flush();
        sectionStarter.cloreSection(session, EpreuveType.TCF_CE);
        entityManager.flush();
        entityManager.clear();

        TcfDiagnosticDto vue = viewService.vue(service.lire(user.getId(), session.getId()));
        assertThat(section(vue, EpreuveType.TCF_CE).etat())
                .isEqualTo(TcfDiagnosticSectionState.TERMINEE);
        assertThat(section(vue, EpreuveType.TCF_CE).niveau())
                .as("une section close rend son niveau")
                .isNotNull();
        // Les trois autres n'ont pas bouge.
        assertThat(section(vue, EpreuveType.TCF_CO).niveau()).isNull();
        assertThat(section(vue, EpreuveType.TCF_EE).niveau()).isNull();
    }

    /**
     * 🔴 <b>AUCUNE REPONSE = AUCUNE MESURE, jamais un A1.</b>
     *
     * <p>Constate a l'ecran le 2026-09-13 : une comprehension orale ouverte
     * puis quittee <b>sans repondre a une seule question</b> s'affichait
     * « Niveau A1 · 100 / 499 » — un verdict que personne n'a rendu, sur une
     * epreuve que personne n'a passee. Exactement la confusion que
     * V040/V041/V042 ont payee : une absence de donnee devenue le verdict le
     * plus bas.
     *
     * <p>⚠️ A ne pas confondre avec une epreuve <b>partiellement</b> repondue :
     * la, ne pas repondre EST une reponse, comme au TCF. La frontiere est a
     * zero.
     */
    @Test
    @DisplayName("🔴 Une épreuve close sans AUCUNE réponse n'a ni niveau ni score")
    void aucuneReponseNeDonneAucunNiveau() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        sectionStarter.lancerSection(session, EpreuveType.TCF_CO);
        entityManager.flush();
        sectionStarter.cloreSection(session, EpreuveType.TCF_CO);
        entityManager.flush();
        entityManager.clear();

        var co = section(
                viewService.vue(service.lire(user.getId(), session.getId())),
                EpreuveType.TCF_CO);
        assertThat(co.etat()).isEqualTo(TcfDiagnosticSectionState.TERMINEE);
        assertThat(co.niveau())
                .as("null = non evaluee, jamais le palier le plus bas")
                .isNull();
        assertThat(co.scoreCalibre())
                .as("un plancher affiche seul se lirait comme un resultat")
                .isNull();
    }

    /**
     * 🛑 <b>Quitter une epreuve COMMENCEE, c'est la terminer</b> ; une epreuve
     * <b>jamais ouverte</b> attend le candidat aussi longtemps qu'il faut.
     * C'est mot pour mot la regle de suspension d'un examen blanc, et c'est
     * l'arbitrage du proprietaire du 2026-09-13.
     */
    @Test
    @DisplayName("🛑 Clore une section : la commencée se termine, celle qui n'a jamais été ouverte survit")
    void cloreNeFermeQueCeQuiAEteOuvert() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        // Jamais commencee : la clore ne fait rien.
        sectionStarter.cloreSection(session, EpreuveType.TCF_CO);
        entityManager.flush();
        assertThat(sub(session, EpreuveType.TCF_CO).getFinishedAt())
                .as("on ne ferme que ce qui a ete ouvert")
                .isNull();

        // Commencee puis quittee : elle est close, et elle ne se reprend plus.
        sectionStarter.lancerSection(session, EpreuveType.TCF_EE);
        entityManager.flush();
        sectionStarter.cloreSection(session, EpreuveType.TCF_EE);
        entityManager.flush();
        java.time.Instant close = sub(session, EpreuveType.TCF_EE).getFinishedAt();
        assertThat(close).isNotNull();

        // Idempotent : un second appel ne redate pas la cloture.
        sectionStarter.cloreSection(session, EpreuveType.TCF_EE);
        entityManager.flush();
        assertThat(sub(session, EpreuveType.TCF_EE).getFinishedAt()).isEqualTo(close);
    }

    private com.sejourfr.app.dto.TcfDiagnosticSectionDto section(
            TcfDiagnosticDto vue, EpreuveType epreuve) {
        return vue.sections().stream()
                .filter(s -> s.epreuve() == epreuve)
                .findFirst().orElseThrow();
    }

    private Attempt sub(TcfDiagnosticSession session, EpreuveType epreuve) {
        return attemptManager.findSubAttempts(session.getParentAttempt().getId()).stream()
                .filter(a -> a.getEpreuve() == epreuve)
                .findFirst().orElseThrow();
    }

    /**
     * ⚠️ <b>REVOQUE « tirage et chrono reduits »</b> (2026-09-13, arbitrage du
     * proprietaire) : une section de comprehension du diagnostic <b>est</b> un
     * examen blanc de son epreuve — meme volume, meme duree pleine. Le prorata
     * qui vivait ici (`dureeReduite`) a ete supprime avec la composition
     * reduite qu'il accompagnait.
     */
    @Test
    @DisplayName("Une section de compréhension EST un examen blanc d'épreuve : même volume, durée pleine")
    void laSectionEstUnExamenBlancDEpreuve() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        Attempt ce = attemptManager.findSubAttempts(session.getParentAttempt().getId())
                .stream().filter(a -> a.getEpreuve() == EpreuveType.TCF_CE).findFirst().orElseThrow();

        assertThat(ce.getTimeLimitSeconds())
                .as("la duree officielle de l'epreuve, pas un prorata")
                .isEqualTo(DureeEpreuve.secondesPourQcm(QuestionType.CE));
        assertThat(ce.getTotalQuestions())
                .as("le volume d'un examen blanc de module")
                .isEqualTo(AttemptCompositionService.MODULE_EXAM_TOTAL);
        assertThat(ce.getModule()).isEqualTo(Module.TCF);
    }

    @Test
    @DisplayName("🛑 L'EE et l'EO du diagnostic sont OFFERTES : elles ne brûlent pas le freebie de l'examen blanc")
    void productionsDuDiagnosticNeConsommentRien() {
        User user = testData.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        Attempt ee = attemptManager.findSubAttempts(session.getParentAttempt().getId())
                .stream().filter(a -> a.getEpreuve() == EpreuveType.TCF_EE).findFirst().orElseThrow();
        ProductionTask tache = testData.productionTask(EpreuveType.TCF_EE);
        testData.productionSubmission(ee, tache, user);
        entityManager.flush();
        entityManager.clear();

        // Le compte est gratuit : sans le filtre `tcfDiagnostic IS NULL`, cette
        // soumission aurait consommé l'unique EE/EO offerte de l'examen blanc
        // complet, et le prochain examen serait arrivé avec EE/EO verrouillées.
        assertThat(productionAccessService.isFullExamProductionLocked(user.getId()))
                .as("une production de diagnostic ne verrouille jamais l'examen blanc")
                .isFalse();
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
