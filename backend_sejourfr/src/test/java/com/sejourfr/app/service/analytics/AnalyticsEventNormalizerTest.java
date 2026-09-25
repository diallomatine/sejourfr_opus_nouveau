package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AnalyticsFirstTouchRequest;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.TrafficSource;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * La validation d'un evenement d'analytics vue du cote « ce qui est refuse ».
 * L'ingestion en lot est publique : tout ce qui n'est pas verrouille ici est
 * verrouille nulle part. Repris de l'ancien {@code AnalyticsIngestionServiceTest}
 * quand l'endpoint unitaire a ete retire (Q17) : la regle, elle, n'a pas bouge.
 */
class AnalyticsEventNormalizerTest {

    private static final ClientContext WEB_DIRECT =
            new ClientContext(ClientPlatform.WEB, TrafficSource.DIRECT);

    private final AnalyticsEventNormalizer normalizer = new AnalyticsEventNormalizer();

    private static AnalyticsFirstTouchRequest firstTouch(String source, String campaign, String content,
                                                         String referrer) {
        return new AnalyticsFirstTouchRequest(source, null, campaign, content, null, "/reussir", referrer);
    }

    // ------------------------------------------------------------------------
    // Ce qui est refusé
    // ------------------------------------------------------------------------

    /**
     * Venant d'un client, {@code CHECKOUT_STARTED} serait une INTENTION et non un
     * fait : la derniere marche de l'entonnoir ne voudrait plus rien dire.
     */
    @Test
    @DisplayName("Un événement posé par le serveur est refusé au client")
    void evenementServeurRefuse() {
        assertThatThrownBy(() -> normalizer.refuseEvenementServeur(AnalyticsEvent.CHECKOUT_STARTED))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("CHECKOUT_STARTED")
                .hasMessageContaining("posé par le serveur");
    }

    /**
     * 🛑 Le test qui rend le §95 du brief vrai par construction : aucune cle hors
     * allowlist n'entre, donc aucun mot de passe, aucune production, aucun jeton.
     */
    @Test
    @DisplayName("Une propriété hors allowlist est refusée en nommant ce qui était accepté")
    void proprieteHorsAllowlist() {
        assertThatThrownBy(() -> normalizer.properties(AnalyticsEvent.LANDING_VIEWED,
                Map.of("email", "candidat@exemple.fr")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("email")
                .hasMessageContaining("LANDING_VIEWED")
                .hasMessageContaining("landingPath");
    }

    @Test
    @DisplayName("Une propriété valide ailleurs est refusée sur un événement qui ne l'admet pas")
    void proprieteValideMaisPasIci() {
        assertThatThrownBy(() -> normalizer.properties(AnalyticsEvent.PRICING_VIEWED,
                Map.of("ctaLocation", "HERO")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("ctaLocation")
                .hasMessageContaining("PRICING_VIEWED");
    }

    @Test
    @DisplayName("Une valeur d'énumération inconnue est refusée")
    void valeurEnumInconnue() {
        assertThatThrownBy(() -> normalizer.properties(AnalyticsEvent.DIAGNOSTIC_CTA_CLICKED,
                Map.of("ctaLocation", "PARTOUT")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("ctaLocation");
    }

    @Test
    @DisplayName("Un chemin hors allowlist est refusé ; un chemin absent est un cas normal")
    void chemins() {
        assertThatThrownBy(() -> normalizer.path("/reussir/f47ac10b-58cc-4372-a567-0e02b2c3d479"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("path");
        assertThat(normalizer.path(null)).isNull();
        assertThat(normalizer.path("/reussir")).isEqualTo("/reussir");
    }

    @Test
    @DisplayName("Une clé de dédoublonnage n'est pas du texte libre")
    void dedupKeyBornee() {
        assertThatThrownBy(() -> normalizer.dedupKey("clé avec espaces et accents"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("dedupKey");
        assertThat(normalizer.dedupKey("landing:2026-08-21:abc")).isEqualTo("landing:2026-08-21:abc");
        assertThat(normalizer.dedupKey(null)).isNull();
    }

    // ------------------------------------------------------------------------
    // Propriétés
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Les valeurs d'énumération sont normalisées et les clés triées")
    void proprietesNormaliseesEtTriees() {
        String json = normalizer.toJson(normalizer.properties(AnalyticsEvent.DIAGNOSTIC_CTA_CLICKED,
                Map.of("diagnosticType", "rapid", "ctaLocation", "hero")));
        assertThat(json).isEqualTo("{\"ctaLocation\":\"HERO\",\"diagnosticType\":\"RAPID\"}");
        assertThat(normalizer.toJson(normalizer.properties(AnalyticsEvent.LOGIN_CLICKED, null)))
                .isEqualTo("{}");
    }

    @Test
    @DisplayName("Une propriété sans valeur est ignorée, pas refusée")
    void proprieteVideIgnoree() {
        Map<String, String> properties = new HashMap<>();
        properties.put("ctaLocation", "HERO");
        properties.put("diagnosticType", "  ");
        assertThat(normalizer.toJson(normalizer.properties(AnalyticsEvent.DIAGNOSTIC_CTA_CLICKED, properties)))
                .isEqualTo("{\"ctaLocation\":\"HERO\"}");
    }

    // ------------------------------------------------------------------------
    // Attribution
    // ------------------------------------------------------------------------

    /**
     * Sans ce garde-fou, la deuxieme page vue d'un visiteur venu de TikTok
     * ramenerait son last touch a « direct », et « quelle source a precede
     * l'achat » repondrait « direct » pour tout le monde.
     */
    @Test
    @DisplayName("Une source n'est explicite que déclarée : bloc d'attribution ou en-tête de provenance")
    void sourceExplicite() {
        assertThat(normalizer.sourceExplicite(null, WEB_DIRECT)).isFalse();
        assertThat(normalizer.sourceExplicite(null, new ClientContext(ClientPlatform.WEB, "tiktok"))).isTrue();
        assertThat(normalizer.sourceExplicite(firstTouch("TikTok", null, null, null), WEB_DIRECT)).isTrue();
    }

    @Test
    @DisplayName("Un bloc d'attribution normalise la provenance et ne garde que l'hôte du referrer")
    void blocAttribution() {
        AnalyticsVisitorManager.Attribution attribution = normalizer.attribution(
                firstTouch("TikTok", "campagne-aout", "video-12",
                        "https://www.tiktok.com/@sejourfr/video/123?x=1"),
                WEB_DIRECT, "/reussir");
        assertThat(attribution.source()).isEqualTo("tiktok");
        assertThat(attribution.content()).isEqualTo("video-12");
        // 🛑 L'HÔTE SEUL : une URL de referrer peut porter un identifiant ou un
        // terme de recherche, et n'a rien à faire dans une mesure d'audience.
        assertThat(attribution.referrerHost()).isEqualTo("www.tiktok.com");
    }

    @Test
    @DisplayName("Une provenance inconnue retombe dans « autre », jamais dans une dimension neuve")
    void provenanceInconnueRangeeDansAutre() {
        assertThat(normalizer.attribution(firstTouch("un-reseau-invente", null, null, null), WEB_DIRECT, null)
                .source()).isEqualTo(TrafficSource.OTHER);
    }

    /**
     * Un nom de campagne est ecrit par un outil marketing sur lequel nous
     * n'avons aucun pouvoir : la longueur est une borne de STOCKAGE, pas une
     * regle metier.
     */
    @Test
    @DisplayName("Une UTM trop longue est tronquée, pas rejetée")
    void utmTropLongueTronquee() {
        assertThat(normalizer.attribution(firstTouch("tiktok", "c".repeat(300), null, null), WEB_DIRECT, null)
                .campaign()).hasSize(120);
    }

    @Test
    @DisplayName("Un referrer illisible est oublié, il n'empêche pas la mesure")
    void referrerIllisibleOublie() {
        assertThat(normalizer.attribution(firstTouch("tiktok", null, null, "??? pas un hôte"), WEB_DIRECT, null)
                .referrerHost()).isNull();
    }
}
