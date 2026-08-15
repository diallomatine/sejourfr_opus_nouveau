package com.sejourfr.app.service;

import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Le chrono d'un examen blanc QCM est <b>opposable serveur</b>, de bout en
 * bout.
 *
 * <p>{@code attempts.time_limit_seconds} n'était lu que par les fronts : rien
 * n'empêchait de répondre après l'échéance — un simple appel HTTP direct, ou
 * un onglet laissé ouvert, et l'examen blanc n'avait plus de limite. Les
 * productions EE/EO étaient protégées depuis toujours ; les QCM ne l'étaient
 * pas.
 */
class AttemptExpirationIT extends AbstractIntegrationTest {

    @Autowired AttemptService service;
    @Autowired AttemptManager attemptManager;
    @Autowired AttemptQuestionManager attemptQuestionManager;
    @Autowired TestData data;

    /** Examen civique de thème (20 Q / 20 min), démarré puis reculé dans le passé. */
    private Attempt examenDemarreIlYa(User user, Theme theme, long secondes) {
        var req = new StartAttemptRequest(AttemptType.MOCK_EXAM, Module.CIVIQUE, null,
                theme.getId(), null, null, null, null, null, 1);
        UUID id = service.start(user.getId(), req).id();
        Attempt a = attemptManager.findById(id).orElseThrow();
        a.setStartedAt(Instant.now().minusSeconds(secondes));
        return attemptManager.save(a);
    }

    private AttemptQuestion premiereQuestion(Attempt a) {
        return attemptQuestionManager.findByAttemptOrderedByPosition(a.getId()).get(0);
    }

    private static UUID unChoix(AttemptQuestion aq) {
        return aq.getQuestion().getChoices().stream()
                .filter(Choice::isCorrect).map(Choice::getId).findFirst().orElseThrow();
    }

    private Theme themeAvecQuestions() {
        Theme theme = data.theme(Module.CIVIQUE, "exp-" + System.nanoTime(), "Expiration");
        for (int i = 0; i < 25; i++) {
            data.question(theme);
        }
        return theme;
    }

    @Test
    @DisplayName("Repondre apres l'echeance est refuse")
    void reponseHorsDelaiRefusee() {
        User user = data.user();
        Theme theme = themeAvecQuestions();
        Attempt a = examenDemarreIlYa(user, theme, 20 * 60 + 300);
        AttemptQuestion aq = premiereQuestion(a);

        assertThatThrownBy(() -> service.submitAnswer(user.getId(), a.getId(),
                new SubmitAnswerRequest(aq.getId(), List.of(unChoix(aq)))))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("écoulé");
    }

    @Test
    @DisplayName("La grace de 60 s couvre l'auto-soumission declenchee a 0:00")
    void reponseDansLaGraceAcceptee() {
        User user = data.user();
        Theme theme = themeAvecQuestions();
        Attempt a = examenDemarreIlYa(
                user, theme, 20 * 60 + DureeEpreuve.GRACE_SOUMISSION_SECONDS - 10);
        AttemptQuestion aq = premiereQuestion(a);

        assertThatCode(() -> service.submitAnswer(user.getId(), a.getId(),
                new SubmitAnswerRequest(aq.getId(), List.of(unChoix(aq)))))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("Les reponses deja enregistrees survivent au refus")
    void reponsesAnterieuresConservees() {
        User user = data.user();
        Theme theme = themeAvecQuestions();
        // Dans les temps : une réponse passe.
        Attempt a = examenDemarreIlYa(user, theme, 60);
        AttemptQuestion premiere = premiereQuestion(a);
        service.submitAnswer(user.getId(), a.getId(),
                new SubmitAnswerRequest(premiere.getId(), List.of(unChoix(premiere))));

        // Le candidat s'absente : le temps continue de courir.
        a.setStartedAt(Instant.now().minusSeconds(20 * 60 + 300));
        attemptManager.save(a);
        AttemptQuestion seconde = attemptQuestionManager
                .findByAttemptOrderedByPosition(a.getId()).get(1);

        assertThatThrownBy(() -> service.submitAnswer(user.getId(), a.getId(),
                new SubmitAnswerRequest(seconde.getId(), List.of(unChoix(seconde)))))
                .isInstanceOf(BusinessException.class);

        // Le refus porte sur UNE réponse : il ne fait pas échouer la session.
        assertThat(attemptQuestionManager.findByAttemptOrderedByPosition(a.getId()).get(0)
                .getAnswer()).isNotNull();
    }

    @Test
    @DisplayName("Un entrainement libre n'a pas de chrono, donc jamais de refus")
    void entrainementLibreJamaisRefuse() {
        User user = data.user();
        data.userSubscription(user, data.plan());
        Theme theme = themeAvecQuestions();
        var req = new StartAttemptRequest(AttemptType.TRAINING, Module.CIVIQUE, null,
                theme.getId(), null, null, 5, null, null, null);
        Attempt a = attemptManager.findById(service.start(user.getId(), req).id()).orElseThrow();
        a.setStartedAt(Instant.now().minusSeconds(30L * 24 * 3600));
        attemptManager.save(a);
        AttemptQuestion aq = premiereQuestion(a);

        assertThat(a.getTimeLimitSeconds()).isNull();
        assertThatCode(() -> service.submitAnswer(user.getId(), a.getId(),
                new SubmitAnswerRequest(aq.getId(), List.of(unChoix(aq)))))
                .doesNotThrowAnyException();
    }
}
