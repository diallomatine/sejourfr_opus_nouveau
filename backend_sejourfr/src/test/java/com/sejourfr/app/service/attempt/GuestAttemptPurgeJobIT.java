package com.sejourfr.app.service.attempt;

import com.sejourfr.app.config.GuestAttemptPurgeProperties;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Purge des attempts invités : ce qu'elle supprime, ce qu'elle épargne, et
 * surtout ce qu'elle ne peut <b>jamais</b> toucher (un attempt de compte).
 *
 * <p>Le drapeau est remis à sa valeur de production ({@code false}) avant
 * chaque test : le comportement livré est « rien ne se passe », et un test qui
 * purge doit l'activer explicitement.
 */
class GuestAttemptPurgeJobIT extends AbstractIntegrationTest {

    @Autowired GuestAttemptPurgeJob job;
    @Autowired GuestAttemptPurgeProperties properties;
    @Autowired AttemptManager attemptManager;
    @Autowired AttemptQuestionManager attemptQuestionManager;
    @Autowired TestData data;
    @Autowired EntityManager em;

    /**
     * Le POJO est un singleton partagé par le contexte Spring mis en cache :
     * on le remet aux valeurs de production avant ET après chaque test, sinon
     * une classe de test voisine hériterait d'une purge activée.
     */
    @BeforeEach
    @AfterEach
    void resetFlag() {
        properties.setEnabled(false);
        properties.setRetention(Duration.ofHours(2));
        properties.setBatchSize(500);
    }

    private UUID guestAttempt(Instant startedAt) {
        Attempt a = new Attempt();
        a.setClientIp("198.51.100.7");
        a.setType(AttemptType.TRAINING);
        a.setModule(Module.CIVIQUE);
        a.setTotalQuestions(0);
        a.setStartedAt(startedAt);
        UUID id = attemptManager.save(a).getId();
        em.flush();
        return id;
    }

    private UUID userAttempt(User user, Instant startedAt) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.TRAINING);
        a.setModule(Module.CIVIQUE);
        a.setTotalQuestions(0);
        a.setStartedAt(startedAt);
        UUID id = attemptManager.save(a).getId();
        em.flush();
        return id;
    }

    private static Instant hoursAgo(int hours) {
        return Instant.now().minus(Duration.ofHours(hours));
    }

    /**
     * Lance la passe puis vide le contexte de persistance : un DELETE en masse
     * (JPQL) ne notifie pas les entités déjà chargées — sans ce {@code clear},
     * un {@code findById} rendrait l'instance en cache et le test mentirait.
     */
    private int purge() {
        int purged = job.purgeExpiredGuestAttempts();
        em.clear();
        return purged;
    }

    private boolean exists(UUID attemptId) {
        return attemptManager.findById(attemptId).isPresent();
    }

    @Test
    void drapeauEteintParDefaut_rienNEstSupprime() {
        assertThat(properties.isEnabled()).isFalse();
        UUID vieux = guestAttempt(hoursAgo(48));

        assertThat(purge()).isZero();
        assertThat(exists(vieux)).isTrue();
    }

    @Test
    void active_supprimeLesInvitesAuDelaDuDelai() {
        properties.setEnabled(true);
        UUID vieux = guestAttempt(hoursAgo(3));

        assertThat(purge()).isGreaterThanOrEqualTo(1);
        assertThat(exists(vieux)).isFalse();
    }

    @Test
    void active_epargneUnInviteRecent() {
        properties.setEnabled(true);
        UUID recent = guestAttempt(hoursAgo(1));

        purge();

        assertThat(exists(recent)).isTrue();
    }

    @Test
    void active_uneSessionNonTermineeEstPurgeeSurStartedAt() {
        properties.setEnabled(true);
        UUID abandonne = guestAttempt(hoursAgo(5));
        assertThat(attemptManager.findById(abandonne).orElseThrow().getFinishedAt()).isNull();

        purge();

        assertThat(exists(abandonne)).isFalse();
    }

    @Test
    void active_neTouchePasUnAttemptDeCompte_memeTresAncien() {
        properties.setEnabled(true);
        User user = data.user();
        UUID duCompte = userAttempt(user, hoursAgo(24 * 365));
        UUID invite = guestAttempt(hoursAgo(24 * 365));

        purge();

        assertThat(exists(duCompte)).isTrue();
        assertThat(exists(invite)).isFalse();
    }

    @Test
    void deleteGuestAttemptsByIds_ignoreUnIdDeCompte() {
        // Le DELETE redouble la condition user IS NULL : même en lui passant
        // explicitement l'id d'un attempt de compte, rien n'est supprimé.
        User user = data.user();
        UUID duCompte = userAttempt(user, hoursAgo(24 * 365));

        int deleted = attemptManager.deleteGuestAttemptsByIds(List.of(duCompte));
        em.clear();

        assertThat(deleted).isZero();
        assertThat(exists(duCompte)).isTrue();
    }

    @Test
    void active_lesTablesFillesPartentEnCascadeBase() {
        properties.setEnabled(true);
        Question q = data.question();
        UUID inviteId = guestAttempt(hoursAgo(3));
        AttemptQuestion aq = new AttemptQuestion();
        aq.setAttempt(attemptManager.findById(inviteId).orElseThrow());
        aq.setQuestion(q);
        aq.setPosition(0);
        UUID aqId = attemptQuestionManager.save(aq).getId();
        em.flush();

        purge();

        assertThat(exists(inviteId)).isFalse();
        Long fillesRestantes = em.createQuery(
                        "SELECT count(aq) FROM AttemptQuestion aq WHERE aq.id = :id", Long.class)
                .setParameter("id", aqId)
                .getSingleResult();
        assertThat(fillesRestantes).isZero();
    }

    @Test
    void active_borneDeLot_laPasseBoucleJusquAEpuisement() {
        properties.setEnabled(true);
        properties.setBatchSize(2);
        for (int i = 0; i < 5; i++) {
            guestAttempt(hoursAgo(3 + i));
        }

        assertThat(purge()).isGreaterThanOrEqualTo(5);
        assertThat(attemptManager.findGuestAttemptIdsStartedBefore(hoursAgo(2), 10)).isEmpty();
    }

    @Test
    void active_delaiConfigurable() {
        properties.setEnabled(true);
        properties.setRetention(Duration.ofMinutes(10));
        UUID vieuxDeTrenteMinutes = guestAttempt(Instant.now().minus(Duration.ofMinutes(30)));

        purge();

        assertThat(exists(vieuxDeTrenteMinutes)).isFalse();
    }

    @Test
    void batchSizeNul_passeIgnoree() {
        properties.setEnabled(true);
        properties.setBatchSize(0);
        UUID vieux = guestAttempt(hoursAgo(48));

        assertThat(purge()).isZero();
        assertThat(exists(vieux)).isTrue();
    }
}
