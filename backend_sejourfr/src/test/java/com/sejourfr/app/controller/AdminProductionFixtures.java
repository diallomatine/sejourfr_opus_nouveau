package com.sejourfr.app.controller;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.support.TestData;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Jeu d'essai des ITs de la console « Productions IA ». Chaque test tire un
 * {@link #jeton} propre et le met dans l'email de ses candidats : la recherche
 * {@code q=<jeton>} isole ses lignes de tout ce que la base contient d'autre.
 */
final class AdminProductionFixtures {

    final String jeton = "pia" + UUID.randomUUID().toString().substring(0, 8);

    private final TestData testData;
    private final ProductionSubmissionManager submissionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final UserManager userManager;

    AdminProductionFixtures(TestData testData, ProductionSubmissionManager submissionManager,
                            AiEvaluationManager aiEvaluationManager, UserManager userManager) {
        this.testData = testData;
        this.submissionManager = submissionManager;
        this.aiEvaluationManager = aiEvaluationManager;
        this.userManager = userManager;
    }

    User candidat(String prefixe) {
        return testData.user(prefixe + "." + jeton + "@test.sejourfr");
    }

    User candidatInterne(String prefixe) {
        User u = candidat(prefixe);
        u.setInternal(true);
        return userManager.save(u);
    }

    ProductionSubmission production(User u, EpreuveType epreuve, int tache, SubmissionStatut statut, Instant at) {
        return production(u, testData.attempt(u), epreuve, tache, statut, at);
    }

    ProductionSubmission production(User u, Attempt attempt, EpreuveType epreuve, int tache,
                                    SubmissionStatut statut, Instant at) {
        ProductionSubmission s = testData.productionSubmission(
                attempt, testData.productionTacheNumero(epreuve, (short) tache), u);
        if (epreuve == EpreuveType.TCF_EO) {
            s.setTexteSoumis(null);
            s.setMotsCount(null);
            s.setMediaDurationSec(139);
        }
        s.setStatut(statut);
        s.setSubmittedAt(at);
        return submissionManager.save(s);
    }

    /** Évaluation v15 réelle : 4 critères /20, note et niveau du serveur, confiance présente. */
    AiEvaluation evaluation(ProductionSubmission s, NiveauCecrl niveau, NiveauCecrl niveauIa,
                            String rubrics, int communiquer, int interagir, int lexique, int morpho) {
        AiEvaluation e = new AiEvaluation();
        e.setSubmission(s);
        e.setModeleUtilise("deepseek-v4-flash");
        e.setPromptVersion("v9");
        e.setRubricsVersion(rubrics);
        BigDecimal note = BigDecimal.valueOf(communiquer + interagir + lexique + morpho)
                .multiply(new BigDecimal("0.25")).setScale(1, java.math.RoundingMode.HALF_UP);
        e.setNoteSur20(note);
        e.setNiveauCecrl(niveau);
        e.setNiveauCecrlIa(niveauIa);
        e.setTokensInput(34959);
        e.setTokensInputCacheHit(34048);
        e.setTokensOutput(2006);
        e.setCoutMicroUsd(928);
        Map<String, Object> f = new HashMap<>();
        List<Map<String, Object>> scores = new ArrayList<>();
        scores.add(critere("communiquer", "Communiquer", communiquer));
        scores.add(critere("interagir", "Interagir", interagir));
        scores.add(critere("lexique", "Lexique", lexique));
        scores.add(critere("morphosyntaxe", "Morphosyntaxe", morpho));
        f.put("scores_criteres", scores);
        f.put("note_globale", note);
        f.put("niveau_cecrl", niveau == null ? null : niveau.name());
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", List.of("Production complète."));
        f.put("justification_niveau", "Pourquoi pas B2 : test décisif non passé.");
        f.put("points_forts", List.of("Récit ordonné."));
        e.setFeedbackJson(f);
        return aiEvaluationManager.save(e);
    }

    AiEvaluation evaluationV15(ProductionSubmission s, NiveauCecrl niveau) {
        return evaluation(s, niveau, niveau, "v15", 8, 8, 7, 7);
    }

    AiEvaluation nonEvaluable(ProductionSubmission s) {
        AiEvaluation e = new AiEvaluation();
        e.setSubmission(s);
        e.setModeleUtilise("validation-serveur");
        e.setPromptVersion("v9");
        e.setRubricsVersion("v15");
        e.setEvaluabilite(ProductionEvaluabilite.NON_EVALUABLE);
        Map<String, Object> f = new HashMap<>();
        f.put("avertissements", List.of("Production vide."));
        e.setFeedbackJson(f);
        return aiEvaluationManager.save(e);
    }

    ProductionSubmission tempsReel(ProductionSubmission s) {
        s.setSource(ProductionSubmissionSource.REALTIME);
        return submissionManager.save(s);
    }

    private static Map<String, Object> critere(String code, String label, int note) {
        Map<String, Object> m = new HashMap<>();
        m.put("code", code);
        m.put("label", label);
        m.put("note_sur_20", note);
        m.put("bande", "SATISFAISANT");
        m.put("commentaire", "Commentaire " + code);
        m.put("preuve", "extrait");
        return m;
    }
}
