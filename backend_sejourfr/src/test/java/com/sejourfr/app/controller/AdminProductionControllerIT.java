package com.sejourfr.app.controller;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AdminProductionAnnotationFiltre;
import com.sejourfr.app.enums.AdminProductionNiveauFiltre;
import com.sejourfr.app.enums.AdminProductionPeriode;
import com.sejourfr.app.enums.AdminProductionStatutIa;
import com.sejourfr.app.enums.AdminProductionTri;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.adminproduction.AdminProductionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.FenetreMesure;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contrat de {@code GET /api/admin/productions} et
 * {@code GET /api/admin/productions/{id}} : périmètre (EE/EO complètes, hors
 * diagnostic), tri par défaut stable, pagination serveur, chaque filtre et
 * leur combinaison, recherche, fiche (calcul, vue candidat, technique) et
 * lecture passive. Les droits (401/403) sont dans {@code AdminRoutesSecurityIT}.
 */
class AdminProductionControllerIT extends AbstractIntegrationTest {

    private static final String URL = "/api/admin/productions";

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData testData;
    @Autowired private AuthTestSupport auth;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private EntityManager entityManager;
    @Autowired private AdminProductionService service;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private AiEvaluationManager aiEvaluationManager;
    @Autowired private TranscriptionManager transcriptionManager;
    @Autowired private UserManager userManager;

    private AdminProductionFixtures fx;
    private String bearer;

    @BeforeEach
    void setUp() {
        fx = new AdminProductionFixtures(testData, submissionManager, aiEvaluationManager, userManager);
        bearer = auth.bearer(testData.admin());
    }

    private JsonNode get200(String path, String... params) throws Exception {
        var req = get(path).header(HttpHeaders.AUTHORIZATION, bearer);
        for (int i = 0; i < params.length; i += 2) req = req.param(params[i], params[i + 1]);
        String body = mockMvc.perform(req).andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body);
    }

    private JsonNode list(String... params) throws Exception {
        String[] all = new String[params.length + 2];
        all[0] = "q";
        all[1] = fx.jeton;
        System.arraycopy(params, 0, all, 2, params.length);
        return get200(URL, all);
    }

    private static List<String> ids(JsonNode page) {
        List<String> ids = new ArrayList<>();
        page.get("content").forEach(n -> ids.add(n.get("id").asString()));
        return ids;
    }

    private List<UUID> idsService(AdminProductionService.Filtres f) {
        return service.list(f, AdminProductionTri.DATE_DESC, 0, 100).content().stream()
                .map(d -> d.id()).toList();
    }

    private AdminProductionService.Filtres filtres() {
        return new AdminProductionService.Filtres(fx.jeton, null, null, null, null, null, null, null, null, null, false);
    }

    // ------------------------------------------------------------------ liste

    @Test
    void tri_par_defaut_plus_recentes_d_abord_et_stable_a_date_egale() throws Exception {
        User u = fx.candidat("tri");
        Instant t = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        ProductionSubmission recente = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, t.minusSeconds(60));
        ProductionSubmission a = fx.production(u, EpreuveType.TCF_EE, 2, SubmissionStatut.EVALUATED, t.minusSeconds(600));
        ProductionSubmission b = fx.production(u, EpreuveType.TCF_EO, 1, SubmissionStatut.EVALUATED, t.minusSeconds(600));
        // Postgres ordonne les uuid octet par octet = ordre de la forme hexadécimale.
        List<String> egales = new ArrayList<>(List.of(a.getId().toString(), b.getId().toString()));
        egales.sort(java.util.Comparator.reverseOrder());

        JsonNode page = list();

        assertThat(ids(page)).containsExactly(recente.getId().toString(), egales.get(0), egales.get(1));
        assertThat(page.get("size").asInt()).isEqualTo(25);
        assertThat(page.get("page").asInt()).isZero();
        assertThat(page.get("totalElements").asLong()).isEqualTo(3);
    }

    @Test
    void pagination_serveur_et_bornes_de_taille() throws Exception {
        User u = fx.candidat("page");
        Instant t = Instant.now();
        for (int i = 0; i < 5; i++) {
            fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, t.minusSeconds(i * 60L));
        }

        JsonNode p1 = list("size", "2", "page", "1");
        assertThat(ids(p1)).hasSize(2);
        assertThat(p1.get("totalElements").asLong()).isEqualTo(5);
        assertThat(p1.get("totalPages").asInt()).isEqualTo(3);
        assertThat(p1.get("first").asBoolean()).isFalse();
        assertThat(p1.get("last").asBoolean()).isFalse();

        JsonNode loin = list("size", "2", "page", "10");
        assertThat(ids(loin)).isEmpty();
        assertThat(loin.get("totalElements").asLong()).isEqualTo(5);

        assertThat(list("size", "500").get("size").asInt()).isEqualTo(100);
        assertThat(list("size", "0").get("size").asInt()).isEqualTo(1);
        assertThat(list("page", "-3").get("page").asInt()).isZero();
    }

    @Test
    void filtres_type_tache_niveau_statut_et_combinaison() {
        User u = fx.candidat("filtres");
        Instant t = Instant.now();
        ProductionSubmission eeB1 = fx.production(u, EpreuveType.TCF_EE, 2, SubmissionStatut.EVALUATED, t);
        fx.evaluationV15(eeB1, NiveauCecrl.B1);
        ProductionSubmission eoA2 = fx.production(u, EpreuveType.TCF_EO, 2, SubmissionStatut.EVALUATED, t.minusSeconds(1));
        fx.evaluation(eoA2, NiveauCecrl.A2, NiveauCecrl.A2, "v15", 4, 4, 4, 4);
        ProductionSubmission nonEval = fx.production(u, EpreuveType.TCF_EO, 1, SubmissionStatut.EVALUATED, t.minusSeconds(2));
        fx.nonEvaluable(nonEval);
        ProductionSubmission echec = fx.production(u, EpreuveType.TCF_EE, 3, SubmissionStatut.FAILED, t.minusSeconds(3));
        ProductionSubmission enCours = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATING, t.minusSeconds(4));

        AdminProductionService.Filtres base = filtres();
        assertThat(idsService(base)).hasSize(5);
        assertThat(idsService(with(base, EpreuveType.TCF_EO, null, null, null)))
                .containsExactlyInAnyOrder(eoA2.getId(), nonEval.getId());
        assertThat(idsService(with(base, null, 2, null, null)))
                .containsExactlyInAnyOrder(eeB1.getId(), eoA2.getId());
        assertThat(idsService(with(base, null, null, AdminProductionNiveauFiltre.B1, null)))
                .containsExactly(eeB1.getId());
        // null = inconnu, jamais A1 : non évaluable, échec et en cours n'ont AUCUN niveau.
        assertThat(idsService(with(base, null, null, AdminProductionNiveauFiltre.SANS_NIVEAU, null)))
                .containsExactlyInAnyOrder(nonEval.getId(), echec.getId(), enCours.getId());
        assertThat(idsService(with(base, null, null, AdminProductionNiveauFiltre.A1, null))).isEmpty();
        assertThat(idsService(with(base, null, null, null, AdminProductionStatutIa.EVALUEE)))
                .containsExactlyInAnyOrder(eeB1.getId(), eoA2.getId());
        assertThat(idsService(with(base, null, null, null, AdminProductionStatutIa.NON_EVALUABLE)))
                .containsExactly(nonEval.getId());
        assertThat(idsService(with(base, null, null, null, AdminProductionStatutIa.ECHEC)))
                .containsExactly(echec.getId());
        assertThat(idsService(with(base, null, null, null, AdminProductionStatutIa.EN_COURS)))
                .containsExactly(enCours.getId());
        assertThat(idsService(with(base, EpreuveType.TCF_EO, 2, AdminProductionNiveauFiltre.A2,
                AdminProductionStatutIa.EVALUEE))).containsExactly(eoA2.getId());
        assertThat(idsService(with(base, EpreuveType.TCF_EE, 2, AdminProductionNiveauFiltre.A2, null))).isEmpty();
    }

    private static AdminProductionService.Filtres with(AdminProductionService.Filtres f, EpreuveType epreuve,
                                                       Integer tache, AdminProductionNiveauFiltre niveau,
                                                       AdminProductionStatutIa statut) {
        return new AdminProductionService.Filtres(f.q(), epreuve, tache, niveau, statut, f.signalement(),
                f.annotation(), f.periode(), f.from(), f.to(), f.includeInternal());
    }

    @Test
    void filtre_de_periode_en_jours_de_paris() throws Exception {
        User u = fx.candidat("periode");
        Instant now = Instant.now();
        ProductionSubmission auj = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, now);
        ProductionSubmission dixJours = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED,
                now.minus(10, ChronoUnit.DAYS));
        fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, now.minus(40, ChronoUnit.DAYS));

        assertThat(ids(list("periode", "TODAY"))).containsExactly(auj.getId().toString());
        assertThat(ids(list("periode", "LAST_7_DAYS"))).containsExactly(auj.getId().toString());
        assertThat(ids(list("periode", "LAST_30_DAYS")))
                .containsExactly(auj.getId().toString(), dixJours.getId().toString());
        LocalDate jour = LocalDate.ofInstant(now.minus(10, ChronoUnit.DAYS), FenetreMesure.PARIS);
        assertThat(ids(list("from", jour.toString(), "to", jour.toString())))
                .containsExactly(dixJours.getId().toString());
        assertThat(ids(list())).hasSize(3);
    }

    @Test
    void comptes_internes_exclus_par_defaut() throws Exception {
        User externe = fx.candidat("externe");
        User interne = fx.candidatInterne("interne");
        ProductionSubmission pe = fx.production(externe, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, Instant.now());
        ProductionSubmission pi = fx.production(interne, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, Instant.now());

        assertThat(ids(list())).containsExactly(pe.getId().toString());
        JsonNode avec = list("includeInternal", "true");
        assertThat(ids(avec)).containsExactlyInAnyOrder(pe.getId().toString(), pi.getId().toString());
        avec.get("content").forEach(n -> assertThat(n.get("userInternal").asBoolean())
                .isEqualTo(n.get("id").asString().equals(pi.getId().toString())));
    }

    @Test
    void recherche_par_email_id_utilisateur_et_id_production() throws Exception {
        User alice = testData.user("Alice_Martin." + fx.jeton + "@test.sejourfr");
        User bob = testData.user("aliceXmartin." + fx.jeton + "@test.sejourfr");
        ProductionSubmission pa = fx.production(alice, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, Instant.now());
        ProductionSubmission pb = fx.production(bob, EpreuveType.TCF_EO, 1, SubmissionStatut.EVALUATED, Instant.now());

        // « contient », sans casse, et le « _ » saisi n'est pas un joker.
        assertThat(ids(get200(URL, "q", "ALICE_MARTIN." + fx.jeton))).containsExactly(pa.getId().toString());
        assertThat(ids(get200(URL, "q", alice.getId().toString()))).containsExactly(pa.getId().toString());
        assertThat(ids(get200(URL, "q", pb.getId().toString()))).containsExactly(pb.getId().toString());
        assertThat(ids(get200(URL, "q", UUID.randomUUID().toString()))).isEmpty();
    }

    @Test
    void tris_niveau_epreuve_et_date() throws Exception {
        User u = fx.candidat("tris");
        Instant t = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        ProductionSubmission b2 = fx.production(u, EpreuveType.TCF_EO, 1, SubmissionStatut.EVALUATED, t.minusSeconds(10));
        fx.evaluation(b2, NiveauCecrl.B2, NiveauCecrl.B2, "v15", 12, 12, 12, 12);
        ProductionSubmission a2 = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, t.minusSeconds(20));
        fx.evaluation(a2, NiveauCecrl.A2, NiveauCecrl.A2, "v15", 4, 4, 4, 4);
        ProductionSubmission b1 = fx.production(u, EpreuveType.TCF_EO, 2, SubmissionStatut.EVALUATED, t.minusSeconds(30));
        fx.evaluationV15(b1, NiveauCecrl.B1);
        ProductionSubmission sans = fx.production(u, EpreuveType.TCF_EE, 2, SubmissionStatut.FAILED, t);

        String sB2 = b2.getId().toString(), sA2 = a2.getId().toString(), sB1 = b1.getId().toString(),
                sSans = sans.getId().toString();
        assertThat(ids(list("sort", "NIVEAU_DESC"))).containsExactly(sB2, sB1, sA2, sSans);
        assertThat(ids(list("sort", "NIVEAU_ASC"))).containsExactly(sA2, sB1, sB2, sSans);
        assertThat(ids(list("sort", "DATE_ASC"))).containsExactly(sB1, sA2, sB2, sSans);
        assertThat(ids(list("sort", "DATE_DESC"))).containsExactly(sSans, sB2, sA2, sB1);
        // EE avant EO, puis tâche, puis le plus récent.
        assertThat(ids(list("sort", "EPREUVE"))).containsExactly(sA2, sSans, sB2, sB1);
    }

    @Test
    void filtre_annotation_humaine_remplace_les_onglets_de_calibration() {
        User u = fx.candidat("annot");
        ProductionSubmission annotee = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, Instant.now());
        ProductionSubmission vierge = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, Instant.now());
        testData.humanCalibrationNote(annotee, testData.admin());

        AdminProductionService.Filtres f = filtres();
        assertThat(idsService(new AdminProductionService.Filtres(f.q(), null, null, null, null, null,
                AdminProductionAnnotationFiltre.ANNOTEES, null, null, null, false))).containsExactly(annotee.getId());
        assertThat(idsService(new AdminProductionService.Filtres(f.q(), null, null, null, null, null,
                AdminProductionAnnotationFiltre.NON_ANNOTEES, null, null, null, false))).containsExactly(vierge.getId());
    }

    @Test
    void parametres_invalides_400() throws Exception {
        for (String[] p : List.of(
                new String[]{"epreuve", "TCF_CO"},
                new String[]{"epreuve", "INCONNUE"},
                new String[]{"tache", "4"},
                new String[]{"niveau", "C1"},
                new String[]{"statut", "SUCCES"},
                new String[]{"sort", "COUT"},
                new String[]{"from", "2026-09-01"},
                new String[]{"from", "2026-13-01", "to", "2026-13-02"})) {
            var req = get(URL).header(HttpHeaders.AUTHORIZATION, bearer);
            for (int i = 0; i < p.length; i += 2) req = req.param(p[i], p[i + 1]);
            mockMvc.perform(req).andExpect(status().isBadRequest());
        }
        mockMvc.perform(get(URL).header(HttpHeaders.AUTHORIZATION, bearer)
                        .param("periode", "TODAY").param("from", "2026-09-01").param("to", "2026-09-02"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void diagnostic_hors_perimetre_liste_et_fiche() throws Exception {
        User u = fx.candidat("diag");
        ProductionSubmission diag = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, Instant.now());
        diag.setDiagnostic(true);
        submissionManager.save(diag);

        assertThat(ids(list())).isEmpty();
        mockMvc.perform(get(URL + "/" + diag.getId()).header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isNotFound());
        mockMvc.perform(get(URL + "/" + UUID.randomUUID()).header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isNotFound());
    }

    /** Une page = contenu + comptage, quel que soit le nombre de lignes : égalité stricte. */
    @Test
    void une_page_coute_deux_requetes() {
        User u = fx.candidat("cout");
        for (int i = 0; i < 6; i++) {
            ProductionSubmission s = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED,
                    Instant.now().minusSeconds(i));
            fx.evaluationV15(s, NiveauCecrl.B1);
        }
        entityManager.flush();
        entityManager.clear();
        Statistics stats = entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
        stats.setStatisticsEnabled(true);
        stats.clear();

        var page = service.list(filtres(), AdminProductionTri.NIVEAU_DESC, 0, 5);

        assertThat(page.content()).hasSize(5);
        assertThat(page.totalElements()).isEqualTo(6);
        assertThat(stats.getPrepareStatementCount()).isEqualTo(2);
    }

    // ------------------------------------------------------------------ fiche

    @Test
    void fiche_ee_calcul_vue_candidat_et_technique() throws Exception {
        User u = fx.candidat("ficheee");
        ProductionSubmission s = fx.production(u, EpreuveType.TCF_EE, 2, SubmissionStatut.EVALUATED, Instant.now());
        AiEvaluation e = fx.evaluation(s, NiveauCecrl.B1, NiveauCecrl.A2, "v15", 8, 8, 7, 7);

        JsonNode d = get200(URL + "/" + s.getId());

        assertThat(d.at("/entete/id").asString()).isEqualTo(s.getId().toString());
        assertThat(d.at("/entete/userEmail").asString()).isEqualTo(u.getEmail());
        assertThat(d.at("/entete/epreuve").asString()).isEqualTo("TCF_EE");
        assertThat(d.at("/entete/tache").asInt()).isEqualTo(2);
        assertThat(d.at("/entete/niveauObserve").asString()).isEqualTo("B1");
        assertThat(d.at("/entete/statutIa").asString()).isEqualTo("EVALUEE");
        assertThat(d.at("/entete/statutIaLabel").asString()).isEqualTo("Évaluée");
        assertThat(d.at("/entete/contexte").asString()).isEqualTo("ENTRAINEMENT");
        assertThat(d.at("/sujet/consigne").asString()).isEqualTo(s.getProductionTask().getConsigne());
        assertThat(d.at("/sujet/motsMin").asInt()).isEqualTo(40);
        assertThat(d.at("/reponse/texte").asString()).isEqualTo(s.getTexteSoumis());
        assertThat(d.at("/reponse/motsCount").asInt()).isEqualTo(42);
        assertThat(d.at("/reponse/audioConserve").asBoolean()).isFalse();
        assertThat(d.at("/reponse/audioMotif").isNull()).isTrue();
        assertThat(d.at("/reponse/transcriptionInfo").isNull()).isTrue();

        assertThat(d.at("/evaluationIa/evaluationId").asString()).isEqualTo(e.getId().toString());
        assertThat(d.at("/evaluationIa/criteres")).hasSize(4);
        assertThat(d.at("/evaluationIa/criteres/0/poids").decimalValue()).isEqualByComparingTo("0.25");
        assertThat(d.at("/evaluationIa/niveauIa").asString()).isEqualTo("A2");
        assertThat(d.at("/evaluationIa/niveauRetenu").asString()).isEqualTo("B1");
        assertThat(d.at("/evaluationIa/ecartNiveauCrans").asInt()).isEqualTo(1);
        assertThat(d.at("/evaluationIa/niveauMontreAuCandidat").asBoolean()).isTrue();
        assertThat(d.at("/evaluationIa/justificationNiveau").asString()).contains("Pourquoi pas B2");
        assertThat(d.at("/evaluationIa/nbEvaluations").asLong()).isEqualTo(1);

        assertThat(d.at("/calcul/statut").asString()).isEqualTo("CALCULE");
        assertThat(d.at("/calcul/noteRecalculee").decimalValue()).isEqualByComparingTo("7.5");
        assertThat(d.at("/calcul/niveauRecalcule").asString()).isEqualTo("B1");
        assertThat(d.at("/calcul/coherent").asBoolean()).isTrue();
        assertThat(d.at("/calcul/seuils/b1").decimalValue()).isEqualByComparingTo("6");

        assertThat(d.at("/technique/modele").asString()).isEqualTo("deepseek-v4-flash");
        assertThat(d.at("/technique/coutMicroUsd").asInt()).isEqualTo(928);
        assertThat(d.at("/technique/tokensInputCacheHit").asInt()).isEqualTo(34048);
        assertThat(d.at("/technique/coutLegacyCentimesEuro").isNull()).isTrue();
        assertThat(d.has("provider")).isFalse();

        // JSON persisté : tel qu'en base, justification comprise.
        assertThat(d.at("/jsonPersiste/justification_niveau").asString()).contains("Pourquoi pas B2");
        assertThat(d.get("signalements")).isEmpty();
        assertThat(d.get("signalable").asBoolean()).isTrue();

        // Vue candidat = EXACTEMENT ce que sert l'endpoint candidat (même mapper).
        String candidat = mockMvc.perform(get("/api/production-submissions/" + s.getId())
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(u)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        JsonNode vue = objectMapper.readTree(candidat);
        assertThat(d.at("/vueCandidat/evaluation")).isEqualTo(vue.get("evaluation"));
        assertThat(d.at("/vueCandidat/evaluation/feedback").has("justification_niveau")).isFalse();
    }

    @Test
    void fiche_eo_temps_reel_transcription_sans_audio() throws Exception {
        User u = fx.candidat("ficheeo");
        Attempt examen = testData.attempt(u);
        examen.setSlotNumber(1);
        testData.saveAttempt(examen);
        ProductionSubmission s = fx.tempsReel(
                fx.production(u, examen, EpreuveType.TCF_EO, 2, SubmissionStatut.EVALUATED, Instant.now()));
        Transcription t = testData.transcription(s);
        t.setModeleUtilise("realtime");
        t.setQualiteDegradee(false);
        t.setTauxCollages(0.0);
        transcriptionManager.save(t);
        fx.evaluation(s, NiveauCecrl.B1, NiveauCecrl.B1, "v15", 9, 9, 8, 8);

        JsonNode d = get200(URL + "/" + s.getId());

        assertThat(d.at("/entete/source").asString()).isEqualTo("REALTIME");
        assertThat(d.at("/entete/contexte").asString()).isEqualTo("EXAMEN_BLANC");
        assertThat(d.at("/entete/contexteLabel").asString()).isEqualTo("Examen blanc d'épreuve");
        assertThat(d.at("/reponse/texte").isNull()).isTrue();
        assertThat(d.at("/reponse/transcription").asString()).isEqualTo(t.getTexte());
        assertThat(d.at("/reponse/dureeSec").asInt()).isEqualTo(139);
        assertThat(d.at("/reponse/audioConserve").asBoolean()).isFalse();
        assertThat(d.at("/reponse/audioMotif").asString()).contains("Audio non conservé");
        assertThat(d.at("/reponse/transcriptionInfo/outil").asString()).isEqualTo("realtime");
        assertThat(d.at("/reponse/transcriptionInfo/qualiteDegradee").asBoolean()).isFalse();
        assertThat(d.at("/reponse/transcriptionInfo/coutMicroUsd").isNull()).isTrue();
        assertThat(d.at("/calcul/noteRecalculee").decimalValue()).isEqualByComparingTo("8.5");
        assertThat(d.at("/calcul/coherent").asBoolean()).isTrue();
        assertThat(d.at("/vueCandidat/transcription").asString()).isEqualTo(t.getTexte());
    }

    @Test
    void fiche_regle_historique_non_tracable_garde_le_niveau_persiste() throws Exception {
        User u = fx.candidat("ancienne");
        ProductionSubmission s = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, Instant.now());
        fx.evaluation(s, NiveauCecrl.A2, NiveauCecrl.A2, null, 9, 9, 9, 9);

        JsonNode d = get200(URL + "/" + s.getId());

        assertThat(d.at("/calcul/statut").asString()).isEqualTo("REGLE_NON_TRACABLE");
        assertThat(d.at("/calcul/statutLabel").asString()).contains("non traçable");
        assertThat(d.at("/calcul/niveauPersiste").asString()).isEqualTo("A2");
        assertThat(d.at("/calcul/noteRecalculee").isNull()).isTrue();
        assertThat(d.at("/calcul/coherent").isNull()).isTrue();
        assertThat(d.at("/evaluationIa/criteres/0/poids").isNull()).isTrue();
        assertThat(d.at("/entete/niveauObserve").asString()).isEqualTo("A2");
    }

    /** DI-07 : grille v4.2 (seuils de la config actuelle) → calcul partiel, cohérence jamais conclue. */
    @Test
    void fiche_grille_historique_partielle_coherence_non_verifiable() throws Exception {
        User u = fx.candidat("partiel");
        ProductionSubmission s = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.EVALUATED, Instant.now());
        fx.evaluation(s, NiveauCecrl.B2, NiveauCecrl.B2, "v4.2", 2, 2, 2, 2);

        JsonNode d = get200(URL + "/" + s.getId());

        assertThat(d.at("/calcul/statut").asString()).isEqualTo("CALCUL_PARTIEL");
        assertThat(d.at("/calcul/statutLabel").asString()).contains("cohérence non vérifiable");
        assertThat(d.at("/calcul/seuilsDeLaGrille").asBoolean()).isFalse();
        assertThat(d.at("/calcul/niveauPersiste").asString()).isEqualTo("B2");
        assertThat(d.at("/calcul/coherent").isNull()).isTrue();
    }

    @Test
    void fiche_echec_sans_evaluation() throws Exception {
        User u = fx.candidat("echec");
        ProductionSubmission s = fx.production(u, EpreuveType.TCF_EE, 1, SubmissionStatut.FAILED, Instant.now());
        s.setErreurMessage("Sortie LLM invalide après une tentative de réparation");
        submissionManager.save(s);

        JsonNode d = get200(URL + "/" + s.getId());

        assertThat(d.at("/entete/statutIa").asString()).isEqualTo("ECHEC");
        assertThat(d.at("/entete/niveauObserve").isNull()).isTrue();
        assertThat(d.get("evaluationIa").isNull()).isTrue();
        assertThat(d.at("/calcul/statut").asString()).isEqualTo("SANS_EVALUATION");
        assertThat(d.at("/technique/erreurMessage").asString()).contains("Sortie LLM invalide");
        assertThat(d.at("/technique/modele").isNull()).isTrue();
        assertThat(d.get("jsonPersiste").isNull()).isTrue();
        assertThat(d.get("signalable").asBoolean()).isFalse();
    }

    @Test
    void fiche_non_evaluable_aucun_calcul_mais_signalable() throws Exception {
        User u = fx.candidat("vide");
        ProductionSubmission s = fx.production(u, EpreuveType.TCF_EO, 1, SubmissionStatut.EVALUATED, Instant.now());
        fx.nonEvaluable(s);

        JsonNode d = get200(URL + "/" + s.getId());

        assertThat(d.at("/entete/statutIa").asString()).isEqualTo("NON_EVALUABLE");
        assertThat(d.at("/entete/niveauObserve").isNull()).isTrue();
        assertThat(d.at("/evaluationIa/evaluabilite").asString()).isEqualTo("NON_EVALUABLE");
        assertThat(d.at("/evaluationIa/criteres")).isEmpty();
        assertThat(d.at("/calcul/statut").asString()).isEqualTo("NON_EVALUABLE");
        assertThat(d.get("signalable").asBoolean()).isTrue();
    }

    /** Ouvrir la liste ou une fiche n'écrit rien (ni insertion, ni mise à jour, ni suppression). */
    @Test
    void lecture_passive_aucune_ecriture() throws Exception {
        User u = fx.candidat("passif");
        ProductionSubmission s = fx.production(u, EpreuveType.TCF_EO, 2, SubmissionStatut.EVALUATED, Instant.now());
        testData.transcription(s);
        fx.evaluationV15(s, NiveauCecrl.B1);
        entityManager.flush();
        entityManager.clear();
        Object avant = entityManager.createNativeQuery(
                        "SELECT updated_at FROM production_submissions WHERE id = :id")
                .setParameter("id", s.getId()).getSingleResult();
        Statistics stats = entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
        stats.setStatisticsEnabled(true);
        stats.clear();

        get200(URL + "/" + s.getId());
        list();
        entityManager.flush();

        assertThat(stats.getEntityInsertCount()).isZero();
        assertThat(stats.getEntityUpdateCount()).isZero();
        assertThat(stats.getEntityDeleteCount()).isZero();
        Object apres = entityManager.createNativeQuery(
                        "SELECT updated_at FROM production_submissions WHERE id = :id")
                .setParameter("id", s.getId()).getSingleResult();
        assertThat(apres).isEqualTo(avant);
    }
}
