package com.sejourfr.app.repository;

import com.sejourfr.app.entity.User;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Les candidats des scenarios d'emails ENGAGEMENT (docs/regles/emails.md).
 *
 * <p>Toutes les requetes partagent le meme socle : compte actif, non supprime,
 * role USER, et rappels d'entrainement ACTIVES ({@code COALESCE(..., TRUE)} :
 * une ligne de preference absente vaut « actif »). Les desabonnes sont exclus
 * ICI, sans ligne SKIPPED (brief §4).
 *
 * <p>Pagination par jeu de cles ({@code id > :after ORDER BY id LIMIT :limit}),
 * jamais par offset : une page envoyee ne decale pas la suivante.
 *
 * <p>🛑 Ces requetes ne font que BORNER les candidats. La regle de couverture
 * d'un acces (« couvrant », « prolonge au-dela ») n'est pas ecrite ici : elle
 * est appliquee en Java par {@code SubscriptionService.covers}, sa seule autorite.
 */
public interface EmailScenarioRepository extends Repository<User, UUID> {

    interface UserCandidate {
        UUID getUserId();
        String getEmail();
        String getFirstName();
        Instant getAt();
    }

    interface AccessCandidate {
        UUID getAccessId();
        UUID getUserId();
        String getEmail();
        String getFirstName();
    }

    /** Comptes crees dans {@code [from, to)} qui n'ont JAMAIS eu d'acces Premium. */
    @Query(value = """
            SELECT u.id AS userId, u.email AS email, u.first_name AS firstName, u.created_at AS at
              FROM users u
              LEFT JOIN user_email_preferences p ON p.user_id = u.id
             WHERE u.deleted_at IS NULL AND u.is_active AND u.role = 'USER'
               AND COALESCE(p.engagement_enabled, TRUE)
               AND u.created_at >= :from AND u.created_at < :to
               AND NOT EXISTS (SELECT 1 FROM user_subscriptions s JOIN plans pl ON pl.id = s.plan_id
                                WHERE s.user_id = u.id AND pl.code <> 'FREE'
                                  AND pl.module_access <> 'NONE' AND s.status <> 'PENDING')
               AND u.id > :after
             ORDER BY u.id
             LIMIT :limit
            """, nativeQuery = true)
    List<UserCandidate> findNeverPremiumCreatedBetween(@Param("from") Instant from, @Param("to") Instant to,
                                                       @Param("after") UUID after, @Param("limit") int limit);

    /** Comptes dont la derniere activite d'entrainement (vue V073) tombe dans {@code [from, to)}. */
    @Query(value = """
            SELECT u.id AS userId, u.email AS email, u.first_name AS firstName, v.derniere_activite_at AS at
              FROM users u
              JOIN v_derniere_activite_entrainement v ON v.user_id = u.id
              LEFT JOIN user_email_preferences p ON p.user_id = u.id
             WHERE u.deleted_at IS NULL AND u.is_active AND u.role = 'USER'
               AND COALESCE(p.engagement_enabled, TRUE)
               AND v.derniere_activite_at >= :from AND v.derniere_activite_at < :to
               AND u.id > :after
             ORDER BY u.id
             LIMIT :limit
            """, nativeQuery = true)
    List<UserCandidate> findLastActivityBetween(@Param("from") Instant from, @Param("to") Instant to,
                                                @Param("after") UUID after, @Param("limit") int limit);

    /**
     * Comptes qui ont au moins un acces payant pas encore termine ({@code at} =
     * derniere activite, nulle si jamais d'activite). Sur-ensemble : Java decide
     * de la couverture.
     */
    @Query(value = """
            SELECT u.id AS userId, u.email AS email, u.first_name AS firstName, v.derniere_activite_at AS at
              FROM users u
              LEFT JOIN v_derniere_activite_entrainement v ON v.user_id = u.id
              LEFT JOIN user_email_preferences p ON p.user_id = u.id
             WHERE u.deleted_at IS NULL AND u.is_active AND u.role = 'USER'
               AND COALESCE(p.engagement_enabled, TRUE)
               AND EXISTS (SELECT 1 FROM user_subscriptions s JOIN plans pl ON pl.id = s.plan_id
                            WHERE s.user_id = u.id AND pl.code <> 'FREE' AND pl.module_access <> 'NONE'
                              AND (s.ends_at IS NULL OR s.ends_at > :now))
               AND u.id > :after
             ORDER BY u.id
             LIMIT :limit
            """, nativeQuery = true)
    List<UserCandidate> findWithOpenPaidAccess(@Param("now") Instant now,
                                               @Param("after") UUID after, @Param("limit") int limit);

    /**
     * Les ACHATS UNIQUES (pass) dont la fin tombe dans {@code (from, to]}. Les
     * abonnements recurrents dormants sont exclus (arbitrage n°5) : ils se
     * renouvellent, leur « fin » n'en est pas une.
     */
    @Query(value = """
            SELECT s.id AS accessId, u.id AS userId, u.email AS email, u.first_name AS firstName
              FROM user_subscriptions s
              JOIN plans pl ON pl.id = s.plan_id
              JOIN users u ON u.id = s.user_id
              LEFT JOIN user_email_preferences p ON p.user_id = u.id
             WHERE u.deleted_at IS NULL AND u.is_active AND u.role = 'USER'
               AND COALESCE(p.engagement_enabled, TRUE)
               AND pl.purchase_type = 'ONE_TIME' AND NOT s.auto_renew
               AND pl.code <> 'FREE' AND pl.module_access <> 'NONE'
               AND s.ends_at > :from AND s.ends_at <= :to
               AND s.id > :after
             ORDER BY s.id
             LIMIT :limit
            """, nativeQuery = true)
    List<AccessCandidate> findOneTimeAccessEndingBetween(@Param("from") Instant from, @Param("to") Instant to,
                                                         @Param("after") UUID after, @Param("limit") int limit);
}
