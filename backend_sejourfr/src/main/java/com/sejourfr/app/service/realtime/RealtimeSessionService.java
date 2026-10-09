package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.dto.AppendTranscriptRequest;
import com.sejourfr.app.dto.FinishRealtimeSessionRequest;
import com.sejourfr.app.dto.RealtimeSessionDescriptor;
import com.sejourfr.app.dto.RealtimeSessionStateResponse;
import com.sejourfr.app.dto.ResumeRealtimeSessionRequest;
import com.sejourfr.app.dto.StartRealtimeSessionRequest;
import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.RealtimeConductEventType;
import com.sejourfr.app.enums.RealtimeEndCause;
import com.sejourfr.app.enums.RealtimeFallbackReason;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.RealtimeMesureManager;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.ProductionEvaluationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Orchestre les sessions d'expression orale temps reel (Taches 1 & 2). Quatre
 * cas d'usage : (1) demarrer une session (verif quota -> emission token ephemere
 * Gemini, ou bascule async si indisponible), (2) accumuler le transcript relaye
 * par le client (et debiter le quota a la 1re connexion reelle), (3) REPRENDRE
 * une session dont le WebSocket est tombe, (4) cloturer.
 *
 * <p>INVARIANT CENTRAL : un slot de simulation n'est debite QU'UNE FOIS par
 * session, quoi qu'il arrive au reseau. Il l'est a la transition
 * {@code PENDING -> ACTIVE}, faite sous verrou de ligne, jamais a l'emission
 * d'un token — donc ni le demarrage, ni une reprise, ni un reessai de fragment
 * ne peuvent le rejouer.
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
 *
 * <p>MESURE (V090, lot M du chantier examinateur IA) : chaque session porte sa
 * version de persona, sa plateforme, sa fenêtre de silence VAD et sa cause de
 * fin ; chaque segment relayé est conservé horodaté, chaque repli asynchrone et
 * chaque reprise sont tracés. Rien de tout cela ne change le comportement servi
 * au candidat ni ce que lit la notation.
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
    private final ProductionAccessService accessService;
    private final RealtimeProperties props;
    private final RealtimeMesureManager mesureManager;
    private final RealtimeConductConfig conductConfig;

    /** Ouverture sans plateforme déclarée ({@link ClientPlatform#UNKNOWN}). */
    public RealtimeSessionDescriptor start(User user, StartRealtimeSessionRequest req) {
        return start(user, req, ClientPlatform.UNKNOWN);
    }

    /**
     * @param platform plateforme déclarée par l'appel ({@code X-Sejourfr-Client}),
     *                 conservée pour la mesure ; n'influence rien d'autre.
     */
    @Transactional
    public RealtimeSessionDescriptor start(User user, StartRealtimeSessionRequest req, ClientPlatform platform) {
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

        // Session visée validée AVANT de consommer un slot temps réel : sans
        // ça, on ouvrait une session sur n'importe quel attempt de
        // l'utilisateur (y compris une sous-épreuve pré-terminée par le verrou
        // freemium ou une épreuve écrite), pour finir refusé à la notation.
        Attempt attempt = resolveAttempt(req.attemptId(), user);
        if (attempt != null) {
            accessService.assertCanSubmit(user.getId(), attempt, task);
        }

        RealtimeQuotaService.Quota quota = quotaService.evaluate(user.getId());
        if (!tokenBroker.isConfigured() || !quota.canStartRealtime()) {
            RealtimeFallbackReason reason = tokenBroker.isConfigured()
                    ? RealtimeFallbackReason.QUOTA : RealtimeFallbackReason.NOT_CONFIGURED;
            mesureManager.tracerRepli(user.getId(), task.getId(), null, tache, reason);
            return RealtimeSessionDescriptor.asyncFallback(tache, target, quota.remaining());
        }

        RealtimeTokenBroker.MintedSession minted;
        try {
            minted = tokenBroker.mint(personaBuilder.build(task, examenBlanc(attempt)), null);
        } catch (RuntimeException e) {
            // Mint en echec : on ne bloque pas, on bascule en async.
            log.warn("Mint token realtime echoue, bascule async : {}", e.getMessage());
            mesureManager.tracerRepli(user.getId(), task.getId(), null, tache, RealtimeFallbackReason.MINT_FAILED);
            return RealtimeSessionDescriptor.asyncFallback(tache, target, quota.remaining());
        }

        RealtimeSession session = new RealtimeSession();
        session.setUser(user);
        // Un seul porteur réservé : le GRANT INTEGRAL admin d'abord, sinon l'achat
        // (RealtimeQuotaService). Le débit, lui, n'a lieu qu'à la connexion.
        session.setSubscription(quota.achatPorteur().orElse(null));
        session.setAccessOverrideId(quota.grantPorteur().map(AccessOverride::getId).orElse(null));
        session.setAttempt(attempt);
        session.setProductionTask(task);
        session.setEpreuve(EpreuveType.TCF_EO);
        session.setTacheNumero(tache);
        session.setProvider(tokenBroker.provider());
        session.setModel(minted.model());
        session.setStatus(RealtimeSessionStatus.PENDING);
        session.setPersonaVersion(props.getPersonaVersion());
        session.setClientPlatform(platform == null ? ClientPlatform.UNKNOWN : platform);
        session.setVadSilenceMs(props.getGemini().getVad().getSilenceDurationMs());
        session.setConductConfigVersion(conductConfig.version());
        session = sessionManager.save(session);

        // Slot reserve par cette session -> on l'enleve de l'affichage.
        return descriptor(session, minted, tache, target, Math.max(0, quota.remaining() - 1), null);
    }

    /**
     * REPREND une session dont le WebSocket est tombe (coupure reseau, appli en
     * arriere-plan) : emet un NOUVEAU token ephemere qui rouvre la MEME
     * conversation, sans re-debiter le slot de simulation.
     *
     * <p>Le handle de reprise est verrouille dans le setup du token cote serveur :
     * le token est contraint, le client ne peut poser aucun champ de setup, donc
     * c'est le seul chemin possible pour le lui transmettre.
     *
     * <p>Aucune ecriture de quota ici : le slot a deja ete debite au premier
     * fragment de transcript ({@code PENDING -> ACTIVE}), et une session encore
     * {@code PENDING} le sera a son premier fragment — dans les deux cas, une
     * seule fois.
     */
    @Transactional
    public RealtimeSessionDescriptor resume(User user, UUID sessionId, ResumeRealtimeSessionRequest req) {
        RealtimeSession session = ownedSessionForUpdate(user, sessionId);
        if (session.getStatus() == RealtimeSessionStatus.COMPLETED
                || session.getStatus() == RealtimeSessionStatus.FAILED) {
            throw new BusinessException("Cette simulation est deja terminee : elle ne peut plus etre reprise.");
        }
        RealtimeProperties.SessionResumption conf = props.getGemini().getSessionResumption();
        if (!conf.isEnabled() || !tokenBroker.supportsResumption()) {
            throw new BusinessException("La reprise de session n'est pas disponible.");
        }
        if (session.getResumptionCount() >= conf.getMaxResumptions()) {
            throw new BusinessException("Nombre de reprises atteint pour cette simulation.");
        }
        ProductionTask task = session.getProductionTask();
        if (task == null) {
            throw new BusinessException("Cette simulation n'a plus de consigne rattachee.");
        }

        applyResumptionHandle(session, req == null ? null : req.resumptionHandle());
        RealtimeTokenBroker.MintedSession minted;
        try {
            minted = tokenBroker.mint(personaBuilder.build(task, examenBlanc(session.getAttempt())),
                    session.getResumptionHandle());
        } catch (RuntimeException e) {
            // Meme philosophie qu'au demarrage : on ne bloque pas le candidat.
            log.warn("Reprise de session {} impossible (mint KO) : {}", session.getId(), e.getMessage());
            mesureManager.tracerRepli(user.getId(), task.getId(), session.getId(), session.getTacheNumero(),
                    RealtimeFallbackReason.RESUME_MINT_FAILED);
            return RealtimeSessionDescriptor.asyncFallback(
                    session.getTacheNumero(), task.getDureeMaxSec(), quotaService.remaining(user.getId()));
        }
        session.setResumptionCount(session.getResumptionCount() + 1);
        sessionManager.save(session);
        // Seul le serveur sait quel handle il vient de verrouiller : sans lui, la
        // conversation repart d'un contexte vide côté fournisseur.
        mesureManager.ajouterEvenement(session.getId(), session.getResumptionHandle() != null
                ? RealtimeConductEventType.RESUME_WITH_HANDLE
                : RealtimeConductEventType.RESUME_WITHOUT_HANDLE, null, null);

        // Le slot est deja debite des lors que la session a parle (ACTIVE) ; il
        // ne le sera qu'au premier fragment tant qu'elle est PENDING.
        int remaining = quotaService.remaining(user.getId());
        int shown = session.getStatus() == RealtimeSessionStatus.PENDING
                ? Math.max(0, remaining - 1) : remaining;
        return descriptor(session, minted, session.getTacheNumero(), task.getDureeMaxSec(), shown,
                session.getResumptionHandle() != null);
    }

    @Transactional
    public void appendTranscript(User user, UUID sessionId, AppendTranscriptRequest req) {
        // Lecture VERROUILLEE : deux connexions du meme candidat peuvent se
        // chevaucher (celle qui tombe et celle qui reprend). Sans le verrou, deux
        // ajouts concurrents debitaient deux fois le slot et perdaient un tour.
        RealtimeSession session = ownedSessionForUpdate(user, sessionId);
        if (session.getStatus() == RealtimeSessionStatus.COMPLETED
                || session.getStatus() == RealtimeSessionStatus.FAILED) {
            // Fragment tardif apres cloture : on ignore silencieusement.
            return;
        }
        boolean handleUpdated = applyResumptionHandle(session, req.resumptionHandle());
        if (isAlreadyApplied(session, req.turnIndex())) {
            // Reessai reseau d'un tour deja enregistre : ne rien dupliquer, et
            // surtout ne pas rejouer la transition PENDING -> ACTIVE.
            if (handleUpdated) {
                sessionManager.save(session);
            }
            return;
        }
        if (session.getStatus() == RealtimeSessionStatus.PENDING) {
            // Premiere activite reelle : connexion etablie -> debit d'UNE session
            // sur le porteur reserve (achat ou GRANT INTEGRAL admin), par l'unique
            // autorite du quota. Transition PENDING->ACTIVE unique (garde du if +
            // verrou de ligne), donc debit exactement une fois par session ; le
            // debit est lui-meme conditionne au solde > 0. Une session jamais
            // connectee (PENDING) ou en echec sans connexion ne consomme rien.
            session.setStatus(RealtimeSessionStatus.ACTIVE);
            session.setConnectedAt(Instant.now());
            quotaService.debiter(session);
        }
        if (req.turnIndex() != null) {
            session.setLastTurnIndex(req.turnIndex());
        }
        session.setTranscript(appendLine(session.getTranscript(), req.speaker(), req.text()));
        sessionManager.save(session);
        mesureManager.ajouterTour(session.getId(), req.turnIndex(), speakerCode(req.speaker()), req.text().trim(),
                req.startedAtMs(), req.endedAtMs());
    }

    /**
     * Vrai si ce tour a deja ete applique. Le client numerote ses tours de facon
     * strictement croissante ; un index deja vu est donc un REESSAI, pas un
     * nouveau tour. Sans index (client historique), on ne peut rien dedupliquer :
     * l'appel reste ajoutant, comme avant.
     */
    private static boolean isAlreadyApplied(RealtimeSession session, Integer turnIndex) {
        return turnIndex != null
                && session.getLastTurnIndex() != null
                && turnIndex <= session.getLastTurnIndex();
    }

    /** Memorise le dernier handle de reprise. Vrai si la session a change. */
    private static boolean applyResumptionHandle(RealtimeSession session, String handle) {
        if (handle == null || handle.isBlank() || handle.equals(session.getResumptionHandle())) {
            return false;
        }
        session.setResumptionHandle(handle);
        return true;
    }

    private RealtimeSessionDescriptor descriptor(RealtimeSession session,
                                                 RealtimeTokenBroker.MintedSession minted,
                                                 int tache,
                                                 Integer target,
                                                 int sessionsRemaining,
                                                 Boolean contextRestored) {
        RealtimeProperties.Audio audio = props.getAudio();
        RealtimeProperties.Gemini gemini = props.getGemini();
        boolean resumable = gemini.getSessionResumption().isEnabled() && tokenBroker.supportsResumption();
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
                gemini.getVoice(),
                tache,
                target,
                sessionsRemaining,
                resumable,
                resumable
                        ? Math.max(0, gemini.getSessionResumption().getMaxResumptions() - session.getResumptionCount())
                        : 0,
                gemini.getNewSessionExpireSeconds(),
                contextRestored,
                conductConfig.client()
        );
    }

    /**
     * Tâche jouée dans un examen blanc (d'épreuve ou complet) : la T2 s'ouvre
     * sur l'en-tête d'enchaînement. Même autorité que les quotas d'examen.
     */
    private static boolean examenBlanc(Attempt attempt) {
        return attempt != null && ProductionAccessService.isExamSession(attempt);
    }

    /**
     * Pas de {@code @Transactional} : on declenche la notation (creation de
     * submission + pipeline async) APRES avoir commite l'etat de la session,
     * sinon la submission ne serait pas visible du thread async (REQUIRES_NEW).
     * Les acces lazy ici se limitent a {@code getId()} (resolus depuis le proxy,
     * sans session Hibernate ouverte).
     */
    public RealtimeSessionStateResponse finish(User user, UUID sessionId) {
        return finish(user, sessionId, null);
    }

    /**
     * Clôture avec ce que le client déclare (V090) : la cause de fin et ses
     * événements de conduite, enregistrés à la PREMIÈRE clôture seulement (une
     * clôture rejouée ne les duplique pas). {@code ERROR} clôt en {@code FAILED}
     * sans notation : le candidat repasse sur l'enregistrement classique, noter
     * le dialogue créerait une seconde soumission.
     */
    public RealtimeSessionStateResponse finish(User user, UUID sessionId, FinishRealtimeSessionRequest req) {
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
        RealtimeEndCause endCause = req == null ? null : RealtimeEndCause.parse(req.endCause());
        session.setEndedAt(Instant.now());
        session.setEndCause(endCause);
        boolean reallyHappened = endCause != RealtimeEndCause.ERROR
                && session.getConnectedAt() != null
                && session.getTranscript() != null && !session.getTranscript().isBlank();
        session.setStatus(reallyHappened ? RealtimeSessionStatus.COMPLETED : RealtimeSessionStatus.FAILED);
        sessionManager.save(session);
        enregistrerEvenements(session.getId(), req == null ? null : req.events());

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
     *
     * @return vrai seulement si une submission a bien ete creee. Une garde
     *         refusee (epreuve terminee, chrono, quota) ne cree rien : annoncer
     *         « resultat disponible » enverrait le front sur un ecran vide.
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
            return false;
        }
        // La submission a été créée (l'éval s'effectue en arrière-plan et peut
        // échouer sans impacter l'existence de la submission) : côté front, il y a
        // bien un résultat à afficher (spinner puis note, ou statut FAILED rejouable).
        return true;
    }

    /** Événements déclarés par le client ; un type inconnu ou réservé au serveur est ignoré. */
    private void enregistrerEvenements(UUID sessionId, List<FinishRealtimeSessionRequest.ConductEvent> events) {
        if (events == null) return;
        for (FinishRealtimeSessionRequest.ConductEvent e : events) {
            if (e == null) continue;
            RealtimeConductEventType type = RealtimeConductEventType.parse(e.type());
            if (type == null || !type.declarableParLeClient()) continue;
            mesureManager.ajouterEvenement(sessionId, type, e.atMs(), e.valueMs());
        }
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
        return owned(user, sessionId, sessionManager.findById(sessionId).orElse(null));
    }

    /** Idem, mais verrouillee : a utiliser des qu'on va ecrire sur la session. */
    private RealtimeSession ownedSessionForUpdate(User user, UUID sessionId) {
        return owned(user, sessionId, sessionManager.findByIdForUpdate(sessionId).orElse(null));
    }

    private static RealtimeSession owned(User user, UUID sessionId, RealtimeSession session) {
        if (session == null || session.getUser() == null
                || !session.getUser().getId().equals(user.getId())) {
            // 404 plutot que 403 : ne pas reveler l'existence des sessions d'autrui.
            throw new NotFoundException("Session introuvable : " + sessionId);
        }
        return session;
    }

    private static String speakerCode(String speaker) {
        return "EXAMINER".equalsIgnoreCase(speaker) ? "EXAMINER" : "CANDIDATE";
    }

    private static String appendLine(String current, String speaker, String text) {
        String label = "EXAMINER".equalsIgnoreCase(speaker) ? "Examinateur" : "Candidat";
        String line = label + " : " + text.trim();
        return (current == null || current.isBlank()) ? line : current + "\n" + line;
    }
}
