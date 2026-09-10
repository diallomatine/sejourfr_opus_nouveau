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
import com.sejourfr.app.manager.AnswerManager;
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
 * ligne : meme format (40 questions), couverture equilibree contre representative,
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
    private final AnswerManager answerManager;
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
        return creer(user, null, mention(user.getTargetProcedure()));
    }

    /**
     * Ouvre un diagnostic pour un <b>visiteur sans compte</b> (V053).
     *
     * <p>🛑 <b>Arbitrage du proprietaire, 2026-09-10</b> : « que ce soit le
     * diagnostic examen civique ou TCF, l'utilisateur doit pouvoir passer le
     * diagnostic AVANT de creer son compte ». Il repond a ses 40 questions,
     * <b>puis</b> on lui demande un compte pour voir le resultat.
     *
     * <p>🛑 <b>Pourquoi une session en base et pas un stockage local</b>, alors
     * que le TCF garde ses productions sur l'appareil : corriger du QCM cote
     * client obligerait a SERVIR LES BONNES REPONSES a un visiteur, et jouer 40
     * questions hors {@code attempts} obligerait a ecrire un SECOND RUNNER.
     * Les deux sont interdits. On reutilise donc l'attempt invite de la demo
     * (user NULL + client_ip), deja en place.
     *
     * <p>🛑 <b>Aucun quota ici</b> : le compteur du gratuit
     * ({@link #assertPeutOuvrirUnNouveau}) porte sur un COMPTE, et il n'y en a
     * pas encore. Le frein d'un visiteur est le rate-limit par IP, pose au
     * bord d'entree.
     */
    @Transactional
    public CivicDiagnosticSession ouvrirInvite(TargetProcedure procedure, String clientIp) {
        if (clientIp == null || clientIp.isBlank()) {
            throw new BusinessException("Impossible de déterminer l'IP du client");
        }
        return creer(null, clientIp, mention(procedure));
    }

    /**
     * Le tirage, l'attempt et la session — <b>un seul endroit</b>, que le
     * porteur soit un compte ou une IP.
     *
     * <p>Deux chemins de creation divergeraient a la premiere evolution du
     * format, et l'un des deux produirait alors une mesure incomparable.
     */
    private CivicDiagnosticSession creer(User user, String clientIp, Difficulty mention) {
        List<Question> questions = composer.composer(mention);
        if (questions.isEmpty()) {
            throw new BusinessException(
                    "Aucune question civique disponible pour votre démarche.");
        }

        Instant now = Instant.now();
        Attempt attempt = new Attempt();
        attempt.setUser(user);
        // L'IP tient lieu de porteur tant qu'il n'y a pas de compte : c'est
        // exactement le contrat de l'attempt de demo.
        attempt.setClientIp(clientIp);
        // 🛑 MOCK_EXAM porte le comportement de passation (pas de correction
        // live, chrono), pas la nature de l'objet : c'est le discriminant
        // `civicDiagnostic` qui dit que ce n'est PAS un examen blanc, et les
        // grilles le filtrent sur lui.
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(Module.CIVIQUE);
        attempt.setStatus(AttemptStatus.EN_COURS);
        attempt.setTotalQuestions(questions.size());
        attempt.setStartedAt(now);
        // 🛑 Pas de slotNumber : les slots sont la grille des examens blancs.
        attempt = attemptManager.save(attempt);

        CivicDiagnosticSession session = new CivicDiagnosticSession();
        session.setUser(user);
        session.setClientIp(clientIp);
        session.setAttempt(attempt);
        // 🛑 La mention vit sur la SESSION, pas sur l'attempt : elle y est
        // recopiee au moment du diagnostic et ne se relit jamais depuis
        // `users`. Changer de demarche ne doit pas reinterpreter un diagnostic
        // deja passe.
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
                session.getId(), user == null ? "invite" : user.getId(),
                mention, questions.size());
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
    private static Difficulty mention(TargetProcedure procedure) {
        if (procedure == null) {
            return Difficulty.CSP;
        }
        return switch (procedure) {
            case CSP -> Difficulty.CSP;
            case CR -> Difficulty.CR;
            case NAT -> Difficulty.NAT;
        };
    }

    /**
     * Le diagnostic courant, ou vide si le candidat n'en a jamais ouvert.
     *
     * <p>🛑 <b>Cloture PARESSEUSE</b> : si l'attempt est termine mais que la
     * session est restee ouverte, on la clot ici. Sans ca, un candidat qui
     * repond a ses 40 questions puis quitte sans ouvrir son resultat garde un
     * diagnostic « en cours » <b>pour toujours</b> — et le Plan continue de lui
     * reclamer un diagnostic qu'il vient de terminer. Defaut constate a
     * l'usage, et il se repare tout seul a la premiere lecture.
     *
     * <p>Meme patron que la cloture paresseuse de l'examen complet : l'etat
     * vrai est celui de l'attempt, la session le rattrape a la lecture.
     */
    @Transactional
    public Optional<CivicDiagnosticSession> courant(UUID userId) {
        return sessionManager.findLatest(userId).map(this::cloturerSiAttemptTermine);
    }

    /**
     * Clot la session dont l'attempt est deja fini.
     *
     * <p>Idempotent, et sans effet sur une session dont l'attempt tourne
     * encore : c'est l'attempt qui fait foi, pas l'inverse.
     */
    private CivicDiagnosticSession cloturerSiAttemptTermine(CivicDiagnosticSession session) {
        if (session.getStatus() == TcfDiagnosticStatus.COMPLETED) {
            return session;
        }
        if (session.getAttempt().getFinishedAt() == null) {
            return session;
        }
        session.setStatus(TcfDiagnosticStatus.COMPLETED);
        session.setCompletedAt(session.getAttempt().getFinishedAt());
        log.info("Diagnostic civique cloture a la lecture : session={}", session.getId());
        return sessionManager.save(session);
    }

    /**
     * Le diagnostic d'un <b>visiteur</b>, identifie par l'IP de son navigateur.
     *
     * <p>🛑 <b>404 des qu'un compte porte la session</b> : une fois adoptee,
     * elle n'est plus lisible que par son porteur, meme depuis la meme IP.
     * Sans cette porte, deux personnes derriere le meme NAT liraient le
     * diagnostic l'une de l'autre.
     */
    @Transactional
    public CivicDiagnosticSession lireInvite(UUID sessionId, String clientIp) {
        CivicDiagnosticSession session = sessionManager.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Diagnostic introuvable : " + sessionId));
        if (session.getUser() != null
                || clientIp == null
                || !clientIp.equals(session.getClientIp())) {
            throw new NotFoundException("Diagnostic introuvable : " + sessionId);
        }
        return cloturerSiAttemptTermine(session);
    }

    /**
     * <b>L'adoption</b> : le visiteur vient de creer son compte (ou de se
     * connecter), et son diagnostic devient le sien.
     *
     * <p>🛑 <b>Rien n'est rejoue, rien n'est retire.</b> Ce sont les MEMES
     * questions, deja corrigees a la volee cote serveur : on ne fait que poser
     * le porteur. Un second tirage produirait une mesure differente de celle
     * que le candidat vient de passer.
     *
     * <p>🛑 <b>Le quota du compte s'applique</b> ({@code 20_} §4.3) : un compte
     * qui a deja son diagnostic gratuit ne s'en offre pas un second en
     * repassant par le tunnel invite. Le message renvoye est celui de
     * {@link #assertPeutOuvrirUnNouveau}, et le front propose alors le
     * diagnostic existant.
     *
     * <p><b>Idempotent</b> : reappeler avec la meme session deja adoptee par ce
     * compte rend la session, sans rien refaire — un double appui pendant
     * l'inscription ne doit pas produire une erreur.
     */
    @Transactional
    public CivicDiagnosticSession adopter(UUID userId, UUID sessionId, String clientIp) {
        CivicDiagnosticSession session = sessionManager.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Diagnostic introuvable : " + sessionId));

        if (session.getUser() != null) {
            if (session.getUser().getId().equals(userId)) {
                return cloturerSiAttemptTermine(session);
            }
            throw new NotFoundException("Diagnostic introuvable : " + sessionId);
        }
        if (clientIp == null || !clientIp.equals(session.getClientIp())) {
            throw new NotFoundException("Diagnostic introuvable : " + sessionId);
        }

        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        assertPeutOuvrirUnNouveau(userId);

        session.setUser(user);
        // 🛑 L'IP s'efface a l'adoption : elle n'a plus de role, et la garder
        // ferait d'une donnee de tunnel une donnee de compte.
        session.setClientIp(null);

        Attempt attempt = session.getAttempt();
        attempt.setUser(user);
        attempt.setClientIp(null);
        attemptManager.save(attempt);
        answerManager.rattacherAuCompte(user, attempt.getId());

        log.info("Diagnostic civique adopte : session={} user={}", session.getId(), userId);
        return cloturerSiAttemptTermine(sessionManager.save(session));
    }

    /** Un diagnostic precis. 404 sur celui d'autrui : on ne revele pas son existence. */
    @Transactional
    public CivicDiagnosticSession lire(UUID userId, UUID sessionId) {
        CivicDiagnosticSession session = sessionManager.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Diagnostic introuvable : " + sessionId));
        if (session.getUser() == null || !session.getUser().getId().equals(userId)) {
            throw new NotFoundException("Diagnostic introuvable : " + sessionId);
        }
        return cloturerSiAttemptTermine(session);
    }

    /**
     * Cloture le diagnostic et fige sa date de fin.
     *
     * <p>Il n'exige pas que les 40 questions soient repondues : le resultat se
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
