package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.dto.AppendTranscriptRequest;
import com.sejourfr.app.dto.RealtimeSessionDescriptor;
import com.sejourfr.app.dto.RealtimeSessionStateResponse;
import com.sejourfr.app.dto.StartRealtimeSessionRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.service.ProductionEvaluationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Orchestre les sessions d'expression orale temps reel (Taches 1 & 2). Trois
 * cas d'usage : (1) demarrer une session (verif quota -> emission token ephemere
 * Gemini, ou bascule async si indisponible), (2) accumuler le transcript relaye
 * par le client (et debiter le quota a la 1re connexion reelle), (3) cloturer.
 *
 * <p>Le mode temps reel S'AJOUTE : il ne remplace pas le pipeline async. Quand il
 * n'est pas possible (quota epuise, pass non eligible, non configure, echec de
 * mint), on renvoie {@code ASYNC_FALLBACK} et le client fait l'epreuve en
 * enregistrement classique — le candidat n'est jamais bloque.
 *
 * <p>NOTE LOT : ce service est le socle "transport + quota". La NOTATION (creer 1
 * {@code production_submission} par tache a partir du transcript dialogue et
 * lancer le pipeline d'evaluation existant) est branchee au lot 2 dans
 * {@link #finish}.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RealtimeSessionService {

    private final RealtimeSessionManager sessionManager;
    private final RealtimeQuotaService quotaService;
    private final RealtimePersonaBuilder personaBuilder;
    private final RealtimeTokenBroker tokenBroker;
    private final ProductionTaskManager productionTaskManager;
    private final AttemptManager attemptManager;
    private final ProductionEvaluationService productionEvaluationService;
    private final RealtimeProperties props;

    @Transactional
    public RealtimeSessionDescriptor start(User user, StartRealtimeSessionRequest req) {
        ProductionTask task = productionTaskManager.findActiveById(req.productionTaskId())
                .orElseThrow(() -> new NotFoundException("Consigne introuvable : " + req.productionTaskId()));
        if (task.getEpreuve() != EpreuveType.TCF_EO) {
            throw new BusinessException("Le mode temps reel ne concerne que l'expression orale (TCF_EO).");
        }
        short tache = task.getTacheNumero() != null ? task.getTacheNumero() : 0;
        if (tache != 1 && tache != 2) {
            throw new BusinessException("Le mode temps reel ne concerne que les taches 1 et 2.");
        }
        Integer target = task.getDureeMaxSec();

        RealtimeQuotaService.Quota quota = quotaService.evaluate(user.getId());
        if (!tokenBroker.isConfigured() || !quota.canStartRealtime()) {
            return RealtimeSessionDescriptor.asyncFallback(tache, target, quota.remaining());
        }

        RealtimeTokenBroker.MintedSession minted;
        try {
            minted = tokenBroker.mint(personaBuilder.build(task));
        } catch (RuntimeException e) {
            // Mint en echec : on ne bloque pas, on bascule en async.
            log.warn("Mint token realtime echoue, bascule async : {}", e.getMessage());
            return RealtimeSessionDescriptor.asyncFallback(tache, target, quota.remaining());
        }

        Attempt attempt = resolveAttempt(req.attemptId(), user);

        RealtimeSession session = new RealtimeSession();
        session.setUser(user);
        session.setSubscription(quota.subscription());
        session.setAttempt(attempt);
        session.setProductionTask(task);
        session.setEpreuve(EpreuveType.TCF_EO);
        session.setTacheNumero(tache);
        session.setProvider(tokenBroker.provider());
        session.setModel(minted.model());
        session.setStatus(RealtimeSessionStatus.PENDING);
        session = sessionManager.save(session);

        RealtimeProperties.Audio audio = props.getAudio();
        return new RealtimeSessionDescriptor(
                RealtimeSessionDescriptor.MODE_REALTIME,
                session.getId(),
                tokenBroker.provider(),
                minted.model(),
                minted.wsEndpoint(),
                minted.token(),
                audio.getInputMimeType(),
                audio.getInputSampleRate(),
                audio.getOutputSampleRate(),
                props.getGemini().getVoice(),
                tache,
                target,
                // Slot reserve par cette session -> on l'enleve de l'affichage.
                Math.max(0, quota.remaining() - 1)
        );
    }

    @Transactional
    public void appendTranscript(User user, UUID sessionId, AppendTranscriptRequest req) {
        RealtimeSession session = ownedSession(user, sessionId);
        if (session.getStatus() == RealtimeSessionStatus.COMPLETED
                || session.getStatus() == RealtimeSessionStatus.FAILED) {
            // Fragment tardif apres cloture : on ignore silencieusement.
            return;
        }
        if (session.getStatus() == RealtimeSessionStatus.PENDING) {
            // Premiere activite reelle : connexion etablie -> debit du quota.
            session.setStatus(RealtimeSessionStatus.ACTIVE);
            session.setConnectedAt(Instant.now());
        }
        session.setTranscript(appendLine(session.getTranscript(), req.speaker(), req.text()));
        sessionManager.save(session);
    }

    /**
     * Pas de {@code @Transactional} : on declenche la notation (creation de
     * submission + pipeline async) APRES avoir commite l'etat de la session,
     * sinon la submission ne serait pas visible du thread async (REQUIRES_NEW).
     * Les acces lazy ici se limitent a {@code getId()} (resolus depuis le proxy,
     * sans session Hibernate ouverte).
     */
    public RealtimeSessionStateResponse finish(User user, UUID sessionId) {
        RealtimeSession session = ownedSession(user, sessionId);
        if (session.getStatus() == RealtimeSessionStatus.COMPLETED
                || session.getStatus() == RealtimeSessionStatus.FAILED) {
            // Double finish (idempotent) : « evaluated » se relit du transcript
            // (une submission n'existe que si le candidat a parlé).
            boolean alreadyEvaluated = session.getStatus() == RealtimeSessionStatus.COMPLETED
                    && session.getAttempt() != null && session.getProductionTask() != null
                    && hasCandidateTurn(session.getTranscript());
            return RealtimeSessionStateResponse.of(session, quotaService.remaining(user.getId()), alreadyEvaluated);
        }
        session.setEndedAt(Instant.now());
        boolean reallyHappened = session.getConnectedAt() != null
                && session.getTranscript() != null && !session.getTranscript().isBlank();
        session.setStatus(reallyHappened ? RealtimeSessionStatus.COMPLETED : RealtimeSessionStatus.FAILED);
        sessionManager.save(session);

        boolean evaluated = false;
        if (session.getStatus() == RealtimeSessionStatus.COMPLETED) {
            evaluated = triggerNotation(user, session);
        }
        return RealtimeSessionStateResponse.of(session, quotaService.remaining(user.getId()), evaluated);
    }

    /**
     * Cree une submission EO + lance la notation a partir du transcript. On
     * envoie le DIALOGUE COMPLET (tours examinateur + candidat) au pipeline : la
     * consigne « interaction » des rubriques fait noter le candidat tout en
     * s'appuyant sur l'echange pour juger l'adequation et la gestion (T2). Echec
     * de notation non bloquant : la session reste COMPLETED, pas de penalite.
     */
    private boolean triggerNotation(User user, RealtimeSession session) {
        if (session.getAttempt() == null || session.getProductionTask() == null) {
            log.warn("Session realtime {} sans attempt/tache : notation ignoree.", session.getId());
            return false;
        }
        String dialogue = session.getTranscript();
        if (!hasCandidateTurn(dialogue)) {
            log.info("Session realtime {} sans tour candidat : rien a noter.", session.getId());
            return false;
        }
        Integer durationSec = elapsedSeconds(session);
        try {
            productionEvaluationService.evaluateRealtimeTranscript(
                    user.getId(),
                    session.getProductionTask().getId(),
                    session.getAttempt().getId(),
                    dialogue,
                    durationSec);
        } catch (RuntimeException e) {
            log.warn("Notation realtime echouee pour session {} : {}", session.getId(), e.getMessage());
        }
        // La submission a été créée (l'éval s'effectue en arrière-plan et peut
        // échouer sans impacter l'existence de la submission) : côté front, il y a
        // bien un résultat à afficher (spinner puis note, ou statut FAILED rejouable).
        return true;
    }

    /** Vrai si le transcript contient au moins un tour « Candidat : … » non vide. */
    private static boolean hasCandidateTurn(String transcript) {
        if (transcript == null || transcript.isBlank()) {
            return false;
        }
        for (String line : transcript.split("\n")) {
            String trimmed = line.strip();
            if (trimmed.startsWith("Candidat :")
                    && !trimmed.substring("Candidat :".length()).strip().isEmpty()) {
                return true;
            }
        }
        return false;
    }

    private static Integer elapsedSeconds(RealtimeSession session) {
        if (session.getConnectedAt() == null || session.getEndedAt() == null) {
            return null;
        }
        long sec = session.getEndedAt().getEpochSecond() - session.getConnectedAt().getEpochSecond();
        return sec > 0 ? (int) sec : null;
    }

    private Attempt resolveAttempt(UUID attemptId, User user) {
        if (attemptId == null) {
            return null;
        }
        Attempt attempt = attemptManager.findById(attemptId)
                .orElseThrow(() -> new NotFoundException("Attempt introuvable : " + attemptId));
        if (attempt.getUser() == null || !attempt.getUser().getId().equals(user.getId())) {
            // 404 plutot que 403 : ne pas reveler l'existence des attempts d'autrui.
            throw new NotFoundException("Attempt introuvable : " + attemptId);
        }
        return attempt;
    }

    private RealtimeSession ownedSession(User user, UUID sessionId) {
        RealtimeSession session = sessionManager.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session introuvable : " + sessionId));
        if (session.getUser() == null || !session.getUser().getId().equals(user.getId())) {
            throw new NotFoundException("Session introuvable : " + sessionId);
        }
        return session;
    }

    private static String appendLine(String current, String speaker, String text) {
        String label = "EXAMINER".equalsIgnoreCase(speaker) ? "Examinateur" : "Candidat";
        String line = label + " : " + text.trim();
        return (current == null || current.isBlank()) ? line : current + "\n" + line;
    }
}
