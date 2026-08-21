package com.sejourfr.app.service.attempt;

import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.mapper.AttemptMapper;
import com.sejourfr.app.mapper.QuestionMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Abandon et reprise : <b>le temps est la seule autorité</b>.
 *
 * <p>Quitter ne suspend rien. Le candidat qui revient avant l'échéance reprend
 * avec le temps réellement restant ; celui qui revient après retrouve son
 * épreuve close, notée sur les réponses déjà enregistrées. Il n'existe
 * volontairement <b>aucun</b> flux « recommencer une épreuve interrompue ».
 *
 * <p>Unitaire (mocks Mockito) : la clôture tourne en
 * {@code REQUIRES_NEW} en production — donc dans une transaction propre, que
 * les tests d'intégration à rollback ne peuvent pas observer. C'est la logique
 * qui est verrouillée ici ; le refus de soumission hors délai, lui, est aussi
 * couvert de bout en bout par {@code AttemptExpirationIT}.
 */
class AttemptInteractionServiceExpiryTest {

    private static final Instant MAINTENANT = Instant.now();

    private AttemptManager attemptManager;
    private AttemptQuestionManager attemptQuestionManager;
    private AttemptInteractionService service;

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        attemptQuestionManager = mock(AttemptQuestionManager.class);
        AnswerManager answerManager = mock(AnswerManager.class);
        AttemptScoringService scoringService = mock(AttemptScoringService.class);
        AttemptMapper mapper = mock(AttemptMapper.class);

        service = new AttemptInteractionService(
                attemptManager, attemptQuestionManager, answerManager, scoringService, mapper,
                new QuestionMapper());

        when(attemptManager.save(any(Attempt.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    // ------------------------------------------------------------------ fixtures

    /** Session QCM civique démarrée il y a {@code ilYaSecondes}, avec son chrono. */
    private Attempt session(Integer limite, long ilYaSecondes) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        User u = new User();
        u.setId(UUID.randomUUID());
        a.setUser(u);
        a.setType(AttemptType.MOCK_EXAM);
        a.setModule(Module.CIVIQUE);
        a.setEpreuve(EpreuveType.CIVIQUE);
        a.setStatus(AttemptStatus.EN_COURS);
        a.setStartedAt(MAINTENANT.minusSeconds(ilYaSecondes));
        a.setTimeLimitSeconds(limite);
        when(attemptManager.findById(a.getId())).thenReturn(Optional.of(a));
        return a;
    }

    /** Deux questions, la première répondue juste, la seconde restée vide. */
    private void deuxQuestionsDontUneJuste(Attempt attempt) {
        List<AttemptQuestion> aqs = new ArrayList<>();
        aqs.add(question(attempt, true));
        aqs.add(question(attempt, null));
        when(attemptQuestionManager.findByAttemptOrderedByPosition(attempt.getId())).thenReturn(aqs);
    }

    private static AttemptQuestion question(Attempt attempt, Boolean correct) {
        AttemptQuestion aq = new AttemptQuestion();
        aq.setId(UUID.randomUUID());
        aq.setAttempt(attempt);
        Question q = new Question();
        q.setId(UUID.randomUUID());
        Choice c = new Choice();
        c.setId(UUID.randomUUID());
        c.setCorrect(true);
        q.setChoices(new ArrayList<>(List.of(c)));
        aq.setQuestion(q);
        if (correct != null) {
            Answer a = new Answer();
            a.setCorrect(correct);
            aq.setAnswer(a);
        }
        return aq;
    }

    // ------------------------------------------------------------------ clôture

    @Test
    @DisplayName("Revenir apres l'echeance : l'epreuve est close avec ce qui etait enregistre")
    void clotureAutomatiqueAvecLesReponsesExistantes() {
        Attempt a = session(20 * 60, 20 * 60 + 120);
        deuxQuestionsDontUneJuste(a);

        assertThat(service.closeIfExpired(a.getId())).isTrue();

        assertThat(a.getFinishedAt()).isNotNull();
        assertThat(a.getStatus()).isEqualTo(AttemptStatus.TERMINE);
        assertThat(a.getScore()).isEqualTo(1);
    }

    @Test
    @DisplayName("Revenir avant l'echeance : rien n'est cloture, le temps restant est reel")
    void aucuneClotureAvantLecheance() {
        Attempt a = session(20 * 60, 10 * 60);
        deuxQuestionsDontUneJuste(a);

        assertThat(service.closeIfExpired(a.getId())).isFalse();
        assertThat(a.getFinishedAt()).isNull();
    }

    @Test
    @DisplayName("La grace de 60 s protege l'auto-soumission de 0:00")
    void graceAvantCloture() {
        Attempt a = session(20 * 60, 20 * 60 + 30);
        deuxQuestionsDontUneJuste(a);

        assertThat(service.closeIfExpired(a.getId())).isFalse();
    }

    @Test
    @DisplayName("Une session sans chrono n'est jamais cloturee")
    void sansChronoJamaisCloture() {
        Attempt a = session(null, 90 * 24 * 3600);

        assertThat(service.closeIfExpired(a.getId())).isFalse();
        assertThat(a.getFinishedAt()).isNull();
    }

    @Test
    @DisplayName("Idempotent : une session deja terminee n'est pas retouchee")
    void idempotent() {
        Attempt a = session(20 * 60, 20 * 60 + 600);
        Instant fin = MAINTENANT.minusSeconds(300);
        a.setFinishedAt(fin);
        a.setStatus(AttemptStatus.TERMINE);

        assertThat(service.closeIfExpired(a.getId())).isFalse();
        assertThat(a.getFinishedAt()).isEqualTo(fin);
    }

    @Test
    @DisplayName("Attempt inconnu ou id nul : sans effet")
    void inconnuSansEffet() {
        when(attemptManager.findById(any())).thenReturn(Optional.empty());

        assertThat(service.closeIfExpired(UUID.randomUUID())).isFalse();
        assertThat(service.closeIfExpired(null)).isFalse();
        assertThat(service.closeExpiredSubAttempts(null)).isZero();
    }

    @Test
    @DisplayName("Une sous-epreuve d'examen complet PAS ENCORE LANCEE n'expire jamais")
    void sousEpreuveNonLanceeJamaisCloturee() {
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        parent.setEpreuve(EpreuveType.TCF_COMPLET);

        Attempt ce = session(35 * 60, 3 * 3600);
        ce.setEpreuve(EpreuveType.TCF_CE);
        ce.setModule(Module.TCF);
        ce.setParentAttempt(parent);
        when(attemptManager.findSubAttempts(parent.getId())).thenReturn(List.of(ce));

        // Les 4 sous-attempts sont créés d'un bloc : sans cette règle, la CE
        // aurait expiré pendant que le candidat passait la CO.
        assertThat(service.closeExpiredSubAttempts(parent.getId())).isZero();
        assertThat(ce.getFinishedAt()).isNull();
    }

    @Test
    @DisplayName("Une sous-epreuve LANCEE puis abandonnee est cloturee")
    void sousEpreuveLanceeExpire() {
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        parent.setEpreuve(EpreuveType.TCF_COMPLET);

        Attempt ce = session(35 * 60, 3 * 3600);
        ce.setEpreuve(EpreuveType.TCF_CE);
        ce.setModule(Module.CIVIQUE); // évite la branche de scoring TCF, hors sujet ici
        ce.setParentAttempt(parent);
        ce.setTimerStartedAt(MAINTENANT.minusSeconds(35 * 60 + 120));
        deuxQuestionsDontUneJuste(ce);
        when(attemptManager.findSubAttempts(parent.getId())).thenReturn(List.of(ce));

        assertThat(service.closeExpiredSubAttempts(parent.getId())).isEqualTo(1);
        assertThat(ce.getStatus()).isEqualTo(AttemptStatus.TERMINE);
    }

    // ------------------------------------------------------------------ refus

    @Test
    @DisplayName("Une reponse hors delai est refusee — sans faire echouer le runner")
    void reponseHorsDelaiRefusee() {
        Attempt a = session(20 * 60, 20 * 60 + 120);
        AttemptQuestion aq = question(a, null);
        when(attemptQuestionManager.findById(aq.getId())).thenReturn(Optional.of(aq));

        assertThatThrownBy(() -> service.submitAnswerForAttempt(
                a, new SubmitAnswerRequest(aq.getId(), List.of())))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("écoulé")
                // Message actionnable : le candidat doit comprendre que ses
                // réponses précédentes ne sont pas perdues.
                .hasMessageContaining("conservées");
    }

    @Test
    @DisplayName("Une reponse dans la grace passe encore")
    void reponseDansLaGraceAcceptee() {
        Attempt a = session(20 * 60, 20 * 60 + 30);
        AttemptQuestion aq = question(a, null);
        when(attemptQuestionManager.findById(aq.getId())).thenReturn(Optional.of(aq));

        assertThatCode(() -> service.submitAnswerForAttempt(
                a, new SubmitAnswerRequest(aq.getId(), List.of())))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("Un entrainement libre (sans chrono) n'est jamais refuse")
    void entrainementLibreJamaisRefuse() {
        Attempt a = session(null, 30 * 24 * 3600);
        a.setType(AttemptType.TRAINING);
        AttemptQuestion aq = question(a, null);
        when(attemptQuestionManager.findById(aq.getId())).thenReturn(Optional.of(aq));

        assertThatCode(() -> service.submitAnswerForAttempt(
                a, new SubmitAnswerRequest(aq.getId(), List.of())))
                .doesNotThrowAnyException();
    }
}
