package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AnalyticsBatchEventRequest;
import com.sejourfr.app.dto.AnalyticsBatchRequest;
import com.sejourfr.app.dto.AnalyticsBatchResponse;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.AnalyticsIdentityManager;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.util.ClientContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Reception d'un <b>lot</b> d'evenements d'analytics
 * ({@code POST /api/public/analytics/events/batch}, chantier Suivi, Q17).
 *
 * <p>Trois regles, et elles structurent tout le fichier :
 * <ol>
 *   <li><b>Rejet individuel.</b> L'enveloppe invalide refuse le lot (400) ; un
 *       evenement invalide est rejete SEUL, avec son motif nomme, et les autres
 *       sont ecrits (202). Une file mobile ne doit pas rester bloquee pour un
 *       evenement mal forme.</li>
 *   <li><b>Idempotence par {@code eventId}.</b> Tire par le client a la
 *       creation de l'evenement ; l'insertion est un
 *       {@code ON CONFLICT DO NOTHING}. Un lot rejoue n'ecrit rien et repond
 *       202 avec des doublons (scenario 10).</li>
 *   <li><b>Le serveur resout ce qui est resolvable.</b> Le type d'une run
 *       citee se lit sur la run (un client ne peut pas ranger un civique en
 *       TCF), la plateforme sur les en-tetes, {@code is_internal} sur les
 *       comptes. Une run ou un parcours inconnu est un rejet, jamais un
 *       identifiant orphelin ecrit en base.</li>
 * </ol>
 *
 * <p>Cout borne et independant de la taille du lot pour les lectures : une
 * requete pour les runs, une pour les parcours, une pour {@code is_internal},
 * une ou deux pour le visiteur ; puis une insertion par evenement.
 */
@Service
@RequiredArgsConstructor
public class AnalyticsBatchIngestionService {

    private final AnalyticsEventNormalizer normalizer;
    private final AnalyticsVisitorManager visitorManager;
    private final AnalyticsEventManager eventManager;
    private final AnalyticsIdentityManager identityManager;
    private final DiagnosticRunManager diagnosticRunManager;
    private final JourneyManager journeyManager;
    private final UserManager userManager;
    private final AnalyticsConfig config;
    private final Clock clock;

    /**
     * Ingere un lot.
     *
     * @param request lot recu (enveloppe deja validee par {@code @Valid})
     * @param client  contexte resolu par {@code ClientContextResolver}, en-tetes
     *                d'abord, corps en repli
     * @param country pays deja resolu par l'appelant ({@code null} = inconnu)
     * @param device  type d'appareil deja resolu par l'appelant
     * @param principal adresse du compte appelant s'il est connecte (jeton JWT
     *                  valide), {@code null} sinon — un {@code sendBeacon} n'en
     *                  porte jamais
     * @throws IllegalArgumentException enveloppe invalide (lot trop gros,
     *         attribution hors allowlist) : tout le lot est refuse
     */
    @Transactional
    public AnalyticsBatchResponse ingest(AnalyticsBatchRequest request, ClientContext client,
                                         String country, AnalyticsDeviceType device, String principal) {
        List<AnalyticsBatchEventRequest> events = request.events();
        int max = config.ingestion().maxBatchSize();
        if (events.size() > max) {
            throw new IllegalArgumentException("Valeur invalide pour « events » : " + events.size()
                    + " événements. Attendu : " + max + " au plus par lot.");
        }
        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        Instant receivedAt = clock.instant();
        List<AnalyticsBatchResponse.Rejection> rejected = new ArrayList<>();

        List<Candidat> candidats = new ArrayList<>();
        for (int i = 0; i < events.size(); i++) {
            AnalyticsBatchEventRequest raw = events.get(i);
            try {
                candidats.add(lire(i, raw, receivedAt));
            } catch (IllegalArgumentException e) {
                rejected.add(new AnalyticsBatchResponse.Rejection(i, raw == null ? null : raw.eventId(),
                        e.getMessage()));
            }
        }

        List<Candidat> valides = resoudreContextes(candidats, rejected);
        rejected.sort(Comparator.comparingInt(AnalyticsBatchResponse.Rejection::index));
        if (valides.isEmpty()) {
            return new AnalyticsBatchResponse(events.size(), 0, 0, rejected);
        }

        toucherLeVisiteur(request, ctx, country, device, valides);
        UUID userId = principal == null ? null
                : userManager.findByEmail(principal).map(u -> u.getId()).orElse(null);
        boolean internal = identityManager.isInternal(request.anonymousId(), userId);

        int accepted = 0;
        int duplicates = 0;
        for (Candidat c : valides) {
            boolean ecrit = eventManager.record(new AnalyticsEventManager.Ligne(
                    c.event, c.occurredAt, request.anonymousId(), request.sessionId(), userId, c.path,
                    c.propertiesJson, c.dedupKey, c.eventId, receivedAt, ctx.platform(), ctx.appVersion(),
                    c.diagnosticType, c.diagnosticRunId, c.journeyId, internal));
            if (ecrit) accepted++;
            else duplicates++;
        }
        return new AnalyticsBatchResponse(events.size(), accepted, duplicates, rejected);
    }

    // ------------------------------------------------------------------------
    // Validation d'un evenement, sans base
    // ------------------------------------------------------------------------

    private Candidat lire(int index, AnalyticsBatchEventRequest raw, Instant receivedAt) {
        if (raw == null) throw new IllegalArgumentException("Événement vide.");
        UUID eventId = uuidRequis(raw.eventId(), "eventId");
        AnalyticsEvent event = normalizer.parseEvent(raw.event());
        normalizer.refuseEvenementServeur(event);

        Candidat c = new Candidat(index, eventId, event);
        c.occurredAt = horodate(raw.occurredAt(), receivedAt);
        c.path = normalizer.path(raw.path());
        c.propertiesJson = normalizer.toJson(normalizer.properties(event, raw.properties()));
        c.dedupKey = normalizer.dedupKey(raw.dedupKey());

        AnalyticsEvent.Contexte contexte = event.getContexte();
        UUID runId = uuidFacultatif(raw.diagnosticRunId(), "diagnosticRunId");
        boolean typeDeclare = raw.diagnosticType() != null && !raw.diagnosticType().isBlank();
        if ((runId != null || typeDeclare) && !contexte.admetDiagnostic()) {
            throw new IllegalArgumentException("« diagnosticRunId » / « diagnosticType » non autorisés sur "
                    + "l'événement " + event.name() + ".");
        }
        c.diagnosticRunId = runId;
        c.diagnosticType = typeDeclare ? DiagnosticRunType.parseOrThrow(raw.diagnosticType()) : null;

        UUID journeyId = uuidFacultatif(raw.journeyId(), "journeyId");
        if (journeyId != null && !contexte.admetPlan()) {
            throw new IllegalArgumentException("« journeyId » non autorisé sur l'événement "
                    + event.name() + ".");
        }
        c.journeyId = journeyId;
        return c;
    }

    /**
     * Horodate retenue (brief §4.1) :
     * <ul>
     *   <li>absente ⇒ heure de reception ;</li>
     *   <li>dans le futur au-dela de la tolerance ⇒ <b>heure de reception</b>
     *       (horloge client fausse : on garde le geste, pas sa date) ;</li>
     *   <li>plus ancienne que {@code maxEventAgeHours} ⇒ <b>rejet</b> : sans cette
     *       borne, un endpoint public permet de fabriquer l'historique.</li>
     * </ul>
     */
    private Instant horodate(String raw, Instant receivedAt) {
        if (raw == null || raw.isBlank()) return receivedAt;
        Instant declaree;
        try {
            declaree = Instant.parse(raw.trim());
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Valeur invalide pour « occurredAt » : « " + raw
                    + " ». Attendu : une date ISO-8601 UTC (2026-09-25T10:15:30Z).");
        }
        if (declaree.isAfter(receivedAt.plus(config.ingestion().clockSkewTolerance()))) {
            return receivedAt;
        }
        if (declaree.isBefore(receivedAt.minus(config.ingestion().maxEventAge()))) {
            throw new IllegalArgumentException("Valeur invalide pour « occurredAt » : « " + raw
                    + " ». Attendu : un geste de moins de " + config.ingestion().maxEventAgeHours() + " h.");
        }
        return declaree;
    }

    // ------------------------------------------------------------------------
    // Resolution serveur des contextes (une requete par nature)
    // ------------------------------------------------------------------------

    private List<Candidat> resoudreContextes(List<Candidat> candidats,
                                             List<AnalyticsBatchResponse.Rejection> rejected) {
        Set<UUID> runIds = new HashSet<>();
        Set<UUID> journeyIds = new HashSet<>();
        for (Candidat c : candidats) {
            if (c.diagnosticRunId != null) runIds.add(c.diagnosticRunId);
            if (c.journeyId != null) journeyIds.add(c.journeyId);
        }
        Map<UUID, DiagnosticRunType> types = diagnosticRunManager.typesByIds(runIds);
        Set<UUID> parcours = journeyManager.existingIds(journeyIds);

        List<Candidat> valides = new ArrayList<>();
        for (Candidat c : candidats) {
            String motif = motifDeContexte(c, types, parcours);
            if (motif != null) {
                rejected.add(new AnalyticsBatchResponse.Rejection(c.index, c.eventId.toString(), motif));
                continue;
            }
            if (c.diagnosticRunId != null) c.diagnosticType = types.get(c.diagnosticRunId);
            valides.add(c);
        }
        return valides;
    }

    private String motifDeContexte(Candidat c, Map<UUID, DiagnosticRunType> types, Set<UUID> parcours) {
        if (c.diagnosticRunId != null) {
            DiagnosticRunType type = types.get(c.diagnosticRunId);
            if (type == null) {
                return "Valeur invalide pour « diagnosticRunId » : « " + c.diagnosticRunId
                        + " ». Attendu : une run de diagnostic existante.";
            }
            if (c.diagnosticType != null && c.diagnosticType != type) {
                return "Valeur invalide pour « diagnosticType » : « " + c.diagnosticType
                        + " ». La run citée est de type " + type + ".";
            }
        }
        if (c.journeyId != null && !parcours.contains(c.journeyId)) {
            return "Valeur invalide pour « journeyId » : « " + c.journeyId
                    + " ». Attendu : un parcours existant.";
        }
        return null;
    }

    // ------------------------------------------------------------------------
    // Visiteur
    // ------------------------------------------------------------------------

    /**
     * Le visiteur AVANT les evenements (la cle etrangere l'exige). Deux
     * ecritures au plus : a la plus ancienne horodate (c'est elle qui fixe
     * {@code first_seen_at} d'un nouveau visiteur) puis a la plus recente
     * ({@code last_seen_at}). L'upsert tient deja {@code LEAST}/{@code GREATEST}.
     */
    private void toucherLeVisiteur(AnalyticsBatchRequest request, ClientContext ctx, String country,
                                   AnalyticsDeviceType device, List<Candidat> valides) {
        Instant premier = valides.stream().map(c -> c.occurredAt).min(Comparator.naturalOrder()).orElseThrow();
        Instant dernier = valides.stream().map(c -> c.occurredAt).max(Comparator.naturalOrder()).orElseThrow();
        String path = valides.stream().map(c -> c.path).filter(p -> p != null).findFirst().orElse(null);

        AnalyticsVisitorManager.Attribution attribution =
                normalizer.attribution(request.firstTouch(), ctx, path);
        boolean explicitSource = normalizer.sourceExplicite(request.firstTouch(), ctx);
        visitorManager.touch(request.anonymousId(), premier, attribution, explicitSource,
                country, device, ctx.platform());
        if (dernier.isAfter(premier)) {
            visitorManager.touch(request.anonymousId(), dernier, attribution, false,
                    country, device, ctx.platform());
        }
    }

    // ------------------------------------------------------------------------

    private static UUID uuidRequis(String raw, String champ) {
        UUID id = uuidFacultatif(raw, champ);
        if (id == null) throw new IllegalArgumentException("« " + champ + " » requis.");
        return id;
    }

    private static UUID uuidFacultatif(String raw, String champ) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return UUID.fromString(raw.trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Valeur invalide pour « " + champ + " » : « " + raw
                    + " ». Attendu : un UUID.");
        }
    }

    /** Un evenement valide, en attente de la resolution de ses contextes. */
    private static final class Candidat {
        private final int index;
        private final UUID eventId;
        private final AnalyticsEvent event;
        private Instant occurredAt;
        private String path;
        private String propertiesJson;
        private String dedupKey;
        private UUID diagnosticRunId;
        private DiagnosticRunType diagnosticType;
        private UUID journeyId;

        private Candidat(int index, UUID eventId, AnalyticsEvent event) {
            this.index = index;
            this.eventId = eventId;
            this.event = event;
        }
    }
}
