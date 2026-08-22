package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AnalyticsEventRequest;
import com.sejourfr.app.dto.AnalyticsFirstTouchRequest;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.TrafficSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * L'ingestion vue du cote « ce qui est refuse ». L'endpoint est public : tout ce
 * qui n'est pas verrouille ici est verrouille nulle part.
 */
class AnalyticsIngestionServiceTest {

    private static final UUID VISITEUR = UUID.randomUUID();
    private static final UUID SESSION = UUID.randomUUID();
    private static final ClientContext WEB_DIRECT =
            new ClientContext(ClientPlatform.WEB, TrafficSource.DIRECT);

    private AnalyticsVisitorManager visitorManager;
    private AnalyticsEventManager eventManager;
    private AnalyticsIngestionService service;

    @BeforeEach
    void setUp() {
        visitorManager = mock(AnalyticsVisitorManager.class);
        eventManager = mock(AnalyticsEventManager.class);
        service = new AnalyticsIngestionService(visitorManager, eventManager);
        when(eventManager.record(any(), any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(true);
    }

    private AnalyticsEventRequest requete(AnalyticsEvent event, String path,
                                          Map<String, String> properties) {
        return new AnalyticsEventRequest(VISITEUR, SESSION, event, path, null, properties, null, null);
    }

    private boolean track(AnalyticsEventRequest request) {
        return service.track(request, WEB_DIRECT, "FR", AnalyticsDeviceType.DESKTOP_WEB, null);
    }

    // ------------------------------------------------------------------------
    // Chemin nominal
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Un événement valide touche le visiteur PUIS écrit le geste")
    void cheminNominal() {
        boolean ecrit = track(requete(AnalyticsEvent.DIAGNOSTIC_CTA_CLICKED, "/reussir",
                Map.of("ctaLocation", "hero", "diagnosticType", "rapid")));

        assertThat(ecrit).isTrue();
        verify(visitorManager).touch(eq(VISITEUR), any(), any(), anyBoolean(), eq("FR"),
                eq(AnalyticsDeviceType.DESKTOP_WEB), eq(ClientPlatform.WEB));

        ArgumentCaptor<String> json = ArgumentCaptor.forClass(String.class);
        verify(eventManager).record(eq(AnalyticsEvent.DIAGNOSTIC_CTA_CLICKED), any(), eq(VISITEUR),
                eq(SESSION), isNull(), eq("/reussir"), json.capture(), isNull());
        // Clés triées : deux lignes du même événement sont comparables à l'œil.
        assertThat(json.getValue())
                .isEqualTo("{\"ctaLocation\":\"HERO\",\"diagnosticType\":\"RAPID\"}");
    }

    @Test
    @DisplayName("Un rejeu dédoublonné n'écrit rien et ne lève pas")
    void rejeuDedoublonne() {
        when(eventManager.record(any(), any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(false);
        assertThat(track(requete(AnalyticsEvent.PRICING_VIEWED, "/tarifs", null))).isFalse();
    }

    // ------------------------------------------------------------------------
    // Ce qui est refusé
    // ------------------------------------------------------------------------

    /**
     * Venant d'un client, {@code CHECKOUT_STARTED} serait une INTENTION et non un
     * fait : la derniere marche de l'entonnoir ne voudrait plus rien dire.
     */
    @Test
    @DisplayName("Un événement posé par le serveur est refusé au client, et rien n'est écrit")
    void evenementServeurRefuse() {
        assertThatThrownBy(() -> track(requete(AnalyticsEvent.CHECKOUT_STARTED, "/paiement",
                Map.of("planCode", "INTEGRAL_PASS_2M"))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("CHECKOUT_STARTED")
                .hasMessageContaining("posé par le serveur");
        verify(visitorManager, never()).touch(any(), any(), any(), anyBoolean(), any(), any(), any());
        verify(eventManager, never()).record(any(), any(), any(), any(), any(), any(), any(), any());
    }

    /**
     * 🛑 Le test qui rend le §95 du brief vrai par construction : aucune clé hors
     * allowlist n'entre, donc aucun mot de passe, aucune production, aucun jeton.
     */
    @Test
    @DisplayName("Une propriété hors allowlist est refusée en nommant ce qui était accepté")
    void proprieteHorsAllowlist() {
        assertThatThrownBy(() -> track(requete(AnalyticsEvent.LANDING_VIEWED, "/reussir",
                Map.of("email", "candidat@exemple.fr"))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("email")
                .hasMessageContaining("LANDING_VIEWED")
                .hasMessageContaining("landingPath");
        verify(eventManager, never()).record(any(), any(), any(), any(), any(), any(), any(), any());
    }

    /**
     * La cle existe, mais pas sur CET evenement : sans ce contrôle, un front
     * pourrait deposer n'importe quelle propriete du registre n'importe ou.
     */
    @Test
    @DisplayName("Une propriété valide ailleurs est refusée sur un événement qui ne l'admet pas")
    void proprieteValideMaisPasIci() {
        assertThatThrownBy(() -> track(requete(AnalyticsEvent.PRICING_VIEWED, "/tarifs",
                Map.of("ctaLocation", "HERO"))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("ctaLocation")
                .hasMessageContaining("PRICING_VIEWED");
    }

    @Test
    @DisplayName("Une valeur d'énumération inconnue est refusée")
    void valeurEnumInconnue() {
        assertThatThrownBy(() -> track(requete(AnalyticsEvent.DIAGNOSTIC_CTA_CLICKED, "/reussir",
                Map.of("ctaLocation", "PARTOUT"))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("ctaLocation");
    }

    @Test
    @DisplayName("Un chemin hors allowlist est refusé")
    void cheminHorsAllowlist() {
        assertThatThrownBy(() -> track(requete(AnalyticsEvent.LANDING_VIEWED,
                "/reussir/f47ac10b-58cc-4372-a567-0e02b2c3d479", null)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("path");
    }

    /**
     * Sans cette borne, l'endpoint public permet de reecrire le mois dernier :
     * on ne mesure plus rien, on enregistre ce qu'on nous raconte.
     */
    @Test
    @DisplayName("Une horodate à plus de 24 h de l'heure serveur est refusée, dans les deux sens")
    void horodateHorsFenetre() {
        for (Instant declaree : new Instant[]{
                Instant.now().minus(Duration.ofHours(25)),
                Instant.now().plus(Duration.ofHours(25))}) {
            AnalyticsEventRequest request = new AnalyticsEventRequest(
                    VISITEUR, SESSION, AnalyticsEvent.LANDING_VIEWED, "/reussir",
                    declaree, null, null, null);
            assertThatThrownBy(() -> track(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("occurredAt");
        }
    }

    @Test
    @DisplayName("Une horodate dans la fenêtre est conservée telle quelle")
    void horodateAcceptee() {
        Instant declaree = Instant.now().minus(Duration.ofHours(3));
        track(new AnalyticsEventRequest(VISITEUR, SESSION, AnalyticsEvent.LANDING_VIEWED,
                "/reussir", declaree, null, null, null));
        verify(eventManager).record(any(), eq(declaree), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Une clé de dédoublonnage n'est pas du texte libre")
    void dedupKeyBornee() {
        AnalyticsEventRequest fautif = new AnalyticsEventRequest(
                VISITEUR, SESSION, AnalyticsEvent.LANDING_VIEWED, "/reussir", null, null, null,
                "clé avec espaces et accents");
        assertThatThrownBy(() -> track(fautif))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("dedupKey");

        track(new AnalyticsEventRequest(VISITEUR, SESSION, AnalyticsEvent.LANDING_VIEWED,
                "/reussir", null, null, null, "landing:2026-08-21:abc"));
        verify(eventManager).record(any(), any(), any(), any(), any(), any(), any(),
                eq("landing:2026-08-21:abc"));
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
    @DisplayName("Sans source déclarée, le last touch n'est PAS réécrit")
    void sourceNonExpliciteNeReecritPasLeLastTouch() {
        track(requete(AnalyticsEvent.LANDING_VIEWED, "/reussir", null));
        verify(visitorManager).touch(any(), any(), any(), eq(false), any(), any(), any());
    }

    @Test
    @DisplayName("Une provenance déclarée en en-tête rend la source explicite")
    void enTeteDeProvenanceEstExplicite() {
        service.track(requete(AnalyticsEvent.LANDING_VIEWED, "/reussir", null),
                new ClientContext(ClientPlatform.WEB, "tiktok"), "FR",
                AnalyticsDeviceType.MOBILE_WEB, null);
        verify(visitorManager).touch(any(), any(), any(), eq(true), any(), any(), any());
    }

    @Test
    @DisplayName("Un bloc d'attribution rend la source explicite et normalise la provenance")
    void blocAttributionExplicite() {
        AnalyticsEventRequest request = new AnalyticsEventRequest(
                VISITEUR, SESSION, AnalyticsEvent.LANDING_VIEWED, "/reussir", null, null,
                new AnalyticsFirstTouchRequest("TikTok", "cpc", "campagne-aout", "video-12",
                        null, "/reussir", "https://www.tiktok.com/@sejourfr/video/123?x=1"),
                null);
        track(request);

        ArgumentCaptor<AnalyticsVisitorManager.Attribution> captor =
                ArgumentCaptor.forClass(AnalyticsVisitorManager.Attribution.class);
        verify(visitorManager).touch(any(), any(), captor.capture(), eq(true), any(), any(), any());

        AnalyticsVisitorManager.Attribution attribution = captor.getValue();
        assertThat(attribution.source()).isEqualTo("tiktok");
        assertThat(attribution.content()).isEqualTo("video-12");
        // 🛑 L'HÔTE SEUL : une URL de referrer peut porter un identifiant ou un
        // terme de recherche, et n'a rien à faire dans une mesure d'audience.
        assertThat(attribution.referrerHost()).isEqualTo("www.tiktok.com");
    }

    @Test
    @DisplayName("Une provenance inconnue retombe dans « autre », jamais dans une dimension neuve")
    void provenanceInconnueRangeeDansAutre() {
        AnalyticsEventRequest request = new AnalyticsEventRequest(
                VISITEUR, SESSION, AnalyticsEvent.LANDING_VIEWED, "/reussir", null, null,
                new AnalyticsFirstTouchRequest("un-reseau-invente", null, null, null, null, null, null),
                null);
        track(request);
        ArgumentCaptor<AnalyticsVisitorManager.Attribution> captor =
                ArgumentCaptor.forClass(AnalyticsVisitorManager.Attribution.class);
        verify(visitorManager).touch(any(), any(), captor.capture(), anyBoolean(), any(), any(), any());
        assertThat(captor.getValue().source()).isEqualTo(TrafficSource.OTHER);
    }

    /**
     * Un nom de campagne est ecrit par un outil marketing sur lequel nous
     * n'avons aucun pouvoir. Perdre l'evenement entier parce qu'il fait 130
     * caracteres serait un mauvais echange : la longueur est une borne de
     * STOCKAGE, pas une regle metier.
     */
    @Test
    @DisplayName("Une UTM trop longue est tronquée, pas rejetée")
    void utmTropLongueTronquee() {
        AnalyticsEventRequest request = new AnalyticsEventRequest(
                VISITEUR, SESSION, AnalyticsEvent.LANDING_VIEWED, "/reussir", null, null,
                new AnalyticsFirstTouchRequest("tiktok", null, "c".repeat(300), null, null, null, null),
                null);
        track(request);
        ArgumentCaptor<AnalyticsVisitorManager.Attribution> captor =
                ArgumentCaptor.forClass(AnalyticsVisitorManager.Attribution.class);
        verify(visitorManager).touch(any(), any(), captor.capture(), anyBoolean(), any(), any(), any());
        assertThat(captor.getValue().campaign()).hasSize(120);
    }

    @Test
    @DisplayName("Un referrer illisible est oublié, il n'empêche pas la mesure")
    void referrerIllisibleOublie() {
        AnalyticsEventRequest request = new AnalyticsEventRequest(
                VISITEUR, SESSION, AnalyticsEvent.LANDING_VIEWED, "/reussir", null, null,
                new AnalyticsFirstTouchRequest("tiktok", null, null, null, null, null, "??? pas un hôte"),
                null);
        track(request);
        ArgumentCaptor<AnalyticsVisitorManager.Attribution> captor =
                ArgumentCaptor.forClass(AnalyticsVisitorManager.Attribution.class);
        verify(visitorManager).touch(any(), any(), captor.capture(), anyBoolean(), any(), any(), any());
        assertThat(captor.getValue().referrerHost()).isNull();
    }

    @Test
    @DisplayName("Une propriété sans valeur est ignorée, pas refusée")
    void proprieteVideIgnoree() {
        java.util.Map<String, String> properties = new java.util.HashMap<>();
        properties.put("ctaLocation", "HERO");
        properties.put("diagnosticType", "  ");
        track(requete(AnalyticsEvent.DIAGNOSTIC_CTA_CLICKED, "/reussir", properties));
        verify(eventManager).record(any(), any(), any(), any(), any(), any(),
                eq("{\"ctaLocation\":\"HERO\"}"), any());
    }

    @Test
    @DisplayName("Le compte est posé à l'écriture quand le visiteur est déjà connu")
    void compteConnuPoseALEcriture() {
        UUID userId = UUID.randomUUID();
        service.track(requete(AnalyticsEvent.PRICING_VIEWED, "/tarifs", null),
                WEB_DIRECT, "FR", AnalyticsDeviceType.DESKTOP_WEB, userId);
        verify(eventManager).record(any(), any(), any(), any(), eq(userId), any(), any(), any());
    }

    @Test
    @DisplayName("Un chemin absent est un cas normal")
    void cheminAbsent() {
        track(requete(AnalyticsEvent.LOGIN_CLICKED, null, null));
        verify(eventManager).record(any(), any(), any(), any(), isNull(), isNull(), eq("{}"),
                isNull());
    }

    @Test
    @DisplayName("Un contexte client absent ne fait pas échouer la mesure")
    void contexteAbsentTolere() {
        service.track(requete(AnalyticsEvent.LANDING_VIEWED, "/reussir", null), null, null,
                AnalyticsDeviceType.UNKNOWN, null);
        verify(visitorManager).touch(any(), any(), any(), eq(false), isNull(),
                eq(AnalyticsDeviceType.UNKNOWN), eq(ClientPlatform.UNKNOWN));
    }
}
