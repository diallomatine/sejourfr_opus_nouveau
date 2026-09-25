package com.sejourfr.app.controller;

import com.jayway.jsonpath.JsonPath;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.repository.UserRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.ClientContextResolver;
import com.sejourfr.app.util.JetonSecret;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le cycle de vie d'une {@code diagnostic_run} de bout en bout (chantier Suivi,
 * lot 2a) : creation idempotente, « soumis » une seule fois, claim dans la
 * transaction d'auth, contexte d'inscription, et rattachement serveur aux
 * sessions. Scenarios du brief §12 : 3, 5, 6, 7, 16 (civique), 20.
 */
class DiagnosticRunLifecycleIT extends AbstractIntegrationTest {

    private static final String IP = "203.0.113.50";
    private static final String AUTRE_IP = "203.0.113.51";
    private static final String MOT_DE_PASSE = "MotDePasse1!";

    @Autowired private MockMvc mvc;
    @Autowired private TestData testData;
    @Autowired private AuthTestSupport auth;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private UserRepository userRepository;
    @Autowired private EntityManager em;

    // ------------------------------------------------------------------------
    // Outils
    // ------------------------------------------------------------------------

    /** Reponse de creation, lue. */
    private record Creee(UUID id, String token, boolean created) {
    }

    private static MockHttpServletRequestBuilder depuis(MockHttpServletRequestBuilder builder, String ip) {
        return builder.with(r -> {
            r.setRemoteAddr(ip);
            return r;
        });
    }

    private MockHttpServletRequestBuilder creation(String type, UUID clientKey, UUID anon, UUID sessionId) {
        String body = "{\"diagnosticType\":\"" + type + "\",\"clientKey\":\"" + clientKey + "\""
                + (sessionId == null ? "" : ",\"sessionId\":\"" + sessionId + "\"") + "}";
        MockHttpServletRequestBuilder b = depuis(post("/api/public/diagnostic-runs"), IP)
                .contentType(MediaType.APPLICATION_JSON).content(body);
        if (anon != null) b.header(ClientContextResolver.HEADER_ANONYMOUS_ID, anon.toString());
        return b;
    }

    private Creee creer(MockHttpServletRequestBuilder requete) throws Exception {
        String json = mvc.perform(requete).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return new Creee(UUID.fromString(JsonPath.read(json, "$.diagnosticRunId")),
                JsonPath.read(json, "$.claimToken"), JsonPath.read(json, "$.created"));
    }

    private Creee creerInvite(String type, UUID anon) throws Exception {
        return creer(creation(type, UUID.randomUUID(), anon, null));
    }

    private MockHttpServletRequestBuilder soumission(UUID runId, String token) {
        return depuis(post("/api/public/diagnostic-runs/" + runId + "/submit"), IP)
                .contentType(MediaType.APPLICATION_JSON)
                .content(token == null ? "{}" : "{\"claimToken\":\"" + token + "\"}");
    }

    private Map<String, Object> run(UUID id) {
        return jdbc.queryForMap("SELECT * FROM diagnostic_run WHERE id = ?", id);
    }

    private static String inscription(String email, UUID runId, String token) {
        return "{\"email\":\"" + email + "\",\"password\":\"" + MOT_DE_PASSE + "\",\"firstName\":\"Awa\","
                + "\"lastName\":\"Diallo\""
                + (runId == null ? "" : ",\"diagnosticRunId\":\"" + runId + "\"")
                + (token == null ? "" : ",\"claimToken\":\"" + token + "\"") + "}";
    }

    private String inscrire(String email, UUID runId, String token, UUID anon) throws Exception {
        MockHttpServletRequestBuilder b = post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .header(ClientContextResolver.HEADER_CLIENT, "ios")
                .content(inscription(email, runId, token));
        if (anon != null) b.header(ClientContextResolver.HEADER_ANONYMOUS_ID, anon.toString());
        String json = mvc.perform(b).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(json, "$.accessToken");
    }

    private void connecter(User user, UUID runId, String token) throws Exception {
        em.flush();
        String body = "{\"email\":\"" + user.getEmail() + "\",\"password\":\"" + TestData.DEFAULT_PASSWORD + "\""
                + (runId == null ? "" : ",\"diagnosticRunId\":\"" + runId + "\"")
                + (token == null ? "" : ",\"claimToken\":\"" + token + "\"") + "}";
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk());
    }

    private User relire(String email) {
        em.flush();
        em.clear();
        return userRepository.findByEmail(email).orElseThrow();
    }

    /** Ouvre un diagnostic civique invite depuis {@link #IP} ; rend (sessionId, attemptId). */
    private UUID[] civiqueInvite() throws Exception {
        String json = mvc.perform(depuis(post("/api/public/civic-diagnostics"), IP))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return new UUID[]{UUID.fromString(JsonPath.read(json, "$.sessionId")),
                UUID.fromString(JsonPath.read(json, "$.attemptId"))};
    }

    private void finirInvite(UUID attemptId) throws Exception {
        mvc.perform(depuis(post("/api/public/attempts/" + attemptId + "/finish"), IP))
                .andExpect(status().isOk());
    }

    // ------------------------------------------------------------------------
    // Creation
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Création : contexte client posé, seul le hash du jeton stocké, TTL de la config")
    void creationPoseLeContexte() throws Exception {
        UUID anon = UUID.randomUUID();
        Creee c = creer(creation("QUICK_TCF", UUID.randomUUID(), anon, null)
                .header(ClientContextResolver.HEADER_CLIENT, "ios")
                .header(ClientContextResolver.HEADER_APP_VERSION, "2.4.1+57"));

        assertThat(c.created()).isTrue();
        // 256 bits en base64url : 43 caracteres.
        assertThat(c.token()).hasSize(43);
        Map<String, Object> row = run(c.id());
        assertThat(row.get("diagnostic_type")).isEqualTo("QUICK_TCF");
        assertThat(row.get("platform")).isEqualTo("IOS");
        assertThat(row.get("app_version")).isEqualTo("2.4.1+57");
        assertThat(row.get("anonymous_id")).isEqualTo(anon);
        assertThat(row.get("user_id")).isNull();
        assertThat(row.get("submitted_at")).isNull();
        assertThat(row.get("claim_token_hash")).isEqualTo(JetonSecret.sha256Hex(c.token()));
        assertThat(row.get("claim_token_hash")).isNotEqualTo(c.token());
        Instant expire = ((Timestamp) row.get("claim_token_expires_at")).toInstant();
        assertThat(expire).isCloseTo(Instant.now().plus(Duration.ofDays(30)), within(Duration.ofMinutes(5)));
    }

    @Test
    @DisplayName("Idempotence : même (anonymousId, clientKey) ⇒ même run, nouveau jeton, l'ancien ne vaut plus rien")
    void creationIdempotente() throws Exception {
        UUID anon = UUID.randomUUID();
        UUID cle = UUID.randomUUID();
        Creee premiere = creer(creation("QUICK_TCF", cle, anon, null));
        Creee rejeu = creer(creation("QUICK_TCF", cle, anon, null));

        assertThat(rejeu.id()).isEqualTo(premiere.id());
        assertThat(rejeu.created()).isFalse();
        assertThat(rejeu.token()).isNotEqualTo(premiere.token());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM diagnostic_run WHERE anonymous_id = ?",
                Long.class, anon)).isEqualTo(1L);
        assertThat(run(premiere.id()).get("claim_token_hash")).isEqualTo(JetonSecret.sha256Hex(rejeu.token()));

        // L'ancien jeton ne prouve plus rien.
        mvc.perform(soumission(premiere.id(), premiere.token())).andExpect(status().isNotFound());

        // La meme cle sous un AUTRE identifiant ne resout jamais vers la run d'un tiers.
        Creee autre = creer(creation("QUICK_TCF", cle, UUID.randomUUID(), null));
        assertThat(autre.id()).isNotEqualTo(premiere.id());
        assertThat(autre.created()).isTrue();
    }

    @Test
    @DisplayName("Une clientKey rejouée pour un autre type est un conflit, pas une seconde run")
    void cleRejoueeAutreType() throws Exception {
        UUID anon = UUID.randomUUID();
        UUID cle = UUID.randomUUID();
        creer(creation("QUICK_TCF", cle, anon, null));
        mvc.perform(creation("CIVIQUE", cle, anon, null)).andExpect(status().isConflict());
    }

    @Test
    @DisplayName("Type inconnu ⇒ 400 ; diagnostic complet sans compte ⇒ 403")
    void creationsRefusees() throws Exception {
        mvc.perform(creation("RAPIDE", UUID.randomUUID(), UUID.randomUUID(), null))
                .andExpect(status().isBadRequest());
        mvc.perform(creation("FULL_TCF", UUID.randomUUID(), UUID.randomUUID(), null))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Appelant connecté : le porteur est posé dès la création")
    void creationConnectee() throws Exception {
        User user = testData.user();
        em.flush();
        Creee c = creer(creation("QUICK_TCF", UUID.randomUUID(), UUID.randomUUID(), null)
                .header("Authorization", auth.bearer(user)));
        assertThat(run(c.id()).get("user_id")).isEqualTo(user.getId());
    }

    // ------------------------------------------------------------------------
    // « Soumis »
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("« Soumis » une seule fois : le second appel ne redate rien")
    void soumisUneSeuleFois() throws Exception {
        Creee c = creerInvite("QUICK_TCF", UUID.randomUUID());

        mvc.perform(soumission(c.id(), c.token())).andExpect(status().isNoContent());
        Object premier = run(c.id()).get("submitted_at");
        assertThat(premier).isNotNull();
        assertThat(run(c.id()).get("submitted_authenticated")).isEqualTo(false);

        mvc.perform(soumission(c.id(), c.token())).andExpect(status().isNoContent());
        assertThat(run(c.id()).get("submitted_at")).isEqualTo(premier);
    }

    @Test
    @DisplayName("« Soumis » : run absente, jeton faux ou absent ⇒ 404, rien d'écrit")
    void soumisRefuse() throws Exception {
        mvc.perform(soumission(UUID.randomUUID(), "x")).andExpect(status().isNotFound());

        Creee c = creerInvite("QUICK_TCF", UUID.randomUUID());
        mvc.perform(soumission(c.id(), "pas-le-bon-jeton")).andExpect(status().isNotFound());
        mvc.perform(soumission(c.id(), null)).andExpect(status().isNotFound());
        assertThat(run(c.id()).get("submitted_at")).isNull();
    }

    @Test
    @DisplayName("« Soumis » : le runId d'un tiers ne s'écrit ni avec un autre compte ni avec un autre jeton")
    void soumisRunDUnTiers() throws Exception {
        User proprietaire = testData.user();
        User intrus = testData.user();
        em.flush();
        Creee duProprietaire = creer(creation("QUICK_TCF", UUID.randomUUID(), UUID.randomUUID(), null)
                .header("Authorization", auth.bearer(proprietaire)));
        Creee autreRun = creerInvite("QUICK_TCF", UUID.randomUUID());

        mvc.perform(soumission(duProprietaire.id(), null).header("Authorization", auth.bearer(intrus)))
                .andExpect(status().isNotFound());
        mvc.perform(soumission(duProprietaire.id(), autreRun.token())).andExpect(status().isNotFound());
        // Le jeton de la run, mais depuis un autre identifiant de mesure.
        UUID anon = UUID.randomUUID();
        Creee invite = creerInvite("QUICK_TCF", anon);
        mvc.perform(soumission(invite.id(), invite.token())
                        .header(ClientContextResolver.HEADER_ANONYMOUS_ID, UUID.randomUUID().toString()))
                .andExpect(status().isNotFound());
        assertThat(run(duProprietaire.id()).get("submitted_at")).isNull();
        assertThat(run(invite.id()).get("submitted_at")).isNull();
    }

    @Test
    @DisplayName("« Soumis » d'un civique ou d'un complet : 409, le serveur en est l'autorité")
    void soumisCiviqueRefuse() throws Exception {
        Creee c = creerInvite("CIVIQUE", UUID.randomUUID());
        mvc.perform(soumission(c.id(), c.token())).andExpect(status().isConflict());
        assertThat(run(c.id()).get("submitted_at")).isNull();
    }

    /** Scenario 6 : deja connecte ⇒ « deja connecte », jamais une inscription. */
    @Test
    @DisplayName("Scénario 6 — déjà connecté : soumis connecté, rattaché sans claim")
    void scenario6DejaConnecte() throws Exception {
        User user = testData.user();
        em.flush();
        Creee c = creer(creation("QUICK_TCF", UUID.randomUUID(), UUID.randomUUID(), null)
                .header("Authorization", auth.bearer(user)));

        mvc.perform(soumission(c.id(), null).header("Authorization", auth.bearer(user)))
                .andExpect(status().isNoContent());

        Map<String, Object> row = run(c.id());
        assertThat(row.get("submitted_authenticated")).isEqualTo(true);
        assertThat(row.get("user_id")).isEqualTo(user.getId());
        assertThat(row.get("claimed_at")).isNull();
        assertThat(row.get("claim_kind")).isNull();
    }

    // ------------------------------------------------------------------------
    // Claim et contexte d'inscription
    // ------------------------------------------------------------------------

    /** Scenario 3. */
    @Test
    @DisplayName("Scénario 3 — diagnostic anonyme puis inscription même appareil : AFTER_DIAGNOSTIC, claim SIGNUP")
    void scenario3InscritApresDiagnostic() throws Exception {
        UUID anon = UUID.randomUUID();
        Creee c = creerInvite("QUICK_TCF", anon);
        mvc.perform(soumission(c.id(), c.token())).andExpect(status().isNoContent());

        String email = "scenario3@test.sejourfr";
        inscrire(email, c.id(), c.token(), anon);

        User user = relire(email);
        assertThat(user.getSignupContext()).hasToString("AFTER_DIAGNOSTIC");
        assertThat(user.getSignupDiagnosticType()).hasToString("QUICK_TCF");
        assertThat(user.getSignupDiagnosticRunId()).isEqualTo(c.id());
        assertThat(user.getSignupPlatform()).hasToString("IOS");
        assertThat(user.getSignupAnonymousId()).isEqualTo(anon);

        Map<String, Object> row = run(c.id());
        assertThat(row.get("user_id")).isEqualTo(user.getId());
        assertThat(row.get("claim_kind")).isEqualTo("SIGNUP");
        assertThat(row.get("claimed_via")).isEqualTo("SAME_DEVICE");
        assertThat(row.get("claimed_at")).isNotNull();
        // Soumis AVANT le compte : il reste un soumis anonyme.
        assertThat(row.get("submitted_authenticated")).isEqualTo(false);
    }

    /** Scenario 5 : sans jeton, aucune recherche par anonymous_id. */
    @Test
    @DisplayName("Scénario 5 — inscription sans jeton : OUTSIDE_DIAGNOSTIC, run jamais rattachée")
    void scenario5SansJeton() throws Exception {
        UUID anon = UUID.randomUUID();
        Creee c = creerInvite("QUICK_TCF", anon);
        mvc.perform(soumission(c.id(), c.token())).andExpect(status().isNoContent());

        String email = "scenario5@test.sejourfr";
        // Meme identifiant de mesure que la run : ce n'est PAS une preuve.
        inscrire(email, null, null, anon);

        User user = relire(email);
        assertThat(user.getSignupContext()).hasToString("OUTSIDE_DIAGNOSTIC");
        assertThat(user.getSignupDiagnosticType()).isNull();
        assertThat(user.getSignupDiagnosticRunId()).isNull();
        assertThat(run(c.id()).get("user_id")).isNull();
        assertThat(run(c.id()).get("claimed_at")).isNull();
        // Compte « soumis anonymes jamais rattaches ».
        assertThat(jdbc.queryForObject("SELECT count(*) FROM diagnostic_run WHERE id = ? "
                + "AND submitted_at IS NOT NULL AND user_id IS NULL", Long.class, c.id())).isEqualTo(1L);
    }

    /** Scenario 20. */
    @Test
    @DisplayName("Scénario 20 — runId valide, jeton absent ou faux : pas de claim, l'inscription réussit")
    void scenario20JetonAbsentOuFaux() throws Exception {
        Creee c = creerInvite("QUICK_TCF", UUID.randomUUID());
        mvc.perform(soumission(c.id(), c.token())).andExpect(status().isNoContent());

        inscrire("scenario20a@test.sejourfr", c.id(), null, null);
        inscrire("scenario20b@test.sejourfr", c.id(), "faux-jeton", null);
        // Identifiant illisible : jamais un 400 d'auth.
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content(inscription("scenario20c@test.sejourfr", null, c.token())
                                .replace("}", ",\"diagnosticRunId\":\"pas-un-uuid\"}")))
                .andExpect(status().isOk());

        assertThat(relire("scenario20a@test.sejourfr").getSignupContext()).hasToString("OUTSIDE_DIAGNOSTIC");
        assertThat(relire("scenario20b@test.sejourfr").getSignupContext()).hasToString("OUTSIDE_DIAGNOSTIC");
        assertThat(run(c.id()).get("claimed_at")).isNull();
        assertThat(run(c.id()).get("user_id")).isNull();
    }

    @Test
    @DisplayName("Jeton expiré : pas de claim")
    void jetonExpire() throws Exception {
        Creee c = creerInvite("QUICK_TCF", UUID.randomUUID());
        mvc.perform(soumission(c.id(), c.token())).andExpect(status().isNoContent());
        jdbc.update("UPDATE diagnostic_run SET claim_token_expires_at = now() - interval '1 minute' WHERE id = ?",
                c.id());

        inscrire("expire@test.sejourfr", c.id(), c.token(), null);

        assertThat(relire("expire@test.sejourfr").getSignupContext()).hasToString("OUTSIDE_DIAGNOSTIC");
        assertThat(run(c.id()).get("claimed_at")).isNull();
    }

    @Test
    @DisplayName("Jeton déjà utilisé : la run reste au premier compte")
    void jetonDejaClaime() throws Exception {
        Creee c = creerInvite("QUICK_TCF", UUID.randomUUID());
        mvc.perform(soumission(c.id(), c.token())).andExpect(status().isNoContent());
        inscrire("premier@test.sejourfr", c.id(), c.token(), null);
        User premier = relire("premier@test.sejourfr");

        User autre = testData.user();
        connecter(autre, c.id(), c.token());

        Map<String, Object> row = run(c.id());
        assertThat(row.get("user_id")).isEqualTo(premier.getId());
        assertThat(row.get("claim_kind")).isEqualTo("SIGNUP");
    }

    @Test
    @DisplayName("Run claimée mais jamais soumise : rattachée, et l'inscription reste OUTSIDE_DIAGNOSTIC")
    void claimSansSoumission() throws Exception {
        Creee c = creerInvite("QUICK_TCF", UUID.randomUUID());
        inscrire("nonsoumis@test.sejourfr", c.id(), c.token(), null);

        User user = relire("nonsoumis@test.sejourfr");
        assertThat(user.getSignupContext()).hasToString("OUTSIDE_DIAGNOSTIC");
        assertThat(run(c.id()).get("claim_kind")).isEqualTo("SIGNUP");
        assertThat(run(c.id()).get("user_id")).isEqualTo(user.getId());
    }

    // ------------------------------------------------------------------------
    // Civique : rattachement de session et « soumis » serveur
    // ------------------------------------------------------------------------

    /** Scenario 7, sur le parcours civique reel. */
    @Test
    @DisplayName("Scénario 7 — compte existant déconnecté, civique invité, connexion : claim LOGIN, pas d'inscription")
    void scenario7ConnecteApresDiagnostic() throws Exception {
        User user = testData.user();
        em.flush();
        UUID anon = UUID.randomUUID();
        UUID[] civique = civiqueInvite();
        Creee c = creer(creation("CIVIQUE", UUID.randomUUID(), anon, civique[0]));
        assertThat(run(c.id()).get("civic_diagnostic_session_id")).isEqualTo(civique[0]);

        finirInvite(civique[1]);
        assertThat(run(c.id()).get("submitted_at")).isNotNull();
        assertThat(run(c.id()).get("submitted_authenticated")).isEqualTo(false);

        connecter(user, c.id(), c.token());

        Map<String, Object> row = run(c.id());
        assertThat(row.get("claim_kind")).isEqualTo("LOGIN");
        assertThat(row.get("user_id")).isEqualTo(user.getId());
        // Une connexion n'est pas une inscription : le contexte du compte ne bouge pas.
        assertThat(relire(user.getEmail()).getSignupContext()).isNull();

        // L'adoption du contenu reste le geste d'aujourd'hui, inchange.
        mvc.perform(depuis(post("/api/civic-diagnostics/" + civique[0] + "/adopt"), IP)
                        .header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Compte ayant déjà son diagnostic civique : la run est claimée, le contenu refusé comme avant")
    void compteAyantDejaSonDiagnostic() throws Exception {
        User user = testData.user();
        em.flush();
        mvc.perform(post("/api/civic-diagnostics").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk());

        UUID[] civique = civiqueInvite();
        Creee c = creer(creation("CIVIQUE", UUID.randomUUID(), UUID.randomUUID(), civique[0]));
        finirInvite(civique[1]);
        connecter(user, c.id(), c.token());

        assertThat(run(c.id()).get("claim_kind")).isEqualTo("LOGIN");
        mvc.perform(depuis(post("/api/civic-diagnostics/" + civique[0] + "/adopt"), IP)
                        .header("Authorization", auth.bearer(user)))
                .andExpect(status().isUnprocessableEntity());
        assertThat(run(c.id()).get("user_id")).isEqualTo(user.getId());
    }

    @Test
    @DisplayName("Session civique d'une autre IP : 404, aucune run créée")
    void sessionCiviqueDUnTiers() throws Exception {
        UUID[] civique = civiqueInvite();
        UUID anon = UUID.randomUUID();
        mvc.perform(depuis(creation("CIVIQUE", UUID.randomUUID(), anon, civique[0]), AUTRE_IP))
                .andExpect(status().isNotFound());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM diagnostic_run WHERE anonymous_id = ?",
                Long.class, anon)).isZero();
    }

    @Test
    @DisplayName("Session déjà tracée : une seconde création rend la même run")
    void sessionDejaTracee() throws Exception {
        UUID[] civique = civiqueInvite();
        Creee premiere = creer(creation("CIVIQUE", UUID.randomUUID(), UUID.randomUUID(), civique[0]));
        Creee seconde = creer(creation("CIVIQUE", UUID.randomUUID(), UUID.randomUUID(), civique[0]));
        assertThat(seconde.id()).isEqualTo(premiere.id());
        assertThat(seconde.created()).isFalse();
    }

    @Test
    @DisplayName("Civique connecté : « soumis » connecté à la fin de l'attempt")
    void civiqueConnecte() throws Exception {
        User user = testData.user();
        em.flush();
        String json = mvc.perform(post("/api/civic-diagnostics").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        UUID sessionId = UUID.fromString(JsonPath.read(json, "$.sessionId"));
        UUID attemptId = UUID.fromString(JsonPath.read(json, "$.attemptId"));

        Creee c = creer(creation("CIVIQUE", UUID.randomUUID(), UUID.randomUUID(), sessionId)
                .header("Authorization", auth.bearer(user)));
        mvc.perform(post("/api/attempts/" + attemptId + "/finish").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk());

        Map<String, Object> row = run(c.id());
        assertThat(row.get("submitted_authenticated")).isEqualTo(true);
        assertThat(row.get("user_id")).isEqualTo(user.getId());
    }

    /** Scenario 16, sur le civique (Q2 : le TCF rapide ne se refait pas). */
    @Test
    @DisplayName("Scénario 16 — civique refait 3 fois : 3 soumissions brutes, 1 personne")
    void scenario16CiviqueRefait() throws Exception {
        UUID anon = UUID.randomUUID();
        for (int i = 0; i < 3; i++) {
            UUID[] civique = civiqueInvite();
            creer(creation("CIVIQUE", UUID.randomUUID(), anon, civique[0]));
            finirInvite(civique[1]);
        }

        assertThat(jdbc.queryForObject("SELECT count(*) FROM diagnostic_run WHERE anonymous_id = ? "
                + "AND submitted_at IS NOT NULL", Long.class, anon)).isEqualTo(3L);
        assertThat(jdbc.queryForObject("SELECT count(DISTINCT COALESCE(user_id, anonymous_id)) "
                + "FROM diagnostic_run WHERE anonymous_id = ?", Long.class, anon)).isEqualTo(1L);
    }

    // ------------------------------------------------------------------------
    // TCF complet : cloture (le handoff du TCF rapide : DiagnosticRunQuickTcfHandoffIT)
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Diagnostic complet : run liée à l'ouverture, « soumis » connecté à la clôture")
    void diagnosticComplet() throws Exception {
        User user = testData.user();
        em.flush();
        String json = mvc.perform(post("/api/tcf-diagnostics").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        UUID sessionId = UUID.fromString(JsonPath.read(json, "$.sessionId"));

        Creee c = creer(creation("FULL_TCF", UUID.randomUUID(), UUID.randomUUID(), sessionId)
                .header("Authorization", auth.bearer(user)));
        assertThat(run(c.id()).get("tcf_diagnostic_session_id")).isEqualTo(sessionId);
        assertThat(run(c.id()).get("submitted_at")).isNull();

        mvc.perform(post("/api/tcf-diagnostics/" + sessionId + "/result").header("Authorization", auth.bearer(user)))
                .andExpect(status().isOk());

        Map<String, Object> row = run(c.id());
        assertThat(row.get("submitted_at")).isNotNull();
        assertThat(row.get("submitted_authenticated")).isEqualTo(true);
    }
}
