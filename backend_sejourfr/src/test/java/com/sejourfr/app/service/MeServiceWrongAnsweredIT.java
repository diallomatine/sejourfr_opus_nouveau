package com.sejourfr.app.service;

import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * « Mes erreurs » ({@code GET /api/me/questions/wrong}) sur base réelle.
 *
 * <p>Le service récupérait d'abord les 30 erreurs les plus récentes du module,
 * PUIS filtrait en mémoire : un utilisateur avec 225 CO ratées en voyait 8, et
 * 0 sur un thème civique qui en comptait 41. Le filtre {@code CO} excluait en
 * plus {@code CO_IMAGE}, à rebours de la règle appliquée partout ailleurs.
 *
 * <p>Couvre aussi {@code /api/me/stats?module=} dont {@code attemptsTotal}
 * ignorait le module demandé.
 */
class MeServiceWrongAnsweredIT extends AbstractIntegrationTest {

    @Autowired MeService meService;
    @Autowired TestData data;
    @Autowired AnswerManager answerManager;
    @Autowired AttemptManager attemptManager;
    @Autowired AttemptQuestionManager attemptQuestionManager;
    @Autowired QuestionManager questionManager;

    private int positionSeq = 0;

    // ------------------------------------------------------------------ erreurs

    /**
     * Le cas de la revue : beaucoup d'erreurs CE (assez pour saturer le plafond)
     * et quelques CO plus anciennes. Avant le correctif, filtrer sur CO ne
     * renvoyait rien — les 30 lignes remontées étaient toutes des CE.
     */
    @Test
    void filtreParType_nEstPasEcraseParLePlafond() {
        User user = data.user();
        Theme theme = data.theme(Module.TCF, "wrong-tcf", "TCF erreurs");
        Attempt attempt = attempt(user, Module.TCF, EpreuveType.TCF_CE);
        Instant base = Instant.now().minus(10, ChronoUnit.HOURS);

        // 3 CO anciennes…
        List<Question> co = questions(theme, Module.TCF, QuestionType.CO, 3);
        for (int i = 0; i < co.size(); i++) {
            answer(user, attempt, co.get(i), false, base.plus(i, ChronoUnit.MINUTES));
        }
        // … puis largement de quoi remplir le plafond en CE, toutes plus récentes.
        List<Question> ce = questions(theme, Module.TCF, QuestionType.CE,
                MeService.MAX_WRONG_PER_MODULE + 5);
        for (int i = 0; i < ce.size(); i++) {
            answer(user, attempt, ce.get(i), false, base.plus(1, ChronoUnit.HOURS)
                    .plus(i, ChronoUnit.MINUTES));
        }

        List<QuestionPublicResponse> onlyCo =
                meService.wrongAnswered(user.getId(), Module.TCF, QuestionType.CO, null);

        assertThat(onlyCo).extracting(QuestionPublicResponse::id)
                .containsExactlyInAnyOrderElementsOf(co.stream().map(Question::getId).toList());
    }

    /** Idem côté civique : le thème demandé, pas le thème présent dans les 30 dernières. */
    @Test
    void filtreParTheme_nEstPasEcraseParLePlafond() {
        User user = data.user();
        Theme cible = data.theme(Module.CIVIQUE, "wrong-civ-a", "Thème visé");
        Theme bruit = data.theme(Module.CIVIQUE, "wrong-civ-b", "Thème bruyant");
        Attempt attempt = attempt(user, Module.CIVIQUE, EpreuveType.CIVIQUE);
        Instant base = Instant.now().minus(10, ChronoUnit.HOURS);

        List<Question> visees = questions(cible, Module.CIVIQUE, QuestionType.CONNAISSANCE, 3);
        for (int i = 0; i < visees.size(); i++) {
            answer(user, attempt, visees.get(i), false, base.plus(i, ChronoUnit.MINUTES));
        }
        List<Question> bruyantes = questions(bruit, Module.CIVIQUE, QuestionType.CONNAISSANCE,
                MeService.MAX_WRONG_PER_MODULE + 5);
        for (int i = 0; i < bruyantes.size(); i++) {
            answer(user, attempt, bruyantes.get(i), false, base.plus(1, ChronoUnit.HOURS)
                    .plus(i, ChronoUnit.MINUTES));
        }

        List<QuestionPublicResponse> result =
                meService.wrongAnswered(user.getId(), Module.CIVIQUE, null, cible.getId());

        assertThat(result).extracting(QuestionPublicResponse::id)
                .containsExactlyInAnyOrderElementsOf(visees.stream().map(Question::getId).toList());
    }

    /** Règle transverse du projet : un filtre CO inclut CO_IMAGE. */
    @Test
    void filtreCO_inclutCoImage() {
        User user = data.user();
        Theme theme = data.theme(Module.TCF, "wrong-co-img", "TCF CO image");
        Attempt attempt = attempt(user, Module.TCF, EpreuveType.TCF_CO);

        Question co = questions(theme, Module.TCF, QuestionType.CO, 1).get(0);
        Question coImage = questions(theme, Module.TCF, QuestionType.CO_IMAGE, 1).get(0);
        Question ce = questions(theme, Module.TCF, QuestionType.CE, 1).get(0);
        answer(user, attempt, co, false, Instant.now());
        answer(user, attempt, coImage, false, Instant.now());
        answer(user, attempt, ce, false, Instant.now());

        List<QuestionPublicResponse> result =
                meService.wrongAnswered(user.getId(), Module.TCF, QuestionType.CO, null);

        assertThat(result).extracting(QuestionPublicResponse::id)
                .containsExactlyInAnyOrder(co.getId(), coImage.getId());
    }

    /** Le filtre CO_IMAGE reste, lui, strict (on ne remonte pas les CO simples). */
    @Test
    void filtreCoImage_resteStrict() {
        User user = data.user();
        Theme theme = data.theme(Module.TCF, "wrong-co-img-2", "TCF CO image 2");
        Attempt attempt = attempt(user, Module.TCF, EpreuveType.TCF_CO);

        Question co = questions(theme, Module.TCF, QuestionType.CO, 1).get(0);
        Question coImage = questions(theme, Module.TCF, QuestionType.CO_IMAGE, 1).get(0);
        answer(user, attempt, co, false, Instant.now());
        answer(user, attempt, coImage, false, Instant.now());

        List<QuestionPublicResponse> result =
                meService.wrongAnswered(user.getId(), Module.TCF, QuestionType.CO_IMAGE, null);

        assertThat(result).extracting(QuestionPublicResponse::id).containsExactly(coImage.getId());
    }

    @Test
    void plafondToujoursApplique_apresFiltres() {
        User user = data.user();
        Theme theme = data.theme(Module.TCF, "wrong-cap", "TCF plafond");
        Attempt attempt = attempt(user, Module.TCF, EpreuveType.TCF_CE);
        Instant base = Instant.now().minus(5, ChronoUnit.HOURS);

        List<Question> ce = questions(theme, Module.TCF, QuestionType.CE,
                MeService.MAX_WRONG_PER_MODULE + 7);
        for (int i = 0; i < ce.size(); i++) {
            answer(user, attempt, ce.get(i), false, base.plus(i, ChronoUnit.MINUTES));
        }

        assertThat(meService.wrongAnswered(user.getId(), Module.TCF, QuestionType.CE, null))
                .hasSize(MeService.MAX_WRONG_PER_MODULE);
    }

    @Test
    void bonnesReponsesEtAutresUsers_sontExclus() {
        User user = data.user();
        User autre = data.user();
        Theme theme = data.theme(Module.TCF, "wrong-excl", "TCF exclusions");
        Attempt attempt = attempt(user, Module.TCF, EpreuveType.TCF_CE);
        Attempt attemptAutre = attempt(autre, Module.TCF, EpreuveType.TCF_CE);

        Question ratee = questions(theme, Module.TCF, QuestionType.CE, 1).get(0);
        Question reussie = questions(theme, Module.TCF, QuestionType.CE, 1).get(0);
        Question rateeParAutre = questions(theme, Module.TCF, QuestionType.CE, 1).get(0);
        answer(user, attempt, ratee, false, Instant.now());
        answer(user, attempt, reussie, true, Instant.now());
        answer(autre, attemptAutre, rateeParAutre, false, Instant.now());

        assertThat(meService.wrongAnswered(user.getId(), Module.TCF, QuestionType.CE, null))
                .extracting(QuestionPublicResponse::id)
                .containsExactly(ratee.getId());
    }

    // -------------------------------------------------------------------- stats

    /**
     * {@code attemptsTotal} renvoyait le même nombre pour ?module=CIVIQUE et
     * ?module=TCF, à côté de compteurs pourtant filtrés.
     */
    @Test
    void stats_attemptsTotal_estScopeAuModule() {
        User user = data.user();
        attempt(user, Module.CIVIQUE, EpreuveType.CIVIQUE);
        attempt(user, Module.CIVIQUE, EpreuveType.CIVIQUE);
        attempt(user, Module.TCF, EpreuveType.TCF_CO);

        UserStatsResponse civique = meService.stats(user.getId(), Module.CIVIQUE);
        UserStatsResponse tcf = meService.stats(user.getId(), Module.TCF);

        assertThat(civique.attemptsTotal()).isEqualTo(2);
        assertThat(tcf.attemptsTotal()).isEqualTo(1);
    }

    // ------------------------------------------------------------------ fixtures

    private List<Question> questions(Theme theme, Module module, QuestionType type, int count) {
        return java.util.stream.IntStream.range(0, count)
                .mapToObj(i -> {
                    Question q = data.question(theme);
                    q.setModule(module);
                    q.setQuestionType(type);
                    q.setDifficulty(module == Module.TCF ? Difficulty.B1 : Difficulty.CSP);
                    return questionManager.save(q);
                })
                .toList();
    }

    private Attempt attempt(User user, Module module, EpreuveType epreuve) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.TRAINING);
        a.setModule(module);
        a.setEpreuve(epreuve);
        a.setMode(AttemptMode.ENTRAINEMENT);
        a.setStatus(AttemptStatus.EN_COURS);
        a.setStartedAt(Instant.now());
        return attemptManager.save(a);
    }

    private Answer answer(User user, Attempt attempt, Question question, boolean correct, Instant when) {
        AttemptQuestion aq = new AttemptQuestion();
        aq.setAttempt(attempt);
        aq.setQuestion(question);
        aq.setPosition(positionSeq++);
        aq = attemptQuestionManager.save(aq);

        Answer ans = new Answer();
        ans.setAttemptQuestion(aq);
        ans.setUser(user);
        ans.setSelectedChoiceIds(List.<UUID>of());
        ans.setCorrect(correct);
        ans.setAnsweredAt(when);
        return answerManager.save(ans);
    }
}
