package com.sejourfr.app.controller;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.AiEvaluationFlag;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.MotifSignalement;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.repository.AiEvaluationFlagRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Signalement d'une évaluation IA (V085, F-3 A) : création, doublon, vérifier,
 * retirer (soft), filtres de la liste, et AUCUN effet sur l'évaluation ni sur
 * ce que voit le candidat. Les 403 USER sont dans {@code AdminRoutesSecurityIT}.
 */
class AdminProductionFlagIT extends AbstractIntegrationTest {

    private static final String URL = "/api/admin/productions";

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData testData;
    @Autowired private AuthTestSupport auth;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private EntityManager entityManager;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private AiEvaluationManager aiEvaluationManager;
    @Autowired private UserManager userManager;
    @Autowired private AiEvaluationFlagRepository flagRepository;

    private AdminProductionFixtures fx;
    private User admin;
    private String bearer;

    @BeforeEach
    void setUp() {
        fx = new AdminProductionFixtures(testData, submissionManager, aiEvaluationManager, userManager);
        admin = testData.admin();
        admin.setFirstName("Ada");
        admin.setLastName("Lovelace");
        userManager.save(admin);
        bearer = auth.bearer(admin);
    }

    private ProductionSubmission evaluee(String prefixe) {
        ProductionSubmission s = fx.production(fx.candidat(prefixe), EpreuveType.TCF_EE, 2,
                SubmissionStatut.EVALUATED, Instant.now());
        fx.evaluationV15(s, NiveauCecrl.B1);
        return s;
    }

    private JsonNode post200(String path, int attendu, String body) throws Exception {
        var req = post(path).header(HttpHeaders.AUTHORIZATION, bearer);
        if (body != null) req = req.contentType(MediaType.APPLICATION_JSON).content(body);
        String out = mockMvc.perform(req).andExpect(status().is(attendu))
                .andReturn().getResponse().getContentAsString();
        return out.isEmpty() ? null : objectMapper.readTree(out);
    }

    private JsonNode signaler(UUID submissionId, String motif, String commentaire, int attendu) throws Exception {
        String body = commentaire == null
                ? "{\"motif\":\"" + motif + "\"}"
                : "{\"motif\":\"" + motif + "\",\"commentaire\":\"" + commentaire + "\"}";
        return post200(URL + "/" + submissionId + "/flags", attendu, body);
    }

    private JsonNode detail(UUID submissionId) throws Exception {
        String out = mockMvc.perform(get(URL + "/" + submissionId).header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(out);
    }

    private List<String> ids(String... params) throws Exception {
        var req = get(URL).header(HttpHeaders.AUTHORIZATION, bearer).param("q", fx.jeton);
        for (int i = 0; i < params.length; i += 2) req = req.param(params[i], params[i + 1]);
        JsonNode page = objectMapper.readTree(mockMvc.perform(req).andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        List<String> ids = new ArrayList<>();
        page.get("content").forEach(n -> ids.add(n.get("id").asString()));
        return ids;
    }

    @Test
    void creer_un_signalement_201_visible_dans_la_fiche_et_la_liste() throws Exception {
        ProductionSubmission s = evaluee("creer");

        JsonNode flag = signaler(s.getId(), "NIVEAU_INCOHERENT", "B1 généreux", 201);

        assertThat(flag.get("motif").asString()).isEqualTo("NIVEAU_INCOHERENT");
        assertThat(flag.get("motifLabel").asString()).isEqualTo("Niveau incohérent");
        assertThat(flag.get("commentaire").asString()).isEqualTo("B1 généreux");
        assertThat(flag.get("etat").asString()).isEqualTo("SIGNALE");
        assertThat(flag.at("/createdBy/email").asString()).isEqualTo(admin.getEmail());
        assertThat(flag.at("/createdBy/nom").asString()).isEqualTo("Ada Lovelace");
        assertThat(flag.get("verifiedAt").isNull()).isTrue();

        JsonNode d = detail(s.getId());
        assertThat(d.at("/entete/etatSignalement").asString()).isEqualTo("SIGNALE");
        assertThat(d.get("signalements")).hasSize(1);
        assertThat(d.get("signalable").asBoolean()).isFalse();
    }

    @Test
    void motif_obligatoire_doublon_409_sans_evaluation_422_production_inconnue_404() throws Exception {
        ProductionSubmission s = evaluee("refus");
        post200(URL + "/" + s.getId() + "/flags", 400, "{\"commentaire\":\"sans motif\"}");
        post200(URL + "/" + s.getId() + "/flags", 400, "{\"motif\":\"PAS_UN_MOTIF\"}");
        post200(URL + "/" + s.getId() + "/flags", 400,
                "{\"motif\":\"AUTRE\",\"commentaire\":\"" + "x".repeat(1001) + "\"}");

        signaler(s.getId(), "AUTRE", null, 201);
        signaler(s.getId(), "SCORE_INCOHERENT", null, 409);

        ProductionSubmission echec = fx.production(fx.candidat("echec"), EpreuveType.TCF_EE, 1,
                SubmissionStatut.FAILED, Instant.now());
        signaler(echec.getId(), "AUTRE", null, 422);
        signaler(UUID.randomUUID(), "AUTRE", null, 404);
        post200(URL + "/flags/" + UUID.randomUUID() + "/verify", 404, null);
        post200(URL + "/flags/" + UUID.randomUUID() + "/remove", 404, null);
    }

    @Test
    void une_production_non_evaluable_peut_etre_signalee() throws Exception {
        ProductionSubmission s = fx.production(fx.candidat("vide"), EpreuveType.TCF_EO, 1,
                SubmissionStatut.EVALUATED, Instant.now());
        fx.nonEvaluable(s);

        JsonNode flag = signaler(s.getId(), "TRANSCRIPTION", "Le candidat a parlé", 201);

        assertThat(flag.get("motifLabel").asString()).isEqualTo("Problème de transcription");
    }

    @Test
    void verifier_puis_retirer_historique_conserve_et_nouveau_signalement_possible() throws Exception {
        ProductionSubmission s = evaluee("cycle");
        String flagId = signaler(s.getId(), "FEEDBACK_INCORRECT", null, 201).get("id").asString();

        JsonNode verifie = post200(URL + "/flags/" + flagId + "/verify", 200, null);
        assertThat(verifie.get("etat").asString()).isEqualTo("VERIFIE");
        assertThat(verifie.at("/verifiedBy/email").asString()).isEqualTo(admin.getEmail());
        String verifiedAt = verifie.get("verifiedAt").asString();
        // Idempotent : re-vérifier ne change rien.
        assertThat(post200(URL + "/flags/" + flagId + "/verify", 200, null).get("verifiedAt").asString())
                .isEqualTo(verifiedAt);
        assertThat(detail(s.getId()).at("/entete/etatSignalement").asString()).isEqualTo("VERIFIE");

        JsonNode retire = post200(URL + "/flags/" + flagId + "/remove", 200, null);
        assertThat(retire.get("etat").asString()).isEqualTo("RETIRE");
        assertThat(retire.at("/removedBy/email").asString()).isEqualTo(admin.getEmail());
        // Retirer est idempotent ; vérifier un signalement retiré est un conflit.
        post200(URL + "/flags/" + flagId + "/remove", 200, null);
        post200(URL + "/flags/" + flagId + "/verify", 409, null);

        JsonNode d = detail(s.getId());
        assertThat(d.at("/entete/etatSignalement").asString()).isEqualTo("AUCUN");
        assertThat(d.get("signalements")).hasSize(1);
        assertThat(d.at("/signalements/0/etat").asString()).isEqualTo("RETIRE");
        assertThat(d.get("signalable").asBoolean()).isTrue();
        assertThat(flagRepository.findById(UUID.fromString(flagId))).isPresent();

        signaler(s.getId(), "AUTRE", "Second regard", 201);
        assertThat(detail(s.getId()).get("signalements")).hasSize(2);
    }

    /** SIGNALEES = actif non vérifié ; VERIFIEES = actif vérifié ; retiré = non signalée. */
    @Test
    void filtres_de_signalement() throws Exception {
        ProductionSubmission signalee = evaluee("f1");
        ProductionSubmission verifiee = evaluee("f2");
        ProductionSubmission retiree = evaluee("f3");
        ProductionSubmission jamais = evaluee("f4");
        signaler(signalee.getId(), "AUTRE", null, 201);
        String v = signaler(verifiee.getId(), "AUTRE", null, 201).get("id").asString();
        post200(URL + "/flags/" + v + "/verify", 200, null);
        String r = signaler(retiree.getId(), "AUTRE", null, 201).get("id").asString();
        post200(URL + "/flags/" + r + "/remove", 200, null);

        assertThat(ids("signalement", "SIGNALEES")).containsExactly(signalee.getId().toString());
        assertThat(ids("signalement", "VERIFIEES")).containsExactly(verifiee.getId().toString());
        assertThat(ids("signalement", "NON_SIGNALEES"))
                .containsExactlyInAnyOrder(retiree.getId().toString(), jamais.getId().toString());
        assertThat(ids()).hasSize(4);
        mockMvc.perform(get(URL).header(HttpHeaders.AUTHORIZATION, bearer).param("signalement", "TOUTES"))
                .andExpect(status().isBadRequest());
    }

    /** 🛑 Un signalement ne modifie JAMAIS l'évaluation ni ce que voit le candidat. */
    @Test
    void aucun_effet_sur_l_evaluation_ni_sur_la_vue_candidat() throws Exception {
        User candidat = fx.candidat("effet");
        ProductionSubmission s = fx.production(candidat, EpreuveType.TCF_EE, 2, SubmissionStatut.EVALUATED,
                Instant.now());
        AiEvaluation e = fx.evaluationV15(s, NiveauCecrl.B1);
        entityManager.flush();
        Object[] avant = ligneEvaluation(e.getId());
        String vueAvant = vueCandidat(s, candidat);

        String flagId = signaler(s.getId(), "NIVEAU_INCOHERENT", "à revoir", 201).get("id").asString();
        post200(URL + "/flags/" + flagId + "/verify", 200, null);
        post200(URL + "/flags/" + flagId + "/remove", 200, null);
        entityManager.flush();
        entityManager.clear();

        assertThat(ligneEvaluation(e.getId())).containsExactly(avant);
        assertThat(objectMapper.readTree(vueCandidat(s, candidat)).get("evaluation"))
                .isEqualTo(objectMapper.readTree(vueAvant).get("evaluation"));
        assertThat(aiEvaluationManager.countBySubmissionId(s.getId())).isEqualTo(1);
    }

    @Test
    void un_seul_signalement_actif_par_evaluation_tenu_par_la_base() {
        ProductionSubmission s = evaluee("index");
        AiEvaluation e = aiEvaluationManager.findLatestBySubmissionId(s.getId()).orElseThrow();
        flagRepository.saveAndFlush(flag(e, s));

        assertThatThrownBy(() -> flagRepository.saveAndFlush(flag(e, s)))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private AiEvaluationFlag flag(AiEvaluation e, ProductionSubmission s) {
        AiEvaluationFlag f = new AiEvaluationFlag();
        f.setEvaluationId(e.getId());
        f.setSubmissionId(s.getId());
        f.setMotif(MotifSignalement.AUTRE);
        f.setCreatedBy(admin.getId());
        return f;
    }

    private Object[] ligneEvaluation(UUID evaluationId) {
        return (Object[]) entityManager.createNativeQuery("""
                        SELECT note_sur_20, niveau_cecrl, niveau_cecrl_ia, evaluabilite,
                               CAST(feedback_json AS text), evaluated_at
                          FROM ai_evaluations WHERE id = :id""")
                .setParameter("id", evaluationId).getSingleResult();
    }

    private String vueCandidat(ProductionSubmission s, User candidat) throws Exception {
        return mockMvc.perform(get("/api/production-submissions/" + s.getId())
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(candidat)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
    }
}
