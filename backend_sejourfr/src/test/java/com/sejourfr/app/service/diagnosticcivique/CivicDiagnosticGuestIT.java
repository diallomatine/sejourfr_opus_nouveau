package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * LE DIAGNOSTIC CIVIQUE PASSÉ AVANT LE COMPTE (V053).
 *
 * <p>🛑 <b>Arbitrage du propriétaire, 2026-09-10</b> : « que ce soit le
 * diagnostic examen civique ou TCF, l'utilisateur doit pouvoir passer le
 * diagnostic avant de créer son compte ; il répond au QCM et seulement après on
 * lui demande de créer son compte pour voir le résultat. »
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>une session sans compte existe, avec ses 40 questions, et son attempt
 *       porte <b>dès la première seconde</b> le discriminant
 *       {@code civic_diagnostic_id} — sinon un visiteur créerait un « examen
 *       blanc » aux yeux de toutes les grilles ;</li>
 *   <li>🛑 <b>l'étanchéité entre navigateurs</b> : l'IP est le seul lien entre
 *       la session et son visiteur. Une autre IP ne doit rien lire, et une
 *       session déjà adoptée ne doit plus être lisible publiquement — deux
 *       personnes derrière le même NAT ne se lisent pas ;</li>
 *   <li>l'adoption ne <b>rejoue rien</b> : même session, même attempt, mêmes
 *       questions. Un second tirage donnerait au candidat un résultat qui n'est
 *       pas celui qu'il vient de passer ;</li>
 *   <li>une session sans porteur est <b>invisible</b> des écrans connectés
 *       jusqu'à l'adoption — c'est ce qui garantit que le Plan ne s'appuie
 *       jamais sur le diagnostic d'un inconnu.</li>
 * </ul>
 */
class CivicDiagnosticGuestIT extends AbstractIntegrationTest {

    private static final String IP = "203.0.113.7";
    private static final String AUTRE_IP = "203.0.113.8";

    @Autowired private CivicDiagnosticService service;
    @Autowired private CivicDiagnosticViewService viewService;
    @Autowired private TestData testData;
    @Autowired private EntityManager entityManager;
    @Autowired private JdbcTemplate jdbc;

    @Test
    @DisplayName("Un visiteur ouvre ses 40 questions sans compte, et l'attempt est déjà un diagnostic")
    void ouvertureSansCompte() {
        CivicDiagnosticSession session = service.ouvrirInvite(TargetProcedure.NAT, IP);
        entityManager.flush();

        assertThat(session.getUser()).isNull();
        assertThat(session.getClientIp()).isEqualTo(IP);
        // La démarche déclarée par le visiteur pilote le tirage : mesurer un
        // candidat NAT sur des questions CSP produirait un plan incomplet.
        assertThat(session.getMention()).isEqualTo(Difficulty.NAT);
        assertThat(viewService.vue(session).total()).isEqualTo(40);

        // 🛑 Le discriminant existe AVANT le compte. Sans lui, ces 40 questions
        // seraient un examen blanc pour toutes les grilles, dès la première.
        UUID diagnosticDeLAttempt = jdbc.queryForObject(
                "SELECT civic_diagnostic_id FROM attempts WHERE id = ?",
                UUID.class, session.getAttempt().getId());
        assertThat(diagnosticDeLAttempt).isEqualTo(session.getId());
        assertThat(session.getAttempt().getUser()).isNull();
        assertThat(session.getAttempt().getClientIp()).isEqualTo(IP);
    }

    @Test
    @DisplayName("Sans démarche déclarée, le tirage retombe sur CSP — le périmètre le plus étroit")
    void demarcheAbsenteDonneCsp() {
        CivicDiagnosticSession session = service.ouvrirInvite(null, IP);
        assertThat(session.getMention()).isEqualTo(Difficulty.CSP);
    }

    @Test
    @DisplayName("🛑 Une autre IP ne lit pas le diagnostic du visiteur")
    void autreIpNeLitRien() {
        CivicDiagnosticSession session = service.ouvrirInvite(TargetProcedure.CSP, IP);
        entityManager.flush();

        assertThat(service.lireInvite(session.getId(), IP).getId()).isEqualTo(session.getId());
        assertThatThrownBy(() -> service.lireInvite(session.getId(), AUTRE_IP))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    @DisplayName("Tant qu'il n'est pas adopté, le diagnostic invité est invisible des écrans connectés")
    void invisibleAvantAdoption() {
        User user = testData.user();
        service.ouvrirInvite(TargetProcedure.CSP, IP);
        entityManager.flush();
        entityManager.clear();

        // Le Plan, l'Accueil et les Examens lisent tous cet état : s'ils
        // voyaient une session sans porteur, ils bâtiraient sur le diagnostic
        // d'un inconnu.
        assertThat(service.courant(user.getId())).isEmpty();
    }

    @Test
    @DisplayName("L'adoption garde la MÊME session, le MÊME attempt et les MÊMES questions")
    void adoptionNeRejoueRien() {
        CivicDiagnosticSession invite = service.ouvrirInvite(TargetProcedure.CR, IP);
        entityManager.flush();
        UUID sessionId = invite.getId();
        UUID attemptId = invite.getAttempt().getId();
        Difficulty mention = invite.getMention();
        entityManager.clear();

        User user = testData.user();
        CivicDiagnosticSession adopte = service.adopter(user.getId(), sessionId, IP);
        entityManager.flush();
        entityManager.clear();

        assertThat(adopte.getId()).isEqualTo(sessionId);
        assertThat(adopte.getAttempt().getId()).isEqualTo(attemptId);
        // 🛑 La mention reste celle du TIRAGE, pas celle du compte créé ensuite :
        // un diagnostic se relit avec ce qui l'a produit.
        assertThat(adopte.getMention()).isEqualTo(mention);
        assertThat(adopte.getUser().getId()).isEqualTo(user.getId());
        // L'IP n'a plus de rôle : la garder ferait d'une donnée de tunnel une
        // donnée de compte.
        assertThat(adopte.getClientIp()).isNull();

        Integer questions = jdbc.queryForObject(
                "SELECT COUNT(*) FROM attempt_questions WHERE attempt_id = ?",
                Integer.class, attemptId);
        assertThat(questions).isEqualTo(40);

        UUID porteurDeLAttempt = jdbc.queryForObject(
                "SELECT user_id FROM attempts WHERE id = ?", UUID.class, attemptId);
        assertThat(porteurDeLAttempt).isEqualTo(user.getId());

        // Et l'écran connecté le voit enfin : c'est ce qui débloque le Plan.
        assertThat(service.courant(user.getId()))
                .isPresent()
                .get()
                .extracting(CivicDiagnosticSession::getId)
                .isEqualTo(sessionId);
    }

    @Test
    @DisplayName("L'adoption est idempotente, et une session déjà adoptée n'est plus publique")
    void adoptionIdempotenteEtFermee() {
        CivicDiagnosticSession invite = service.ouvrirInvite(TargetProcedure.CSP, IP);
        entityManager.flush();
        UUID sessionId = invite.getId();
        entityManager.clear();

        User user = testData.user();
        service.adopter(user.getId(), sessionId, IP);
        entityManager.flush();
        entityManager.clear();

        // Un double appui pendant l'inscription ne doit pas produire d'erreur.
        assertThat(service.adopter(user.getId(), sessionId, IP).getId()).isEqualTo(sessionId);

        // 🛑 Plus rien de public, même depuis la même IP : sinon deux personnes
        // derrière le même NAT liraient le diagnostic l'une de l'autre.
        assertThatThrownBy(() -> service.lireInvite(sessionId, IP))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    @DisplayName("🛑 Un second compte n'adopte pas le diagnostic déjà porté par un autre")
    void pasDeVolDAdoption() {
        CivicDiagnosticSession invite = service.ouvrirInvite(TargetProcedure.CSP, IP);
        entityManager.flush();
        UUID sessionId = invite.getId();
        entityManager.clear();

        User premier = testData.user("premier.invite@sejourfr.test");
        service.adopter(premier.getId(), sessionId, IP);
        entityManager.flush();
        entityManager.clear();

        User second = testData.user("second.invite@sejourfr.test");
        assertThatThrownBy(() -> service.adopter(second.getId(), sessionId, IP))
                .isInstanceOf(NotFoundException.class);
    }
}
