package com.sejourfr.app.dto;

import java.util.Map;

/**
 * Un evenement d'un lot. <b>Tout est recu en texte</b>, identifiants compris :
 * un UUID ou un nom d'evenement mal forme doit rejeter CET evenement, pas faire
 * echouer la lecture de tout le lot.
 *
 * <p>Jamais de pays, de type d'appareil ni de plateforme ici : ils sont
 * resolus serveur.
 *
 * @param eventId         UUID tire par le client <b>a la creation</b> de
 *                        l'evenement (pas a l'envoi) : c'est lui qui rend un
 *                        lot rejouable sans doublon. Obligatoire.
 * @param event           nom au registre {@code AnalyticsEvent}
 * @param occurredAt      horodate ISO-8601 du geste. Absente ⇒ heure de
 *                        reception ; dans le futur au-dela de la tolerance ⇒
 *                        ramenee a l'heure de reception ; plus ancienne que
 *                        {@code ingestion.maxEventAgeHours} ⇒ rejetee
 * @param path            ecran, dans l'allowlist {@code AnalyticsPaths}
 * @param properties      proprietes, cles ET valeurs allowlistees par evenement
 * @param dedupKey        idempotence metier facultative
 * @param diagnosticRunId run du tunnel (UUID), si l'evenement l'admet ; elle
 *                        doit exister, et son type fait foi
 * @param diagnosticType  {@code QUICK_TCF | FULL_TCF | CIVIQUE}, si l'evenement
 *                        l'admet ; doit concorder avec la run si elle est citee
 * @param journeyId       {@code plan_id} = {@code journey.id} (UUID), si
 *                        l'evenement l'admet ; il doit exister
 */
public record AnalyticsBatchEventRequest(
        String eventId,
        String event,
        String occurredAt,
        String path,
        Map<String, String> properties,
        String dedupKey,
        String diagnosticRunId,
        String diagnosticType,
        String journeyId
) {}
