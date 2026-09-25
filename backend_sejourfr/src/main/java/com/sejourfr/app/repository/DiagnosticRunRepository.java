package com.sejourfr.app.repository;

import com.sejourfr.app.entity.DiagnosticRun;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * 🛑 <b>Chaque transition est un {@code UPDATE} conditionnel</b> : « soumis une
 * seule fois », « claime une seule fois », « lie une seule fois » sont tenus par
 * la clause {@code WHERE}, pas par une lecture suivie d'une ecriture. Deux
 * requetes concurrentes ne peuvent donc pas ecrire deux fois le meme fait ;
 * l'appelant lit le nombre de lignes touchees.
 *
 * <p>Aucune de ces requetes ne vide le contexte de persistance : elles tournent
 * au milieu de transactions metier (fin d'attempt, auth) dont les entites
 * doivent rester attachees.
 */
public interface DiagnosticRunRepository extends JpaRepository<DiagnosticRun, UUID> {

    /** Type de chacune des runs existantes parmi {@code ids}, en une requete. */
    @Query("SELECT r.id AS id, r.diagnosticType AS type FROM DiagnosticRun r WHERE r.id IN :ids")
    List<RunType> findTypesByIdIn(@Param("ids") Collection<UUID> ids);

    interface RunType {
        UUID getId();

        com.sejourfr.app.enums.DiagnosticRunType getType();
    }

    /**
     * L'etat courant d'une run, lu <b>en colonnes</b> et non en entite : une
     * projection scalaire relit la base, la ou une entite deja chargee dans le
     * contexte de persistance garderait les valeurs d'avant un {@code UPDATE}
     * natif (jeton tourne, claim). Toute verification d'appartenance lit ceci.
     */
    @Query("""
            SELECT r.id AS id, r.diagnosticType AS diagnosticType, r.anonymousId AS anonymousId,
                   r.userId AS userId, r.submittedAt AS submittedAt, r.claimTokenHash AS claimTokenHash,
                   r.claimTokenExpiresAt AS claimTokenExpiresAt, r.claimedAt AS claimedAt
              FROM DiagnosticRun r WHERE r.id = :id
            """)
    Optional<StateRow> findStateById(@Param("id") UUID id);

    interface StateRow {
        UUID getId();

        com.sejourfr.app.enums.DiagnosticRunType getDiagnosticType();

        UUID getAnonymousId();

        UUID getUserId();

        Instant getSubmittedAt();

        String getClaimTokenHash();

        Instant getClaimTokenExpiresAt();

        Instant getClaimedAt();
    }

    // ------------------------------------------------------------------------
    // Creation
    // ------------------------------------------------------------------------

    /**
     * Insere la run, sauf si {@code (anonymous_id, client_key)} existe deja
     * (index partiel {@code ux_diagnostic_run_client_key}). Sans
     * {@code anonymous_id}, aucun conflit n'est possible : la creation n'est
     * alors pas idempotente (limite assumee, D22).
     *
     * @return 1 si la run a ete creee, 0 si la cle existait
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            INSERT INTO diagnostic_run (id, diagnostic_type, platform, app_version, anonymous_id, user_id,
                                        client_key, subject_viewed_at, claim_token_hash, claim_token_expires_at,
                                        diagnostic_session_id, tcf_diagnostic_session_id,
                                        civic_diagnostic_session_id, updated_at)
            VALUES (:id, :type, :platform, :appVersion, :anonymousId, :userId, :clientKey, :now, :hash, :expiresAt,
                    :quickSessionId, :tcfSessionId, :civicSessionId, :now)
            ON CONFLICT (anonymous_id, client_key) WHERE client_key IS NOT NULL DO NOTHING
            """, nativeQuery = true)
    int insertIfAbsent(@Param("id") UUID id, @Param("type") String type, @Param("platform") String platform,
                       @Param("appVersion") String appVersion, @Param("anonymousId") UUID anonymousId,
                       @Param("userId") UUID userId, @Param("clientKey") UUID clientKey,
                       @Param("now") Instant now, @Param("hash") String hash,
                       @Param("expiresAt") Instant expiresAt, @Param("quickSessionId") UUID quickSessionId,
                       @Param("tcfSessionId") UUID tcfSessionId, @Param("civicSessionId") UUID civicSessionId);

    Optional<DiagnosticRun> findByAnonymousIdAndClientKey(UUID anonymousId, UUID clientKey);

    Optional<DiagnosticRun> findFirstByDiagnosticSessionIdOrderBySubjectViewedAtAsc(UUID sessionId);

    Optional<DiagnosticRun> findFirstByTcfDiagnosticSessionIdOrderBySubjectViewedAtAsc(UUID sessionId);

    Optional<DiagnosticRun> findFirstByCivicDiagnosticSessionIdOrderBySubjectViewedAtAsc(UUID sessionId);

    /**
     * Nouveau jeton pour une run existante (rejeu de la creation) : seul le
     * hash est stocke, l'ancien jeton ne vaut donc plus rien.
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE diagnostic_run
               SET claim_token_hash = :hash, claim_token_expires_at = :expiresAt, updated_at = :now
             WHERE id = :id
            """, nativeQuery = true)
    int rotateToken(@Param("id") UUID id, @Param("hash") String hash, @Param("expiresAt") Instant expiresAt,
                    @Param("now") Instant now);

    // ------------------------------------------------------------------------
    // Rattachement a la session reelle (FK V074), une seule fois
    // ------------------------------------------------------------------------

    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE diagnostic_run SET diagnostic_session_id = :sessionId, updated_at = :now
             WHERE id = :id AND diagnostic_type = 'QUICK_TCF' AND diagnostic_session_id IS NULL
            """, nativeQuery = true)
    int linkQuickSession(@Param("id") UUID id, @Param("sessionId") UUID sessionId, @Param("now") Instant now);

    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE diagnostic_run SET tcf_diagnostic_session_id = :sessionId, updated_at = :now
             WHERE id = :id AND diagnostic_type = 'FULL_TCF' AND tcf_diagnostic_session_id IS NULL
            """, nativeQuery = true)
    int linkTcfSession(@Param("id") UUID id, @Param("sessionId") UUID sessionId, @Param("now") Instant now);

    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE diagnostic_run SET civic_diagnostic_session_id = :sessionId, updated_at = :now
             WHERE id = :id AND diagnostic_type = 'CIVIQUE' AND civic_diagnostic_session_id IS NULL
            """, nativeQuery = true)
    int linkCivicSession(@Param("id") UUID id, @Param("sessionId") UUID sessionId, @Param("now") Instant now);

    // ------------------------------------------------------------------------
    // « Soumis » — une seule fois par run (Q3)
    // ------------------------------------------------------------------------

    /**
     * Pose « soumis » si la run ne l'est pas encore. Un soumis CONNECTE pose
     * aussi le porteur s'il manquait : « soumis connecte » implique « compte
     * rattache » (etape 3 du tunnel), jamais l'un sans l'autre.
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE diagnostic_run
               SET submitted_at = :now, submitted_authenticated = :authenticated,
                   user_id = COALESCE(user_id, :userId), updated_at = :now
             WHERE id = :id AND submitted_at IS NULL
            """, nativeQuery = true)
    int markSubmitted(@Param("id") UUID id, @Param("authenticated") boolean authenticated,
                      @Param("userId") UUID userId, @Param("now") Instant now);

    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE diagnostic_run
               SET submitted_at = :now, submitted_authenticated = :authenticated,
                   user_id = COALESCE(user_id, :userId), updated_at = :now
             WHERE civic_diagnostic_session_id = :sessionId AND submitted_at IS NULL
            """, nativeQuery = true)
    int markSubmittedByCivicSession(@Param("sessionId") UUID sessionId,
                                    @Param("authenticated") boolean authenticated,
                                    @Param("userId") UUID userId, @Param("now") Instant now);

    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE diagnostic_run
               SET submitted_at = :now, submitted_authenticated = true,
                   user_id = COALESCE(user_id, :userId), updated_at = :now
             WHERE tcf_diagnostic_session_id = :sessionId AND submitted_at IS NULL
            """, nativeQuery = true)
    int markSubmittedByTcfSession(@Param("sessionId") UUID sessionId, @Param("userId") UUID userId,
                                  @Param("now") Instant now);

    // ------------------------------------------------------------------------
    // Claim — dans la transaction d'auth
    // ------------------------------------------------------------------------

    /**
     * Claim par jeton. Toutes les conditions sont redites dans le {@code WHERE}
     * (hash, expiration, jamais claimee, sans porteur) : deux authentifications
     * concurrentes avec le meme jeton ne claiment qu'une fois.
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE diagnostic_run
               SET user_id = :userId, claimed_at = :now, claim_kind = :kind, claimed_via = :via,
                   updated_at = :now
             WHERE id = :id AND claim_token_hash = :hash AND claim_token_expires_at > :now
               AND claimed_at IS NULL AND user_id IS NULL
            """, nativeQuery = true)
    int claim(@Param("id") UUID id, @Param("hash") String hash, @Param("userId") UUID userId,
              @Param("kind") String kind, @Param("via") String via, @Param("now") Instant now);

    // ------------------------------------------------------------------------
    // Plan ↔ run (Q8)
    // ------------------------------------------------------------------------

    /**
     * La run <b>fondatrice</b> d'un parcours : celle du diagnostic le plus
     * ancien journalise sur ce parcours ({@code journey_assessment_event}), a
     * condition qu'elle appartienne au porteur du parcours. Le lien passe par
     * les FK de session de la run — jamais par un identifiant recu d'un client.
     *
     * <p>Diagnostic rapide et civique : l'evenement porte l'id de la SESSION.
     * Diagnostic complet : il porte l'id de la SECTION (attempt), dont
     * {@code attempts.tcf_diagnostic_id} donne la session.
     */
    @Query(value = """
            SELECT r.* FROM journey j
              JOIN journey_assessment_event e ON e.journey_id = j.id
              LEFT JOIN attempts a ON e.assessment_kind = 'FULL_DIAGNOSTIC' AND a.id = e.source_assessment_id
              JOIN diagnostic_run r ON r.user_id = j.user_id AND (
                       (e.assessment_kind = 'QUICK_DIAGNOSTIC' AND r.diagnostic_session_id = e.source_assessment_id)
                    OR (e.assessment_kind = 'CIVIC_DIAGNOSTIC' AND r.civic_diagnostic_session_id = e.source_assessment_id)
                    OR (e.assessment_kind = 'FULL_DIAGNOSTIC' AND r.tcf_diagnostic_session_id = a.tcf_diagnostic_id))
             WHERE j.id = :journeyId AND j.user_id = :userId
             ORDER BY e.completed_at ASC, e.processed_at ASC, r.subject_viewed_at ASC, r.id ASC
             LIMIT 1
            """, nativeQuery = true)
    Optional<DiagnosticRun> findFoundingRun(@Param("journeyId") UUID journeyId, @Param("userId") UUID userId);

    // ------------------------------------------------------------------------
    // Retention (D14 → D27)
    // ------------------------------------------------------------------------

    /**
     * Oublie l'identifiant de mesure des runs vues avant {@code cutoff}, par lot.
     * La run et ses faits restent ; seul le traceur part.
     */
    @Modifying
    @Query(value = """
            UPDATE diagnostic_run SET anonymous_id = NULL, client_key = NULL, updated_at = :now
             WHERE id IN (SELECT id FROM diagnostic_run
                           WHERE subject_viewed_at < :cutoff AND anonymous_id IS NOT NULL
                           LIMIT :limit)
            """, nativeQuery = true)
    int forgetAnonymousIdBefore(@Param("cutoff") Instant cutoff, @Param("limit") int limit,
                                @Param("now") Instant now);
}
