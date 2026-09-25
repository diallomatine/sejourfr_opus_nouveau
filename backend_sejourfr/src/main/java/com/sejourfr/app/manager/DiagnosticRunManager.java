package com.sejourfr.app.manager;

import com.sejourfr.app.entity.DiagnosticRun;
import com.sejourfr.app.enums.AuthKind;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticRunClaimVia;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.repository.DiagnosticRunRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Seule couche autorisee a toucher {@link DiagnosticRunRepository}.
 *
 * <p>Les transitions rendent un {@code boolean} : « cette ecriture a-t-elle eu
 * lieu ? ». Faux n'est jamais une erreur — la run etait deja soumise, deja
 * claimee, deja liee, ou le jeton ne correspondait pas.
 */
@Component
@RequiredArgsConstructor
public class DiagnosticRunManager {

    private final DiagnosticRunRepository repository;

    /**
     * Type serveur des runs qui existent parmi {@code ids}. Une run absente de la
     * map n'existe pas. Une seule requete, quelle que soit la taille du lot.
     */
    @Transactional(readOnly = true)
    public Map<UUID, DiagnosticRunType> typesByIds(Collection<UUID> ids) {
        Map<UUID, DiagnosticRunType> types = new HashMap<>();
        if (ids == null || ids.isEmpty()) return types;
        for (DiagnosticRunRepository.RunType row : repository.findTypesByIdIn(ids)) {
            types.put(row.getId(), row.getType());
        }
        return types;
    }

    @Transactional
    public DiagnosticRun save(DiagnosticRun run) {
        return repository.save(run);
    }

    /**
     * Etat courant d'une run, relu en base a chaque appel (jamais l'entite
     * du contexte de persistance, que les {@code UPDATE} natifs ne rafraichissent
     * pas). C'est ce que lisent les verifications d'appartenance et le claim.
     */
    public record State(UUID id, DiagnosticRunType type, UUID anonymousId, UUID userId, Instant submittedAt,
                        String claimTokenHash, Instant claimTokenExpiresAt, Instant claimedAt) {
    }

    @Transactional(readOnly = true)
    public Optional<State> findState(UUID id) {
        if (id == null) return Optional.empty();
        return repository.findStateById(id).map(r -> new State(r.getId(), r.getDiagnosticType(),
                r.getAnonymousId(), r.getUserId(), r.getSubmittedAt(), r.getClaimTokenHash(),
                r.getClaimTokenExpiresAt(), r.getClaimedAt()));
    }

    /** Donnees d'une run a creer ; l'une au plus des trois sessions est posee. */
    public record NewRun(UUID id, DiagnosticRunType type, ClientPlatform platform, String appVersion,
                         UUID anonymousId, UUID userId, UUID clientKey, String claimTokenHash,
                         Instant claimTokenExpiresAt, UUID quickSessionId, UUID tcfSessionId,
                         UUID civicSessionId) {
    }

    /** @return {@code true} si la run a ete creee, {@code false} si sa cle existait deja */
    @Transactional
    public boolean insertIfAbsent(NewRun run, Instant now) {
        return repository.insertIfAbsent(run.id(), run.type().name(),
                run.platform() == null ? null : run.platform().name(), run.appVersion(),
                run.anonymousId(), run.userId(), run.clientKey(), now, run.claimTokenHash(),
                run.claimTokenExpiresAt(), run.quickSessionId(), run.tcfSessionId(),
                run.civicSessionId()) == 1;
    }

    @Transactional(readOnly = true)
    public Optional<DiagnosticRun> findByClientKey(UUID anonymousId, UUID clientKey) {
        if (anonymousId == null || clientKey == null) return Optional.empty();
        return repository.findByAnonymousIdAndClientKey(anonymousId, clientKey);
    }

    /** La run deja liee a cette session (la plus ancienne s'il y en avait plusieurs). */
    @Transactional(readOnly = true)
    public Optional<DiagnosticRun> findBySession(DiagnosticRunType type, UUID sessionId) {
        if (sessionId == null) return Optional.empty();
        return switch (type) {
            case QUICK_TCF -> repository.findFirstByDiagnosticSessionIdOrderBySubjectViewedAtAsc(sessionId);
            case FULL_TCF -> repository.findFirstByTcfDiagnosticSessionIdOrderBySubjectViewedAtAsc(sessionId);
            case CIVIQUE -> repository.findFirstByCivicDiagnosticSessionIdOrderBySubjectViewedAtAsc(sessionId);
        };
    }

    @Transactional
    public void rotateToken(UUID runId, String claimTokenHash, Instant expiresAt, Instant now) {
        repository.rotateToken(runId, claimTokenHash, expiresAt, now);
    }

    /** Lie la run a sa session, si elle n'en a pas encore et que les types concordent. */
    @Transactional
    public boolean linkSession(UUID runId, DiagnosticRunType type, UUID sessionId, Instant now) {
        if (runId == null || sessionId == null) return false;
        return switch (type) {
            case QUICK_TCF -> repository.linkQuickSession(runId, sessionId, now);
            case FULL_TCF -> repository.linkTcfSession(runId, sessionId, now);
            case CIVIQUE -> repository.linkCivicSession(runId, sessionId, now);
        } == 1;
    }

    /**
     * @param userId compte de l'appelant s'il est connecte ; pose comme porteur
     *               si la run n'en avait pas
     */
    @Transactional
    public boolean markSubmitted(UUID runId, UUID userId, Instant now) {
        return repository.markSubmitted(runId, userId != null, userId, now) == 1;
    }

    /**
     * « Soumis » serveur a la fin de l'attempt civique ; {@code userId} nul =
     * invite. {@code answered} / {@code questions} : la mesure figee a cet
     * instant (V076), lue par le seuil de la config.
     */
    @Transactional
    public int markSubmittedByCivicSession(UUID sessionId, UUID userId, int answered, int questions,
                                           Instant now) {
        if (sessionId == null) return 0;
        return repository.markSubmittedByCivicSession(sessionId, userId != null, userId, answered, questions,
                now);
    }

    /** « Soumis » serveur a la cloture du diagnostic complet (toujours connecte). */
    @Transactional
    public int markSubmittedByTcfSession(UUID sessionId, UUID userId, Instant now) {
        if (sessionId == null) return 0;
        return repository.markSubmittedByTcfSession(sessionId, userId, now);
    }

    /** Claim par jeton, conditions redites dans l'UPDATE. */
    @Transactional
    public boolean claim(UUID runId, String claimTokenHash, UUID userId, AuthKind kind,
                         DiagnosticRunClaimVia via, Instant now) {
        return repository.claim(runId, claimTokenHash, userId, kind.name(), via.name(), now) == 1;
    }

    /**
     * <b>Plan ↔ run (Q8)</b> : la run fondatrice du parcours {@code journeyId},
     * resolue par le serveur seul. Vide si le parcours n'appartient pas a
     * {@code userId}, s'il n'a aucun diagnostic journalise, ou si ce diagnostic
     * n'a pas de run liee (diagnostic anterieur au lot 2a, client ancien) —
     * {@code null} = inconnu, jamais une run devinee.
     */
    @Transactional(readOnly = true)
    public Optional<DiagnosticRun> findFoundingRun(UUID journeyId, UUID userId) {
        if (journeyId == null || userId == null) return Optional.empty();
        return repository.findFoundingRun(journeyId, userId);
    }

    /** Retention : oublie l'identifiant de mesure des runs plus vieilles que {@code cutoff}. */
    @Transactional
    public int forgetAnonymousIdBefore(Instant cutoff, int limit, Instant now) {
        return repository.forgetAnonymousIdBefore(cutoff, limit, now);
    }
}
