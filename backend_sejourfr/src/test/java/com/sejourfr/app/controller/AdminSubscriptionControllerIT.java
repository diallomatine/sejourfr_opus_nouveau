package com.sejourfr.app.controller;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import com.sejourfr.app.service.AdminSubscriptionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrat HTTP de {@code GET /api/admin/subscriptions} : pagination serveur
 * ({@code PageResponse}), filtres appliqués AVANT la découpe en pages, tri
 * stable, plafond de taille, et coût constant d'une page.
 *
 * <p>{@code user_subscriptions} n'est pas seedée par Flyway : seules les lignes
 * du test existent, les totaux s'assertent donc exactement.</p>
 */
class AdminSubscriptionControllerIT extends AbstractIntegrationTest {

    private static final String URL = "/api/admin/subscriptions";

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData testData;
    @Autowired private AuthTestSupport auth;
    @Autowired private UserSubscriptionRepository repository;
    @Autowired private AdminSubscriptionService service;
    @Autowired private EntityManager entityManager;
    @Autowired private ObjectMapper objectMapper;

    private String bearer;

    @BeforeEach
    void setUp() {
        bearer = auth.bearer(testData.admin());
    }

    private UserSubscription sub(SubscriptionSource source, Instant updatedAt) {
        return sub(testData.user(), testData.plan(), source, updatedAt);
    }

    private UserSubscription sub(User user, Plan plan, SubscriptionSource source, Instant updatedAt) {
        UserSubscription s = testData.userSubscription(user, plan);
        s.setSource(source);
        s.setStatus(SubscriptionStatus.ACTIVE);
        repository.saveAndFlush(s);
        // TestData persiste déjà la ligne : un setUpdatedAt() serait écrasé par le
        // @PreUpdate au flush. L'instant est donc posé en SQL, hors entité.
        entityManager.createNativeQuery("UPDATE user_subscriptions SET updated_at = :t WHERE id = :id")
                .setParameter("t", updatedAt)
                .setParameter("id", s.getId())
                .executeUpdate();
        entityManager.detach(s);
        return s;
    }

    private JsonNode list(String... params) throws Exception {
        var req = get(URL).header(HttpHeaders.AUTHORIZATION, bearer);
        for (int i = 0; i < params.length; i += 2) req = req.param(params[i], params[i + 1]);
        String body = mockMvc.perform(req).andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body);
    }

    private static List<String> ids(JsonNode page) {
        List<String> ids = new ArrayList<>();
        page.get("content").forEach(n -> ids.add(n.get("id").asString()));
        return ids;
    }

    @Test
    void rendUnePageResponseAvecTotalEtNombreDePages() throws Exception {
        Instant t = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        for (int i = 0; i < 5; i++) sub(SubscriptionSource.STRIPE, t.minusSeconds(i));

        mockMvc.perform(get(URL).param("page", "1").param("size", "2")
                        .header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content.length()").value(2))
                .andExpect(jsonPath("$.page").value(1))
                .andExpect(jsonPath("$.size").value(2))
                .andExpect(jsonPath("$.totalElements").value(5))
                .andExpect(jsonPath("$.totalPages").value(3))
                .andExpect(jsonPath("$.first").value(false))
                .andExpect(jsonPath("$.last").value(false))
                .andExpect(jsonPath("$.content[0].userEmail").exists())
                .andExpect(jsonPath("$.content[0].planCode").exists());
    }

    @Test
    void plusRecentesEnTete() throws Exception {
        Instant t = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        UserSubscription vieille = sub(SubscriptionSource.STRIPE, t.minus(2, ChronoUnit.DAYS));
        UserSubscription recente = sub(SubscriptionSource.STRIPE, t);
        UserSubscription milieu = sub(SubscriptionSource.STRIPE, t.minus(1, ChronoUnit.DAYS));

        assertThat(ids(list("size", "10"))).containsExactly(
                recente.getId().toString(), milieu.getId().toString(), vieille.getId().toString());
    }

    /**
     * Cinq lignes au même {@code updated_at} : sans second critère de tri, Postgres
     * est libre de les rendre dans n'importe quel ordre à chaque requête, et une
     * ligne pouvait apparaître sur deux pages ou sur aucune.
     */
    @Test
    void triStable_lesPagesSeSuiventSansDoublonNiTrou() throws Exception {
        Instant memeInstant = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        List<String> attendus = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            attendus.add(sub(SubscriptionSource.STRIPE, memeInstant).getId().toString());
        }

        List<String> parPages = new ArrayList<>();
        for (int page = 0; page < 3; page++) {
            parPages.addAll(ids(list("page", String.valueOf(page), "size", "2")));
        }
        List<String> dUnCoup = ids(list("size", "5"));

        assertThat(parPages).hasSize(5).doesNotHaveDuplicates()
                .containsExactlyInAnyOrderElementsOf(attendus);
        assertThat(parPages).containsExactlyElementsOf(dUnCoup);
    }

    @Test
    void lesFiltresSontAppliquesAvantLaDecoupeEnPages() throws Exception {
        Instant t = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        for (int i = 0; i < 7; i++) sub(SubscriptionSource.APPLE, t.minusSeconds(i));
        for (int i = 0; i < 3; i++) sub(SubscriptionSource.STRIPE, t.minusSeconds(100 + i));

        JsonNode derniere = list("source", "APPLE", "page", "2", "size", "3");

        assertThat(derniere.get("totalElements").asLong()).isEqualTo(7);
        assertThat(derniere.get("totalPages").asInt()).isEqualTo(3);
        assertThat(derniere.get("last").asBoolean()).isTrue();
        assertThat(derniere.get("content")).hasSize(1);
        derniere.get("content").forEach(n -> assertThat(n.get("source").asString()).isEqualTo("APPLE"));
    }

    @Test
    void rechercheEtModuleCombinesAvecLaPagination() throws Exception {
        Instant t = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        Plan civique = testData.plan(ModuleAccess.CIVIQUE);
        Plan integral = testData.plan(ModuleAccess.INTEGRAL);
        String marqueur = "pagin" + System.nanoTime();
        for (int i = 0; i < 3; i++) {
            sub(testData.user(marqueur + i + "@test.sejourfr"), civique, SubscriptionSource.STRIPE, t.minusSeconds(i));
        }
        sub(testData.user(marqueur + "x@test.sejourfr"), integral, SubscriptionSource.STRIPE, t);
        sub(testData.user(), civique, SubscriptionSource.STRIPE, t);

        JsonNode page = list("search", marqueur.toUpperCase(), "moduleAccess", "CIVIQUE", "size", "2");

        assertThat(page.get("totalElements").asLong()).isEqualTo(3);
        assertThat(page.get("totalPages").asInt()).isEqualTo(2);
        assertThat(page.get("content")).hasSize(2);
    }

    @Test
    void tailleDePagePlafonneeA100() throws Exception {
        sub(SubscriptionSource.STRIPE, Instant.now());

        JsonNode page = list("size", "5000");

        assertThat(page.get("size").asInt()).isEqualTo(100);
        assertThat(page.get("totalElements").asLong()).isEqualTo(1);
    }

    @Test
    void pageAuDelaDeLaDerniere_contenuVideMaisTotauxJustes() throws Exception {
        Instant t = Instant.now();
        for (int i = 0; i < 3; i++) sub(SubscriptionSource.STRIPE, t.minusSeconds(i));

        JsonNode page = list("page", "9", "size", "2");

        assertThat(page.get("content")).isEmpty();
        assertThat(page.get("totalElements").asLong()).isEqualTo(3);
        assertThat(page.get("totalPages").asInt()).isEqualTo(2);
    }

    @Test
    void parametreDePageNonNumerique_400() throws Exception {
        mockMvc.perform(get(URL).param("page", "abc").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isBadRequest());
    }

    /**
     * Une page = la requête de contenu (user et plan joints) + le comptage. Égalité
     * stricte : un {@code <=} laisserait passer le retour du N+1 (1 + 2 requêtes
     * par ligne) tant qu'il reste sous le seuil.
     */
    @Test
    void unePageCouteDeuxRequetes_quelQueSoitLeNombreDeLignes() {
        Instant t = Instant.now();
        for (int i = 0; i < 6; i++) sub(SubscriptionSource.STRIPE, t.minusSeconds(i));
        entityManager.clear();

        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();

        var page = service.list(null, null, null, null, 0, 5);

        assertThat(page.content()).hasSize(5);
        assertThat(new HashSet<>(page.content().stream().map(d -> d.userEmail()).toList())).hasSize(5);
        assertThat(statistics.getPrepareStatementCount()).isEqualTo(2);
    }
}
