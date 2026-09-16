package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.dto.TcfDiagnosticDto;
import com.sejourfr.app.dto.TcfDiagnosticResultDto;
import com.sejourfr.app.dto.TcfDiagnosticSectionDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Une épreuve MESURÉE est une section FAITE</b> — arbitrage du propriétaire
 * du 2026-09-16, contre la vraie base.
 *
 * <p>Verbatim : « <i>un diagnostic complet, chaque épreuve est un examen blanc
 * de l'épreuve. Donc si un examen blanc est fait ailleurs, directement on
 * considère que le diagnostic de cette épreuve est fait, et les priorités à
 * travailler identifiées.</i> »
 *
 * <p>Ce que ce fichier verrouille, et pourquoi il est en {@code *IT} : la
 * réponse à « cette épreuve est-elle mesurée ? » vient de deux <b>requêtes</b>
 * ({@code findQcmEpreuvesPassees} / {@code findProductionEpreuvesPassees}) dont
 * tout le sens est dans le prédicat SQL de provenance. Un test à mocks aurait
 * vérifié le câblage sans jamais vérifier la règle.
 *
 * <p>🛑 L'autre moitié est tout aussi importante : <b>une épreuve mesurée nulle
 * part reste non mesurée</b>. On ne remplace pas un trou par un plancher —
 * c'est l'invariant que V040/V041/V042 ont payé.
 */
class TcfDiagnosticEpreuveMesureeIT extends AbstractIntegrationTest {

    @Autowired
    private TestData data;
    @Autowired
    private TcfDiagnosticService service;
    @Autowired
    private TcfDiagnosticViewService viewService;
    @Autowired
    private TcfDiagnosticReadService readService;
    @Autowired
    private TcfProfileService profileService;
    @Autowired
    private AttemptManager attemptManager;
    @Autowired
    private com.sejourfr.app.manager.AttemptQuestionManager attemptQuestionManager;
    @Autowired
    private EntityManager entityManager;

    /**
     * 🛑 <b>Le défaut constaté sur un compte réel.</b> Le candidat passe un
     * examen blanc de compréhension orale depuis l'Accueil ; l'écran Diagnostic
     * continuait d'annoncer sa propre section CO « Terminée · Non évaluée ».
     * Les deux affirmations étaient vraies séparément, et c'est exactement ce
     * que le propriétaire refuse.
     */
    @Test
    @DisplayName("🛑 Une CO mesurée par un examen blanc ISOLÉ rend la section faite, au niveau du produit")
    void examenBlancIsole_rendLaSectionFaite() {
        User user = data.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        Attempt examen = examenQcm(user, EpreuveType.TCF_CO, 80, Instant.now());
        entityManager.flush();
        entityManager.clear();

        TcfDiagnosticSectionDto co = section(
                viewService.vue(service.lire(user.getId(), session.getId())),
                EpreuveType.TCF_CO);

        assertThat(co.etat())
                .as("mesurée = faite : on ne redemande pas une épreuve qu'on sait mesurée")
                .isEqualTo(TcfDiagnosticSectionState.TERMINEE);

        // 🛑 LE niveau du produit, pas un second calcul : la même valeur que
        // l'Accueil et le Profil servent pour cette épreuve.
        TcfLevelProfile profil = profileService.levelProfileAccueil(user.getId());
        assertThat(co.niveau()).isNotNull().isEqualTo(profil.co());

        // « Voir le rapport » pointe sur l'examen qui a mesuré, pas sur le
        // sous-attempt vide du diagnostic — dont le rapport n'existe pas.
        assertThat(co.rapportAttemptId()).isEqualTo(examen.getId());
        assertThat(co.attemptId()).isNotEqualTo(examen.getId());

        // 🛑 Pas de « /499 » : le niveau servi est une MOYENNE d'examens, en
        // afficher un score serait celui d'un seul d'entre eux.
        assertThat(co.scoreCalibre()).isNull();

        // Les trois autres épreuves ne sont pas mesurées : rien n'est inventé.
        assertThat(section(viewService.vue(session), EpreuveType.TCF_CE).niveau()).isNull();
    }

    /**
     * 🛑 <b>« Et les priorités à travailler identifiées. »</b> C'est la seconde
     * moitié de la demande, et la plus facile à oublier : une épreuve déclarée
     * faite qui ne rendrait aucune tâche à travailler n'aurait servi à rien.
     */
    @Test
    @DisplayName("🛑 Une EE mesurée par un examen TCF COMPLET rend la section faite ET ses priorités")
    void examenTcfComplet_rendLaSectionFaiteEtSesPriorites() {
        User user = data.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        // L'épreuve EE d'un examen blanc TCF complet : pas de slot, un parent.
        Attempt parent = conteneurComplet(user);
        Attempt ee = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.A2);
        ee.setSlotNumber(null);
        ee.setParentAttempt(parent);
        attemptManager.save(ee);
        entityManager.flush();
        entityManager.clear();

        session = service.lire(user.getId(), session.getId());
        TcfDiagnosticSectionDto vue = section(viewService.vue(session), EpreuveType.TCF_EE);
        assertThat(vue.etat()).isEqualTo(TcfDiagnosticSectionState.TERMINEE);
        assertThat(vue.niveau()).isEqualTo(NiveauCecrl.A2);
        assertThat(vue.rapportAttemptId()).isEqualTo(ee.getId());

        // Les 3 tâches de CETTE épreuve alimentent les priorités du diagnostic,
        // exactement comme si elle avait été jouée dans la session.
        TcfDiagnosticResultDto resultat = viewService.resultat(session, NiveauCecrl.B2);
        assertThat(resultat.priorites())
                .as("une épreuve mesurée ailleurs doit nommer ses tâches à travailler")
                .isNotEmpty()
                .allSatisfy(p -> assertThat(p.epreuve()).isEqualTo(EpreuveType.TCF_EE));
        assertThat(resultat.priorites()).extracting(p -> p.taskCode()).doesNotContainNull();
    }

    /**
     * 🔴 <b>Aucune réponse = aucune mesure, jamais un A1 fabriqué.</b> Une
     * section close à zéro réponse, sur une épreuve que rien d'autre n'a
     * mesurée, reste honnêtement non mesurée — et le candidat peut la passer.
     */
    @Test
    @DisplayName("🔴 Une épreuve mesurée NULLE PART reste non mesurée, même close à zéro réponse")
    void aucuneMesure_resteNonMesuree() {
        User user = data.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        // La CO est ouverte puis quittée sans répondre à une seule question.
        Attempt co = attemptManager.findSubAttempts(session.getParentAttempt().getId())
                .stream().filter(a -> a.getEpreuve() == EpreuveType.TCF_CO)
                .findFirst().orElseThrow();
        assertThat(co).isNotNull();
        entityManager.flush();
        entityManager.clear();

        TcfDiagnosticSectionDto vue = section(
                viewService.vue(service.lire(user.getId(), session.getId())),
                EpreuveType.TCF_CO);

        assertThat(vue.niveau()).isNull();
        assertThat(vue.scoreCalibre()).isNull();
        assertThat(vue.rapportAttemptId())
                .as("aucun rapport à ouvrir quand rien n'a été mesuré")
                .isNull();
    }

    /**
     * 🛑 <b>La lecture HISTORIQUE n'est jamais enrichie.</b> {@code sections}
     * dit ce que CETTE session a mesuré, et rien d'autre : c'est elle que lisent
     * la comparaison de deux diagnostics, le palier initial et la courbe de
     * l'écran Progrès. L'enrichir rendrait toute évolution {@code STABLE} —
     * « vous avez tenu votre niveau » sur une épreuve que ce diagnostic-là n'a
     * jamais mesurée.
     */
    @Test
    @DisplayName("🛑 `sections` reste la mesure de la SESSION ; seule `sectionsMesurees` comble")
    void lectureHistorique_nEstPasEnrichie() {
        User user = data.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();
        examenQcm(user, EpreuveType.TCF_CE, 90, Instant.now());
        entityManager.flush();
        entityManager.clear();

        session = service.lire(user.getId(), session.getId());

        assertThat(niveauDe(readService.sections(session), EpreuveType.TCF_CE))
                .as("cette session n'a rien mesuré en CE")
                .isNull();
        assertThat(niveauDe(readService.sectionsMesurees(session), EpreuveType.TCF_CE))
                .as("le produit, lui, sait que l'épreuve est mesurée")
                .isNotNull();
    }

    /**
     * Le compteur « N sections sur 4 terminées » et la clôture suivent la même
     * vérité : les 4 épreuves étant mesurées, le diagnostic se clôt et rend son
     * résultat, même si aucune section n'a été jouée dans la session.
     *
     * <p>🛑 Aucune garde n'a été levée pour cela : {@code cloturer} n'a jamais
     * exigé les 4 sections (10_ §4.2 impose déjà de calculer sur ce qui existe).
     */
    @Test
    @DisplayName("Les 4 épreuves mesurées ailleurs ⇒ 4 sections terminées, et le résultat se rend")
    void quatreEpreuvesMesurees_lediagnosticSeClot() {
        User user = data.user();
        TcfDiagnosticSession session = service.ouvrir(user.getId());
        entityManager.flush();

        examenQcm(user, EpreuveType.TCF_CO, 80, Instant.now());
        examenQcm(user, EpreuveType.TCF_CE, 80, Instant.now());
        data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        data.epreuveProductionPassee(user, EpreuveType.TCF_EO, NiveauCecrl.B1);
        entityManager.flush();
        entityManager.clear();

        session = service.lire(user.getId(), session.getId());
        assertThat(viewService.vue(session).sections())
                .allSatisfy(s -> {
                    assertThat(s.etat()).isEqualTo(TcfDiagnosticSectionState.TERMINEE);
                    assertThat(s.niveau()).isNotNull();
                });

        service.cloturer(user.getId(), session.getId());
        entityManager.flush();
        entityManager.clear();

        session = service.lire(user.getId(), session.getId());
        assertThat(viewService.resultat(session, NiveauCecrl.B2).niveauGlobal())
                .as("le plancher des quatre épreuves mesurées")
                .isNotNull();
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

    /** Un examen QCM d'épreuve passé seul, avec une réponse — donc qualifiant. */
    private Attempt examenQcm(User user, EpreuveType epreuve, int pondere, Instant fin) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.MOCK_EXAM);
        a.setModule(Module.TCF);
        a.setEpreuve(epreuve);
        a.setMode(AttemptMode.EXAMEN);
        a.setStatus(AttemptStatus.TERMINE);
        a.setSlotNumber(1);
        a.setStartedAt(fin.minus(30, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        a.setWeightedScore(pondere);
        a.setMaxWeightedScore(100);
        attemptManager.save(a);
        data.answer(data.attemptQuestion(a, data.question()));
        return a;
    }

    /** Le conteneur d'un examen blanc TCF complet — il porte les sous-épreuves. */
    private Attempt conteneurComplet(User user) {
        Attempt parent = new Attempt();
        parent.setUser(user);
        parent.setType(AttemptType.MOCK_EXAM);
        parent.setModule(Module.TCF);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setMode(AttemptMode.EXAMEN);
        parent.setStatus(AttemptStatus.TERMINE);
        parent.setStartedAt(Instant.now().minus(3, ChronoUnit.HOURS));
        return attemptManager.save(parent);
    }

    private static TcfDiagnosticSectionDto section(TcfDiagnosticDto vue, EpreuveType epreuve) {
        return vue.sections().stream()
                .filter(s -> s.epreuve() == epreuve)
                .findFirst().orElseThrow();
    }

    private static NiveauCecrl niveauDe(
            java.util.List<TcfDiagnosticReadService.Section> sections, EpreuveType epreuve) {
        return sections.stream()
                .filter(s -> s.epreuve() == epreuve)
                .findFirst().orElseThrow()
                .niveau();
    }
}
