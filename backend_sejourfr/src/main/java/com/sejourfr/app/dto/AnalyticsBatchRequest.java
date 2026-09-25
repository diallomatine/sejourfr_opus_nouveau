package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

/**
 * Un lot d'evenements d'analytics ({@code POST /api/public/analytics/events/batch},
 * chantier Suivi, arbitrage Q17).
 *
 * <p>L'<b>enveloppe</b> porte ce qui est commun a tout le lot (le visiteur, sa
 * visite, son attribution) ; une enveloppe invalide refuse tout le lot (400).
 * Chaque <b>evenement</b> est valide a part : un evenement invalide est rejete
 * seul, sans faire echouer les autres (202 + rapport).
 *
 * <p>{@code client} et {@code appVersion} ne servent que si les en-tetes
 * {@code X-Sejourfr-Client} / {@code X-Sejourfr-App-Version} manquent : un
 * {@code sendBeacon} (envoi a la fermeture d'une page) ne peut poser aucun
 * en-tete. <b>L'en-tete prime toujours.</b>
 *
 * @param anonymousId identifiant de mesure du visiteur (retention 13 mois)
 * @param sessionId   visite courante
 * @param client      {@code web | ios | android}, repli de l'en-tete
 * @param appVersion  version de l'application, repli de l'en-tete
 * @param firstTouch  attribution, a la premiere requete du visiteur seulement
 * @param events      au plus {@code ingestion.maxBatchSize} evenements (config)
 */
public record AnalyticsBatchRequest(
        @NotNull(message = "anonymousId requis") UUID anonymousId,
        @NotNull(message = "sessionId requis") UUID sessionId,
        String client,
        String appVersion,
        AnalyticsFirstTouchRequest firstTouch,
        @NotNull(message = "events requis") List<AnalyticsBatchEventRequest> events
) {}
