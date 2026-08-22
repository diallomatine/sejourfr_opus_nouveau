package com.sejourfr.app.util;

import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.AnalyticsDiagnosticType;
import com.sejourfr.app.enums.AnalyticsRegistrationContext;
import com.sejourfr.app.enums.ClientPlatform;

import java.util.Locale;
import java.util.Map;

/**
 * Libelles FR de l'ecran Analytics — <b>poses par le serveur</b>, jamais par la
 * console.
 *
 * <p><b>Pourquoi ici et pas dans les enums.</b> Les libelles geles par
 * {@code AnalyticsLabelsTest} ({@code AnalyticsCtaLocation}) sont un
 * <i>contrat</i> recopie a la main dans les trois fronts. Ceux-ci n'en sont pas :
 * ils ne servent qu'a l'ecran admin, qui les recoit dans la reponse et n'en
 * tient aucune copie. Les mettre dans les enums en ferait des contrats a
 * mirrorer pour rien.
 *
 * <p>🛑 <b>« direct » et « inconnu » ne se confondent jamais</b> (brief §84,
 * doctrine {@code TrafficSource}) : le premier est une provenance
 * <i>observee</i> — personne n'a clique de lien —, le second est une
 * <i>absence d'observation</i>. Les fondre gonflerait le direct de tout
 * l'historique anterieur a la mesure, et ferait disparaitre le seul signal qui
 * dit « on ne sait pas ». C'est pour ca que « inconnu » reste affiche : un gros
 * volume d'inconnu est lui-meme l'information.
 */
public final class AnalyticsLibelles {

    /**
     * Cle de repli quand la geo-IP n'a rien conclu.
     *
     * <p>{@code UNKNOWN} et non le code ISO {@code ZZ} : cette valeur est lue
     * par un humain dans une console, et « ZZ » ressemble a un pays alors que
     * c'en est l'absence. Meme parti pris que {@code ClientPlatform.UNKNOWN}.
     */
    public static final String PAYS_INCONNU = "UNKNOWN";

    private static final Map<String, String> SOURCES = Map.of(
            "tiktok", "TikTok",
            "instagram", "Instagram",
            "whatsapp", "WhatsApp",
            "facebook", "Facebook",
            "youtube", "YouTube",
            TrafficSource.DIRECT, "Accès direct",
            TrafficSource.OTHER, "Autre réseau",
            TrafficSource.UNKNOWN, "Inconnu");

    private static final Map<AnalyticsDeviceType, String> APPAREILS = Map.of(
            AnalyticsDeviceType.MOBILE_WEB, "Mobile (web)",
            AnalyticsDeviceType.DESKTOP_WEB, "Ordinateur (web)",
            AnalyticsDeviceType.TABLET_WEB, "Tablette (web)",
            AnalyticsDeviceType.IOS, "Application iOS",
            AnalyticsDeviceType.ANDROID, "Application Android",
            AnalyticsDeviceType.UNKNOWN, "Inconnu");

    private static final Map<AnalyticsRegistrationContext, String> CONTEXTES = Map.of(
            AnalyticsRegistrationContext.LANDING, "Depuis une landing",
            AnalyticsRegistrationContext.BEFORE_DIAGNOSTIC, "Avant le diagnostic",
            AnalyticsRegistrationContext.DURING_DIAGNOSTIC, "Pendant le diagnostic",
            AnalyticsRegistrationContext.AFTER_DIAGNOSTIC, "Après les productions",
            AnalyticsRegistrationContext.DIAGNOSTIC_REPORT, "Depuis le rapport",
            AnalyticsRegistrationContext.PRICING, "Depuis la page tarifs",
            AnalyticsRegistrationContext.MOBILE_APP, "Depuis l'application",
            AnalyticsRegistrationContext.OTHER, "Autre");

    /**
     * Ce que chaque contexte dit reellement du parcours. Un compteur sans cette
     * phrase se lit mal : « après les productions » et « pendant le
     * diagnostic » designent deux moments tres differents de la decision.
     */
    private static final Map<AnalyticsRegistrationContext, String> INDICES = Map.of(
            AnalyticsRegistrationContext.LANDING, "Le compte est créé avant tout parcours.",
            AnalyticsRegistrationContext.BEFORE_DIAGNOSTIC,
            "Le compte est demandé avant la première production.",
            AnalyticsRegistrationContext.DURING_DIAGNOSTIC,
            "Le parcours est interrompu par la création de compte.",
            AnalyticsRegistrationContext.AFTER_DIAGNOSTIC,
            "Les deux productions sont faites, l'analyse attend un compte.",
            AnalyticsRegistrationContext.DIAGNOSTIC_REPORT,
            "Le niveau est connu, le compte vient après.",
            AnalyticsRegistrationContext.PRICING, "Le compte est créé depuis les prix.",
            AnalyticsRegistrationContext.MOBILE_APP, "Inscription dans l'application.",
            AnalyticsRegistrationContext.OTHER, "Contexte non déclaré par le front.");

    private AnalyticsLibelles() {
    }

    /** Libelle d'une provenance normalisee. Une valeur inconnue se rend telle quelle. */
    public static String source(String code) {
        if (code == null || code.isBlank()) return SOURCES.get(TrafficSource.UNKNOWN);
        String libelle = SOURCES.get(code.toLowerCase(Locale.ROOT));
        return libelle != null ? libelle : code;
    }

    /** Libelle d'un type d'appareil, tolerant a une valeur inconnue en base. */
    public static String appareil(String code) {
        AnalyticsDeviceType type = lire(AnalyticsDeviceType.class, code);
        return type == null ? APPAREILS.get(AnalyticsDeviceType.UNKNOWN) : APPAREILS.get(type);
    }

    /** Plateforme normalisee ({@code WEB} / {@code MOBILE} / {@code UNKNOWN}). */
    public static String plateforme(String code) {
        ClientPlatform platform = lire(ClientPlatform.class, code);
        return platform == null ? ClientPlatform.UNKNOWN.name() : platform.name();
    }

    /** Libelle d'un contexte d'inscription. */
    public static String contexte(String code) {
        AnalyticsRegistrationContext ctx = lire(AnalyticsRegistrationContext.class, code);
        return ctx == null ? CONTEXTES.get(AnalyticsRegistrationContext.OTHER) : CONTEXTES.get(ctx);
    }

    /** Ce que ce contexte dit du parcours. */
    public static String indiceContexte(String code) {
        AnalyticsRegistrationContext ctx = lire(AnalyticsRegistrationContext.class, code);
        return ctx == null ? INDICES.get(AnalyticsRegistrationContext.OTHER) : INDICES.get(ctx);
    }

    /**
     * Nom du pays en francais.
     *
     * <p>{@code UNKNOWN} et tout code illisible rendent « Inconnu » — jamais un pays
     * plausible : <i>null = inconnu, jamais invente</i>.
     */
    public static String pays(String code) {
        if (code == null || code.isBlank() || PAYS_INCONNU.equalsIgnoreCase(code)) return "Inconnu";
        String nom = Locale.of("", code.toUpperCase(Locale.ROOT)).getDisplayCountry(Locale.FRENCH);
        return nom == null || nom.isBlank() || nom.equalsIgnoreCase(code) ? code : nom;
    }

    /** Libelle d'une variante de diagnostic. */
    public static String diagnostic(String code) {
        AnalyticsDiagnosticType type = lire(AnalyticsDiagnosticType.class, code);
        if (type == null) return "Format non déclaré";
        return switch (type) {
            case RAPID -> "Diagnostic rapide";
            case COMPLETE -> "Diagnostic complet";
            case UNKNOWN -> "Format non déclaré";
        };
    }

    /** Ce que chaque format demande reellement au candidat. */
    public static String sousTitreDiagnostic(String code) {
        AnalyticsDiagnosticType type = lire(AnalyticsDiagnosticType.class, code);
        if (type == null) return "Le front n'a pas nommé le format.";
        return switch (type) {
            case RAPID -> "Expression écrite puis orale.";
            case COMPLETE -> "Les quatre domaines : EE, EO, CO, CE.";
            case UNKNOWN -> "Le front n'a pas nommé le format.";
        };
    }

    private static <E extends Enum<E>> E lire(Class<E> type, String code) {
        if (code == null || code.isBlank()) return null;
        for (E constant : type.getEnumConstants()) {
            if (constant.name().equalsIgnoreCase(code.trim())) return constant;
        }
        return null;
    }
}
