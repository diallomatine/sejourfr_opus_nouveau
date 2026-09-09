package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Le parcours du diagnostic TCF 4 epreuves (10_ §4, 30_ §5).
 *
 * <p>🛑 <b>Ce n'est pas un examen blanc</b> et le nom compte : 10_ §4.1
 * l'interdit explicitement. Les deux objets coexistent — l'examen blanc est au
 * format reel et sert a se mettre en situation, le diagnostic est reduit en
 * comprehension et sert a construire le Plan.
 *
 * <p>Il REUTILISE la mecanique de l'examen complet (parent {@code TCF_COMPLET}
 * + 4 sous-attempts, chrono par epreuve, cloture paresseuse a la lecture,
 * productions branchees sur {@code /api/production-submissions}) et se
 * distingue par {@code attempts.tcf_diagnostic_id}. Sans ce discriminant, il
 * remonterait dans la grille des examens blancs.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TcfDiagnosticService {

    private final TcfDiagnosticSessionManager sessionManager;
    private final AttemptManager attemptManager;
    private final UserManager userManager;
    private final SubscriptionService subscriptionService;
    private final TcfDiagnosticSectionStarter sectionStarter;
    private final TcfDiagnosticReadService readService;
    private final TcfDiagnosticProperties props;

    // ------------------------------------------------------------------------
    // Ouverture
    // ------------------------------------------------------------------------

    /**
     * Ouvre un diagnostic, ou rend celui qui est deja en cours.
     *
     * <p><b>Idempotent</b> : un diagnostic en cours est repris, jamais double.
     * Deux appuis sur « Commencer » ne creent pas deux diagnostics.
     *
     * <p>Freemium (10_ §4.3 et §4.6) : <b>le premier est offert</b>. Les
     * suivants sont une reevaluation reservee aux abonnes TCF, et espacee d'au
     * moins {@code reevaluation} — sans ce delai, une reevaluation a volonte ne
     * mesurerait plus une progression, juste le bruit de deux passations
     * rapprochees.
     */
    @Transactional
    public TcfDiagnosticSession ouvrir(UUID userId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));

        Optional<TcfDiagnosticSession> enCours = sessionManager.findLatest(userId)
                .filter(d -> d.getStatus() == TcfDiagnosticStatus.IN_PROGRESS);
        if (enCours.isPresent()) {
            return enCours.get();
        }

        assertPeutOuvrirUnNouveau(userId);

        Instant now = Instant.now();
        Attempt parent = creerParent(user, now);

        TcfDiagnosticSession session = new TcfDiagnosticSession();
        session.setUser(user);
        session.setParentAttempt(parent);
        session.setConfigVersion(props.getConfigVersion());
        session.setStatus(TcfDiagnosticStatus.IN_PROGRESS);
        session.setStartedAt(now);
        session.setExpiresAt(now.plus(props.getReprise()));
        session = sessionManager.save(session);

        // Le parent porte le discriminant : c'est lui qui tient les grilles
        // d'examens blancs a l'ecart du diagnostic.
        parent.setTcfDiagnostic(session);
        attemptManager.save(parent);

        sectionStarter.creerLesQuatreSections(user, session, parent);

        log.info("Diagnostic TCF ouvert : session={} user={} configVersion={}",
                session.getId(), userId, session.getConfigVersion());
        return session;
    }

    /**
     * Le candidat a-t-il le droit d'ouvrir un NOUVEAU diagnostic ?
     *
     * <p>Le message est celui que l'ecran affiche : il nomme la raison, jamais
     * un refus technique.
     */
    private void assertPeutOuvrirUnNouveau(UUID userId) {
        long deja = sessionManager.countByUser(userId);
        if (deja == 0) {
            return; // Le premier est offert, sans condition.
        }
        if (!subscriptionService.hasTcf(userId)) {
            throw new BusinessException(
                    "Votre diagnostic initial a déjà été réalisé. "
                            + "Passez Premium pour réévaluer votre niveau et mesurer votre progression.");
        }
        Instant plusRecent = sessionManager.findLatest(userId)
                .map(TcfDiagnosticSession::getStartedAt)
                .orElse(Instant.EPOCH);
        Instant ouvrableA = plusRecent.plus(props.getReevaluation());
        if (Instant.now().isBefore(ouvrableA)) {
            long jours = java.time.Duration.between(Instant.now(), ouvrableA).toDays() + 1;
            throw new BusinessException(
                    "Une réévaluation est possible tous les " + props.getReevaluation().toDays()
                            + " jours. Vous pourrez en relancer une dans " + jours + " jour(s).");
        }
    }

    private Attempt creerParent(User user, Instant now) {
        Attempt parent = new Attempt();
        parent.setUser(user);
        parent.setType(AttemptType.MOCK_EXAM);
        parent.setModule(Module.TCF);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setStatus(AttemptStatus.EN_COURS);
        parent.setStartedAt(now);
        // 🛑 Pas de slotNumber : les slots sont la grille des 20 examens blancs,
        // et un diagnostic n'y entre pas.
        return attemptManager.save(parent);
    }

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    /** Le diagnostic courant, ou vide si le candidat n'en a jamais ouvert. */
    @Transactional(readOnly = true)
    public Optional<TcfDiagnosticSession> courant(UUID userId) {
        return sessionManager.findLatest(userId);
    }

    /** Un diagnostic precis. 404 sur celui d'autrui : on ne revele pas son existence. */
    @Transactional(readOnly = true)
    public TcfDiagnosticSession lire(UUID userId, UUID sessionId) {
        TcfDiagnosticSession session = sessionManager.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Diagnostic introuvable : " + sessionId));
        if (session.getUser() == null || !session.getUser().getId().equals(userId)) {
            throw new NotFoundException("Diagnostic introuvable : " + sessionId);
        }
        return session;
    }

    /**
     * Cloture le diagnostic et fige sa date de fin.
     *
     * <p>Appele quand le candidat demande son resultat. Il n'exige PAS que les
     * 4 sections soient faites : passe le delai de reprise, 10_ §4.2 impose de
     * « calculer sur les sections realisees », les autres restant « non
     * evaluee ». Rien n'est detruit, rien n'est invente.
     */
    @Transactional
    public TcfDiagnosticSession cloturer(UUID userId, UUID sessionId) {
        TcfDiagnosticSession session = lire(userId, sessionId);
        if (session.getStatus() == TcfDiagnosticStatus.COMPLETED) {
            return session;
        }
        Instant now = Instant.now();
        session.setStatus(TcfDiagnosticStatus.COMPLETED);
        session.setCompletedAt(now);

        Attempt parent = session.getParentAttempt();
        if (parent.getFinishedAt() == null) {
            parent.setFinishedAt(now);
            parent.setStatus(AttemptStatus.TERMINE);
        }
        // Cache de LECTURE du niveau global, comme l'examen complet le fait
        // deja. La source reste le recalcul : ce champ ne sert qu'aux listes.
        readService.niveauGlobal(readService.sections(session))
                .ifPresent(parent::setFinalCecrlLevel);
        attemptManager.save(parent);

        return sessionManager.save(session);
    }

    /**
     * Palier vise par le candidat, plancher de sa demarche applique.
     *
     * <p>🛑 Il vient de {@code TargetProcedure.niveauVise} et de nulle part
     * ailleurs : la table demarche → palier a deja vecu en six copies, dont une
     * tirait un candidat NAT vers le B1.
     */
    public Optional<NiveauCecrl> cible(User user) {
        TargetLevel vise = com.sejourfr.app.enums.TargetProcedure.niveauVise(
                user.getTargetProcedure(), user.getTargetLevel());
        if (vise == null) {
            return Optional.empty();
        }
        return Optional.of(switch (vise) {
            case A2 -> NiveauCecrl.A2;
            case B1 -> NiveauCecrl.B1;
            case B2 -> NiveauCecrl.B2;
        });
    }
}
