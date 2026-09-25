package com.sejourfr.app.service.diagnosticrun;

import com.sejourfr.app.dto.DiagnosticRunCreateRequest;
import com.sejourfr.app.dto.DiagnosticRunCreatedResponse;
import com.sejourfr.app.dto.DiagnosticRunSubmitRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.DiagnosticRun;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.JetonSecret;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Le cycle de vie d'une {@code diagnostic_run}</b> (chantier Suivi, lot 2a) :
 * la TRACE d'un passage dans le tunnel diagnostic, jamais son contenu (Q3).
 *
 * <h2>Qui pose quoi</h2>
 * <table>
 *   <tr><th>Fait</th><th>QUICK_TCF</th><th>CIVIQUE</th><th>FULL_TCF</th></tr>
 *   <tr><td>Sujet vu (creation)</td><td colspan="3">client, a l'affichage de la
 *       premiere question — {@link #create}</td></tr>
 *   <tr><td>Session liee</td><td>a la creation si connecte ; au handoff
 *       ({@code POST /api/diagnostics?diagnosticRunId=}) sinon</td>
 *       <td colspan="2">a la creation ({@code sessionId})</td></tr>
 *   <tr><td>Soumis</td><td><b>client</b>, a « Analyser mes reponses » —
 *       {@link #submit}</td><td><b>serveur</b>, a la fin de l'attempt</td>
 *       <td><b>serveur</b>, a la cloture</td></tr>
 *   <tr><td>Claim</td><td colspan="3">serveur, dans la transaction d'auth —
 *       {@link DiagnosticRunClaimService}</td></tr>
 * </table>
 *
 * <p>🛑 <b>Une seule autorite de « soumis » par type</b> (D23). Le TCF rapide
 * invite n'a aucun fait serveur avant le compte (sa production reste sur
 * l'appareil, V053), et {@code POST /api/diagnostics} est appele au DEMARRAGE
 * par un candidat connecte : ce n'est pas une soumission. Le civique et le
 * complet, eux, ont un fait serveur fiable ; l'appel client y est refuse (409)
 * pour qu'aucun des deux ne puisse contredire l'autre.
 *
 * <p>🛑 <b>Un identifiant de run recu d'un client n'est jamais cru sur
 * parole</b> : l'appartenance se prouve par le compte (porteur de la run) ou
 * par le {@code claimToken}. Un runId n'est pas un secret — il voyage dans les
 * evenements d'analytics.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DiagnosticRunService {

    /** 256 bits d'aleatoire (brief §3.3 : au moins 128). */
    static final int CLAIM_TOKEN_BYTES = 32;

    private final DiagnosticRunManager runManager;
    private final DiagnosticSessionManager quickSessionManager;
    private final TcfDiagnosticSessionManager tcfSessionManager;
    private final CivicDiagnosticSessionManager civicSessionManager;
    private final AnalyticsConfig config;

    // ------------------------------------------------------------------------
    // Creation — « sujet vu »
    // ------------------------------------------------------------------------

    /**
     * Cree la run d'un passage, ou rend celle qui existe deja pour cette cle ou
     * cette session.
     *
     * <p><b>Idempotence</b>, dans l'ordre : (1) une session fournie et deja
     * tracee rend sa run ; (2) une cle {@code (anonymousId, clientKey)} deja vue
     * rend sa run ; (3) sinon, insertion {@code ON CONFLICT DO NOTHING} (deux
     * requetes concurrentes ne creent qu'une run). Un rejeu rend un
     * <b>nouveau</b> jeton : seul le hash est stocke, l'ancien ne peut pas etre
     * rendu.
     *
     * @param userId compte de l'appelant, {@code null} pour un visiteur
     * @param ip     IP resolue : prouve l'appartenance d'une session civique
     *               invitee, jamais persistee ici
     */
    @Transactional
    public DiagnosticRunCreatedResponse create(DiagnosticRunCreateRequest request, ClientContext client,
                                               String ip, UUID userId) {
        DiagnosticRunType type = DiagnosticRunType.parseOrThrow(request.diagnosticType());
        if (type == DiagnosticRunType.FULL_TCF && userId == null) {
            throw new AccessDeniedException("Le diagnostic complet se passe avec un compte.");
        }
        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        Instant now = Instant.now();

        UUID sessionId = request.sessionId();
        if (sessionId != null) {
            verifierSession(type, sessionId, userId, ip);
            Optional<DiagnosticRun> dejaTracee = runManager.findBySession(type, sessionId);
            if (dejaTracee.isPresent()) {
                return reemettre(dejaTracee.get(), now);
            }
        }

        Optional<DiagnosticRun> rejeu = runManager.findByClientKey(ctx.anonymousId(), request.clientKey());
        if (rejeu.isPresent()) {
            return rejouer(rejeu.get(), type, sessionId, now);
        }

        String token = JetonSecret.tirer(CLAIM_TOKEN_BYTES);
        Instant expiresAt = now.plus(config.claimTokenTtl());
        UUID id = UUID.randomUUID();
        boolean created = runManager.insertIfAbsent(new DiagnosticRunManager.NewRun(
                id, type, ctx.platform(), ctx.appVersion(), ctx.anonymousId(), userId,
                request.clientKey(), JetonSecret.sha256Hex(token), expiresAt,
                type == DiagnosticRunType.QUICK_TCF ? sessionId : null,
                type == DiagnosticRunType.FULL_TCF ? sessionId : null,
                type == DiagnosticRunType.CIVIQUE ? sessionId : null), now);
        if (!created) {
            // Une requete concurrente avec la meme cle a gagne l'insertion.
            DiagnosticRun gagnante = runManager.findByClientKey(ctx.anonymousId(), request.clientKey())
                    .orElseThrow(() -> new IllegalStateException("Run introuvable apres conflit de cle"));
            return rejouer(gagnante, type, sessionId, now);
        }
        log.info("Diagnostic run creee : id={} type={} connecte={}", id, type, userId != null);
        return new DiagnosticRunCreatedResponse(id, type, token, expiresAt, now, true);
    }

    private DiagnosticRunCreatedResponse rejouer(DiagnosticRun run, DiagnosticRunType type, UUID sessionId,
                                                 Instant now) {
        if (run.getDiagnosticType() != type) {
            throw new IllegalStateException("Cette clientKey designe deja une run " + run.getDiagnosticType()
                    + " : une cle par passage.");
        }
        if (sessionId != null) {
            // Session deja verifiee par l'appelant ; la liaison n'ecrit que si
            // la run n'en avait aucune.
            runManager.linkSession(run.getId(), type, sessionId, now);
        }
        return reemettre(run, now);
    }

    private DiagnosticRunCreatedResponse reemettre(DiagnosticRun run, Instant now) {
        String token = JetonSecret.tirer(CLAIM_TOKEN_BYTES);
        Instant expiresAt = now.plus(config.claimTokenTtl());
        runManager.rotateToken(run.getId(), JetonSecret.sha256Hex(token), expiresAt, now);
        return new DiagnosticRunCreatedResponse(run.getId(), run.getDiagnosticType(), token, expiresAt,
                run.getSubjectViewedAt(), false);
    }

    /**
     * La session fournie appartient-elle a l'appelant ? Meme regle que sa
     * propre lecture : le compte porteur, ou l'IP pour une session civique
     * invitee (V053). 404 sinon — on ne revele pas son existence.
     */
    private void verifierSession(DiagnosticRunType type, UUID sessionId, UUID userId, String ip) {
        boolean proprietaire = switch (type) {
            case QUICK_TCF -> quickSessionManager.findById(sessionId)
                    .map(s -> estLeCompte(s.getUser(), userId)).orElse(false);
            case FULL_TCF -> tcfSessionManager.findById(sessionId)
                    .map(s -> estLeCompte(s.getUser(), userId)).orElse(false);
            case CIVIQUE -> civicSessionManager.findById(sessionId)
                    .map(s -> estLeCompte(s.getUser(), userId) || estLeVisiteur(s, ip)).orElse(false);
        };
        if (!proprietaire) {
            throw new NotFoundException("Diagnostic introuvable : " + sessionId);
        }
    }

    private static boolean estLeCompte(User porteur, UUID userId) {
        return porteur != null && userId != null && userId.equals(porteur.getId());
    }

    private static boolean estLeVisiteur(CivicDiagnosticSession session, String ip) {
        return session.getUser() == null && ip != null && ip.equals(session.getClientIp());
    }

    // ------------------------------------------------------------------------
    // « Soumis »
    // ------------------------------------------------------------------------

    /**
     * « Soumis » d'une run {@code QUICK_TCF}, a « Analyser mes reponses ».
     * <b>Une seule fois</b> : un second appel ne redate rien (204 quand meme).
     *
     * <p>Appartenance : le compte porteur de la run, ou le {@code claimToken}
     * valide (et, si les deux sont connus, le meme identifiant de mesure). Un
     * appelant connecte doit porter la run ou montrer son jeton ; il en devient
     * alors le porteur — « soumis connecte » implique « compte rattache ».
     *
     * @throws NotFoundException    run absente ou pas a l'appelant
     * @throws IllegalStateException type dont « soumis » est pose par le serveur (409)
     */
    @Transactional
    public void submit(UUID runId, DiagnosticRunSubmitRequest request, UUID userId, UUID anonymousId) {
        DiagnosticRunManager.State run = runManager.findState(runId)
                .orElseThrow(() -> new NotFoundException("Run introuvable : " + runId));
        Instant now = Instant.now();
        String token = request == null ? null : request.claimToken();
        if (!appartient(run, userId, anonymousId, token, now)) {
            throw new NotFoundException("Run introuvable : " + runId);
        }
        if (run.type() != DiagnosticRunType.QUICK_TCF) {
            throw new IllegalStateException("« Soumis » est pose par le serveur pour un diagnostic "
                    + run.type() + " : aucun appel client n'est attendu.");
        }
        runManager.markSubmitted(runId, userId, now);
    }

    /**
     * Regle d'appartenance d'une run a l'appelant. Porteur pose : seul ce
     * compte, ou un visiteur deconnecte qui montre le jeton. Sans porteur : le
     * jeton, toujours.
     */
    static boolean appartient(DiagnosticRunManager.State run, UUID userId, UUID anonymousId, String token,
                              Instant now) {
        if (run.userId() != null && userId != null) {
            return run.userId().equals(userId);
        }
        return jetonValide(run, token, now)
                && (run.anonymousId() == null || anonymousId == null
                || run.anonymousId().equals(anonymousId));
    }

    static boolean jetonValide(DiagnosticRunManager.State run, String token, Instant now) {
        return run.claimTokenExpiresAt() != null
                && run.claimTokenExpiresAt().isAfter(now)
                && JetonSecret.correspond(token, run.claimTokenHash());
    }

    // ------------------------------------------------------------------------
    // Branchements serveur
    // ------------------------------------------------------------------------

    /**
     * Handoff du TCF rapide : la session du compte vient d'etre ouverte (ou
     * reprise) avec la run que le client avait creee en invite. Liee seulement
     * si la run appartient DEJA a ce compte — claimee a l'auth, ou creee
     * connecte. Aucun jeton ici : c'est le claim qui a prouve la run.
     *
     * <p>Best-effort : une run inconnue, d'un tiers ou deja liee est ignoree en
     * silence, et une erreur ne fait jamais echouer l'ouverture du diagnostic.
     */
    public void linkQuickTcfAtHandoff(UUID runId, UUID userId, UUID sessionId) {
        if (runId == null || userId == null || sessionId == null) return;
        try {
            runManager.findState(runId)
                    .filter(run -> run.type() == DiagnosticRunType.QUICK_TCF)
                    .filter(run -> userId.equals(run.userId()))
                    .ifPresent(run -> runManager.linkSession(runId, DiagnosticRunType.QUICK_TCF, sessionId,
                            Instant.now()));
        } catch (RuntimeException e) {
            log.warn("Liaison run -> session TCF rapide impossible (run={}, session={}) : {}",
                    runId, sessionId, e.toString());
        }
    }

    /**
     * Fin de l'attempt d'un diagnostic civique (public ou connecte, fin
     * explicite, echeance ou cloture) : la run liee a sa session devient
     * « soumise ». {@code submitted_authenticated} = l'attempt a-t-il un porteur
     * A CET INSTANT — un invite qui s'inscrit ensuite reste un soumis anonyme.
     */
    public void onCivicAttemptFinished(Attempt attempt) {
        CivicDiagnosticSession session = attempt.getCivicDiagnostic();
        if (session == null) return;
        UUID userId = attempt.getUser() == null ? null : attempt.getUser().getId();
        runManager.markSubmittedByCivicSession(session.getId(), userId, Instant.now());
    }

    /** Cloture du diagnostic complet : toujours un compte, donc un soumis connecte. */
    public void onFullTcfClosed(TcfDiagnosticSession session) {
        UUID userId = session.getUser() == null ? null : session.getUser().getId();
        runManager.markSubmittedByTcfSession(session.getId(), userId, Instant.now());
    }
}
