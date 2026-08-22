package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AnalyticsVisitor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.UUID;

public interface AnalyticsVisitorRepository extends JpaRepository<AnalyticsVisitor, UUID> {

    /**
     * Cree le visiteur, ou rafraichit ce qui a le droit de bouger.
     *
     * <p><b>Les deux invariants de la table sont tenus ICI, atomiquement</b>, et
     * c'est la raison d'etre de cette requete native :
     * <ul>
     *   <li><b>Le first touch n'apparait dans aucun {@code SET}.</b> Il est donc
     *       ecrit une fois, a l'insertion, et strictement jamais reecrit — pas
     *       « on evite de le reecrire », <i>on ne peut pas</i>. Un « lire puis
     *       ecrire » cote Java aurait laisse deux onglets du meme visiteur poser
     *       deux origines differentes, et le premier contact aurait cesse d'etre
     *       le premier.</li>
     *   <li><b>Le last touch ne bouge que sur source EXPLICITE</b>
     *       ({@code :explicitSource}) : un visiteur qui navigue de page en page
     *       n'apporte aucune nouvelle information d'origine, et ecraser son
     *       last touch a chaque vue le ramenerait a « direct » des la deuxieme
     *       page — « quelle source a precede l'achat » repondrait alors
     *       « direct » pour tout le monde.</li>
     * </ul>
     *
     * <p>Les trois champs deduits serveur ne s'ecrasent jamais avec une absence
     * d'information : un pays deja connu n'est pas efface par une IP privee, un
     * appareil deja identifie n'est pas ramene a {@code UNKNOWN} par un
     * user-agent manquant. <i>null = inconnu, jamais mauvais.</i>
     *
     * <p>{@code first_seen_at} et {@code last_seen_at} passent par
     * {@code LEAST}/{@code GREATEST} : les evenements peuvent arriver dans le
     * desordre (un {@code sendBeacon} differe, un mobile qui rejoue sa file
     * hors ligne), et une horodate ne doit jamais reculer.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            INSERT INTO analytics_visitor (
                anonymous_id, first_seen_at, last_seen_at,
                ft_source, ft_medium, ft_campaign, ft_content, ft_term,
                ft_landing_path, ft_referrer_host,
                lt_source, lt_medium, lt_campaign, lt_content, lt_term, lt_seen_at,
                country_code, device_type, platform)
            VALUES (
                :anonymousId, :seenAt, :seenAt,
                :source, :medium, :campaign, :content, :term,
                :landingPath, :referrerHost,
                :source, :medium, :campaign, :content, :term, :seenAt,
                :countryCode, :deviceType, :platform)
            ON CONFLICT (anonymous_id) DO UPDATE SET
                first_seen_at = LEAST(analytics_visitor.first_seen_at, EXCLUDED.first_seen_at),
                last_seen_at  = GREATEST(analytics_visitor.last_seen_at, EXCLUDED.last_seen_at),
                lt_source   = CASE WHEN :explicitSource THEN EXCLUDED.lt_source   ELSE analytics_visitor.lt_source   END,
                lt_medium   = CASE WHEN :explicitSource THEN EXCLUDED.lt_medium   ELSE analytics_visitor.lt_medium   END,
                lt_campaign = CASE WHEN :explicitSource THEN EXCLUDED.lt_campaign ELSE analytics_visitor.lt_campaign END,
                lt_content  = CASE WHEN :explicitSource THEN EXCLUDED.lt_content  ELSE analytics_visitor.lt_content  END,
                lt_term     = CASE WHEN :explicitSource THEN EXCLUDED.lt_term     ELSE analytics_visitor.lt_term     END,
                lt_seen_at  = CASE WHEN :explicitSource THEN EXCLUDED.lt_seen_at  ELSE analytics_visitor.lt_seen_at  END,
                country_code = COALESCE(analytics_visitor.country_code, EXCLUDED.country_code),
                device_type  = CASE WHEN EXCLUDED.device_type = 'UNKNOWN'
                                    THEN analytics_visitor.device_type ELSE EXCLUDED.device_type END,
                platform     = CASE WHEN EXCLUDED.platform = 'UNKNOWN'
                                    THEN analytics_visitor.platform ELSE EXCLUDED.platform END
            """, nativeQuery = true)
    int upsert(@Param("anonymousId") UUID anonymousId,
               @Param("seenAt") Instant seenAt,
               @Param("source") String source,
               @Param("medium") String medium,
               @Param("campaign") String campaign,
               @Param("content") String content,
               @Param("term") String term,
               @Param("landingPath") String landingPath,
               @Param("referrerHost") String referrerHost,
               @Param("explicitSource") boolean explicitSource,
               @Param("countryCode") String countryCode,
               @Param("deviceType") String deviceType,
               @Param("platform") String platform);
}
