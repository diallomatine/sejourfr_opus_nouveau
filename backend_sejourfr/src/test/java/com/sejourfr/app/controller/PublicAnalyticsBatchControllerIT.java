package com.sejourfr.app.controller;

import com.sejourfr.app.entity.AnalyticsEventRecord;
import com.sejourfr.app.entity.AnalyticsVisitor;
import com.sejourfr.app.entity.DiagnosticRun;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.AnalyticsIdentityManager;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.ClientContextResolver;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * L'ingestion EN LOT de bout en bout, contre la vraie base (V074 appliquee) :
 * dedoublonnage, allowlist, rejet individuel, horloge, contextes resolus
 * serveur, exclusion interne resolue a l'ingestion.
 */
class PublicAnalyticsBatchControllerIT extends AbstractIntegrationTest {

    private static final String URL = "/api/public/analytics/events/batch";

    @Autowired private MockMvc mockMvc;
    @Autowired private AnalyticsEventManager eventManager;
    @Autowired private AnalyticsVisitorManager visitorManager;
    @Autowired private AnalyticsIdentityManager identityManager;
    @Autowired private DiagnosticRunManager diagnosticRunManager;
    @Autowired private TestData testData;
    @Autowired private AuthTestSupport auth;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;

    // ------------------------------------------------------------------------

    /** Un evenement du lot, en JSON. {@code null} = champ absent. */
    private static String evt(String eventId, String event, String extra) {
        StringBuilder sb = new StringBuilder("{");
        if (eventId != null) sb.append("\"eventId\":\"").append(eventId).append("\",");
        sb.append("\"event\":\"").append(event).append("\"");
        if (extra != null && !extra.isBlank()) sb.append(",").append(extra);
        return sb.append("}").toString();
    }

    private static String lot(UUID anonymousId, String enveloppe, String... events) {
        return "{\"anonymousId\":\"" + anonymousId + "\",\"sessionId\":\"" + UUID.randomUUID() + "\""
                + (enveloppe == null ? "" : "," + enveloppe)
                + ",\"events\":[" + String.join(",", events) + "]}";
    }

    private ResultActions envoyer(String body, String client) throws Exception {
        MockHttpServletRequestBuilder req = post(URL).contentType(MediaType.APPLICATION_JSON).content(body);
        if (client != null) req.header(ClientContextResolver.HEADER_CLIENT, client);
        return mockMvc.perform(req);
    }

    private AnalyticsEventRecord ligne(String eventId) {
        return eventManager.findByEventId(UUID.fromString(eventId)).orElseThrow();
    }

    private DiagnosticRun run(DiagnosticRunType type) {
        DiagnosticRun run = new DiagnosticRun();
        run.setId(UUID.randomUUID());
        run.setDiagnosticType(type);
        run.setSubjectViewedAt(Instant.now());
        run.setUpdatedAt(Instant.now());
        DiagnosticRun saved = diagnosticRunManager.save(run);
        em.flush();
        return saved;
    }

    private static String id() {
        return UUID.randomUUID().toString();
    }

    // ------------------------------------------------------------------------
    // Nominal
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Contrôle N7 — le même lot en text/plain (sendBeacon) répond 202 et s'écrit pareil")
    void lotEnTextPlain() throws Exception {
        UUID anon = UUID.randomUUID();
        String e1 = id();
        mockMvc.perform(post(URL).contentType(MediaType.TEXT_PLAIN)
                        .content(lot(anon, "\"client\":\"web\",\"appVersion\":\"0.1.0\"",
                                evt(e1, "LANDING_VIEWED", "\"path\":\"/reussir\""))))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.accepted").value(1));

        AnalyticsEventRecord ligne = ligne(e1);
        assertThat(ligne.getAnonymousId()).isEqualTo(anon);
        assertThat(ligne.getPlatform()).isEqualTo(ClientPlatform.WEB);
    }

    @Test
    @DisplayName("Contrôle N7 — text/plain illisible ou enveloppe invalide : 400, comme en JSON")
    void lotEnTextPlainInvalide() throws Exception {
        mockMvc.perform(post(URL).contentType(MediaType.TEXT_PLAIN).content("pas du json"))
                .andExpect(status().isBadRequest());
        // Enveloppe sans evenements : la meme validation @Valid qu'en JSON.
        mockMvc.perform(post(URL).contentType(MediaType.TEXT_PLAIN)
                        .content("{\"anonymousId\":\"" + UUID.randomUUID() + "\",\"events\":[]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Un lot valide répond 202, écrit chaque événement avec les colonnes V074")
    void lotNominal() throws Exception {
        UUID anon = UUID.randomUUID();
        String e1 = id();
        String e2 = id();
        mockMvc.perform(post(URL).contentType(MediaType.APPLICATION_JSON)
                        .header(ClientContextResolver.HEADER_CLIENT, "ios")
                        .header(ClientContextResolver.HEADER_APP_VERSION, "2.4.1+57")
                        .header(HttpHeaders.USER_AGENT, "Dart/3.6 (dart:io)")
                        .content(lot(anon, null,
                                evt(e1, "LANDING_VIEWED", "\"path\":\"/reussir\""),
                                evt(e2, "PRICING_VIEWED", "\"path\":\"/tarifs\""))))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.received").value(2))
                .andExpect(jsonPath("$.accepted").value(2))
                .andExpect(jsonPath("$.duplicates").value(0))
                .andExpect(jsonPath("$.rejected").isEmpty());

        AnalyticsEventRecord ligne = ligne(e1);
        assertThat(ligne.getAnonymousId()).isEqualTo(anon);
        assertThat(ligne.getReceivedAt()).isNotNull();
        assertThat(ligne.getPlatform()).isEqualTo(ClientPlatform.IOS);
        assertThat(ligne.getAppVersion()).isEqualTo("2.4.1+57");
        assertThat(ligne.getInternal()).isFalse();
        assertThat(ligne.getUserId()).isNull();

        AnalyticsVisitor visiteur = visitorManager.findById(anon).orElseThrow();
        assertThat(visiteur.getPlatform()).isEqualTo(ClientPlatform.IOS);
        // iOS DECLARE : le type d'appareil ne depend plus du user-agent.
        assertThat(visiteur.getDeviceType()).isEqualTo(AnalyticsDeviceType.IOS);
    }

    /** Scenario 10 : le meme lot mobile envoye deux fois ne cree aucun doublon. */
    @Test
    @DisplayName("Scénario 10 — un lot rejoué n'écrit rien de plus et répond des doublons")
    void lotRejoue() throws Exception {
        UUID anon = UUID.randomUUID();
        String body = lot(anon, null,
                evt(id(), "LANDING_VIEWED", "\"path\":\"/reussir\""),
                evt(id(), "PRICING_VIEWED", "\"path\":\"/tarifs\""));

        envoyer(body, "android").andExpect(status().isAccepted()).andExpect(jsonPath("$.accepted").value(2));
        envoyer(body, "android").andExpect(status().isAccepted())
                .andExpect(jsonPath("$.accepted").value(0))
                .andExpect(jsonPath("$.duplicates").value(2));

        assertThat(eventManager.countForVisitor(anon)).isEqualTo(2);
    }

    @Test
    @DisplayName("Le même eventId deux fois dans un lot : une ligne, un doublon")
    void doublonDansLeLot() throws Exception {
        UUID anon = UUID.randomUUID();
        String e = id();
        envoyer(lot(anon, null, evt(e, "PRICING_VIEWED", null), evt(e, "PRICING_VIEWED", null)), "web")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.accepted").value(1))
                .andExpect(jsonPath("$.duplicates").value(1));
        assertThat(eventManager.countForVisitor(anon)).isEqualTo(1);
    }

    // ------------------------------------------------------------------------
    // Rejet individuel
    // ------------------------------------------------------------------------

    /**
     * 🛑 Une file mobile ne doit jamais rester bloquee sur un evenement mal
     * forme : il est rejete SEUL, avec son motif, et le reste est ecrit.
     */
    @Test
    @DisplayName("Rejet partiel — chaque événement invalide est rejeté seul, le reste est écrit")
    void rejetPartiel() throws Exception {
        UUID anon = UUID.randomUUID();
        String valide = id();
        envoyer(lot(anon, null,
                        evt(valide, "DIAGNOSTIC_CTA_CLICKED",
                                "\"path\":\"/reussir\",\"properties\":{\"ctaLocation\":\"hero\"}"),
                        evt(id(), "EVENEMENT_INVENTE", null),
                        evt(id(), "LANDING_VIEWED", "\"properties\":{\"email\":\"a@b.fr\"}"),
                        evt(null, "PRICING_VIEWED", null),
                        evt(id(), "CHECKOUT_STARTED", null),
                        evt(id(), "LANDING_VIEWED", "\"path\":\"/admin/secret\""),
                        evt("pas-un-uuid", "PRICING_VIEWED", null)),
                "web")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.received").value(7))
                .andExpect(jsonPath("$.accepted").value(1))
                .andExpect(jsonPath("$.rejected.length()").value(6))
                .andExpect(jsonPath("$.rejected[0].index").value(1))
                .andExpect(jsonPath("$.rejected[0].reason", containsString("event")))
                .andExpect(jsonPath("$.rejected[1].reason", containsString("email")))
                .andExpect(jsonPath("$.rejected[2].reason", containsString("eventId")))
                .andExpect(jsonPath("$.rejected[3].reason", containsString("posé par le serveur")))
                .andExpect(jsonPath("$.rejected[4].reason", containsString("path")))
                .andExpect(jsonPath("$.rejected[5].eventId").value("pas-un-uuid"));

        assertThat(eventManager.countForVisitor(anon)).isEqualTo(1);
        assertThat(ligne(valide).getProperties()).containsEntry("ctaLocation", "HERO");
    }

    @Test
    @DisplayName("Un lot entièrement rejeté n'écrit aucun événement, mais garde le visiteur et son first touch")
    void lotEntierementRejete() throws Exception {
        UUID anon = UUID.randomUUID();
        envoyer(lot(anon, "\"firstTouch\":{\"source\":\"tiktok\"}", evt(id(), "INCONNU", null)), "web")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.accepted").value(0));
        assertThat(eventManager.countForVisitor(anon)).isZero();
        assertThat(visitorManager.findById(anon).orElseThrow().getFirstTouchSource()).isEqualTo("tiktok");

        // Le lot suivant ne reecrit pas ce first touch.
        envoyer(lot(anon, "\"firstTouch\":{\"source\":\"instagram\"}",
                evt(id(), "LANDING_VIEWED", "\"path\":\"/reussir\"")), "web")
                .andExpect(status().isAccepted());
        assertThat(visitorManager.findById(anon).orElseThrow().getFirstTouchSource()).isEqualTo("tiktok");
    }

    @Test
    @DisplayName("Une page d'arrivée hors allowlist devient inconnue (null) : le lot est accepté")
    void landingPathInconnu() throws Exception {
        UUID anon = UUID.randomUUID();
        envoyer(lot(anon, "\"firstTouch\":{\"source\":\"tiktok\",\"landingPath\":\"/pas-suivie\","
                        + "\"referrerHost\":\"%%%\"}",
                evt(id(), "LANDING_VIEWED", "\"path\":\"/reussir\"")), "web")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.accepted").value(1));
        Map<String, Object> v = jdbc.queryForMap(
                "SELECT ft_source, ft_landing_path, ft_referrer_host FROM analytics_visitor WHERE anonymous_id = ?",
                anon);
        assertThat(v.get("ft_source")).isEqualTo("tiktok");
        assertThat(v.get("ft_landing_path")).isNull();
        assertThat(v.get("ft_referrer_host")).isNull();
    }

    @Test
    @DisplayName("Un lot au-delà de la taille maximale est refusé en entier (400)")
    void lotTropGros() throws Exception {
        UUID anon = UUID.randomUUID();
        List<String> events = new ArrayList<>();
        for (int i = 0; i < 51; i++) events.add(evt(id(), "PRICING_VIEWED", null));
        envoyer(lot(anon, null, events.toArray(String[]::new)), "web")
                .andExpect(status().isBadRequest());
        assertThat(eventManager.countForVisitor(anon)).isZero();
    }

    @Test
    @DisplayName("Une enveloppe sans anonymousId est refusée en entier (400)")
    void enveloppeInvalide() throws Exception {
        envoyer("{\"sessionId\":\"" + UUID.randomUUID() + "\",\"events\":[]}", "web")
                .andExpect(status().isBadRequest());
    }

    // ------------------------------------------------------------------------
    // Horloge
    // ------------------------------------------------------------------------

    /**
     * Brief §4.1 : une horloge client en avance est ramenee a l'heure serveur ;
     * un geste trop ancien est rejete (sinon on fabrique l'historique) ; un geste
     * de la file hors ligne, dans la fenetre, garde sa date.
     */
    @Test
    @DisplayName("Horodate : futur ramené à la réception, trop ancien rejeté, file hors ligne conservée")
    void horloge() throws Exception {
        UUID anon = UUID.randomUUID();
        String futur = id();
        String horsLigne = id();
        Instant ilYATroisJours = Instant.now().minus(Duration.ofDays(3)).truncatedTo(ChronoUnit.SECONDS);
        envoyer(lot(anon, null,
                        evt(futur, "PRICING_VIEWED", "\"occurredAt\":\"" + Instant.now().plus(Duration.ofHours(2)) + "\""),
                        evt(horsLigne, "PRICING_VIEWED", "\"occurredAt\":\"" + ilYATroisJours + "\""),
                        evt(id(), "PRICING_VIEWED", "\"occurredAt\":\"" + Instant.now().minus(Duration.ofDays(8)) + "\""),
                        evt(id(), "PRICING_VIEWED", "\"occurredAt\":\"hier soir\"")),
                "android")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.accepted").value(2))
                .andExpect(jsonPath("$.rejected[0].index").value(2))
                .andExpect(jsonPath("$.rejected[0].reason", containsString("occurredAt")))
                .andExpect(jsonPath("$.rejected[1].index").value(3));

        AnalyticsEventRecord ramene = ligne(futur);
        assertThat(ramene.getOccurredAt()).isEqualTo(ramene.getReceivedAt());
        assertThat(ligne(horsLigne).getOccurredAt()).isEqualTo(ilYATroisJours);
        // first_seen_at suit le geste le plus ancien du lot.
        assertThat(visitorManager.findById(anon).orElseThrow().getFirstSeenAt()).isEqualTo(ilYATroisJours);
    }

    // ------------------------------------------------------------------------
    // Contextes resolus serveur
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("La run citée doit exister, son type fait foi, et un contexte non admis est rejeté")
    void runDeDiagnostic() throws Exception {
        UUID anon = UUID.randomUUID();
        DiagnosticRun civique = run(DiagnosticRunType.CIVIQUE);
        String derive = id();
        envoyer(lot(anon, null,
                        evt(derive, "DIAGNOSTIC_REPORT_VIEWED", "\"diagnosticRunId\":\"" + civique.getId() + "\""),
                        evt(id(), "DIAGNOSTIC_REPORT_VIEWED",
                                "\"diagnosticRunId\":\"" + civique.getId() + "\",\"diagnosticType\":\"QUICK_TCF\""),
                        evt(id(), "DIAGNOSTIC_REPORT_VIEWED", "\"diagnosticRunId\":\"" + UUID.randomUUID() + "\""),
                        evt(id(), "LANDING_VIEWED", "\"diagnosticRunId\":\"" + civique.getId() + "\"")),
                "web")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.accepted").value(1))
                .andExpect(jsonPath("$.rejected[0].reason", containsString("CIVIQUE")))
                .andExpect(jsonPath("$.rejected[1].reason", containsString("run de diagnostic existante")))
                .andExpect(jsonPath("$.rejected[2].reason", containsString("non autorisés")));

        AnalyticsEventRecord ligne = ligne(derive);
        assertThat(ligne.getDiagnosticRunId()).isEqualTo(civique.getId());
        assertThat(ligne.getDiagnosticType()).isEqualTo(DiagnosticRunType.CIVIQUE);
    }

    @Test
    @DisplayName("Le parcours cité (plan_id = journey) doit exister")
    void parcours() throws Exception {
        UUID anon = UUID.randomUUID();
        Journey journey = testData.journey(testData.user(), TargetLevel.B1);
        em.flush();
        String accepte = id();
        envoyer(lot(anon, null,
                        evt(accepte, "PLAN_UNLOCK_CLICKED",
                                "\"path\":\"/plan\",\"journeyId\":\"" + journey.getId() + "\","
                                        + "\"properties\":{\"planCode\":\"INTEGRAL_PASS_1M\",\"displayedPriceCents\":\"1999\"}"),
                        evt(id(), "PLAN_OPENED", "\"journeyId\":\"" + UUID.randomUUID() + "\"")),
                "web")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.accepted").value(1))
                .andExpect(jsonPath("$.rejected[0].reason", containsString("journeyId")));

        AnalyticsEventRecord ligne = ligne(accepte);
        assertThat(ligne.getJourneyId()).isEqualTo(journey.getId());
        assertThat(ligne.getProperties()).containsEntry("displayedPriceCents", "1999");
    }

    // ------------------------------------------------------------------------
    // Exclusion interne (Q6), resolue a l'ingestion
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Scénario 15 — un visiteur lié à un compte interne écrit des événements internes")
    void interneParLien() throws Exception {
        UUID anon = UUID.randomUUID();
        String avant = id();
        envoyer(lot(anon, null, evt(avant, "PRICING_VIEWED", null)), "web").andExpect(status().isAccepted());

        User interne = testData.user();
        interne.setInternal(true);
        em.flush();
        identityManager.link(anon, interne.getId());

        String apres = id();
        envoyer(lot(anon, null, evt(apres, "PRICING_VIEWED", null)), "web").andExpect(status().isAccepted());

        // Pas de reecriture du passe : la ligne d'avant garde ce qu'on savait.
        assertThat(ligne(avant).getInternal()).isFalse();
        assertThat(ligne(apres).getInternal()).isTrue();
    }

    @Test
    @DisplayName("Un appelant authentifié interne est reconnu, et son compte est posé")
    void interneAuthentifie() throws Exception {
        User interne = testData.user();
        interne.setInternal(true);
        em.flush();
        String e = id();
        mockMvc.perform(post(URL).contentType(MediaType.APPLICATION_JSON)
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(interne))
                        .content(lot(UUID.randomUUID(), null, evt(e, "PRICING_VIEWED", null))))
                .andExpect(status().isAccepted());

        assertThat(ligne(e).getUserId()).isEqualTo(interne.getId());
        assertThat(ligne(e).getInternal()).isTrue();
    }

    // ------------------------------------------------------------------------
    // En-tetes absents (sendBeacon) et source declaree
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Sans en-tête (sendBeacon), la plateforme et la version du corps servent de repli")
    void repliDuCorps() throws Exception {
        String e = id();
        envoyer(lot(UUID.randomUUID(), "\"client\":\"android\",\"appVersion\":\"3.1.0\"",
                evt(e, "PRICING_VIEWED", null)), null)
                .andExpect(status().isAccepted());

        assertThat(ligne(e).getPlatform()).isEqualTo(ClientPlatform.ANDROID);
        assertThat(ligne(e).getAppVersion()).isEqualTo("3.1.0");
    }

    /**
     * Scenario 17 (socle) : {@code ig} devient « autre » dans l'allowlist de
     * {@code TrafficSource}, mais la source declaree est gardee pour que la
     * config la range sous instagram a la lecture.
     */
    @Test
    @DisplayName("La source déclarée est gardée brute (ig), à côté de la source normalisée")
    void sourceBrute() throws Exception {
        UUID anon = UUID.randomUUID();
        envoyer(lot(anon, "\"firstTouch\":{\"source\":\"IG\",\"landingPath\":\"/reussir\"}",
                evt(id(), "LANDING_VIEWED", "\"path\":\"/reussir\"")), "web")
                .andExpect(status().isAccepted());

        String brute = jdbc.queryForObject(
                "SELECT ft_source_raw FROM analytics_visitor WHERE anonymous_id = ?", String.class, anon);
        assertThat(brute).isEqualTo("ig");
        assertThat(visitorManager.findById(anon).orElseThrow().getFirstTouchSource()).isEqualTo("autre");
    }
}
