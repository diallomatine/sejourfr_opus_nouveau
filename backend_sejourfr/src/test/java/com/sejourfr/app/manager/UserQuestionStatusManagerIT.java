package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.UserQuestionStatusRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Intégration réelle pour {@link UserQuestionStatusManager} : finders par
 * (user, question), filtre favoris / module, upsert, purge et contrainte
 * d'unicité (user_id, question_id).
 */
class UserQuestionStatusManagerIT extends AbstractIntegrationTest {

    @Autowired
    private UserQuestionStatusManager manager;

    @Autowired
    private UserQuestionStatusRepository repository;

    @Autowired
    private TestData testData;

    @Test
    void findByUserIdAndQuestionIdSelectsMatchingRow() {
        User user = testData.user();
        Question question = testData.question();
        UserQuestionStatus saved = testData.userQuestionStatus(user, question);

        // Ligne concurrente (autre user, autre question) qui ne doit pas matcher.
        testData.userQuestionStatus();

        Optional<UserQuestionStatus> found =
                manager.findByUserIdAndQuestionId(user.getId(), question.getId());
        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(saved.getId());
        assertThat(found.get().isFavorite()).isTrue();

        assertThat(manager.findByUserIdAndQuestionId(user.getId(), UUID.randomUUID()))
                .isEmpty();
        assertThat(manager.findByUserIdAndQuestionId(UUID.randomUUID(), question.getId()))
                .isEmpty();
    }

    @Test
    void findFavoriteQuestionIdsFiltersOnFavoriteAndModule() {
        User user = testData.user();
        Question favorite = testData.question();            // module CIVIQUE
        testData.userQuestionStatus(user, favorite);        // favorite = true

        // Statut non-favori : exclu du résultat.
        Question other = testData.question();
        UserQuestionStatus notFav = new UserQuestionStatus();
        notFav.setUser(user);
        notFav.setQuestion(other);
        notFav.setFavorite(false);
        manager.save(notFav);

        // module null = tous modules confondus.
        assertThat(manager.findFavoriteQuestionIds(user.getId(), null))
                .containsExactly(favorite.getId());
        // module CIVIQUE = la question favorite (CIVIQUE).
        assertThat(manager.findFavoriteQuestionIds(user.getId(), Module.CIVIQUE))
                .containsExactly(favorite.getId());
        // module TCF = aucune (la favorite est CIVIQUE).
        assertThat(manager.findFavoriteQuestionIds(user.getId(), Module.TCF))
                .isEmpty();
    }

    @Test
    void saveUpdatesExistingRow() {
        User user = testData.user();
        Question question = testData.question();
        UserQuestionStatus saved = testData.userQuestionStatus(user, question);
        UUID id = saved.getId();

        saved.setFavorite(false);
        saved.setCorrectCount(9);
        UserQuestionStatus updated = manager.save(saved);

        assertThat(updated.getId()).isEqualTo(id);
        Optional<UserQuestionStatus> reloaded =
                manager.findByUserIdAndQuestionId(user.getId(), question.getId());
        assertThat(reloaded).isPresent();
        assertThat(reloaded.get().getId()).isEqualTo(id);
        assertThat(reloaded.get().isFavorite()).isFalse();
        assertThat(reloaded.get().getCorrectCount()).isEqualTo(9);
    }

    @Test
    void deleteByUserIdRemovesOnlyTargetUserRows() {
        User user = testData.user();
        testData.userQuestionStatus(user, testData.question());
        testData.userQuestionStatus(user, testData.question());

        User otherUser = testData.user();
        Question otherQuestion = testData.question();
        testData.userQuestionStatus(otherUser, otherQuestion);

        int deleted = manager.deleteByUserId(user.getId());
        assertThat(deleted).isEqualTo(2);

        assertThat(manager.findFavoriteQuestionIds(user.getId(), null)).isEmpty();
        assertThat(manager.findByUserIdAndQuestionId(otherUser.getId(), otherQuestion.getId()))
                .isPresent();
    }

    @Test
    void duplicateUserQuestionViolatesUniqueConstraint() {
        User user = testData.user();
        Question question = testData.question();
        testData.userQuestionStatus(user, question);

        UserQuestionStatus dup = new UserQuestionStatus();
        dup.setUser(user);
        dup.setQuestion(question);
        dup.setFavorite(true);

        assertThatThrownBy(() -> repository.saveAndFlush(dup))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void findFavoriteQuestionIdsIsScopedToUser() {
        User user = testData.user();
        testData.userQuestionStatus(user, testData.question());

        List<UUID> otherUserFavorites =
                manager.findFavoriteQuestionIds(testData.user().getId(), null);
        assertThat(otherUserFavorites).isEmpty();
    }
}
