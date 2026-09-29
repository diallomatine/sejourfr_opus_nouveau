package com.sejourfr.app.controller;

import com.sejourfr.app.entity.AnalyticsVisitor;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.util.ClientContextResolver;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * L'ingestion de bout en bout, contre la vraie base (migrations Flyway
 * appliquees) : les contraintes, les index et les deux invariants
 * d'attribution sont ceux de la production.
 */
class PublicAnalyticsControllerIT extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private AnalyticsVisitorManager visitorManager;
    @Autowired
    private AnalyticsEventManager eventManager;

    private static final String UA_IPHONE =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 "
                    + "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

    private void envoyer(String body, String source) throws Exception {
        mockMvc.perform(post("/api/public/analytics/events")
                        .header(HttpHeaders.USER_AGENT, UA_IPHONE)
                        .header(ClientContextResolver.HEADER_CLIENT, "web")
                        .header(ClientContextResolver.HEADER_SOURCE, source)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isNoContent());
    }

    @Test
    @DisplayName("Un événement crée le visiteur et son geste, et répond 204")
    void ingestionNominale() throws Exception {
        UUID anonymousId = UUID.randomUUID();
        envoyer("""
                {"anonymousId":"%s","sessionId":"%s","event":"DIAGNOSTIC_CTA_CLICKED",
                 "path":"/reussir",
                 "properties":{"ctaLocation":"HERO","diagnosticType":"RAPID"},
                 "firstTouch":{"source":"tiktok","medium":"cpc","campaign":"aout",
                               "content":"video-12","landingPath":"/reussir",
                               "referrerHost":"www.tiktok.com"}}
                """.formatted(anonymousId, UUID.randomUUID()), "tiktok");

        AnalyticsVisitor visiteur = visitorManager.findById(anonymousId).orElseThrow();
        assertThat(visiteur.getFirstTouchSource()).isEqualTo("tiktok");
        assertThat(visiteur.getFirstTouchContent()).isEqualTo("video-12");
        assertThat(visiteur.getFirstTouchReferrerHost()).isEqualTo("www.tiktok.com");
        assertThat(visiteur.getPlatform()).isEqualTo(ClientPlatform.WEB);
        // Le type d'appareil est déduit SERVEUR du user-agent : le client ne
        // l'envoie jamais, et le user-agent lui-même n'est pas conservé.
        assertThat(visiteur.getDeviceType()).isEqualTo(AnalyticsDeviceType.MOBILE_WEB);
        assertThat(eventManager.countForVisitor(anonymousId)).isEqualTo(1);
    }

    /**
     * 🛑 L'invariant qui fait toute la valeur de la table. Un visiteur revenu par
     * un autre canal reste attribue a celui qui l'a AMENE ; sinon on perd
     * exactement la reponse qu'on cherche (« d'ou viennent mes utilisateurs ? »).
     */
    @Test
    @DisplayName("Le first touch n'est JAMAIS réécrit, même si le client le renvoie")
    void firstTouchJamaisReecrit() throws Exception {
        UUID anonymousId = UUID.randomUUID();
        String session = UUID.randomUUID().toString();

        envoyer("""
                {"anonymousId":"%s","sessionId":"%s","event":"LANDING_VIEWED","path":"/reussir",
                 "firstTouch":{"source":"tiktok","campaign":"aout","content":"video-12"}}
                """.formatted(anonymousId, session), "tiktok");

        envoyer("""
                {"anonymousId":"%s","sessionId":"%s","event":"LANDING_VIEWED","path":"/reussir",
                 "firstTouch":{"source":"google","campaign":"sea","content":"annonce-3"}}
                """.formatted(anonymousId, session), "google");

        AnalyticsVisitor visiteur = visitorManager.findById(anonymousId).orElseThrow();
        assertThat(visiteur.getFirstTouchSource()).isEqualTo("tiktok");
        assertThat(visiteur.getFirstTouchCampaign()).isEqualTo("aout");
        assertThat(visiteur.getFirstTouchContent()).isEqualTo("video-12");
        // Le last touch, lui, suit la nouvelle source explicite. « google » n'est
        // pas dans l'allowlist des provenances : il retombe donc sur « autre »,
        // ce qui est le comportement voulu — on borne la cardinalité.
        assertThat(visiteur.getLastTouchSource()).isNotEqualTo("tiktok");
        assertThat(visiteur.getLastTouchCampaign()).isEqualTo("sea");
    }

    /**
     * Sans ce garde-fou, la deuxieme page vue d'un visiteur venu de TikTok
     * ramenerait son last touch a « direct ».
     */
    @Test
    @DisplayName("Une navigation ordinaire ne réécrit pas le last touch")
    void navigationOrdinaireNeToucheRienAuLastTouch() throws Exception {
        UUID anonymousId = UUID.randomUUID();
        String session = UUID.randomUUID().toString();

        envoyer("""
                {"anonymousId":"%s","sessionId":"%s","event":"LANDING_VIEWED","path":"/reussir",
                 "firstTouch":{"source":"tiktok","campaign":"aout"}}
                """.formatted(anonymousId, session), "tiktok");

        // Page suivante : aucune provenance déclarée (l'en-tête retombe sur
        // « direct », qui est un repli, pas une observation).
        mockMvc.perform(post("/api/public/analytics/events")
                        .header(HttpHeaders.USER_AGENT, UA_IPHONE)
                        .header(ClientContextResolver.HEADER_CLIENT, "web")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"anonymousId":"%s","sessionId":"%s","event":"PRICING_VIEWED",
                                 "path":"/tarifs"}
                                """.formatted(anonymousId, session)))
                .andExpect(status().isNoContent());

        AnalyticsVisitor visiteur = visitorManager.findById(anonymousId).orElseThrow();
        assertThat(visiteur.getLastTouchSource()).isEqualTo("tiktok");
        assertThat(visiteur.getLastTouchCampaign()).isEqualTo("aout");
        assertThat(eventManager.countForVisitor(anonymousId)).isEqualTo(2);
    }

    @Test
    @DisplayName("Une clé de dédoublonnage rejouée n'écrit rien de plus, et répond 204")
    void dedoublonnage() throws Exception {
        UUID anonymousId = UUID.randomUUID();
        String session = UUID.randomUUID().toString();
        String cle = "landing:" + anonymousId;
        String body = """
                {"anonymousId":"%s","sessionId":"%s","event":"LANDING_VIEWED","path":"/reussir",
                 "dedupKey":"%s"}
                """.formatted(anonymousId, session, cle);

        for (int i = 0; i < 3; i++) {
            envoyer(body, "tiktok");
        }
        assertThat(eventManager.countForVisitor(anonymousId)).isEqualTo(1);
    }

    @Test
    @DisplayName("Une propriété hors allowlist est refusée en 400 nommé, et rien n'est écrit")
    void proprieteHorsAllowlistRefusee() throws Exception {
        UUID anonymousId = UUID.randomUUID();
        mockMvc.perform(post("/api/public/analytics/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"anonymousId":"%s","sessionId":"%s","event":"LANDING_VIEWED",
                                 "path":"/reussir","properties":{"email":"a@b.fr"}}
                                """.formatted(anonymousId, UUID.randomUUID())))
                .andExpect(status().isBadRequest());
        assertThat(visitorManager.findById(anonymousId)).isEmpty();
    }

    @Test
    @DisplayName("Un événement inconnu est refusé en 400 par la désérialisation, en le nommant")
    void evenementInconnuRefuse() throws Exception {
        mockMvc.perform(post("/api/public/analytics/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"anonymousId":"%s","sessionId":"%s","event":"PAYMENT_SUCCEEDED"}
                                """.formatted(UUID.randomUUID(), UUID.randomUUID())))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Un événement posé par le serveur est refusé à un client")
    void evenementServeurRefuse() throws Exception {
        mockMvc.perform(post("/api/public/analytics/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"anonymousId":"%s","sessionId":"%s","event":"CHECKOUT_STARTED",
                                 "path":"/paiement"}
                                """.formatted(UUID.randomUUID(), UUID.randomUUID())))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Un anonymousId qui n'est pas un UUID est refusé, jamais accepté en silence")
    void anonymousIdInvalide() throws Exception {
        mockMvc.perform(post("/api/public/analytics/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"anonymousId":"pas-un-uuid","sessionId":"%s",
                                 "event":"LANDING_VIEWED"}
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isBadRequest());
    }
}
