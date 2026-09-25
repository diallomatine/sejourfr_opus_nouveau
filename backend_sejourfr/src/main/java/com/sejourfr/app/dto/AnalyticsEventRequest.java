package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AnalyticsEvent;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Un evenement d'analytics remonte par un front
 * ({@code POST /api/public/analytics/events}).
 *
 * <p>{@code event} est type par l'enum : une valeur inconnue est refusee en
 * <b>400 nomme</b> (champ, valeur recue, valeurs acceptees) par la
 * deserialisation, sans qu'aucun code n'ait a le prevoir — le
 * {@code GlobalExceptionHandler} le fait deja pour {@code targetProcedure}.
 *
 * <p><b>Ni pays, ni type d'appareil, ni plateforme dans ce payload</b>, et c'est
 * volontaire : ils sont resolus serveur (geo-IP, user-agent, en-tetes). Recus du
 * client, ils seraient falsifiables — et surtout, les calculer des deux cotes
 * garantirait qu'un jour les deux ne diraient plus la meme chose.
 *
 * @param anonymousId identifiant first-party du visiteur (retention 13 mois)
 * @param sessionId   visite courante
 * @param event       registre ferme, cf. {@link AnalyticsEvent}
 * @param path        ecran concerne, dans l'allowlist de {@code AnalyticsPaths}
 * @param occurredAt  horodate du geste. Absente ⇒ maintenant. Refusee au-dela de
 *                    ±24 h : sans cette borne, un client peut fabriquer
 *                    l'historique d'un mois entier
 * @param properties  proprietes de l'evenement, cles ET valeurs allowlistees
 * @param firstTouch  attribution, a la premiere requete du visiteur seulement
 * @param dedupKey    cle d'idempotence facultative — un rejeu n'ecrit rien
 */
public record AnalyticsEventRequest(
        @NotNull(message = "anonymousId requis") UUID anonymousId,
        @NotNull(message = "sessionId requis") UUID sessionId,
        @NotNull(message = "event requis") AnalyticsEvent event,
        String path,
        Instant occurredAt,
        Map<String, String> properties,
        AnalyticsFirstTouchRequest firstTouch,
        String dedupKey
) {}
