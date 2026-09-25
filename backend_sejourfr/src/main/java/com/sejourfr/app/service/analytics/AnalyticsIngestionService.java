package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AnalyticsEventRequest;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.AnalyticsIdentityManager;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.util.ClientContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Reception d'un evenement d'analytics <b>unitaire</b>
 * ({@code POST /api/public/analytics/events}) : valide, resout ce qui doit
 * l'etre serveur, tient le visiteur a jour, ecrit le geste.
 *
 * <p>⚠️ <b>Conserve pendant la bascule vers l'ingestion en lot</b>
 * ({@link AnalyticsBatchIngestionService}, arbitrage Q17), puis retire quand les
 * deux fronts envoient des lots. Les deux passent par la meme validation
 * ({@link AnalyticsEventNormalizer}) et ecrivent les memes colonnes.
 *
 * <p><b>Ce qui n'est PAS ici</b> : aucun evenement d'inscription, de paiement
 * ni de diagnostic termine. Ces faits ont deja une source exacte
 * ({@code users}, {@code user_subscriptions}, {@code diagnostic_run}) et en
 * doubler un creerait une seconde verite (doctrine V036).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsIngestionService {

    /**
     * Ecart maximal tolere entre l'horodate annoncee par le client et l'heure
     * serveur, sur l'endpoint unitaire. Au-dela : 400. (L'ingestion en lot a ses
     * propres bornes, en configuration.)
     */
    static final Duration ECART_HORODATE_MAX = Duration.ofHours(24);

    private final AnalyticsVisitorManager visitorManager;
    private final AnalyticsEventManager eventManager;
    private final AnalyticsIdentityManager identityManager;
    private final AnalyticsEventNormalizer normalizer;

    /**
     * Enregistre un evenement.
     *
     * @param request  corps recu
     * @param client   en-tetes {@code X-Sejourfr-*}
     * @param country  pays deja resolu par l'appelant ({@code null} = inconnu)
     * @param device   type d'appareil deja resolu par l'appelant
     * @param userId   compte de l'appelant s'il est connu, {@code null} sinon
     * @return {@code true} si une ligne a ete ecrite, {@code false} sur un rejeu
     *         dedoublonne. Les deux cas sont normaux et repondent 204.
     */
    @Transactional
    public boolean track(AnalyticsEventRequest request, ClientContext client,
                         String country, AnalyticsDeviceType device, UUID userId) {

        AnalyticsEvent event = request.event();
        normalizer.refuseEvenementServeur(event);

        Instant receivedAt = Instant.now();
        Instant occurredAt = horodate(request.occurredAt(), receivedAt);
        String path = normalizer.path(request.path());
        Map<String, String> properties = normalizer.properties(event, request.properties());
        String dedupKey = normalizer.dedupKey(request.dedupKey());

        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        AnalyticsVisitorManager.Attribution attribution =
                normalizer.attribution(request.firstTouch(), ctx, path);
        boolean explicitSource = normalizer.sourceExplicite(request.firstTouch(), ctx);

        // Le visiteur AVANT l'evenement : la cle etrangere l'exige.
        visitorManager.touch(request.anonymousId(), occurredAt, attribution, explicitSource,
                country, device, ctx.platform());

        boolean internal = identityManager.isInternal(request.anonymousId(), userId);
        return eventManager.record(new AnalyticsEventManager.Ligne(
                event, occurredAt, request.anonymousId(), request.sessionId(), userId, path,
                normalizer.toJson(properties), dedupKey,
                null, receivedAt, ctx.platform(), ctx.appVersion(), null, null, null, internal));
    }

    /**
     * Horodate retenue. Absente ⇒ maintenant ; au-dela de {@link
     * #ECART_HORODATE_MAX} dans un sens ou dans l'autre ⇒ 400 nomme.
     */
    private Instant horodate(Instant declaree, Instant now) {
        if (declaree == null) return now;
        Duration ecart = Duration.between(declaree, now).abs();
        if (ecart.compareTo(ECART_HORODATE_MAX) > 0) {
            throw new IllegalArgumentException(
                    "Valeur invalide pour « occurredAt » : « " + declaree
                            + " ». Attendu : une date à moins de "
                            + ECART_HORODATE_MAX.toHours() + " h de l'heure du serveur.");
        }
        return declaree;
    }
}
