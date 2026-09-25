package com.sejourfr.app.service.analytics;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.dto.AnalyticsFirstTouchRequest;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.AnalyticsProperty;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.util.AnalyticsPaths;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.TrafficSource;
import org.springframework.stereotype.Component;

import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import java.util.regex.Pattern;

/**
 * <b>Autorite unique</b> de la validation d'un evenement d'analytics et de
 * l'attribution de son visiteur, partagee par l'ingestion unitaire et
 * l'ingestion en lot. Deux copies de ces allowlists auraient fini par accepter
 * d'un cote ce que l'autre refuse.
 *
 * <p><b>Tout ce qui est refusable l'est ICI et par une allowlist</b>, parce que
 * l'endpoint est public : le registre d'evenements, les cles de proprietes, les
 * valeurs de proprietes, les chemins, la provenance. C'est ce qui rend « ne
 * jamais stocker de mot de passe, de production, de jeton » vrai par
 * construction plutot que par vigilance, et ce qui borne la cardinalite d'une
 * table qu'un tiers peut alimenter.
 *
 * <p>Chaque refus est une {@link IllegalArgumentException} au message nomme
 * (champ, valeur recue, valeurs admises) : 400 en unitaire, rejet individuel
 * en lot.
 */
@Component
public class AnalyticsEventNormalizer {

    /** Hote de referrer : lettres, chiffres, tirets et points. Rien d'autre. */
    private static final Pattern HOTE = Pattern.compile("^[a-z0-9]([a-z0-9.-]{0,118}[a-z0-9])?$");

    /** Cle de dedoublonnage : identifiant technique, jamais du texte libre. */
    private static final Pattern DEDUP_KEY = Pattern.compile("^[A-Za-z0-9:._-]{1,120}$");

    /** Caracteres conserves d'une source declaree ({@code ft_source_raw}). */
    private static final Pattern HORS_SLUG = Pattern.compile("[^a-z0-9._-]");

    private static final int SOURCE_RAW_MAX = 40;

    /**
     * Instance propre : rien n'est serialise ici qu'une
     * {@code Map<String, String>} deja normalisee.
     */
    private final ObjectMapper objectMapper = new ObjectMapper();

    // ------------------------------------------------------------------------
    // L'evenement
    // ------------------------------------------------------------------------

    /**
     * Nom d'evenement recu en texte (ingestion en lot, ou un nom inconnu doit
     * rejeter CET evenement et pas tout le lot).
     */
    public AnalyticsEvent parseEvent(String raw) {
        String value = raw == null ? "" : raw.trim().toUpperCase(Locale.ROOT);
        for (AnalyticsEvent event : AnalyticsEvent.values()) {
            if (event.name().equals(value)) return event;
        }
        throw new IllegalArgumentException("Valeur invalide pour « event » : « " + raw
                + " ». Attendu : un événement du registre (enums/AnalyticsEvent).");
    }

    /**
     * Un evenement pose par le serveur n'est jamais accepte d'un client.
     *
     * <p>Venant d'un navigateur, {@code CHECKOUT_STARTED} serait une
     * <i>intention</i> et non un fait : la derniere marche de l'entonnoir ne
     * voudrait plus rien dire.
     */
    public void refuseEvenementServeur(AnalyticsEvent event) {
        if (event.isEmisParLeClient()) return;
        throw new IllegalArgumentException(
                "Valeur invalide pour « event » : « " + event.name()
                        + " ». Cet événement est posé par le serveur, un client ne peut pas l'émettre.");
    }

    /** Chemin dans l'allowlist, ou {@code null} s'il est absent. */
    public String path(String raw) {
        return AnalyticsPaths.normalizeOrThrow(raw);
    }

    /**
     * Proprietes normalisees : cles admises <b>par cet evenement</b>, valeurs
     * admises par chaque propriete.
     *
     * <p>Une cle inconnue est un refus, jamais un abandon silencieux : c'est ce
     * qui garantit qu'aucune donnee non prevue n'entre dans la table, et c'est
     * aussi la seule facon qu'un front a d'apprendre qu'il instrumente de
     * travers. {@link TreeMap} : le JSON persiste est stable d'un appel a
     * l'autre.
     */
    public Map<String, String> properties(AnalyticsEvent event, Map<String, String> raw) {
        Map<String, String> normalized = new TreeMap<>();
        if (raw == null || raw.isEmpty()) return normalized;

        for (Map.Entry<String, String> entry : raw.entrySet()) {
            String key = entry.getKey() == null ? "" : entry.getKey().trim();
            // Une valeur absente n'est pas une faute du front (un champ
            // facultatif non renseigne) : on l'ignore.
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

    public String dedupKey(String raw) {
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

    public String toJson(Map<String, String> properties) {
        try {
            return objectMapper.writeValueAsString(properties);
        } catch (JsonProcessingException e) {
            // Impossible en pratique : ce sont des chaines deja normalisees.
            throw new IllegalStateException("Sérialisation des propriétés impossible", e);
        }
    }

    // ------------------------------------------------------------------------
    // L'attribution du visiteur
    // ------------------------------------------------------------------------

    /**
     * Attribution a poser sur le visiteur.
     *
     * <p>La provenance passe par {@link TrafficSource#normalize} : la meme
     * allowlist fermee que {@code users.signup_source}. La source DECLAREE est
     * gardee a cote, brute mais bornee ({@code ft_source_raw}), pour que le
     * regroupement de la config ({@code ig} ⇒ instagram) se fasse a la lecture.
     *
     * <p><b>Les UTM trop longues sont tronquees, pas rejetees</b> : ce sont des
     * chaines redigees par un outil marketing ; les longueurs sont des bornes de
     * <i>stockage</i>, pas des regles.
     */
    public AnalyticsVisitorManager.Attribution attribution(
            AnalyticsFirstTouchRequest firstTouch, ClientContext ctx, String path) {

        if (firstTouch == null) {
            return new AnalyticsVisitorManager.Attribution(
                    ctx.source(), null, null, null, null, path, null, sourceRaw(null, ctx));
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
                hote(firstTouch.referrerHost()),
                sourceRaw(firstTouch.source(), ctx));
    }

    /**
     * Une source est « explicite » quand quelqu'un l'a reellement declaree : un
     * bloc d'attribution avec une provenance, ou un en-tete de provenance qui
     * n'est pas le repli {@code direct}. C'est cette condition, et elle seule,
     * qui autorise la reecriture du last touch.
     */
    public boolean sourceExplicite(AnalyticsFirstTouchRequest firstTouch, ClientContext ctx) {
        if (firstTouch != null && firstTouch.source() != null && !firstTouch.source().isBlank()) {
            return true;
        }
        return ctx.source() != null && !TrafficSource.DIRECT.equals(ctx.source());
    }

    /**
     * Source declaree, en minuscules, reduite au charset {@code [a-z0-9._-]} et a
     * 40 caracteres. {@code null} si rien n'a ete declare — une absence n'est pas
     * « direct ».
     */
    static String sourceRaw(String declared, ClientContext ctx) {
        String value = declared;
        if (value == null || value.isBlank()) {
            value = ctx.source() != null && !TrafficSource.DIRECT.equals(ctx.source()) ? ctx.source() : null;
        }
        if (value == null) return null;
        String slug = HORS_SLUG.matcher(value.trim().toLowerCase(Locale.ROOT)).replaceAll("");
        if (slug.isEmpty()) return null;
        return slug.length() <= SOURCE_RAW_MAX ? slug : slug.substring(0, SOURCE_RAW_MAX);
    }

    /**
     * Hote seul, minuscule, sans port. Une URL complete arrivee par megarde est
     * ramenee a son hote — jamais stockee telle quelle.
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
        return HOTE.matcher(value).matches() ? value : null;
    }

    private String tronque(String raw, int max) {
        if (raw == null) return null;
        String value = raw.trim().replaceAll("[\\p{Cntrl}]", "");
        if (value.isEmpty()) return null;
        return value.length() <= max ? value : value.substring(0, max);
    }
}
