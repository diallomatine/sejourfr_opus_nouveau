package com.sejourfr.app.repository;

import com.sejourfr.app.entity.User;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Lecture agregee du funnel d'acquisition. <strong>Rien ne s'ecrit ici.</strong>
 *
 * <p>Toutes les requetes sont natives et <strong>agregent en SQL</strong> : le
 * cout est independant du nombre de comptes. Charger la cohorte en memoire pour
 * la compter en Java aurait tenu le temps d'une demonstration et se serait
 * effondre au premier millier d'inscrits.
 *
 * <p><strong>La population est la COHORTE D'INSCRIPTION</strong> : les comptes
 * crees dans la fenetre, comptes supprimes exclus. Chaque etape se mesure sur
 * cette cohorte, quelle que soit la date de l'etape — un inscrit du 3 qui paie
 * le 20 compte dans la cohorte du 3. C'est la seule facon d'obtenir un taux de
 * conversion honnete : compter les paiements du mois au numerateur et les
 * inscrits du mois au denominateur melange deux populations.
 *
 * <p>Chaque compte appartient a exactement une cellule (source, plateforme), ce
 * qui rend les sous-totaux additionnables : la somme des comptes distincts par
 * cellule est le compte distinct global.
 */
public interface AudienceFunnelRepository extends Repository<User, UUID> {

    /** Ligne (source, plateforme) et un compte de comptes distincts. */
    interface CohortCell {
        String getSource();
        String getPlatform();
        long getTotal();
    }

    /** Ligne (source, plateforme) et les deux jalons du diagnostic. */
    interface DiagnosticCell {
        String getSource();
        String getPlatform();
        long getStarted();
        long getCompleted();
    }

    /** Ligne (source, plateforme, evenement) et un compte de comptes distincts. */
    interface EventCell {
        String getSource();
        String getPlatform();
        String getEvent();
        long getTotal();
    }

    /** Un point de la serie journaliere, pour une nature d'evenement. */
    interface DailyCell {
        String getKind();
        String getDay();
        long getTotal();
    }

    /** Integrite du diagnostic, mesuree sur TOUTE la base. */
    interface IntegrityRow {
        long getAccounts();
        long getSessions();
        long getMulti();
    }

    // ------------------------------------------------------------------------
    // Cohorte : une cellule = une paire (provenance, plateforme) d'inscription
    // ------------------------------------------------------------------------

    @Query(value = """
            SELECT COALESCE(u.signup_source, 'inconnu')    AS source,
                   COALESCE(u.signup_platform, 'UNKNOWN')  AS platform,
                   count(*)                                AS total
            FROM users u
            WHERE u.deleted_at IS NULL
              AND u.created_at >= :from
              AND u.created_at < :to
            GROUP BY 1, 2
            """, nativeQuery = true)
    List<CohortCell> signupsByCell(@Param("from") Instant from, @Param("to") Instant to);

    /**
     * Diagnostic commence / termine, sur la cohorte. Les deux jalons sortent de
     * la meme requete : une session terminee est necessairement commencee, les
     * separer aurait relu la meme jointure deux fois.
     */
    @Query(value = """
            SELECT COALESCE(u.signup_source, 'inconnu')   AS source,
                   COALESCE(u.signup_platform, 'UNKNOWN') AS platform,
                   count(DISTINCT d.user_id)              AS started,
                   count(DISTINCT d.user_id) FILTER (WHERE d.status = 'COMPLETED') AS completed
            FROM users u
            JOIN diagnostic_sessions d ON d.user_id = u.id
            WHERE u.deleted_at IS NULL
              AND u.created_at >= :from
              AND u.created_at < :to
            GROUP BY 1, 2
            """, nativeQuery = true)
    List<DiagnosticCell> diagnosticsByCell(@Param("from") Instant from, @Param("to") Instant to);

    @Query(value = """
            SELECT COALESCE(u.signup_source, 'inconnu')   AS source,
                   COALESCE(u.signup_platform, 'UNKNOWN') AS platform,
                   e.event                                AS event,
                   count(DISTINCT e.user_id)              AS total
            FROM users u
            JOIN user_funnel_events e ON e.user_id = u.id
            WHERE u.deleted_at IS NULL
              AND u.created_at >= :from
              AND u.created_at < :to
            GROUP BY 1, 2, 3
            """, nativeQuery = true)
    List<EventCell> funnelEventsByCell(@Param("from") Instant from, @Param("to") Instant to);

    /**
     * A paye : au moins une souscription de statut autre que {@code PENDING}.
     * Un remboursement a bien ete un paiement — l'exclure ferait disparaitre du
     * funnel une conversion qui a eu lieu.
     */
    @Query(value = """
            SELECT COALESCE(u.signup_source, 'inconnu')   AS source,
                   COALESCE(u.signup_platform, 'UNKNOWN') AS platform,
                   count(DISTINCT s.user_id)              AS total
            FROM users u
            JOIN user_subscriptions s ON s.user_id = u.id
            WHERE u.deleted_at IS NULL
              AND u.created_at >= :from
              AND u.created_at < :to
              AND s.status <> 'PENDING'
            GROUP BY 1, 2
            """, nativeQuery = true)
    List<CohortCell> purchasesByCell(@Param("from") Instant from, @Param("to") Instant to);

    // ------------------------------------------------------------------------
    // Serie journaliere — comptes BRUTS par jour d'occurrence, pas la cohorte
    // ------------------------------------------------------------------------

    /**
     * Une ligne par (nature, jour) reellement observe. Les jours vides ne
     * remontent pas : c'est le service qui remplit la serie continue, une
     * requete ne doit pas inventer des lignes qui n'existent pas.
     *
     * <p>Le jour est celui d'{@code Europe/Paris}, comme la mesure d'audience
     * anonyme — deux fuseaux dans une meme console rendraient les deux courbes
     * incomparables.
     */
    @Query(value = """
            SELECT 'SIGNUP' AS kind,
                   to_char(u.created_at AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD') AS day,
                   count(DISTINCT u.id) AS total
            FROM users u
            WHERE u.deleted_at IS NULL AND u.created_at >= :from AND u.created_at < :to
            GROUP BY 2
            UNION ALL
            SELECT 'DIAGNOSTIC_STARTED',
                   to_char(d.started_at AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD'),
                   count(DISTINCT d.user_id)
            FROM diagnostic_sessions d
            JOIN users u ON u.id = d.user_id
            WHERE u.deleted_at IS NULL AND d.started_at >= :from AND d.started_at < :to
            GROUP BY 2
            UNION ALL
            SELECT 'DIAGNOSTIC_COMPLETED',
                   to_char(d.completed_at AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD'),
                   count(DISTINCT d.user_id)
            FROM diagnostic_sessions d
            JOIN users u ON u.id = d.user_id
            WHERE u.deleted_at IS NULL AND d.completed_at >= :from AND d.completed_at < :to
            GROUP BY 2
            UNION ALL
            SELECT 'PURCHASE',
                   to_char(s.starts_at AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD'),
                   count(DISTINCT s.user_id)
            FROM user_subscriptions s
            JOIN users u ON u.id = s.user_id
            WHERE u.deleted_at IS NULL AND s.status <> 'PENDING'
              AND s.starts_at >= :from AND s.starts_at < :to
            GROUP BY 2
            """, nativeQuery = true)
    List<DailyCell> dailyCounts(@Param("from") Instant from, @Param("to") Instant to);

    // ------------------------------------------------------------------------
    // Integrite : « un compte ne fait-il qu'un seul diagnostic ? »
    // ------------------------------------------------------------------------

    /**
     * Mesure sur TOUTE la base, pas sur la fenetre : une anomalie d'unicite ne
     * doit pas pouvoir sortir du champ de vision en vieillissant.
     *
     * <p>L'unicite garantie en base est
     * {@code (user_id, diagnostic_code, diagnostic_version)}. Un meme compte
     * pourrait donc legitimement porter une seconde session le jour ou une
     * NOUVELLE version de diagnostic serait publiee — c'est precisement ce que
     * ce compteur surveille : il vaut 0 aujourd'hui, et le jour ou il ne vaut
     * plus 0, c'est soit une republication voulue, soit un bug.
     */
    @Query(value = """
            SELECT (SELECT count(DISTINCT user_id) FROM diagnostic_sessions) AS accounts,
                   (SELECT count(*) FROM diagnostic_sessions)                AS sessions,
                   (SELECT count(*) FROM (
                        SELECT user_id FROM diagnostic_sessions
                        GROUP BY user_id HAVING count(*) > 1
                    ) x)                                                     AS multi
            """, nativeQuery = true)
    IntegrityRow diagnosticIntegrity();
}
