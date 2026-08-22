package com.sejourfr.app.service.analytics;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.dto.AnalyticsEventRequest;
import com.sejourfr.app.dto.AnalyticsFirstTouchRequest;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.AnalyticsProperty;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.util.AnalyticsPaths;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.TrafficSource;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Reception des evenements d'analytics : valide, resout ce qui doit l'etre
 * serveur, tient le visiteur a jour, ecrit le geste.
 *
 * <p><b>Tout ce qui est refusable l'est ICI et par une allowlist</b>, parce que
 * l'endpoint est public : le registre d'evenements, les cles de proprietes, les
 * valeurs de proprietes, les chemins, la provenance. Ce n'est pas de la
 * defiance envers nos propres fronts — c'est ce qui rend le §95 du brief
 * (« ne jamais stocker de mot de passe, de production, de jeton ») vrai par
 * construction plutot que par vigilance, et ce qui borne la cardinalite d'une
 * table qu'un tiers peut alimenter.
 *
 * <p><b>Ce qui n'est PAS ici</b> : aucun evenement d'inscription, de paiement
 * ni de diagnostic termine. Ces faits ont deja une source exacte
 * ({@code users}, {@code user_subscriptions}, {@code diagnostic_sessions}) et
 * en doubler un creerait une seconde verite, condamnee a diverger (doctrine
 * V036).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsIngestionService {

    /**
     * Ecart maximal tolere entre l'horodate annoncee par le client et l'heure
     * serveur.
     *
     * <p>Assez large pour absorber une horloge mal reglee, un
     * {@code sendBeacon} differe et une file rejouee au retour du reseau ; assez
     * etroite pour qu'on ne puisse pas <b>fabriquer un historique</b>. Sans
     * cette borne, l'endpoint public permet de reecrire le mois dernier.
     */
    static final Duration ECART_HORODATE_MAX = Duration.ofHours(24);

    /** Hote de referrer : lettres, chiffres, tirets et points. Rien d'autre. */
    private static final Pattern HOTE = Pattern.compile("^[a-z0-9]([a-z0-9.-]{0,118}[a-z0-9])?$");

    /** Cle de dedoublonnage : identifiant technique, jamais du texte libre. */
    private static final Pattern DEDUP_KEY = Pattern.compile("^[A-Za-z0-9:._-]{1,120}$");

    private final AnalyticsVisitorManager visitorManager;
    private final AnalyticsEventManager eventManager;

    /**
     * Instance propre, comme {@code GoogleSubscriptionService} : rien n'est
     * serialise ici qu'une {@code Map<String, String>} deja normalisee, donc
     * aucun reglage de contexte n'est necessaire — et une dependance de moins.
     */
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Enregistre un evenement.
     *
     * @param request  corps recu
     * @param client   en-tetes {@code X-Sejourfr-Client} / {@code -Source}
     * @param ip       IP de l'appelant — <b>jamais persistee</b>, lue le temps
     *                 d'en tirer un code pays, puis oubliee
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
        refuseEvenementServeur(event);

        Instant occurredAt = horodate(request.occurredAt());
        String path = AnalyticsPaths.normalizeOrThrow(request.path());
        Map<String, String> properties = normalizeProperties(event, request.properties());
        String dedupKey = normalizeDedupKey(request.dedupKey());

        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        AnalyticsVisitorManager.Attribution attribution = attribution(request.firstTouch(), ctx, path);
        boolean explicitSource = sourceExplicite(request.firstTouch(), ctx);

        // Le visiteur AVANT l'evenement : la cle etrangere l'exige, et c'est
        // aussi l'ordre logique — on ne peut pas observer un geste de quelqu'un
        // qui n'existe pas.
        visitorManager.touch(request.anonymousId(), occurredAt, attribution, explicitSource,
                country, device, ctx.platform());

        return eventManager.record(event, occurredAt, request.anonymousId(), request.sessionId(),
                userId, path, toJson(properties), dedupKey);
    }

    // ------------------------------------------------------------------------
    // Validations
    // ------------------------------------------------------------------------

    /**
     * Un evenement pose par le serveur n'est jamais accepte d'un client.
     *
     * <p>Venant d'un navigateur, {@code CHECKOUT_STARTED} serait une
     * <i>intention</i> et non un fait : la derniere marche de l'entonnoir ne
     * voudrait plus rien dire. Meme arbitrage que sur
     * {@code POST /api/me/funnel-events}, ou il est deja refuse.
     */
    private void refuseEvenementServeur(AnalyticsEvent event) {
        if (event.isEmisParLeClient()) return;
        throw new IllegalArgumentException(
                "Valeur invalide pour « event » : « " + event.name()
                        + " ». Cet événement est posé par le serveur, un client ne peut pas l'émettre.");
    }

    /**
     * Horodate retenue. Absente ⇒ maintenant ; au-dela de {@link
     * #ECART_HORODATE_MAX} dans un sens ou dans l'autre ⇒ 400 nomme.
     */
    private Instant horodate(Instant declaree) {
        Instant now = Instant.now();
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

    /**
     * Proprietes normalisees : cles admises <b>par cet evenement</b>, valeurs
     * admises par chaque propriete.
     *
     * <p>Une cle inconnue est un refus, jamais un abandon silencieux : c'est ce
     * qui garantit qu'aucune donnee non prevue n'entre dans la table, et c'est
     * aussi la seule facon qu'un front a d'apprendre qu'il instrumente de
     * travers.
     *
     * <p>{@link TreeMap} : le JSON persiste est stable d'un appel a l'autre, ce
     * qui rend deux lignes comparables a l'oeil et un test reproductible.
     */
    private Map<String, String> normalizeProperties(AnalyticsEvent event, Map<String, String> raw) {
        Map<String, String> normalized = new TreeMap<>();
        if (raw == null || raw.isEmpty()) return normalized;

        for (Map.Entry<String, String> entry : raw.entrySet()) {
            String key = entry.getKey() == null ? "" : entry.getKey().trim();
            // Une valeur absente n'est pas une faute du front (un champ
            // facultatif non renseigne) : on l'ignore, on ne refuse pas
            // l'evenement pour ca.
            if (entry.getValue() == null || entry.getValue().isBlank()) continue;

            AnalyticsProperty property = AnalyticsProperty.byKey(key);
            if (property == null || !event.allows(property)) {
                throw new IllegalArgumentException(
                        "Propriété « " + key + " » non autorisée sur l'événement "
                                + event.name() + ". Propriétés acceptées : " + event.allowedKeys() + ".");
            }
            normalized.put(property.getKey(), property.normalizeOrThrow(entry.getValue()));
        }
        return normalized;
    }

    private String normalizeDedupKey(String raw) {
        if (raw == null || raw.isBlank()) return null;
        String key = raw.trim();
        if (!DEDUP_KEY.matcher(key).matches()) {
            throw new IllegalArgumentException(
                    "Valeur invalide pour « dedupKey » : « " + raw
                            + " ». Attendu : un identifiant technique (lettres, chiffres, « : . _ - »,"
                            + " 120 caractères max).");
        }
        return key;
    }

    private String toJson(Map<String, String> properties) {
        try {
            return objectMapper.writeValueAsString(properties);
        } catch (JsonProcessingException e) {
            // Impossible en pratique : ce sont des chaines deja normalisees.
            throw new IllegalStateException("Sérialisation des propriétés impossible", e);
        }
    }

    // ------------------------------------------------------------------------
    // Attribution
    // ------------------------------------------------------------------------

    /**
     * Attribution a poser sur le visiteur.
     *
     * <p>La provenance passe par {@link TrafficSource#normalize} : la meme
     * allowlist fermee que {@code users.signup_source} et {@code page_views}. Une
     * seule dimension pour un seul fait — deux normalisations differentes
     * rangeraient « tiktok » a deux endroits.
     *
     * <p><b>Les UTM ne sont ni refusees ni rejetees quand elles sont trop
     * longues : elles sont tronquees.</b> Ce sont des chaines redigees par un
     * outil marketing, sur lesquelles nous n'avons aucun pouvoir ; perdre
     * l'evenement entier parce qu'un nom de campagne fait 130 caracteres serait
     * un mauvais echange. Les longueurs sont ici des bornes de <i>stockage</i>,
     * pas des regles.
     */
    private AnalyticsVisitorManager.Attribution attribution(
            AnalyticsFirstTouchRequest firstTouch, ClientContext ctx, String path) {

        if (firstTouch == null) {
            return new AnalyticsVisitorManager.Attribution(
                    ctx.source(), null, null, null, null, path, null);
        }
        String source = firstTouch.source() != null && !firstTouch.source().isBlank()
                ? TrafficSource.normalize(firstTouch.source())
                : ctx.source();
        String landing = firstTouch.landingPath() != null && !firstTouch.landingPath().isBlank()
                ? AnalyticsPaths.normalizeOrThrow(firstTouch.landingPath())
                : path;
        return new AnalyticsVisitorManager.Attribution(
                source,
                tronque(firstTouch.medium(), 40),
                tronque(firstTouch.campaign(), 120),
                tronque(firstTouch.content(), 120),
                tronque(firstTouch.term(), 120),
                landing,
                hote(firstTouch.referrerHost()));
    }

    /**
     * Une source est « explicite » quand quelqu'un l'a reellement declaree : un
     * bloc d'attribution avec une provenance, ou un en-tete de provenance qui
     * n'est pas le repli {@code direct}.
     *
     * <p>C'est cette condition, et elle seule, qui autorise la reecriture du
     * last touch. Sans elle, la deuxieme page vue d'un visiteur venu de TikTok
     * ramenerait son last touch a « direct », et « quelle source a precede
     * l'achat » repondrait « direct » pour tout le monde.
     */
    private boolean sourceExplicite(AnalyticsFirstTouchRequest firstTouch, ClientContext ctx) {
        if (firstTouch != null && firstTouch.source() != null && !firstTouch.source().isBlank()) {
            return true;
        }
        return ctx.source() != null && !TrafficSource.DIRECT.equals(ctx.source());
    }

    /**
     * Hote seul, minuscule, sans port. Une URL complete arrivee par megarde est
     * ramenee a son hote — jamais stockee telle quelle : elle peut porter un
     * identifiant ou un terme de recherche.
     */
    private String hote(String raw) {
        if (raw == null || raw.isBlank()) return null;
        String value = raw.trim().toLowerCase(Locale.ROOT);
        int scheme = value.indexOf("://");
        if (scheme >= 0) value = value.substring(scheme + 3);
        int slash = value.indexOf('/');
        if (slash >= 0) value = value.substring(0, slash);
        int at = value.indexOf('@');
        if (at >= 0) value = value.substring(at + 1);
        int colon = value.indexOf(':');
        if (colon >= 0) value = value.substring(0, colon);
        // Un hote illisible ne vaut pas la peine d'un refus (le referrer est du
        // decor), mais il ne vaut pas non plus d'etre stocke : on l'oublie.
        return HOTE.matcher(value).matches() ? value : null;
    }

    private String tronque(String raw, int max) {
        if (raw == null) return null;
        String value = raw.trim().replaceAll("[\\p{Cntrl}]", "");
        if (value.isEmpty()) return null;
        return value.length() <= max ? value : value.substring(0, max);
    }

    /** Copie defensive utilisee par les tests de normalisation. */
    Map<String, String> normalizePropertiesForTest(AnalyticsEvent event, Map<String, String> raw) {
        return new LinkedHashMap<>(normalizeProperties(event, raw));
    }
}
