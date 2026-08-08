package com.sejourfr.app.service;

import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserQuestionStatusManager;
import com.sejourfr.app.mapper.QuestionMapper;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Test unitaire pur de /api/me : profil (target procedure), stats agrégées,
 * favoris (create-on-demand), revue (garde-fou 403 si jamais tentée ni
 * favorite). Collaborateurs mockés ; aucune DB.
 */
class MeServiceTest {

    private AnswerManager answerManager;
    private AttemptManager attemptManager;
    private UserQuestionStatusManager statusManager;
    private QuestionManager questionManager;
    private UserManager userManager;
    private QuestionMapper questionMapper;
    private MeService service;

    @BeforeEach
    void setUp() {
        answerManager = mock(AnswerManager.class);
        attemptManager = mock(AttemptManager.class);
        statusManager = mock(UserQuestionStatusManager.class);
        questionManager = mock(QuestionManager.class);
        userManager = mock(UserManager.class);
        questionMapper = mock(QuestionMapper.class);
        ThemeManager themeManager = mock(ThemeManager.class);
        AiEvaluationManager aiEvaluationManager = mock(AiEvaluationManager.class);
        FullTcfExamService fullTcfExamService = mock(FullTcfExamService.class);
        service = new MeService(answerManager, attemptManager, statusManager, questionManager,
                userManager, questionMapper, themeManager, aiEvaluationManager, fullTcfExamService);
    }

    private static User user() {
        User u = new User();
        u.setId(UUID.randomUUID());
        return u;
    }

    // ------------------------------------------------------------------ profil

    /**
     * SEUL point d'écriture de {@code users.target_procedure} — donc le seul
     * endroit où les deux colonnes pouvaient se désynchroniser. Le serveur pose
     * lui-même le palier exigé : aucun couple contradictoire ne peut plus être
     * persisté par cette voie.
     */
    @Test
    void updateTargetProcedure_poseAussiLePalierExige() {
        User u = user();
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));

        service.updateTargetProcedure(u.getId(), TargetProcedure.NAT);

        assertThat(u.getTargetProcedure()).isEqualTo(TargetProcedure.NAT);
        assertThat(u.getTargetLevel()).isEqualTo(TargetLevel.B2);
        verify(userManager).save(u);
    }

    /** Changer de démarche recalcule le palier : on ne laisse pas l'ancien. */
    @Test
    void updateTargetProcedure_changerDeDemarcheRecalculeLePalier() {
        User u = user();
        u.setTargetProcedure(TargetProcedure.NAT);
        u.setTargetLevel(TargetLevel.B2);
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));

        service.updateTargetProcedure(u.getId(), TargetProcedure.CSP);

        assertThat(u.getTargetLevel()).isEqualTo(TargetLevel.A2);
    }

    /** Une ligne héritée incohérente est remise d'équerre au premier passage. */
    @Test
    void updateTargetProcedure_repareUnCoupleIncoherentHerite() {
        User u = user();
        u.setTargetProcedure(TargetProcedure.NAT);
        u.setTargetLevel(TargetLevel.B1);
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));

        service.updateTargetProcedure(u.getId(), TargetProcedure.NAT);

        assertThat(u.getTargetLevel()).isEqualTo(TargetLevel.B2);
    }

    @Test
    void updateTargetProcedure_userNotFound_throws() {
        UUID id = UUID.randomUUID();
        when(userManager.findById(id)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.updateTargetProcedure(id, TargetProcedure.CSP))
                .isInstanceOf(EntityNotFoundException.class);
    }

    // ------------------------------------------------------------------ stats

    @Test
    void stats_computesSuccessRateAndByTheme() {
        UUID userId = UUID.randomUUID();
        UUID themeId = UUID.randomUUID();
        when(attemptManager.countByUserIdAndModule(userId, Module.CIVIQUE)).thenReturn(4L);
        when(answerManager.countAnsweredByUserAndModule(userId, Module.CIVIQUE)).thenReturn(10L);
        when(answerManager.countCorrectByUserAndModule(userId, Module.CIVIQUE)).thenReturn(7L);
        when(answerManager.aggregateByTheme(userId, Module.CIVIQUE)).thenReturn(List.<Object[]>of(
                new Object[]{themeId, "CIV_X", "Thème X", 5, 3}));
        when(questionManager.countActiveByTheme(themeId)).thenReturn(20L);

        UserStatsResponse resp = service.stats(userId, Module.CIVIQUE);

        assertThat(resp.attemptsTotal()).isEqualTo(4);
        assertThat(resp.questionsAnswered()).isEqualTo(10);
        assertThat(resp.questionsCorrect()).isEqualTo(7);
        assertThat(resp.successRate()).isEqualTo(0.7);
        assertThat(resp.byTheme()).hasSize(1);
        UserStatsResponse.ThemeStatsResponse ts = resp.byTheme().get(0);
        assertThat(ts.themeId()).isEqualTo(themeId);
        assertThat(ts.answered()).isEqualTo(5);
        assertThat(ts.correct()).isEqualTo(3);
        assertThat(ts.total()).isEqualTo(20);
    }

    @Test
    void stats_zeroAnswered_rateIsZero() {
        UUID userId = UUID.randomUUID();
        when(attemptManager.countByUserIdAndModule(userId, Module.TCF)).thenReturn(0L);
        when(answerManager.countAnsweredByUserAndModule(userId, Module.TCF)).thenReturn(0L);
        when(answerManager.countCorrectByUserAndModule(userId, Module.TCF)).thenReturn(0L);
        when(answerManager.aggregateByTheme(userId, Module.TCF)).thenReturn(List.of());

        assertThat(service.stats(userId, Module.TCF).successRate()).isEqualTo(0.0);
    }

    // ------------------------------------------------------------------ favoris

    @Test
    void addFavorite_existingStatus_setsFavoriteTrue() {
        UUID userId = UUID.randomUUID();
        UUID qId = UUID.randomUUID();
        UserQuestionStatus existing = new UserQuestionStatus();
        existing.setFavorite(false);
        when(statusManager.findByUserIdAndQuestionId(userId, qId)).thenReturn(Optional.of(existing));

        service.addFavorite(userId, qId);

        assertThat(existing.isFavorite()).isTrue();
        verify(statusManager).save(existing);
    }

    @Test
    void addFavorite_noStatus_createsNewFavorite() {
        UUID userId = UUID.randomUUID();
        UUID qId = UUID.randomUUID();
        when(statusManager.findByUserIdAndQuestionId(userId, qId)).thenReturn(Optional.empty());
        when(userManager.findById(userId)).thenReturn(Optional.of(user()));
        when(questionManager.findById(qId)).thenReturn(Optional.of(new Question()));

        service.addFavorite(userId, qId);

        org.mockito.ArgumentCaptor<UserQuestionStatus> captor =
                org.mockito.ArgumentCaptor.forClass(UserQuestionStatus.class);
        verify(statusManager).save(captor.capture());
        assertThat(captor.getValue().isFavorite()).isTrue();
    }

    @Test
    void removeFavorite_absent_isNoop() {
        UUID userId = UUID.randomUUID();
        UUID qId = UUID.randomUUID();
        when(statusManager.findByUserIdAndQuestionId(userId, qId)).thenReturn(Optional.empty());

        service.removeFavorite(userId, qId);

        verify(statusManager, never()).save(any());
    }

    @Test
    void favorites_empty_returnsEmptyWithoutHittingQuestions() {
        UUID userId = UUID.randomUUID();
        when(statusManager.findFavoriteQuestionIds(userId, Module.CIVIQUE)).thenReturn(List.of());

        assertThat(service.favorites(userId, Module.CIVIQUE)).isEmpty();
        verify(questionManager, never()).findAllById(any());
    }

    @Test
    void favorites_nonEmpty_mapsEachQuestion() {
        UUID userId = UUID.randomUUID();
        UUID qId = UUID.randomUUID();
        Question q = new Question();
        q.setId(qId);
        when(statusManager.findFavoriteQuestionIds(userId, Module.CIVIQUE)).thenReturn(List.of(qId));
        when(questionManager.findAllById(List.of(qId))).thenReturn(List.of(q));
        QuestionPublicResponse mapped = mock(QuestionPublicResponse.class);
        when(questionMapper.toPublic(eq(q), anyBoolean(), any())).thenReturn(mapped);

        assertThat(service.favorites(userId, Module.CIVIQUE)).containsExactly(mapped);
    }

    // ------------------------------------------------------------------ erreurs

    @Test
    void wrongAnswered_empty_returnsEmpty() {
        UUID userId = UUID.randomUUID();
        when(answerManager.findRecentWrongQuestionIds(eq(userId), eq(Module.CIVIQUE), any(), any(), anyInt()))
                .thenReturn(List.of());

        assertThat(service.wrongAnswered(userId, Module.CIVIQUE, null, null)).isEmpty();
    }

    /**
     * Le filtrage descend dans la requête (module / type / thème) : le service
     * ne doit RIEN re-filtrer en mémoire, sinon le plafond de 30 s'appliquerait
     * avant les filtres. Le comportement réel du filtre est verrouillé par
     * {@code MeServiceWrongAnsweredIT} (vraie DB).
     */
    @Test
    void wrongAnswered_passesFiltersToTheQuery_andKeepsQueryOrder() {
        UUID userId = UUID.randomUUID();
        UUID themeId = UUID.randomUUID();
        UUID firstId = UUID.randomUUID();
        UUID secondId = UUID.randomUUID();
        Question first = new Question();
        first.setId(firstId);
        Question second = new Question();
        second.setId(secondId);
        when(answerManager.findRecentWrongQuestionIds(
                userId, Module.TCF, QuestionType.CO, themeId, MeService.MAX_WRONG_PER_MODULE))
                .thenReturn(List.of(firstId, secondId));
        // findAllById ne préserve pas l'ordre : on le rend inversé exprès.
        when(questionManager.findAllById(List.of(firstId, secondId)))
                .thenReturn(List.of(second, first));
        QuestionPublicResponse mappedFirst = mock(QuestionPublicResponse.class);
        QuestionPublicResponse mappedSecond = mock(QuestionPublicResponse.class);
        when(questionMapper.toPublic(eq(first), anyBoolean(), any())).thenReturn(mappedFirst);
        when(questionMapper.toPublic(eq(second), anyBoolean(), any())).thenReturn(mappedSecond);

        List<QuestionPublicResponse> result =
                service.wrongAnswered(userId, Module.TCF, QuestionType.CO, themeId);

        assertThat(result).containsExactly(mappedFirst, mappedSecond);
        verify(answerManager).findRecentWrongQuestionIds(
                userId, Module.TCF, QuestionType.CO, themeId, MeService.MAX_WRONG_PER_MODULE);
    }

    // ------------------------------------------------------------------ revue

    @Test
    void review_notAnsweredNorFavorited_throwsForbidden() {
        UUID userId = UUID.randomUUID();
        UUID qId = UUID.randomUUID();
        when(questionManager.findById(qId)).thenReturn(Optional.of(new Question()));
        when(answerManager.hasUserAnsweredQuestion(userId, qId)).thenReturn(false);
        when(statusManager.findByUserIdAndQuestionId(userId, qId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.review(userId, qId))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void review_answered_returnsMappedReview() {
        UUID userId = UUID.randomUUID();
        UUID qId = UUID.randomUUID();
        Question q = new Question();
        when(questionManager.findById(qId)).thenReturn(Optional.of(q));
        when(answerManager.hasUserAnsweredQuestion(userId, qId)).thenReturn(true);
        when(answerManager.findLatestSelectedChoiceIds(userId, qId)).thenReturn(List.of());
        QuestionReviewResponse review = mock(QuestionReviewResponse.class);
        when(questionMapper.toReview(eq(q), any())).thenReturn(review);

        assertThat(service.review(userId, qId)).isSameAs(review);
    }

    @Test
    void review_questionNotFound_throws() {
        UUID userId = UUID.randomUUID();
        UUID qId = UUID.randomUUID();
        when(questionManager.findById(qId)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.review(userId, qId))
                .isInstanceOf(EntityNotFoundException.class);
    }
}
