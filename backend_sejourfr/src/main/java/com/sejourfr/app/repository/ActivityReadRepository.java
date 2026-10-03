package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserActivityDay;
import com.sejourfr.app.entity.UserActivityDayId;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Lecture agregee de l'ecran « Activite » ({@code /api/admin/analytics/activity}
 * et {@code /live}). <b>Rien ne s'ecrit ici.</b> Definitions :
 * {@code docs/regles/mesure-audience.md} § « Activite des utilisateurs ».
 *
 * <p>Tout est agrege en SQL : <b>trois requetes constantes</b> pour la periode
 * (activite, connexions, ecrans), une pour le direct, quel que soit le volume
 * ({@code ActivityPerformanceIT}). Comptes internes ({@code users.is_internal})
 * exclus sauf {@code :includeInternal}. Une ligne de total porte une plateforme
 * {@code NULL}.
 */
public interface ActivityReadRepository extends Repository<UserActivityDay, UserActivityDayId> {

    /** {@code PLATFORM} (par plateforme), {@code TOTAL} ou {@code MULTI}. */
    interface LiveCell {
        String getKind();

        String getPlatform();

        long getN();
    }

    /**
     * Comptes vus depuis {@code :since} ({@code last_seen_at}). {@code :minDay}
     * borne la lecture aux lignes d'hier et d'aujourd'hui (Paris) : une presence
     * a cheval sur minuit vit dans la ligne du jour.
     */
    @Query(value = """
            WITH a AS (
                SELECT DISTINCT d.user_id, d.platform
                  FROM user_activity_day d
                  JOIN users u ON u.id = d.user_id
                 WHERE d.last_seen_at >= :since AND d.day >= :minDay
                   AND (:includeInternal OR NOT u.is_internal)
            )
            SELECT 'PLATFORM' AS kind, platform AS platform, count(DISTINCT user_id) AS n
              FROM a GROUP BY platform
            UNION ALL
            SELECT 'TOTAL', NULL, count(DISTINCT user_id) FROM a
            UNION ALL
            SELECT 'MULTI', NULL, count(*)
              FROM (SELECT user_id FROM a GROUP BY user_id HAVING count(*) > 1) m
            """, nativeQuery = true)
    List<LiveCell> live(@Param("since") Instant since, @Param("minDay") LocalDate minDay,
                        @Param("includeInternal") boolean includeInternal);

    /**
     * {@code PER} : comptes distincts de la periode ({@code CUR}) ou de la periode
     * precedente ({@code PREV}), par plateforme et au total ; {@code DAY} : idem
     * par jour de la periode courante ; {@code MULTI} : comptes vus sur au moins
     * deux plateformes.
     */
    interface ActiveCell {
        String getKind();

        String getPer();

        /** {@code yyyy-MM-dd} pour {@code DAY}, sinon {@code null}. */
        String getDay();

        String getPlatform();

        long getN();
    }

    /**
     * @param from    debut de la periode = fin (exclue) de la periode precedente
     * @param curFrom debut de la lecture de la periode courante, {@code >= from}
     *                (date de debut de mesure, D117)
     * @param to      dernier jour couvert, inclus
     */
    @Query(value = """
            WITH a AS (
                SELECT d.user_id, d.day, d.platform,
                       CASE WHEN d.day >= :from THEN 'CUR' ELSE 'PREV' END AS per
                  FROM user_activity_day d
                  JOIN users u ON u.id = d.user_id
                 WHERE ((d.day >= :prevFrom AND d.day < :from) OR (d.day >= :curFrom AND d.day <= :to))
                   AND (:includeInternal OR NOT u.is_internal)
            )
            SELECT 'PER' AS kind, per AS per, CAST(NULL AS text) AS day,
                   CASE WHEN GROUPING(platform) = 1 THEN NULL ELSE platform END AS platform,
                   count(DISTINCT user_id) AS n
              FROM a
             GROUP BY GROUPING SETS ((per, platform), (per))
            UNION ALL
            SELECT 'DAY', 'CUR', to_char(day, 'YYYY-MM-DD'),
                   CASE WHEN GROUPING(platform) = 1 THEN NULL ELSE platform END,
                   count(DISTINCT user_id)
              FROM a
             WHERE per = 'CUR'
             GROUP BY GROUPING SETS ((day, platform), (day))
            UNION ALL
            SELECT 'MULTI', per, NULL, NULL, count(*)
              FROM (SELECT per, user_id FROM a GROUP BY per, user_id HAVING count(DISTINCT platform) > 1) m
             GROUP BY per
            """, nativeQuery = true)
    List<ActiveCell> active(@Param("prevFrom") LocalDate prevFrom, @Param("from") LocalDate from,
                            @Param("curFrom") LocalDate curFrom, @Param("to") LocalDate to,
                            @Param("includeInternal") boolean includeInternal);

    /** Connexions de la periode ({@code CUR}) ou precedente ({@code PREV}), par plateforme et au total. */
    interface LoginCell {
        String getPer();

        String getPlatform();

        long getUniqueUsers();

        long getTotal();

        long getSignups();

        long getLocal();

        long getGoogle();

        long getApple();
    }

    /**
     * @param from    debut de la periode (instant Paris) = fin exclue de la precedente
     * @param curFrom debut de la lecture courante, {@code >= from} (D117)
     * @param to      fin exclue de la periode
     */
    @Query(value = """
            WITH l AS (
                SELECT e.user_id, e.kind, e.auth_method, e.platform,
                       CASE WHEN e.occurred_at >= :from THEN 'CUR' ELSE 'PREV' END AS per
                  FROM user_login_event e
                  JOIN users u ON u.id = e.user_id
                 WHERE ((e.occurred_at >= :prevFrom AND e.occurred_at < :from)
                        OR (e.occurred_at >= :curFrom AND e.occurred_at < :to))
                   AND (:includeInternal OR NOT u.is_internal)
            )
            SELECT per AS per,
                   CASE WHEN GROUPING(platform) = 1 THEN NULL ELSE platform END AS platform,
                   count(DISTINCT user_id) AS unique_users,
                   count(*) AS total,
                   count(*) FILTER (WHERE kind = 'SIGNUP') AS signups,
                   count(*) FILTER (WHERE auth_method = 'LOCAL') AS local,
                   count(*) FILTER (WHERE auth_method = 'GOOGLE') AS google,
                   count(*) FILTER (WHERE auth_method = 'APPLE') AS apple
              FROM l
             GROUP BY GROUPING SETS ((per, platform), (per))
            """, nativeQuery = true)
    List<LoginCell> logins(@Param("prevFrom") Instant prevFrom, @Param("from") Instant from,
                           @Param("curFrom") Instant curFrom, @Param("to") Instant to,
                           @Param("includeInternal") boolean includeInternal);

    /**
     * Une ligne d'ecran : {@code side} {@code WEB} ou {@code APP} ; {@code bucket}
     * = le chemin (top), {@code ~OTHER}, {@code ~UNDECLARED} ou {@code ~TOTAL}.
     */
    interface ScreenCell {
        String getSide();

        String getBucket();

        long getViews();

        long getUniqueVisitors();

        long getUniqueUsers();

        long getIos();

        long getAndroid();

        long getAppUnknown();
    }

    /**
     * {@code SCREEN_VIEWED} de la periode, onglet Web ({@code platform = WEB}) et
     * onglet App ({@code IOS}, {@code ANDROID}, {@code MOBILE}), chacun lu depuis
     * sa propre date de debut de mesure (N4). Les {@code :top} chemins les plus
     * vus par onglet sont servis tels quels ; les autres sont regroupes EN SQL
     * ({@code ~OTHER}) pour que leurs uniques ne soient jamais additionnes.
     * {@code path} nul = ecran non declare ({@code ~UNDECLARED}). Interne :
     * evenement d'un compte interne, ou identifiant de mesure lie a un compte
     * interne (meme regle que Suivi ; ensemble calcule une fois — sous-requete
     * hachee — et non correle par evenement).
     */
    @Query(value = """
            WITH ev AS (
                SELECT CASE WHEN e.platform = 'WEB' THEN 'WEB' ELSE 'APP' END AS side,
                       e.path, e.anonymous_id, e.user_id, e.platform
                  FROM analytics_event e
                 WHERE e.event = 'SCREEN_VIEWED'
                   AND e.occurred_at < :to
                   AND ((e.platform = 'WEB' AND e.occurred_at >= :webFrom)
                        OR (e.platform IN ('IOS', 'ANDROID', 'MOBILE') AND e.occurred_at >= :appFrom))
                   AND (:includeInternal
                        OR (NOT COALESCE(e.is_internal, false)
                            AND e.anonymous_id NOT IN (SELECT ii.anonymous_id
                                                         FROM analytics_identity ii
                                                         JOIN users iu ON iu.id = ii.user_id
                                                        WHERE iu.is_internal)))
            ),
            vues AS (
                SELECT ev.*, count(*) OVER (PARTITION BY side, path) AS n_path
                  FROM ev
            ),
            b AS (
                SELECT side, anonymous_id, user_id, platform,
                       CASE WHEN path IS NULL THEN '~UNDECLARED'
                            WHEN dense_rank() OVER (PARTITION BY side, path IS NULL
                                                    ORDER BY n_path DESC, path) <= :top THEN path
                            ELSE '~OTHER' END AS bucket
                  FROM vues
            )
            SELECT side AS side,
                   CASE WHEN GROUPING(bucket) = 1 THEN '~TOTAL' ELSE bucket END AS bucket,
                   count(*) AS views,
                   count(DISTINCT anonymous_id) AS unique_visitors,
                   count(DISTINCT user_id) AS unique_users,
                   count(*) FILTER (WHERE platform = 'IOS') AS ios,
                   count(*) FILTER (WHERE platform = 'ANDROID') AS android,
                   count(*) FILTER (WHERE platform = 'MOBILE') AS app_unknown
              FROM b
             GROUP BY GROUPING SETS ((side, bucket), (side))
            """, nativeQuery = true)
    List<ScreenCell> screens(@Param("webFrom") Instant webFrom, @Param("appFrom") Instant appFrom,
                             @Param("to") Instant to, @Param("top") int top,
                             @Param("includeInternal") boolean includeInternal);
}
