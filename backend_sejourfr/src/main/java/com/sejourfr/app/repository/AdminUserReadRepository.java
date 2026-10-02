package com.sejourfr.app.repository;

import com.sejourfr.app.entity.User;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * Lectures de la console admin « Utilisateurs » : <b>lecture seule, sans effet
 * de bord</b>. 🛑 La progression se lit ici en tables, jamais par
 * {@code JourneyService.lire()} (qui CRÉE ou archive un cycle à la lecture, G-10).
 *
 * <p>🛑 Aucune requête ici ne décide d'un accès : {@link #findUserIdsWithOpenPurchase}
 * ne fait que BORNER les candidats, la couverture se décide en Java
 * ({@code SubscriptionService.covers} + {@code AccesEffectifResolver}).
 */
public interface AdminUserReadRepository extends Repository<User, UUID> {

    interface LastActivity {
        UUID getUserId();
        Instant getAt();
    }

    interface CurrentCycle {
        String getModule();
        String getStatus();
        String getEntryLevel();
        String getTargetLevel();
        String getTargetProcedure();
        Instant getStartedAt();
        long getStepsClosed();
        long getStepsTotal();
    }

    interface ModuleCount {
        String getModule();
        long getCount();
    }

    interface ModuleDate {
        String getModule();
        Instant getAt();
    }

    /** Sur-ensemble des comptes à achat payant pas encore terminé (statut non filtré : Java décide). */
    @Query(value = """
            SELECT DISTINCT s.user_id
              FROM user_subscriptions s
              JOIN plans pl ON pl.id = s.plan_id
             WHERE pl.code <> 'FREE' AND pl.module_access <> 'NONE'
               AND (s.ends_at IS NULL OR s.ends_at > :now)
            """, nativeQuery = true)
    List<UUID> findUserIdsWithOpenPurchase(@Param("now") Instant now);

    /** Dernière activité d'entraînement (vue V073, l'autorité) des seuls comptes de la page. */
    @Query(value = """
            SELECT v.user_id AS userId, v.derniere_activite_at AS at
              FROM v_derniere_activite_entrainement v
             WHERE v.user_id IN (:userIds)
            """, nativeQuery = true)
    List<LastActivity> findLastActivity(@Param("userIds") Collection<UUID> userIds);

    /** Le cycle EN COURS de chaque module, avec ses étapes closes / totales (valeurs persistées). */
    @Query(value = """
            SELECT j.module AS module, j.status AS status, j.entry_level AS entryLevel,
                   j.target_level AS targetLevel, j.target_procedure AS targetProcedure,
                   j.created_at AS startedAt,
                   (SELECT count(*) FROM journey_step s WHERE s.journey_id = j.id AND s.closed_at IS NOT NULL) AS stepsClosed,
                   (SELECT count(*) FROM journey_step s WHERE s.journey_id = j.id) AS stepsTotal
              FROM journey j
             WHERE j.user_id = :userId AND j.status = 'EN_COURS'
            """, nativeQuery = true)
    List<CurrentCycle> findCurrentCycles(@Param("userId") UUID userId);

    @Query(value = """
            SELECT j.module AS module, count(*) AS count
              FROM journey j
             WHERE j.user_id = :userId AND j.status = 'HISTORISE'
             GROUP BY j.module
            """, nativeQuery = true)
    List<ModuleCount> countHistorisedCycles(@Param("userId") UUID userId);

    /**
     * Dernier diagnostic CLOS par module : TCF = rapide ({@code diagnostic_sessions})
     * ou complet ({@code tcf_diagnostic_sessions}) ; Civique = {@code civic_diagnostic_sessions}.
     */
    @Query(value = """
            SELECT 'TCF' AS module, max(d.at) AS at
              FROM (SELECT completed_at AS at FROM diagnostic_sessions
                     WHERE user_id = :userId AND status = 'COMPLETED'
                    UNION ALL
                    SELECT completed_at FROM tcf_diagnostic_sessions
                     WHERE user_id = :userId AND status = 'COMPLETED') d
            UNION ALL
            SELECT 'CIVIQUE', max(c.completed_at)
              FROM civic_diagnostic_sessions c
             WHERE c.user_id = :userId AND c.status = 'COMPLETED'
            """, nativeQuery = true)
    List<ModuleDate> findLastCompletedDiagnostics(@Param("userId") UUID userId);
}
