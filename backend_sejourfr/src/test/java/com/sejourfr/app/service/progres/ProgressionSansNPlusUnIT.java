package com.sejourfr.app.service.progres;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 🛑 <b>Les quatre écrans de progression coûtent un nombre de requêtes
 * CONSTANT</b>, qu'un candidat ait passé un examen ou six.
 *
 * <p>⚠️ <b>Égalités, jamais des {@code <=}</b> (patron de
 * {@code NiveauQcmDeriveSansNPlusUnIT}) : un {@code <=} reste vrai tant que le
 * compte est « raisonnable », et un N+1 sur trois lignes de fixture l'est
 * toujours. Le vrai test est que le compte ne bouge pas quand le nombre
 * d'examens est multiplié. Les deux candidats ont donc la <b>même forme</b>
 * d'historique (mêmes provenances, mêmes épreuves), seul le nombre change.
 */
class ProgressionSansNPlusUnIT extends AbstractIntegrationTest {

    @Autowired private ProgressionExamensService service;
    @Autowired private TestData data;
    @Autowired private AttemptManager attemptManager;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private AiEvaluationManager aiEvaluationManager;
    @Autowired private ThemeManager themeManager;
    @Autowired private EntityManager entityManager;

    private final Instant maintenant = Instant.now().truncatedTo(ChronoUnit.SECONDS);

    /** {@code n} fois : un examen de CO seul, un examen complet (4 épreuves), EE et EO seules. */
    private User candidatTcf(int n) {
        User user = data.user();
        for (int i = 0; i < n; i++) {
            Instant fin = maintenant.minus(n - i, ChronoUnit.DAYS);
            Attempt co = data.examenQcmTcfPasse(user, EpreuveType.TCF_CO, NiveauCecrl.A2);
            co.setFinishedAt(fin);
            attemptManager.save(co);

            Attempt parent = new Attempt();
            parent.setUser(user);
            parent.setType(AttemptType.MOCK_EXAM);
            parent.setModule(Module.TCF);
            parent.setEpreuve(EpreuveType.TCF_COMPLET);
            parent.setMode(AttemptMode.EXAMEN);
            parent.setStatus(AttemptStatus.TERMINE);
            parent.setStartedAt(fin.minus(2, ChronoUnit.HOURS));
            parent.setFinishedAt(fin);
            attemptManager.save(parent);
            for (EpreuveType e : List.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                    EpreuveType.TCF_EE, EpreuveType.TCF_EO)) {
                Attempt sub = new Attempt();
                sub.setUser(user);
                sub.setType(AttemptType.MOCK_EXAM);
                sub.setModule(Module.TCF);
                sub.setEpreuve(e);
                sub.setMode(AttemptMode.EXAMEN);
                sub.setStatus(AttemptStatus.TERMINE);
                sub.setParentAttempt(parent);
                sub.setStartedAt(fin.minus(1, ChronoUnit.HOURS));
                sub.setTimerStartedAt(fin.minus(15, ChronoUnit.MINUTES));
                sub.setFinishedAt(fin);
                attemptManager.save(sub);
                if (e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE) {
                    data.reponsesQcmDemontrant(sub,
                            e == EpreuveType.TCF_CO ? QuestionType.CO : QuestionType.CE, NiveauCecrl.B1);
                } else {
                    troisTachesNotees(sub, user, e);
                }
            }
            for (EpreuveType e : List.of(EpreuveType.TCF_EE, EpreuveType.TCF_EO)) {
                Attempt seule = new Attempt();
                seule.setUser(user);
                seule.setType(AttemptType.TRAINING);
                seule.setModule(Module.TCF);
                seule.setEpreuve(e);
                seule.setMode(AttemptMode.EXAMEN);
                seule.setStatus(AttemptStatus.TERMINE);
                seule.setSlotNumber(1);
                seule.setStartedAt(fin.minus(20, ChronoUnit.MINUTES));
                seule.setFinishedAt(fin);
                attemptManager.save(seule);
                troisTachesNotees(seule, user, e);
            }
        }
        return user;
    }

    private void troisTachesNotees(Attempt a, User user, EpreuveType e) {
        for (short numero = 1; numero <= 3; numero++) {
            ProductionSubmission s = data.productionSubmission(a, data.productionTacheNumero(e, numero), user);
            s.setStatut(SubmissionStatut.EVALUATED);
            submissionManager.save(s);
            AiEvaluation ev = data.aiEvaluation(s);
            ev.setNoteSur20(new BigDecimal("12"));
            ev.setNiveauCecrl(null);
            ev.setNiveauCecrlIa(null);
            ev.setFeedbackJson(new java.util.HashMap<>());
            aiEvaluationManager.save(ev);
        }
    }

    /** {@code n} fois : un examen global (une question par thème) et un examen de chaque thème. */
    private User candidatCivique(int n) {
        User user = data.user();
        List<Theme> themes = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
        for (int i = 0; i < n; i++) {
            Instant fin = maintenant.minus(n - i, ChronoUnit.DAYS);
            examenCivique(user, null, 40, 32, fin, themes);
            for (Theme t : themes) {
                examenCivique(user, t, 20, 16, fin, List.of(t));
            }
        }
        return user;
    }

    private void examenCivique(User user, Theme lot, int total, int seuil, Instant fin, List<Theme> themes) {
        Attempt a = data.attempt(user);
        a.setType(AttemptType.MOCK_EXAM);
        a.setMode(AttemptMode.EXAMEN);
        a.setStatus(AttemptStatus.TERMINE);
        a.setLotThemeId(lot == null ? null : lot.getId());
        a.setTotalQuestions(total);
        a.setPassThreshold(seuil);
        a.setTimeLimitSeconds(1200);
        a.setStartedAt(fin.minus(10, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        a.setScore(themes.size());
        for (Theme t : themes) {
            Question q = data.question(t);
            data.answer(data.attemptQuestion(a, q), true);
        }
        attemptManager.save(a);
    }

    @Test
    @DisplayName("🛑 Progression d'une épreuve (CO, EE) : même coût pour 1 examen et pour 6")
    void epreuve() {
        User un = candidatTcf(1);
        User six = candidatTcf(6);

        for (EpreuveType e : List.of(EpreuveType.TCF_CO, EpreuveType.TCF_EE)) {
            long avecUn = compterRequetes(() -> service.epreuve(un.getId(), e));
            long avecSix = compterRequetes(() -> service.epreuve(six.getId(), e));
            assertThat(avecUn).isPositive();
            assertThat(avecSix).as("épreuve %s", e).isEqualTo(avecUn);
        }
        // Et le compte de six est bien lu en entier.
        assertThat(service.epreuve(six.getId(), EpreuveType.TCF_CO).examens()).hasSize(12);
    }

    @Test
    @DisplayName("🛑 Progression TCF globale : même coût pour 1 examen complet et pour 6")
    void tcfGlobal() {
        User un = candidatTcf(1);
        User six = candidatTcf(6);

        long avecUn = compterRequetes(() -> service.tcf(un.getId(), true));
        long avecSix = compterRequetes(() -> service.tcf(six.getId(), true));

        assertThat(avecUn).isPositive();
        assertThat(avecSix).isEqualTo(avecUn);
        assertThat(service.tcf(six.getId(), true).examens()).hasSize(6);
    }

    @Test
    @DisplayName("🛑 Progression civique globale et d'un thème : même coût pour 1 examen et pour 6")
    void civique() {
        User un = candidatCivique(1);
        User six = candidatCivique(6);
        Theme t1 = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE).getFirst();

        long globalUn = compterRequetes(() -> service.civique(un.getId(), true));
        long globalSix = compterRequetes(() -> service.civique(six.getId(), true));
        long themeUn = compterRequetes(() -> service.theme(un.getId(), t1.getId()));
        long themeSix = compterRequetes(() -> service.theme(six.getId(), t1.getId()));

        assertThat(globalUn).isPositive();
        assertThat(globalSix).isEqualTo(globalUn);
        assertThat(themeSix).isEqualTo(themeUn);
        assertThat(service.civique(six.getId(), true).examens()).hasSize(6);
    }

    /** Requêtes préparées émises par {@code action}, session vidée au préalable. */
    private long compterRequetes(Runnable action) {
        entityManager.flush();
        entityManager.clear();
        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();
        action.run();
        return statistics.getPrepareStatementCount();
    }
}
