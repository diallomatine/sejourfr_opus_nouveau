package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AccesAdminFixtures;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.DateMetierParis;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrat HTTP de la console admin « Utilisateurs » (spec §4-§9, §11) : liste,
 * fiche, produits, actions d'accès, sécurité, concurrence. Les actions passent
 * par la vraie API (validation, verrou, contrainte d'exclusion V083).
 */
class AdminUserControllerIT extends AbstractIntegrationTest {

    private static final Duration JOUR = Duration.ofDays(1);

    @Autowired private MockMvc mvc;

    @Autowired private com.sejourfr.app.service.activity.UserActivityService activityService;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private ObjectMapper om;
    @Autowired private AccesAdminFixtures fx;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;
    @Autowired private UserManager userManager;

    private User admin;
    private String bearer;

    @BeforeEach
    void setUp() {
        admin = data.admin();
        bearer = auth.bearer(admin);
    }

    // ------------------------------------------------------------- helpers

    private JsonNode json(ResultActions r) throws Exception {
        return om.readTree(r.andReturn().getResponse().getContentAsString());
    }

    private JsonNode detail(User u) throws Exception {
        return json(mvc.perform(get("/api/admin/users/" + u.getId()).header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk()));
    }

    private JsonNode acces(JsonNode accesses, String produit) {
        for (JsonNode a : accesses) {
            if (a.get("product").asString().equals(produit)) return a;
        }
        throw new AssertionError("produit absent : " + produit);
    }

    private Map<String, Object> corps(String op, String produit, String depuis, LocalDate debut, LocalDate fin,
                                      String motif, boolean dryRun, String version) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("operation", op);
        m.put("product", produit);
        if (depuis != null) m.put("fromProduct", depuis);
        if (debut != null) m.put("startDate", debut.toString());
        if (fin != null) m.put("endDateInclusive", fin.toString());
        if (motif != null) m.put("reason", motif);
        m.put("dryRun", dryRun);
        if (version != null) m.put("expectedVersion", version);
        return m;
    }

    private ResultActions poster(User u, Map<String, Object> corps) throws Exception {
        return mvc.perform(post("/api/admin/users/" + u.getId() + "/access-operations")
                .header(HttpHeaders.AUTHORIZATION, bearer)
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(corps)));
    }

    /** Une action réelle, version lue sur la fiche, 200 attendu. */
    private JsonNode agir(User u, String op, String produit, String depuis, LocalDate debut, LocalDate fin)
            throws Exception {
        String version = detail(u).get("accessVersion").asString();
        return json(poster(u, corps(op, produit, depuis, debut, fin, "Motif support", false, version))
                .andExpect(status().isOk()));
    }

    private UserSubscription achat(User u, ModuleAccess m, Instant debut, Instant fin) {
        UserSubscription s = fx.achat(u, m, debut, fin);
        em.flush();
        return s;
    }

    private JsonNode liste(String... params) throws Exception {
        var req = get("/api/admin/users").header(HttpHeaders.AUTHORIZATION, bearer);
        for (int i = 0; i < params.length; i += 2) req = req.param(params[i], params[i + 1]);
        return json(mvc.perform(req).andExpect(status().isOk()));
    }

    private List<String> emails(JsonNode page) {
        List<String> out = new ArrayList<>();
        page.get("content").forEach(n -> out.add(n.get("email").asString()));
        return out;
    }

    // ------------------------------------------------------------- cas §11

    @Test
    @DisplayName("Cas 1 — utilisateur gratuit, Donner Intégral jusqu'au J+29 : actif immédiatement, origine Admin")
    void cas1DonnerUnAcces() throws Exception {
        User u = data.user();
        LocalDate fin = AccesAdminFixtures.jour(29);

        JsonNode r = agir(u, "GRANT", "INTEGRAL", null, null, fin);

        assertThat(r.get("operationId").isNull()).isFalse();
        JsonNode integral = acces(r.get("accesses"), "INTEGRAL");
        assertThat(integral.get("status").asString()).isEqualTo("ACTIVE");
        assertThat(integral.get("origin").asString()).isEqualTo("ADMIN_GRANT");
        assertThat(integral.get("endDateInclusive").asString()).isEqualTo(fin.toString());
        assertThat(integral.get("defaultEndDateInclusive").asString()).isEqualTo(fin.toString());
        assertThat(r.get("effectiveAccess").get("openModulesLabel").asString()).isEqualTo("TCF + Civique");

        JsonNode me = json(mvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, auth.bearer(u)))
                .andExpect(status().isOk()));
        assertThat(me.get("hasTcf").asBoolean()).isTrue();

        JsonNode d = detail(u);
        assertThat(d.get("history")).hasSize(1);
        assertThat(d.get("history").get(0).get("adminEmail").asString()).isEqualTo(admin.getEmail());
        assertThat(d.get("history").get(0).get("reason").asString()).isEqualTo("Motif support");
    }

    @Test
    @DisplayName("Cas 2 + 5 — Civique acheté (Stripe), Corriger Civique → Intégral : atomique, achat intact, une entrée d'historique")
    void cas2CorrectionDeProduit() throws Exception {
        User u = data.user();
        Instant finAchat = Instant.now().plus(JOUR.multipliedBy(28));
        UserSubscription civique = achat(u, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR), finAchat);
        Map<String, Object> avant = fx.ligneAchat(civique.getId());
        LocalDate fin = DateMetierParis.aujourdhui(finAchat);

        JsonNode r = agir(u, "CORRECT_PRODUCT", "INTEGRAL", "CIVIQUE", null, fin);

        assertThat(acces(r.get("accesses"), "CIVIQUE").get("status").asString()).isEqualTo("REVOKED");
        JsonNode integral = acces(r.get("accesses"), "INTEGRAL");
        assertThat(integral.get("status").asString()).isEqualTo("ACTIVE");
        assertThat(integral.get("endDateInclusive").asString()).isEqualTo(fin.toString());
        assertThat(fx.ligneAchat(civique.getId())).isEqualTo(avant);

        UUID op = UUID.fromString(r.get("operationId").asString());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM access_overrides WHERE operation_id = ?",
                Integer.class, op)).isEqualTo(2);
        JsonNode historique = detail(u).get("history");
        assertThat(historique).hasSize(1);
        assertThat(historique.get(0).get("operation").asString()).isEqualTo("CORRECT_PRODUCT");
        assertThat(historique.get(0).get("changes")).hasSize(2);
    }

    @Test
    @DisplayName("Cas 3 + 5 — Intégral actif jusqu'à J+8, Prolonger à J+29 : actif jusqu'à J+29 inclus, achat intact")
    void cas3Prolonger() throws Exception {
        User u = data.user();
        UserSubscription a = achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(8)));
        Map<String, Object> avant = fx.ligneAchat(a.getId());
        LocalDate fin = AccesAdminFixtures.jour(29);

        JsonNode integral = acces(agir(u, "EXTEND", "INTEGRAL", null, null, fin).get("accesses"), "INTEGRAL");

        assertThat(integral.get("status").asString()).isEqualTo("ACTIVE");
        assertThat(integral.get("endDateInclusive").asString()).isEqualTo(fin.toString());
        assertThat(fx.ligneAchat(a.getId())).isEqualTo(avant);
    }

    @Test
    @DisplayName("Cas 4 — Intégral expiré, Réactiver jusqu'à J+59 : actif")
    void cas4Reactiver() throws Exception {
        User u = data.user();
        achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR.multipliedBy(40)), Instant.now().minus(JOUR.multipliedBy(10)));
        assertThat(acces(detail(u).get("accesses"), "INTEGRAL").get("status").asString()).isEqualTo("EXPIRED");

        JsonNode r = agir(u, "REACTIVATE", "INTEGRAL", null, null, AccesAdminFixtures.jour(59));

        assertThat(acces(r.get("accesses"), "INTEGRAL").get("status").asString()).isEqualTo("ACTIVE");
    }

    @Test
    @DisplayName("Cas 8 — Intégral et Civique actifs, Terminer Intégral : Intégral révoqué, Civique inchangé")
    void cas8TerminerUnProduit() throws Exception {
        User u = data.user();
        achat(u, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(80)));
        achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(20)));
        String civiqueAvant = acces(detail(u).get("accesses"), "CIVIQUE").get("summary").asString();

        JsonNode r = agir(u, "END", "INTEGRAL", null, null, null);

        assertThat(r.get("confirmationRequired").asBoolean()).isTrue();
        assertThat(acces(r.get("accesses"), "INTEGRAL").get("status").asString()).isEqualTo("REVOKED");
        assertThat(acces(r.get("accesses"), "CIVIQUE").get("summary").asString()).isEqualTo(civiqueAvant);
        assertThat(r.get("effectiveAccess").get("effectiveProduct").asString()).isEqualTo("CIVIQUE");
    }

    @Test
    @DisplayName("Cas 9 — achat jusqu'à J+40, Raccourcir à J+10 : actif jusqu'à J+10 inclus, révocation programmée")
    void cas9Raccourcir() throws Exception {
        User u = data.user();
        achat(u, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(40)));
        LocalDate fin = AccesAdminFixtures.jour(10);

        JsonNode civique = acces(agir(u, "SHORTEN", "CIVIQUE", null, null, fin).get("accesses"), "CIVIQUE");

        assertThat(civique.get("status").asString()).isEqualTo("ACTIVE");
        assertThat(civique.get("endDateInclusive").asString()).isEqualTo(fin.toString());
        assertThat(civique.get("alerts").toString()).contains("REVOCATION_PROGRAMMEE");
    }

    @Test
    @DisplayName("Cas 10 — GRANT qui démarre à J+13 : Programmé, aucun accès d'ici là")
    void cas10Programme() throws Exception {
        User u = data.user();

        JsonNode r = agir(u, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(13), AccesAdminFixtures.jour(43));

        assertThat(acces(r.get("accesses"), "INTEGRAL").get("status").asString()).isEqualTo("SCHEDULED");
        assertThat(r.get("effectiveAccess").get("effectiveProduct").asString()).isEqualTo("NONE");
        JsonNode me = json(mvc.perform(get("/api/auth/me").header(HttpHeaders.AUTHORIZATION, auth.bearer(u)))
                .andExpect(status().isOk()));
        assertThat(me.get("hasCivique").asBoolean()).isFalse();
    }

    @Test
    @DisplayName("GO §4 — programmer une décision future ne modifie jamais l'accès d'ici là ; l'original est tronqué, jamais effacé")
    void go4DecisionProgrammee() throws Exception {
        User u = data.user();
        agir(u, "GRANT", "INTEGRAL", null, null, AccesAdminFixtures.jour(29));
        UUID original = jdbc.queryForObject("SELECT id FROM access_overrides WHERE user_id = ?", UUID.class, u.getId());

        JsonNode r = agir(u, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(18), AccesAdminFixtures.jour(50));

        JsonNode integral = acces(r.get("accesses"), "INTEGRAL");
        assertThat(integral.get("status").asString()).isEqualTo("ACTIVE");
        assertThat(integral.get("endDateInclusive").asString()).isEqualTo(AccesAdminFixtures.jour(50).toString());
        UUID op = UUID.fromString(r.get("operationId").asString());
        Map<String, Object> ancien = jdbc.queryForMap(
                "SELECT superseded_at, superseded_by_operation_id FROM access_overrides WHERE id = ?", original);
        assertThat(ancien.get("superseded_at")).isNotNull();
        assertThat(ancien.get("superseded_by_operation_id")).isEqualTo(op);
        Map<String, Object> tete = jdbc.queryForMap("SELECT starts_at, ends_at, operation_id FROM access_overrides "
                + "WHERE replaces_override_id = ? AND superseded_at IS NULL", original);
        assertThat(((java.sql.Timestamp) tete.get("ends_at")).toInstant())
                .isEqualTo(DateMetierParis.minuit(AccesAdminFixtures.jour(18)));
        assertThat(tete.get("operation_id")).isEqualTo(op);
        assertThat(fx.decisionsCourantes(u.getId())).isEqualTo(2);
    }

    @Test
    @DisplayName("Contrainte d'exclusion V083 : deux décisions courantes qui se chevauchent sont refusées par la base")
    void exclusionEnBase() throws Exception {
        User u = data.user();
        agir(u, "GRANT", "CIVIQUE", null, null, AccesAdminFixtures.jour(29));
        UUID op = jdbc.queryForObject("SELECT operation_id FROM access_overrides WHERE user_id = ?", UUID.class, u.getId());

        org.assertj.core.api.Assertions.assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO access_overrides (id, user_id, product, type, starts_at, ends_at, decided_at, reason, "
                        + "created_by, operation_id) VALUES (?, ?, 'CIVIQUE', 'REVOKE', now() + interval '3 days', NULL, "
                        + "now(), 'chevauchement', ?, ?)", UUID.randomUUID(), u.getId(), admin.getId(), op))
                .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("dryRun : aperçu serveur, aucune écriture")
    void dryRun() throws Exception {
        User u = data.user();
        JsonNode r = json(poster(u, corps("GRANT", "CIVIQUE", null, null, AccesAdminFixtures.jour(9),
                "Geste commercial", true, null)).andExpect(status().isOk()));

        assertThat(r.get("dryRun").asBoolean()).isTrue();
        assertThat(r.get("operationId").isNull()).isTrue();
        assertThat(r.get("preview").asString()).contains("Vous allez donner l'accès Civique");
        assertThat(acces(r.get("accesses"), "CIVIQUE").get("status").asString()).isEqualTo("ACTIVE");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM admin_access_operations WHERE user_id = ?",
                Integer.class, u.getId())).isZero();
        assertThat(fx.decisionsCourantes(u.getId())).isZero();
    }

    // ------------------------------------------------------- 400 / 401 / 403 / 404 / 409

    @Test
    @DisplayName("Cas 13 — fin < début, motif vide, produit inconnu : 400 avec message")
    void cas13Validations() throws Exception {
        User u = data.user();
        String version = detail(u).get("accessVersion").asString();
        JsonNode r = json(poster(u, corps("GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(10), AccesAdminFixtures.jour(5),
                "Motif valide", false, version)).andExpect(status().isBadRequest()));
        assertThat(r.get("message").asString()).contains("date de fin");
        poster(u, corps("GRANT", "INTEGRAL", null, null, AccesAdminFixtures.jour(5), "", false, version))
                .andExpect(status().isBadRequest());
        poster(u, corps("GRANT", "TCF", null, null, AccesAdminFixtures.jour(5), "Motif valide", false, version))
                .andExpect(status().isBadRequest());
        assertThat(fx.decisionsCourantes(u.getId())).isZero();
    }

    @Test
    @DisplayName("Cas 14 — non authentifié 401, non admin 403, utilisateur inexistant 404")
    void cas14Securite() throws Exception {
        User u = data.user();
        String cible = "/api/admin/users/" + u.getId();
        mvc.perform(get(cible)).andExpect(status().isUnauthorized());
        mvc.perform(get(cible).header(HttpHeaders.AUTHORIZATION, auth.bearer(u))).andExpect(status().isForbidden());
        mvc.perform(post(cible + "/access-operations").header(HttpHeaders.AUTHORIZATION, auth.bearer(u))
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(corps("END", "CIVIQUE", null, null, null, "abc", false, "x"))))
                .andExpect(status().isForbidden());

        UUID inconnu = UUID.randomUUID();
        mvc.perform(get("/api/admin/users/" + inconnu).header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/admin/users/" + inconnu + "/access-operations").header(HttpHeaders.AUTHORIZATION, bearer)
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(corps("GRANT", "CIVIQUE", null, null, AccesAdminFixtures.jour(3),
                        "Motif valide", false, "x"))))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("G-11 — deux admins sur le même état : le second reçoit 409, rien n'est écrit pour lui")
    void g11EtatPerime() throws Exception {
        User u = data.user();
        String version = detail(u).get("accessVersion").asString();
        poster(u, corps("GRANT", "CIVIQUE", null, null, AccesAdminFixtures.jour(9), "Premier admin", false, version))
                .andExpect(status().isOk());

        JsonNode r = json(poster(u, corps("GRANT", "INTEGRAL", null, null, AccesAdminFixtures.jour(9),
                "Second admin", false, version)).andExpect(status().isConflict()));

        assertThat(r.get("message").asString()).contains("a changé");
        assertThat(detail(u).get("history")).hasSize(1);
    }

    @Test
    @DisplayName("GO §5 — Terminer Civique isolé sous un Intégral actif : 409 explicite")
    void terminerCiviqueSousIntegral() throws Exception {
        User u = data.user();
        achat(u, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(80)));
        achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(20)));
        JsonNode d = detail(u);
        assertThat(acces(d.get("accesses"), "CIVIQUE").get("availableOperations").toString()).doesNotContain("\"END\"");

        JsonNode r = json(poster(u, corps("END", "CIVIQUE", null, null, null, "Fin demandée", false,
                d.get("accessVersion").asString())).andExpect(status().isConflict()));
        assertThat(r.get("message").asString()).contains("Civique reste accessible via Intégral");
    }

    // ------------------------------------------------------------- lecture

    @Test
    @DisplayName("Fiche : compte, accès par produit, achats tronqués, progression, version")
    void fiche() throws Exception {
        User u = data.user();
        Instant finAchat = Instant.now().plus(JOUR.multipliedBy(20));
        UserSubscription a = achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), finAchat);

        JsonNode d = detail(u);

        // Fin d'achat (heure réelle) : pas de date incluse, mais la valeur de pré-remplissage
        // de la modale est servie (jour Paris de la fin), le front ne convertit rien.
        JsonNode integral = acces(d.get("accesses"), "INTEGRAL");
        assertThat(integral.get("endDateInclusive").isNull()).isTrue();
        assertThat(integral.get("defaultEndDateInclusive").asString())
                .isEqualTo(DateMetierParis.aujourdhui(finAchat).toString());
        assertThat(acces(d.get("accesses"), "CIVIQUE").get("defaultEndDateInclusive").isNull()).isTrue();

        assertThat(d.get("account").get("email").asString()).isEqualTo(u.getEmail());
        assertThat(d.get("account").toString()).doesNotContain("password").doesNotContain("Hash");
        assertThat(d.get("accesses")).hasSize(2);
        assertThat(d.get("effectiveAccess").get("effectiveProductLabel").asString()).isEqualTo("Intégral");
        JsonNode achat = d.get("purchases").get(0);
        assertThat(achat.get("sourceLabel").asString()).isEqualTo("Stripe");
        // D-33 : un identifiant Stripe sort entier (seul le purchaseToken Google est tronqué).
        assertThat(achat.get("externalReference").asString()).isEqualTo(a.getOriginalTransactionId());
        assertThat(d.get("progression")).hasSize(2);
        assertThat(d.get("progression").get(0).get("diagnosticDone").asBoolean()).isFalse();
        assertThat(d.get("accessVersion").asString()).hasSize(16);
    }

    @Test
    @DisplayName("Produits : les produits réellement vendus, avec les modules qu'ils ouvrent")
    void produits() throws Exception {
        JsonNode p = json(mvc.perform(get("/api/admin/access-products").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk()));
        assertThat(p).hasSize(2);
        assertThat(p.get(0).get("code").asString()).isEqualTo("CIVIQUE");
        assertThat(p.get(1).get("code").asString()).isEqualTo("INTEGRAL");
        assertThat(p.get(1).get("modulesLabel").asString()).isEqualTo("TCF + Civique");
    }

    @Test
    @DisplayName("Liste : recherche par email / nom / id, filtres sur l'accès EFFECTIF")
    void listeEtFiltres() throws Exception {
        String tag = "liste" + UUID.randomUUID().toString().substring(0, 8);
        User gratuit = data.user(tag + "-gratuit@test.sejourfr");
        User tcf = data.user(tag + "-tcf@test.sejourfr");
        User civique = data.user(tag + "-civique@test.sejourfr");
        User expire = data.user(tag + "-expire@test.sejourfr");
        User revoque = data.user(tag + "-revoque@test.sejourfr");
        User accorde = data.user(tag + "-accorde@test.sejourfr");
        civique.setFirstName("Jeanne");
        civique.setLastName("Dupontel" + tag);
        userManager.save(civique);
        achat(tcf, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(20)));
        achat(civique, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(20)));
        achat(expire, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR.multipliedBy(50)), Instant.now().minus(JOUR.multipliedBy(5)));
        achat(revoque, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(20)));
        agir(revoque, "END", "INTEGRAL", null, null, null);
        agir(accorde, "GRANT", "CIVIQUE", null, null, AccesAdminFixtures.jour(10));

        assertThat(emails(liste("q", tag))).hasSize(6);
        assertThat(emails(liste("q", tag, "filter", "TCF_ACTIVE"))).containsExactly(tcf.getEmail());
        assertThat(emails(liste("q", tag, "filter", "CIVIQUE_ACTIVE")))
                .containsExactlyInAnyOrder(tcf.getEmail(), civique.getEmail(), accorde.getEmail());
        assertThat(emails(liste("q", tag, "filter", "NO_ACTIVE_ACCESS")))
                .containsExactlyInAnyOrder(gratuit.getEmail(), expire.getEmail(), revoque.getEmail());
        assertThat(emails(liste("q", tag, "filter", "EXPIRED")))
                .containsExactlyInAnyOrder(expire.getEmail(), revoque.getEmail());
        assertThat(emails(liste("q", tag, "filter", "MANUAL_ACCESS")))
                .containsExactlyInAnyOrder(revoque.getEmail(), accorde.getEmail());
        assertThat(emails(liste("q", "dupontel" + tag))).containsExactly(civique.getEmail());
        assertThat(emails(liste("q", "Jeanne Dupontel" + tag))).containsExactly(civique.getEmail());
        assertThat(emails(liste("q", tcf.getId().toString()))).containsExactly(tcf.getEmail());

        JsonNode ligneTcf = liste("q", tcf.getEmail()).get("content").get(0);
        assertThat(ligneTcf.get("effectiveAccess").get("effectiveProduct").asString()).isEqualTo("INTEGRAL");
        assertThat(ligneTcf.get("nextEndsAt").isNull()).isFalse();
        assertThat(ligneTcf.get("accountStatus").asString()).isEqualTo("ACTIVE");
        JsonNode ligneAccorde = liste("q", accorde.getEmail()).get("content").get(0);
        assertThat(ligneAccorde.get("manualAccess").asBoolean()).isTrue();
        assertThat(ligneAccorde.get("nextEndDateInclusive").asString()).isEqualTo(AccesAdminFixtures.jour(10).toString());
    }

    @Test
    @DisplayName("Liste : coût constant d'une page (égalité du nombre de requêtes, 2 comptes ou 6)")
    void listeCoutConstant() throws Exception {
        String tag = "cout" + UUID.randomUUID().toString().substring(0, 8);
        for (int i = 0; i < 2; i++) {
            User u = data.user(tag + "-a" + i + "@test.sejourfr");
            achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(20)));
        }
        long petite = requetes(() -> liste("q", tag, "filter", "TCF_ACTIVE"));
        for (int i = 0; i < 4; i++) {
            User u = data.user(tag + "-b" + i + "@test.sejourfr");
            achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(20)));
            agir(u, "GRANT", "CIVIQUE", null, null, AccesAdminFixtures.jour(4));
        }
        long grande = requetes(() -> liste("q", tag, "filter", "TCF_ACTIVE"));

        assertThat(petite).isPositive();
        assertThat(grande).isEqualTo(petite);
    }

    // ------------------------------------------------ sessions EO temps réel (V084)

    private ResultActions posterSessions(User u, String op, String produit, String depuis, LocalDate fin,
                                         Object sessions, boolean dryRun) throws Exception {
        String version = dryRun ? null : detail(u).get("accessVersion").asString();
        Map<String, Object> c = corps(op, produit, depuis, null, fin, "Motif support", dryRun, version);
        c.put("realtimeEoSessions", sessions);
        return poster(u, c);
    }

    private JsonNode sessionsEo(JsonNode accesses) {
        return acces(accesses, "INTEGRAL").get("realtimeEoSessions");
    }

    @Test
    @DisplayName("V084 — les 3 opérations qui créent un GRANT Intégral offrent des sessions : Donner, Réactiver, Corriger Civique → Intégral")
    void sessionsEoTroisOperations() throws Exception {
        User donne = data.user();
        JsonNode r1 = json(posterSessions(donne, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(29), 10, false)
                .andExpect(status().isOk()));
        assertThat(sessionsEo(r1.get("accesses")).get("grantRemaining").asInt()).isEqualTo(10);
        assertThat(sessionsEo(r1.get("accesses")).get("grantGranted").asInt()).isEqualTo(10);
        assertThat(sessionsEo(r1.get("accesses")).get("remaining").asInt()).isEqualTo(10);
        assertThat(sessionsEo(r1.get("accesses")).get("info").isNull()).isTrue();
        assertThat(r1.get("preview").asString()).contains("Cet accès manuel offre 10 sessions EO temps réel.");

        User reactive = data.user();
        achat(reactive, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR.multipliedBy(40)), Instant.now().minus(JOUR.multipliedBy(10)));
        JsonNode r2 = json(posterSessions(reactive, "REACTIVATE", "INTEGRAL", null, AccesAdminFixtures.jour(59), 5, false)
                .andExpect(status().isOk()));
        assertThat(sessionsEo(r2.get("accesses")).get("grantRemaining").asInt()).isEqualTo(5);

        User corrige = data.user();
        achat(corrige, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(60)));
        JsonNode r3 = json(posterSessions(corrige, "CORRECT_PRODUCT", "INTEGRAL", "CIVIQUE", AccesAdminFixtures.jour(60), 7, false)
                .andExpect(status().isOk()));
        assertThat(sessionsEo(r3.get("accesses")).get("grantRemaining").asInt()).isEqualTo(7);
        assertThat(acces(r3.get("accesses"), "CIVIQUE").get("realtimeEoSessions").isNull()).isTrue();

        // L'historique de la fiche dit le changement de solde, depuis le journal (snapshot).
        JsonNode historique = detail(donne).get("history").get(0);
        assertThat(historique.get("changes").toString()).contains("Intégral — sessions EO temps réel : 0 → 10");
        Integer snapshot = jdbc.queryForObject("SELECT (e->>'realtimeEoSessions')::int FROM admin_access_operations o, "
                + "jsonb_array_elements(o.after_state) e WHERE o.user_id = ? AND e->>'product' = 'INTEGRAL'",
                Integer.class, donne.getId());
        assertThat(snapshot).isEqualTo(10);
    }

    @Test
    @DisplayName("V084 — cumul : Donner Intégral +10 sur un GRANT Intégral à 4, sans 409 ; l'aperçu annonce 4 + 10 → 14")
    void sessionsEoCumul() throws Exception {
        User u = data.user();
        posterSessions(u, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(20), 4, false).andExpect(status().isOk());

        JsonNode apercu = json(posterSessions(u, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(40), 10, true)
                .andExpect(status().isOk()));
        assertThat(apercu.get("preview").asString())
                .contains("4 sessions restantes + 10 offertes → 14 sessions disponibles");
        JsonNode r = json(posterSessions(u, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(40), 10, false)
                .andExpect(status().isOk()));
        assertThat(sessionsEo(r.get("accesses")).get("grantRemaining").asInt()).isEqualTo(14);
        assertThat(sessionsEo(r.get("accesses")).get("grantGranted").asInt()).isEqualTo(14);
        assertThat(sessionsEo(detail(u).get("accesses")).get("label").asString())
                .isEqualTo("14 sessions restantes — accès manuel : 14 restantes sur 14 accordées");
    }

    @Test
    @DisplayName("V084 — 400 : négatif, au-delà de 50, sur Prolonger, sur Civique ; rien n'est écrit")
    void sessionsEo400() throws Exception {
        User u = data.user();
        posterSessions(u, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(20), -1, false)
                .andExpect(status().isBadRequest());
        JsonNode trop = json(posterSessions(u, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(20), 51, false)
                .andExpect(status().isBadRequest()));
        assertThat(trop.get("message").asString()).contains("50");
        posterSessions(u, "GRANT", "CIVIQUE", null, AccesAdminFixtures.jour(20), 5, false)
                .andExpect(status().isBadRequest());
        assertThat(fx.decisionsCourantes(u.getId())).isZero();

        posterSessions(u, "GRANT", "INTEGRAL", null, AccesAdminFixtures.jour(20), null, false).andExpect(status().isOk());
        JsonNode prolonger = json(posterSessions(u, "EXTEND", "INTEGRAL", null, AccesAdminFixtures.jour(40), 5, false)
                .andExpect(status().isBadRequest()));
        assertThat(prolonger.get("message").asString())
                .isEqualTo("Les sessions EO temps réel ne s'offrent qu'en donnant, réactivant ou corrigeant vers un accès Intégral.");
        assertThat(fx.decisionsCourantes(u.getId())).isEqualTo(1);
    }

    @Test
    @DisplayName("V084 — fiche : un accès manuel Intégral sans session porte la phrase d'information ; produits : plafond servi")
    void sessionsEoFicheEtProduits() throws Exception {
        User u = data.user();
        agir(u, "GRANT", "INTEGRAL", null, null, AccesAdminFixtures.jour(20));
        JsonNode bloc = sessionsEo(detail(u).get("accesses"));
        assertThat(bloc.get("info").asString())
                .isEqualTo("Cet accès manuel n'ajoute pas actuellement de sessions EO temps réel.");
        assertThat(bloc.get("remaining").asInt()).isZero();
        assertThat(bloc.get("purchaseRemaining").isNull()).isTrue();

        JsonNode p = json(mvc.perform(get("/api/admin/access-products").header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk()));
        assertThat(p.get(0).get("maxRealtimeEoSessions").isNull()).isTrue();
        assertThat(p.get(1).get("maxRealtimeEoSessions").asInt()).isEqualTo(50);
    }

    @FunctionalInterface
    private interface Appel {
        void run() throws Exception;
    }

    private long requetes(Appel appel) throws Exception {
        em.flush();
        em.clear();
        // Toute requete authentifiee entretient la presence (chantier « Activite »,
        // une ecriture par minute au plus) : on rend cette ecriture SYSTEMATIQUE
        // pour que chaque mesure la compte une fois, quel que soit l'ecart entre
        // deux appels.
        activityService.resetThrottle();
        Statistics stats = em.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
        stats.setStatisticsEnabled(true);
        stats.clear();
        appel.run();
        return stats.getPrepareStatementCount();
    }
}
