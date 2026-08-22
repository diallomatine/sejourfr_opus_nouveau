package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AnalyticsIdentity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface AnalyticsIdentityRepository
        extends JpaRepository<AnalyticsIdentity, AnalyticsIdentity.Key> {

    /**
     * Pose le lien anonyme -> compte, ou ne fait rien.
     *
     * <p>Deux garde-fous, tous deux dans le sens « en cas de doute, on n'ecrit
     * pas » — parce que cette ecriture a lieu <b>pendant une connexion</b> et ne
     * doit jamais l'empecher :
     * <ul>
     *   <li>{@code ON CONFLICT DO NOTHING} : rejouable a l'infini (chaque
     *       connexion repose le meme lien), ne leve jamais ;</li>
     *   <li>{@code WHERE EXISTS} sur le visiteur : si le client envoie un
     *       {@code anonymousId} dont aucun evenement n'est jamais arrive (mode
     *       prive, requete perdue, identifiant fabrique), la cle etrangere
     *       echouerait et empoisonnerait la transaction de login. Ici, on
     *       n'ecrit simplement rien.</li>
     * </ul>
     *
     * @return 1 si le lien vient d'etre pose, 0 sinon.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            INSERT INTO analytics_identity (anonymous_id, user_id, linked_at)
            SELECT :anonymousId, :userId, now()
            WHERE EXISTS (SELECT 1 FROM analytics_visitor v WHERE v.anonymous_id = :anonymousId)
              AND EXISTS (SELECT 1 FROM users u WHERE u.id = :userId)
            ON CONFLICT (anonymous_id, user_id) DO NOTHING
            """, nativeQuery = true)
    int link(@Param("anonymousId") UUID anonymousId, @Param("userId") UUID userId);

    /**
     * Purge les liens d'un compte. Explicite pour la meme raison que
     * {@code UserFunnelEventRepository.deleteByUserId} : l'anonymisation laisse
     * la ligne {@code users} en place, la cascade ne part pas.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM AnalyticsIdentity i WHERE i.userId = :userId")
    int deleteByUserId(@Param("userId") UUID userId);

    long countByUserId(UUID userId);
}
