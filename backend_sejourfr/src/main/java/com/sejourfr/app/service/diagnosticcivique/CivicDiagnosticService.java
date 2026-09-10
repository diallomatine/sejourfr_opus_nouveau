package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.config.CivicDiagnosticProperties;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Le parcours du diagnostic civique (lot L9, spec 20_ §4).
 *
 * <p>🛑 <b>Ce n'est pas un examen blanc</b>, et 20_ §4.1 les oppose ligne a
 * ligne : 24 questions contre 40, couverture equilibree contre representative,
 * il CREE le plan la ou l'examen blanc VERIFIE la preparation. Les deux objets
 * coexistent, et {@code attempts.civic_diagnostic_id} les tient a l'ecart.
 *
 * <p>Il REUTILISE tout ce qui existe : un {@code Attempt} ordinaire, ses
 * {@code AttemptQuestion}, et le runner de questions des fronts. 🛑 <b>Aucun
 * ecran de passation n'est cree</b> — un second runner divergerait du premier a
 * la premiere evolution.
 *
 * <p>🛑 <b>Aucun cout LLM.</b> Le civique est du QCM deterministe : la
 * correction ne passe par aucun modele, et le quota est donc distinct de celui
 * des analyses IA (20_ §4.3).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CivicDiagnosticService {

    private final CivicDiagnosticSessionManager sessionManager;
    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final UserManager userManager;
    private final SubscriptionService subscriptionService;
    private final CivicDiagnosticComposer composer;
    private final CivicDiagnosticProperties props;

    /**
     * Ouvre un diagnostic, ou rend celui deja en cours.
     *
     * <p><b>Idempotent</b> : deux appuis sur « Commencer » ne creent pas deux
     * diagnostics — et sur un QCM, cela ferait deux tirages differents, donc
     * deux mesures incomparables.
     */
    @Transactional
    public CivicDiagnosticSession ouvrir(UUID userId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));

        Optional<CivicDiagnosticSession> enCours = sessionManager.findLatest(userId)
                .filter(d -> d.getStatus() == TcfDiagnosticStatus.IN_PROGRESS);
        if (enCours.isPresent()) {
            return enCours.get();
        }

        assertPeutOuvrirUnNouveau(userId);
        Difficulty mention = mention(user);
        List<Question> questions = composer.composer(mention);
        if (questions.isEmpty()) {
            throw new BusinessException(
                    "Aucune question civique disponible pour votre démarche.");
        }

        Instant now = Instant.now();
        Attempt attempt = new Attempt();
        attempt.setUser(user);
        // 🛑 MOCK_EXAM porte le comportement de passation (pas de correction
        // live, chrono), pas la nature de l'objet : c'est le discriminant
        // `civicDiagnostic` qui dit que ce n'est PAS un examen blanc, et les
        // grilles le filtrent sur lui.
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(Module.CIVIQUE);
        // 🛑 La mention vit sur la SESSION, pas sur l'attempt : elle y est
        // recopiee au moment du diagnostic et ne se relit jamais depuis
        // `users`. Changer de demarche ne doit pas reinterpreter un diagnostic
        // deja passe.
        attempt.setStatus(AttemptStatus.EN_COURS);
        attempt.setTotalQuestions(questions.size());
        attempt.setStartedAt(now);
        // 🛑 Pas de slotNumber : les slots sont la grille des examens blancs.
        attempt = attemptManager.save(attempt);

        CivicDiagnosticSession session = new CivicDiagnosticSession();
        session.setUser(user);
        session.setAttempt(attempt);
        session.setMention(mention);
        session.setConfigVersion(props.getConfigVersion());
        session.setStatus(TcfDiagnosticStatus.IN_PROGRESS);
        session.setStartedAt(now);
        session = sessionManager.save(session);

        attempt.setCivicDiagnostic(session);
        attemptManager.save(attempt);

        for (int i = 0; i < questions.size(); i++) {
            AttemptQuestion aq = new AttemptQuestion();
            aq.setAttempt(attempt);
            aq.setQuestion(questions.get(i));
            aq.setPosition(i);
            attemptQuestionManager.save(aq);
        }

        log.info("Diagnostic civique ouvert : session={} user={} mention={} questions={}",
                session.getId(), userId, mention, questions.size());
        return session;
    }

    /**
     * Le candidat a-t-il le droit d'ouvrir un NOUVEAU diagnostic ? (20_ §4.3)
     *
     * <p>Le premier est offert, <b>quota distinct du TCF et des analyses IA</b> :
     * le civique ne coute aucun appel de modele.
     */
    private void assertPeutOuvrirUnNouveau(UUID userId) {
        if (sessionManager.countByUser(userId) == 0) {
            return;
        }
        if (!subscriptionService.hasCivique(userId)) {
            throw new BusinessException(
                    "Votre diagnostic civique a déjà été réalisé. "
                            + "Passez Premium pour le refaire et mesurer votre progression.");
        }
        Instant plusRecent = sessionManager.findLatest(userId)
                .map(CivicDiagnosticSession::getStartedAt)
                .orElse(Instant.EPOCH);
        Instant ouvrableA = plusRecent.plus(props.getReevaluation());
        if (Instant.now().isBefore(ouvrableA)) {
            long jours = Duration.between(Instant.now(), ouvrableA).toDays() + 1;
            throw new BusinessException(
                    "Un nouveau diagnostic est possible tous les "
                            + props.getReevaluation().toDays() + " jours. "
                            + "Vous pourrez en relancer un dans " + jours + " jour(s).");
        }
    }

    /**
     * La mention sur laquelle le candidat est mesure.
     *
     * <p>🛑 Elle vient de {@code TargetProcedure} et de nulle part ailleurs :
     * la table demarche → exigence a deja vecu en six copies dans ce depot.
     * Demarche non declaree ⇒ {@code CSP}, le perimetre le plus etroit — mesurer
     * un candidat sur des questions de naturalisation qu'il n'a pas a connaitre
     * produirait un diagnostic faussement severe.
     */
    private static Difficulty mention(User user) {
        TargetProcedure procedure = user.getTargetProcedure();
        if (procedure == null) {
            return Difficulty.CSP;
        }
        return switch (procedure) {
            case CSP -> Difficulty.CSP;
            case CR -> Difficulty.CR;
            case NAT -> Difficulty.NAT;
        };
    }

    /** Le diagnostic courant, ou vide si le candidat n'en a jamais ouvert. */
    @Transactional(readOnly = true)
    public Optional<CivicDiagnosticSession> courant(UUID userId) {
        return sessionManager.findLatest(userId);
    }

    /** Un diagnostic precis. 404 sur celui d'autrui : on ne revele pas son existence. */
    @Transactional(readOnly = true)
    public CivicDiagnosticSession lire(UUID userId, UUID sessionId) {
        CivicDiagnosticSession session = sessionManager.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Diagnostic introuvable : " + sessionId));
        if (session.getUser() == null || !session.getUser().getId().equals(userId)) {
            throw new NotFoundException("Diagnostic introuvable : " + sessionId);
        }
        return session;
    }

    /**
     * Cloture le diagnostic et fige sa date de fin.
     *
     * <p>Il n'exige pas que les 24 questions soient repondues : le resultat se
     * calcule sur ce qui a ete <b>pose et repondu</b>, et une question sautee
     * ne devient jamais une mauvaise reponse (elle sort du denominateur).
     */
    @Transactional
    public CivicDiagnosticSession cloturer(UUID userId, UUID sessionId) {
        CivicDiagnosticSession session = lire(userId, sessionId);
        if (session.getStatus() == TcfDiagnosticStatus.COMPLETED) {
            return session;
        }
        Instant now = Instant.now();
        session.setStatus(TcfDiagnosticStatus.COMPLETED);
        session.setCompletedAt(now);

        Attempt attempt = session.getAttempt();
        if (attempt.getFinishedAt() == null) {
            attempt.setFinishedAt(now);
            attempt.setStatus(AttemptStatus.TERMINE);
            attemptManager.save(attempt);
        }
        return sessionManager.save(session);
    }
}
