package com.sejourfr.app.specification;

import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.MessageStatus;
import com.sejourfr.app.repository.ConversationRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle (Postgres embarqué) de {@link ConversationSpecifications}.
 * Les prédicats sont exercés via {@code findAll(spec)} pour valider le SQL
 * généré. Combinaison via {@link Specification#allOf} comme le fait
 * {@code ConversationService}. La table {@code conversations} n'est pas seedée
 * par Flyway → assertions exactes possibles (seules les lignes du test existent
 * dans la transaction rollbackée).
 */
class ConversationSpecificationsIT extends AbstractIntegrationTest {

    @Autowired
    private ConversationRepository repository;

    @Autowired
    private TestData testData;

    private Conversation conv(User user, MessageStatus status, boolean unread, String subject) {
        Conversation c = testData.conversation(user);
        c.setStatus(status);
        c.setUnreadForAdmin(unread);
        c.setSubject(subject);
        return repository.save(c);
    }

    @Test
    void hasStatusFiltersByStatus() {
        User u = testData.user();
        Conversation nouveau = conv(u, MessageStatus.NOUVEAU, true, "A");
        Conversation repondu = conv(u, MessageStatus.REPONDU, false, "B");

        List<Conversation> found = repository.findAll(
                ConversationSpecifications.hasStatus(MessageStatus.REPONDU));

        assertThat(found).extracting(Conversation::getId)
                .contains(repondu.getId())
                .doesNotContain(nouveau.getId());
    }

    @Test
    void hasStatusNullMatchesAll() {
        User u = testData.user();
        Conversation a = conv(u, MessageStatus.NOUVEAU, true, "A");
        Conversation b = conv(u, MessageStatus.ARCHIVE, false, "B");

        List<Conversation> found = repository.findAll(
                ConversationSpecifications.hasStatus(null));

        assertThat(found).extracting(Conversation::getId).contains(a.getId(), b.getId());
    }

    @Test
    void unreadOnlyTrueKeepsOnlyUnreadForAdmin() {
        User u = testData.user();
        Conversation unread = conv(u, MessageStatus.NOUVEAU, true, "A");
        Conversation read = conv(u, MessageStatus.LU, false, "B");

        List<Conversation> found = repository.findAll(
                ConversationSpecifications.unreadOnly(true));

        assertThat(found).extracting(Conversation::getId)
                .contains(unread.getId())
                .doesNotContain(read.getId());
    }

    @Test
    void unreadOnlyFalseOrNullAddsNoPredicate() {
        User u = testData.user();
        Conversation unread = conv(u, MessageStatus.NOUVEAU, true, "A");
        Conversation read = conv(u, MessageStatus.LU, false, "B");

        assertThat(repository.findAll(ConversationSpecifications.unreadOnly(false)))
                .extracting(Conversation::getId).contains(unread.getId(), read.getId());
        assertThat(repository.findAll(ConversationSpecifications.unreadOnly(null)))
                .extracting(Conversation::getId).contains(unread.getId(), read.getId());
    }

    @Test
    void hasUserFiltersByUserId() {
        User u1 = testData.user();
        User u2 = testData.user();
        Conversation c1 = conv(u1, MessageStatus.NOUVEAU, true, "A");
        Conversation c2 = conv(u2, MessageStatus.NOUVEAU, true, "B");

        List<Conversation> found = repository.findAll(
                ConversationSpecifications.hasUser(u1.getId()));

        assertThat(found).extracting(Conversation::getId)
                .contains(c1.getId())
                .doesNotContain(c2.getId());
    }

    @Test
    void hasUserNullMatchesAll() {
        User u1 = testData.user();
        User u2 = testData.user();
        Conversation c1 = conv(u1, MessageStatus.NOUVEAU, true, "A");
        Conversation c2 = conv(u2, MessageStatus.NOUVEAU, true, "B");

        List<Conversation> found = repository.findAll(
                ConversationSpecifications.hasUser(null));

        assertThat(found).extracting(Conversation::getId).contains(c1.getId(), c2.getId());
    }

    @Test
    void subjectContainsIsCaseInsensitiveAndNullOrBlankAddsNoPredicate() {
        User u = testData.user();
        Conversation match = conv(u, MessageStatus.NOUVEAU, true, "Probleme FACTURE urgente");
        Conversation other = conv(u, MessageStatus.NOUVEAU, true, "Question sur le quiz");

        // case-insensitive sur un sujet en majuscules
        assertThat(repository.findAll(ConversationSpecifications.subjectContains("facture")))
                .extracting(Conversation::getId)
                .contains(match.getId())
                .doesNotContain(other.getId());
        // blank / null → pas de prédicat → tout
        assertThat(repository.findAll(ConversationSpecifications.subjectContains("  ")))
                .extracting(Conversation::getId).contains(match.getId(), other.getId());
        assertThat(repository.findAll(ConversationSpecifications.subjectContains(null)))
                .extracting(Conversation::getId).contains(match.getId(), other.getId());
    }

    @Test
    void allOfCombinesAllFiltersLikeService() {
        User target = testData.user();
        User otherUser = testData.user();
        String token = "needle-" + System.nanoTime();

        Conversation hit = conv(target, MessageStatus.EN_COURS, true, "Sujet " + token);
        // chaque near-miss diffère par exactement un critère
        Conversation wrongStatus = conv(target, MessageStatus.REPONDU, true, "Sujet " + token);
        Conversation read = conv(target, MessageStatus.EN_COURS, false, "Sujet " + token);
        Conversation wrongUser = conv(otherUser, MessageStatus.EN_COURS, true, "Sujet " + token);
        Conversation wrongSubject = conv(target, MessageStatus.EN_COURS, true, "Sans marqueur");

        Specification<Conversation> spec = Specification.allOf(
                ConversationSpecifications.hasStatus(MessageStatus.EN_COURS),
                ConversationSpecifications.unreadOnly(true),
                ConversationSpecifications.hasUser(target.getId()),
                ConversationSpecifications.subjectContains(token));

        List<Conversation> found = repository.findAll(spec);

        assertThat(found).extracting(Conversation::getId)
                .containsExactly(hit.getId())
                .doesNotContain(wrongStatus.getId(), read.getId(),
                        wrongUser.getId(), wrongSubject.getId());
    }
}
