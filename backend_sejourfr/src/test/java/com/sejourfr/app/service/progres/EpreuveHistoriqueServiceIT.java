package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.EpreuveHistoriqueDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SourceEvaluation;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>« D'où sort mon niveau ? »</b>, contre la vraie base.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>🛑 <b>Une épreuve jamais mesurée rend une liste VIDE</b>, jamais une
 *       erreur ni un palier inventé. C'est la règle « {@code null} = inconnu,
 *       jamais mauvais » sur un écran entier ;</li>
 *   <li>🛑 <b>La provenance est SERVIE et distincte</b> : une sous-épreuve de
 *       diagnostic complet porte aussi un {@code parentAttempt}, et la lire
 *       dans le mauvais ordre l'annoncerait « examen blanc » ;</li>
 *   <li>🛑 <b>Le tri est chronologique, toutes sources confondues</b> : une
 *       baseline de diagnostic ne doit pas passer devant une épreuve d'hier
 *       par le seul hasard de l'ordre de lecture ;</li>
 *   <li>🛑 <b>Le plafond est un plafond d'AFFICHAGE</b> : on balaie plus large
 *       que trois, puis on coupe ;</li>
 *   <li>🛑 <b>La définition de « qualifiante » est celle du profil</b> : un
 *       examen sans aucune réponse n'y entre pas, ici comme dans
 *       {@code TcfProfileService}. Sinon l'écran expliquerait un niveau par
 *       une mesure qui ne l'a pas produit.</li>
 * </ul>
 *
 * <p>Tolérant au seed Flyway : chaque test crée son propre candidat et
 * n'assert que sur lui.
 */
class EpreuveHistoriqueServiceIT extends AbstractIntegrationTest {

    @Autowired private EpreuveHistoriqueService service;
    @Autowired private TestData data;
    @Autowired private AttemptManager attemptManager;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private TcfDiagnosticSessionManager tcfSessionManager;

    @PersistenceContext private EntityManager entityManager;

    /* ------------------------------------------------------------ fixtures -- */

    /**
     * Un examen blanc QCM fini dont les <b>réponses</b> démontrent
     * {@code niveau} — donc qualifiant. 🛑 Le palier ne se déclare plus : il
     * n'existe que dérivé (cf. {@code TestData.reponsesQcmDemontrant}).
     */
    private Attempt examenQcm(User user, EpreuveType epreuve, NiveauCecrl niveau, Instant fin) {
        Attempt a = attemptQcm(user, epreuve, fin);
        data.reponsesQcmDemontrant(a,
                epreuve == EpreuveType.TCF_CE ? QuestionType.CE : QuestionType.CO, niveau);
        entityManager.flush();
        return a;
    }

    /** Le même, sans aucune réponse : passé, mais rien rendu. */
    private Attempt attemptQcm(User user, EpreuveType epreuve, Instant fin) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.MOCK_EXAM);
        a.setModule(Module.TCF);
        a.setEpreuve(epreuve);
        a.setMode(AttemptMode.EXAMEN);
        a.setStatus(AttemptStatus.TERMINE);
        a.setStartedAt(fin.minus(30, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        return attemptManager.save(a);
    }

    /** Le conteneur d'un examen blanc complet — il porte les sous-épreuves. */
    private Attempt conteneurComplet(User user) {
        Attempt parent = new Attempt();
        parent.setUser(user);
        parent.setType(AttemptType.MOCK_EXAM);
        parent.setModule(Module.TCF);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setMode(AttemptMode.EXAMEN);
        parent.setStatus(AttemptStatus.TERMINE);
        parent.setStartedAt(Instant.now().minus(2, ChronoUnit.HOURS));
        return attemptManager.save(parent);
    }

    /** Une session de diagnostic TCF complet, accrochée à son conteneur. */
    private TcfDiagnosticSession sessionComplete(User user, Attempt parent) {
        TcfDiagnosticSession session = new TcfDiagnosticSession();
        session.setUser(user);
        session.setParentAttempt(parent);
        session.setConfigVersion(1);
        session.setStatus(TcfDiagnosticStatus.COMPLETED);
        session.setStartedAt(Instant.now().minus(2, ChronoUnit.HOURS));
        session.setExpiresAt(Instant.now().plus(7, ChronoUnit.DAYS));
        session.setCompletedAt(Instant.now());
        return tcfSessionManager.save(session);
    }

    /**
     * Une épreuve de production passée en examen blanc, terminée, avec sa
     * tâche 1 évaluée. Les tâches jamais rendues comptent 0 : c'est le chemin
     * « épreuve écourtée » de {@code ProductionBilanService}.
     */
    private Attempt examenProduction(User user, EpreuveType epreuve, Instant fin) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.MOCK_EXAM);
        a.setModule(Module.TCF);
        a.setEpreuve(epreuve);
        a.setMode(AttemptMode.EXAMEN);
        a.setStatus(AttemptStatus.TERMINE);
        a.setStartedAt(fin.minus(30, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        a.setSlotNumber(1);
        attemptManager.save(a);

        ProductionTask task = data.productionTask(epreuve);
        ProductionSubmission submission = data.productionSubmission(a, task, user);
        submission.setStatut(SubmissionStatut.EVALUATED);
        submissionManager.save(submission);
        data.aiEvaluation(submission);
        entityManager.flush();
        return a;
    }

    /** La baseline du diagnostic RAPIDE, sur une session terminée. */
    private void diagnosticRapide(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        boolean ecrit = epreuve == EpreuveType.TCF_EE;
        data.diagnosticAnalysis(
                data.diagnosticSubmission(
                        ecrit ? session.getWrittenAttempt() : session.getOralAttempt(),
                        ecrit ? session.getWrittenTask() : session.getOralTask(),
                        user),
                niveau);
        entityManager.flush();
    }

    /* ---------------------------------------------------------------- CO/CE -- */

    @Test
    @DisplayName("🛑 Sans aucune mesure, la liste est VIDE — jamais une erreur, jamais un palier")
    void aucuneEvaluation() {
        User user = data.user();

        for (EpreuveType epreuve : new EpreuveType[]{
                EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                EpreuveType.TCF_EE, EpreuveType.TCF_EO}) {
            EpreuveHistoriqueDto dto = service.historique(user.getId(), epreuve);
            assertThat(dto.epreuve()).isEqualTo(epreuve);
            assertThat(dto.evaluations()).isEmpty();
        }
    }

    @Test
    @DisplayName("Une CO passée seule est servie avec sa date, sa source et son palier")
    void comprehensionOraleSeule() {
        User user = data.user();
        Instant fin = Instant.now().minus(3, ChronoUnit.DAYS);
        examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.B1, fin);

        EpreuveHistoriqueDto dto = service.historique(user.getId(), EpreuveType.TCF_CO);

        assertThat(dto.evaluations()).hasSize(1);
        EpreuveHistoriqueDto.Evaluation e = dto.evaluations().getFirst();
        assertThat(e.niveau()).isEqualTo(NiveauCecrl.B1);
        assertThat(e.source()).isEqualTo(SourceEvaluation.EPREUVE_SEULE);
        // La base tronque les micro-secondes : on compare à la seconde.
        assertThat(e.mesureA())
                .isCloseTo(fin, org.assertj.core.api.Assertions.within(1, ChronoUnit.SECONDS));
    }

    @Test
    @DisplayName("Une CE d'examen blanc complet se dit EXAMEN_BLANC, et n'apparaît pas en CO")
    void comprehensionEcriteDansUnExamenComplet() {
        User user = data.user();
        Attempt parent = conteneurComplet(user);
        Attempt ce = examenQcm(
                user, EpreuveType.TCF_CE, NiveauCecrl.A2, Instant.now().minus(1, ChronoUnit.DAYS));
        ce.setParentAttempt(parent);
        attemptManager.save(ce);
        entityManager.flush();
        entityManager.clear();

        assertThat(service.historique(user.getId(), EpreuveType.TCF_CE).evaluations())
                .singleElement()
                .satisfies(e -> {
                    assertThat(e.source()).isEqualTo(SourceEvaluation.EXAMEN_BLANC);
                    assertThat(e.niveau()).isEqualTo(NiveauCecrl.A2);
                });
        // 🛑 Le scope de l'épreuve est strict : une CE n'explique jamais la CO.
        assertThat(service.historique(user.getId(), EpreuveType.TCF_CO).evaluations()).isEmpty();
    }

    /**
     * 🛑 Une sous-épreuve de diagnostic complet porte <b>aussi</b> un
     * {@code parentAttempt} : c'est exactement le piège que l'ordre des tests
     * de {@code source()} évite.
     */
    @Test
    @DisplayName("🛑 Une CO de diagnostic complet se dit DIAGNOSTIC_COMPLET, pas EXAMEN_BLANC")
    void sousEpreuveDeDiagnosticComplet() {
        User user = data.user();
        Attempt parent = conteneurComplet(user);
        TcfDiagnosticSession session = sessionComplete(user, parent);
        Attempt co = examenQcm(
                user, EpreuveType.TCF_CO, NiveauCecrl.B1, Instant.now().minus(2, ChronoUnit.DAYS));
        co.setParentAttempt(parent);
        co.setTcfDiagnostic(session);
        attemptManager.save(co);
        entityManager.flush();
        entityManager.clear();

        assertThat(service.historique(user.getId(), EpreuveType.TCF_CO).evaluations())
                .singleElement()
                .satisfies(e ->
                        assertThat(e.source()).isEqualTo(SourceEvaluation.DIAGNOSTIC_COMPLET));
    }

    /**
     * La définition de « qualifiante » est celle du profil
     * ({@code AttemptRepository.findQcmEpreuvesPassees}) : zéro réponse ⇒ rien
     * rendu ⇒ pas une mesure. « Aucune preuve » n'est pas « mauvaise preuve ».
     */
    @Test
    @DisplayName("🛑 Un examen abandonné sans AUCUNE réponse n'explique aucun niveau")
    void examenSansAucuneReponse() {
        User user = data.user();
        attemptQcm(user, EpreuveType.TCF_CE, Instant.now());
        entityManager.flush();

        assertThat(service.historique(user.getId(), EpreuveType.TCF_CE).evaluations()).isEmpty();
    }

    /* ---------------------------------------------------------------- EE/EO -- */

    @Test
    @DisplayName("Une EE d'examen blanc est servie avec le palier du bilan d'épreuve")
    void expressionEcriteEnExamen() {
        User user = data.user();
        examenProduction(user, EpreuveType.TCF_EE, Instant.now().minus(1, ChronoUnit.DAYS));
        entityManager.clear();

        assertThat(service.historique(user.getId(), EpreuveType.TCF_EE).evaluations())
                .singleElement()
                .satisfies(e -> {
                    assertThat(e.source()).isEqualTo(SourceEvaluation.EPREUVE_SEULE);
                    // 🛑 Un palier SERVI, quel qu'il soit — jamais `null` posé à
                    // la place d'un verdict que le bilan sait rendre.
                    assertThat(e.niveau()).isNotNull();
                });
    }

    @Test
    @DisplayName("L'EO du diagnostic rapide compte, et se dit DIAGNOSTIC_RAPIDE")
    void expressionOraleDuDiagnosticRapide() {
        User user = data.user();
        diagnosticRapide(user, EpreuveType.TCF_EO, NiveauCecrl.A2);
        entityManager.clear();

        assertThat(service.historique(user.getId(), EpreuveType.TCF_EO).evaluations())
                .singleElement()
                .satisfies(e -> {
                    assertThat(e.source()).isEqualTo(SourceEvaluation.DIAGNOSTIC_RAPIDE);
                    assertThat(e.niveau()).isEqualTo(NiveauCecrl.A2);
                });
    }

    /**
     * 🛑 Le petit sujet de compétence n'est pas une évaluation qualifiante, et
     * l'entraînement libre non plus : le produit n'y calcule aucun palier.
     */
    @Test
    @DisplayName("🛑 Une production d'entraînement libre n'explique aucun niveau d'épreuve")
    void entrainementLibreExclu() {
        User user = data.user();
        Attempt libre = new Attempt();
        libre.setUser(user);
        libre.setType(AttemptType.TRAINING);
        libre.setModule(Module.TCF);
        libre.setEpreuve(EpreuveType.TCF_EE);
        libre.setMode(AttemptMode.ENTRAINEMENT);
        libre.setStatus(AttemptStatus.TERMINE);
        libre.setStartedAt(Instant.now().minus(1, ChronoUnit.HOURS));
        libre.setFinishedAt(Instant.now());
        attemptManager.save(libre);
        ProductionSubmission s = data.productionSubmission(
                libre, data.productionTask(EpreuveType.TCF_EE), user);
        s.setStatut(SubmissionStatut.EVALUATED);
        submissionManager.save(s);
        data.aiEvaluation(s);
        entityManager.flush();
        entityManager.clear();

        assertThat(service.historique(user.getId(), EpreuveType.TCF_EE).evaluations()).isEmpty();
    }

    /* ------------------------------------------------------------- tri, cap -- */

    @Test
    @DisplayName("🛑 Diagnostic et examens se trient ENSEMBLE, du plus récent au plus ancien")
    void triChronologiqueToutesSourcesConfondues() {
        User user = data.user();
        // La baseline du diagnostic date de maintenant (`analyzed_at`), les
        // deux examens d'avant : elle doit donc passer en tête.
        examenProduction(user, EpreuveType.TCF_EE, Instant.now().minus(10, ChronoUnit.DAYS));
        examenProduction(user, EpreuveType.TCF_EE, Instant.now().minus(4, ChronoUnit.DAYS));
        diagnosticRapide(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        entityManager.clear();

        var evaluations = service.historique(user.getId(), EpreuveType.TCF_EE).evaluations();

        assertThat(evaluations).hasSize(3);
        assertThat(evaluations.getFirst().source())
                .isEqualTo(SourceEvaluation.DIAGNOSTIC_RAPIDE);
        assertThat(evaluations).isSortedAccordingTo(
                java.util.Comparator.comparing(
                        EpreuveHistoriqueDto.Evaluation::mesureA).reversed());
    }

    @Test
    @DisplayName("🛑 Trois lignes au plus — un plafond d'AFFICHAGE, pas un budget de lecture")
    void plafondDAffichage() {
        User user = data.user();
        for (int i = 1; i <= 5; i++) {
            examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A2,
                    Instant.now().minus(i, ChronoUnit.DAYS));
        }
        entityManager.clear();

        var evaluations = service.historique(user.getId(), EpreuveType.TCF_CO).evaluations();

        assertThat(evaluations).hasSize(EpreuveHistoriqueService.MAX_EVALUATIONS);
        // Les trois PLUS RÉCENTES, pas les trois premières lues.
        assertThat(evaluations.getFirst().mesureA())
                .isAfter(evaluations.get(1).mesureA());
    }

    /* ------------------------------------------------------------ mauvaise -- */

    @Test
    @DisplayName("🛑 TCF_STRUCTURE n'est pas une épreuve du TCF IRN : 400, pas une liste vide")
    void epreuveHorsDesQuatre() {
        final java.util.UUID userId = data.user().getId();

        assertThatThrownBy(() -> service.historique(userId, EpreuveType.TCF_STRUCTURE))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("TCF IRN");
        assertThatThrownBy(() -> service.historique(userId, EpreuveType.CIVIQUE))
                .isInstanceOf(BusinessException.class);
    }
}
