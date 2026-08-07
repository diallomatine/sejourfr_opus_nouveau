package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class EvaluationOutputValidatorTest {

    @Test
    void classifie_uniquement_une_preuve_non_rattachable_isolee_comme_degradable() {
        String unmatched = "preuve[communiquer] doit citer un passage reel de la production";

        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(unmatched)))
            .contains("communiquer");
        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(
            unmatched,
            "preuve[interagir] doit citer un passage reel de la production")))
            .isEmpty();
        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(
            "preuve[communiquer] doit etre une chaine non vide")))
            .isEmpty();
        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(
            unmatched, "confiance invalide")))
            .isEmpty();
    }

    // ------------------------------------------- contrat v6 : preuve par numero

    /**
     * Sous le contrat v6, la preuve est un ENTIER borne par le nombre de
     * segments servis. C'est la seule chose a verifier, et une preuve inventee
     * n'existe plus : il n'y a plus de texte a rapprocher.
     */
    @Test
    void v6_accepte_une_preuve_qui_designe_un_segment_existant() {
        assertThat(EvaluationOutputValidator.violations(
            feedbackParNumero(1, 2, 3, 4), task(EpreuveType.TCF_EE), rubricsV12(), "v6",
            TEXTE_EE)).isEmpty();
    }

    @Test
    void v6_refuse_un_numero_hors_bornes() {
        assertThat(EvaluationOutputValidator.violations(
            feedbackParNumero(1, 2, 3, 99), task(EpreuveType.TCF_EE), rubricsV12(), "v6", TEXTE_EE))
            .containsExactly(
                "preuve_segment[morphosyntaxe] doit designer un segment numerote de la production");
    }

    @Test
    void v6_refuse_le_zero_et_le_non_entier() {
        assertThat(EvaluationOutputValidator.violations(
            feedbackParNumero(0, 2, 3, 4), task(EpreuveType.TCF_EE), rubricsV12(), "v6", TEXTE_EE))
            .anyMatch(v -> v.contains("doit designer un segment numerote"));

        Map<String, Object> feedback = feedbackParNumero(1, 2, 3, 4);
        scoreDe(feedback, "lexique").put("preuve_segment", "la phrase 2");
        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubricsV12(), "v6", TEXTE_EE))
            .containsExactly("preuve_segment[lexique] doit etre un numero de segment entier");
    }

    /** Une citation recopiee n'a plus sa place dans une sortie v6. */
    @Test
    void v6_refuse_une_preuve_textuelle() {
        Map<String, Object> feedback = feedbackParNumero(1, 2, 3, 4);
        scoreDe(feedback, "lexique").put("preuve", "il est lumineux");
        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubricsV12(), "v6", TEXTE_EE))
            .anyMatch(v -> v.contains("champ inattendu : preuve"));
    }

    /**
     * SEUL le numero inexistant est degradable apres reessai — exactement comme
     * l'etait une citation introuvable. Un champ absent ou non entier reste
     * bloquant, comme l'etait une preuve vide.
     */
    @Test
    void v6_seul_un_numero_inexistant_est_degradable() {
        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(
            "preuve_segment[lexique] doit designer un segment numerote de la production")))
            .contains("lexique");
        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(
            "preuve_segment[lexique] doit etre un numero de segment entier")))
            .isEmpty();
    }

    private static final String TEXTE_EE =
        "Salut Marie ! J'ai déménagé samedi. Mon appartement est lumineux. Viens le voir ?";

    private ProductionRubricsProvider rubricsV12() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v12");
        ProductionRubricsProvider provider = new ProductionRubricsProvider(props, new ObjectMapper());
        provider.load();
        return provider;
    }

    private static Map<String, Object> feedbackParNumero(int communiquer, int interagir,
                                                         int lexique, int morphosyntaxe) {
        Map<String, Object> feedback = validFeedbackV5();
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            scoreNumero("communiquer", communiquer), scoreNumero("interagir", interagir),
            scoreNumero("lexique", lexique), scoreNumero("morphosyntaxe", morphosyntaxe))));
        return feedback;
    }

    private static Map<String, Object> scoreNumero(String code, Object segment) {
        Map<String, Object> score = new LinkedHashMap<>();
        score.put("code", code);
        score.put("note_sur_20", 7);
        score.put("commentaire", "Commentaire centré sur le critère " + code + ".");
        score.put("preuve_segment", segment);
        return score;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> scoreDe(Map<String, Object> feedback, String code) {
        for (Object raw : (List<Object>) feedback.get("scores_criteres")) {
            Map<String, Object> score = (Map<String, Object>) raw;
            if (code.equals(score.get("code"))) return score;
        }
        throw new IllegalArgumentException("critere absent : " + code);
    }

    private ProductionRubricsProvider rubrics;

    @BeforeEach
    void setUp() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v7");
        rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
    }

    @Test
    void accepte_une_sortie_v4_tcf_irn_complete() {
        assertThat(EvaluationOutputValidator.violations(
            validFeedback(), task(EpreuveType.TCF_EE), rubrics, "v4")).isEmpty();
    }

    @Test
    void rejette_le_cas_reel_du_benchmark_avec_deux_criteres() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("scores_criteres", List.of(
            score("lexique", 7), score("morphosyntaxe", 7)));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("exactement 4"))
            .anyMatch(v -> v.contains("criteres manquants"));
    }

    @Test
    void rejette_un_doublon_meme_si_la_liste_compte_quatre_entrees() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("scores_criteres", List.of(
            score("communiquer", 7), score("interagir", 7),
            score("lexique", 7), score("lexique", 7)));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("duplique"));
    }

    @Test
    void rejette_un_champ_hors_contrat_avant_normalisation() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("note_bonus", 2);

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("champ inattendu : note_bonus"));
    }

    @Test
    void rejette_une_note_non_finie_et_un_niveau_superieur_a_b2() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("niveau_cecrl", "C1");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> scores = (List<Map<String, Object>>) feedback.get("scores_criteres");
        scores.get(0).put("note_sur_20", Double.NaN);

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("ne jamais depasser B2"))
            .anyMatch(v -> v.contains("fini"));
    }

    @Test
    void rejette_le_feedback_oral_reel_fonde_sur_hesitations_et_fluidite() {
        Map<String, Object> feedback = validFeedback();
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> scores = (List<Map<String, Object>>) feedback.get("scores_criteres");
        scores.get(0).put("commentaire",
            "Le discours est haché par de nombreuses hésitations et manque de fluidité.");
        feedback.put("points_a_ameliorer", List.of(Map.of(
            "constat", "Votre débit rend la réponse difficile à suivre.",
            "comment", "Parlez plus vite et réduisez les répétitions.")));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4"))
            .anyMatch(v -> v.contains("scores_criteres.commentaire"))
            .anyMatch(v -> v.contains("points_a_ameliorer"));
    }

    /**
     * Le libelle brut ne suffisait pas : sur l'incident du 2026-08-06 le reessai
     * n'a repare AUCUNE des deux violations orales, faute de savoir quel passage
     * et quelle notion etaient rejetes. La violation porte desormais les deux.
     */
    @Test
    void nomme_la_notion_interdite_et_le_passage_rejete() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("suggestions", List.of("Cette reformulation évite les répétitions du début."));

        List<String> violations = EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4");

        List<String> orales = EvaluationOutputValidator.oralViolations(violations);
        assertThat(orales).hasSize(1);
        assertThat(orales.get(0))
            .contains("suggestions")
            .contains("element non evaluable")
            .contains("« repetitions »")
            .contains("Cette reformulation évite les répétitions du début.");
    }

    /**
     * FRONTIERE DU GARDE-FOU ORAL (2026-08-06). {@code exemples_corriges} n'entre
     * dans AUCUN calcul de note : une violation orale y est PURGEE par
     * {@link EvaluationOralArtifactFilter}, elle ne detruit plus l'evaluation.
     * Avant ce changement, deux {@code explication} rejetees ont fait perdre une
     * tache d'examen blanc EO entiere.
     */
    @Test
    void une_violation_orale_dans_un_exemple_corrige_n_est_plus_fatale() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("exemples_corriges", List.of(Map.of(
            "original", "je je voulais dire ça",
            "corrige", "je voulais dire cela",
            "explication", "Cette reformulation évite les répétitions du début.",
            "gain", "un propos plus direct")));

        assertThat(EvaluationOutputValidator.oralViolations(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4"))).isEmpty();
    }

    /** Les champs qui portent le JUGEMENT, eux, restent fatals. */
    @Test
    void les_champs_evaluatifs_restent_fatals() {
        for (String champ : List.of("justification_niveau", "points_forts", "suggestions")) {
            Map<String, Object> feedback = validFeedback();
            String fautif = "La prononciation reste difficile à suivre.";
            feedback.put(champ, "justification_niveau".equals(champ) ? fautif : List.of(fautif));

            assertThat(EvaluationOutputValidator.oralViolations(EvaluationOutputValidator.violations(
                feedback, task(EpreuveType.TCF_EO), rubrics, "v4")))
                .as(champ)
                .hasSize(1);
        }
    }

    // --------------------------------- deux faux positifs du garde-fou oral

    /**
     * CAS REEL : une evaluation a ete detruite pour « cette repetition alourdit la
     * phrase … supprime le pronom repete » — une remarque de MORPHOSYNTAXE, pas de
     * diction. Pire, les rubriques ORDONNENT au correcteur de peser « a-t-il du
     * faire repeter ? » dans {@code communiquer} : le prompt commandait une notion
     * que le validateur interdisait d'ecrire.
     */
    @Test
    void la_repetition_syntaxique_n_est_plus_un_motif_oral_interdit() {
        for (String remarque : List.of(
            "Cette répétition alourdit la phrase : supprime le pronom répété.",
            "La répétition du même connecteur « et » limite la variété des liens.",
            "L'examinateur a dû faire répéter la question, ce qui coupe l'échange.")) {
            Map<String, Object> feedback = validFeedback();
            feedback.put("justification_niveau", remarque);

            assertThat(EvaluationOutputValidator.oralViolations(EvaluationOutputValidator.violations(
                feedback, task(EpreuveType.TCF_EO), rubrics, "v4")))
                .as(remarque)
                .isEmpty();
        }
    }

    /** La REPETITION comme defaut de diction, elle, reste refusee. */
    @Test
    void la_repetition_de_diction_reste_refusee() {
        for (String remarque : List.of(
            "Réduisez les répétitions pour gagner en clarté.",
            "Évite les répétitions du début de ta réponse.",
            "De nombreuses répétitions parsèment votre discours.",
            "Le débit est régulier mais les répétitions gênent l'écoute.")) {
            Map<String, Object> feedback = validFeedback();
            feedback.put("justification_niveau", remarque);

            assertThat(EvaluationOutputValidator.oralViolations(EvaluationOutputValidator.violations(
                feedback, task(EpreuveType.TCF_EO), rubrics, "v4")))
                .as(remarque)
                .hasSize(1);
        }
    }

    /** « Mettre l'accent sur » est une tournure legitime, pas un reproche de diction. */
    @Test
    void mettre_l_accent_sur_n_est_plus_un_motif_oral_interdit() {
        for (String remarque : List.of(
            "Mets l'accent sur les liens logiques entre tes idées.",
            "L'accent est mis sur la demande, ce qui rend le message clair.",
            "Il faudrait mettre l'accent sur la justification de ton choix.")) {
            Map<String, Object> feedback = validFeedback();
            feedback.put("justification_niveau", remarque);

            assertThat(EvaluationOutputValidator.oralViolations(EvaluationOutputValidator.violations(
                feedback, task(EpreuveType.TCF_EO), rubrics, "v4")))
                .as(remarque)
                .isEmpty();
        }
    }

    @Test
    void l_accent_de_diction_reste_refuse() {
        for (String remarque : List.of(
            "Votre accent rend certains mots difficiles à identifier.",
            "Un accent marqué gêne la compréhension.")) {
            Map<String, Object> feedback = validFeedback();
            feedback.put("justification_niveau", remarque);

            assertThat(EvaluationOutputValidator.oralViolations(EvaluationOutputValidator.violations(
                feedback, task(EpreuveType.TCF_EO), rubrics, "v4")))
                .as(remarque)
                .hasSize(1);
        }
    }

    /**
     * NON-REGRESSION : l'acquis principal — « on ne note jamais sur la
     * prononciation » — reste entier. Aucun de ces jetons n'a bouge.
     */
    @Test
    void les_autres_notions_de_diction_restent_toutes_interdites() {
        for (String remarque : List.of(
            "Le discours est haché par de nombreuses hésitations.",
            "La fluidité reste limitée.",
            "La prononciation gêne la compréhension.",
            "Le débit de parole est trop lent.",
            "L'intonation reste plate.",
            "De longues pauses dans la réponse cassent le propos.",
            "Les faux départs sont fréquents.",
            "L'aisance fait défaut.",
            "L'orthographe de la transcription est fautive.",
            "La ponctuation manque.")) {
            Map<String, Object> feedback = validFeedback();
            feedback.put("justification_niveau", remarque);

            assertThat(EvaluationOutputValidator.oralViolations(EvaluationOutputValidator.violations(
                feedback, task(EpreuveType.TCF_EO), rubrics, "v4")))
                .as(remarque)
                .hasSize(1);
        }
    }

    @Test
    void aucune_violation_orale_sur_une_sortie_conforme() {
        assertThat(EvaluationOutputValidator.oralViolations(EvaluationOutputValidator.violations(
            validFeedback(), task(EpreuveType.TCF_EO), rubrics, "v4"))).isEmpty();
    }

    @Test
    void autorise_la_transcription_incertaine_uniquement_dans_la_confiance() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("confiance", "MOYENNE");
        feedback.put("confiance_raisons", List.of(
            "transcription temps réel incertaine avec quelques répétitions"));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4")).isEmpty();
    }

    @Test
    void distingue_la_duree_de_residence_du_temps_de_parole() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of(
                "libelle", "Durée de résidence en France indiquée", "obligatoire", true)),
            "points_oublies", List.of()));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4")).isEmpty();

        feedback.put("justification_niveau",
            "La durée de l’enregistrement est trop courte pour démontrer le niveau.");
        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4"))
            .anyMatch(v -> v.contains("justification_niveau"));
    }

    @Test
    void accepte_le_debit_bancaire_mais_pas_le_debit_de_parole() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of(
                "libelle", "Différence entre carte à débit immédiat et différé expliquée",
                "obligatoire", true)),
            "points_oublies", List.of()));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4")).isEmpty();

        feedback.put("justification_niveau", "Le débit de parole est trop lent.");
        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4"))
            .anyMatch(v -> v.contains("justification_niveau"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void rejette_avant_post_traitement_une_preuve_vide_ou_inventee() {
        Map<String, Object> feedback = validFeedback();
        List<Map<String, Object>> scores =
            (List<Map<String, Object>>) feedback.get("scores_criteres");
        scores.get(0).put("preuve", "");
        scores.get(1).put("preuve", "citation inventée absente");

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4",
            "Voici la phrase du candidat."))
            .anyMatch(v -> v.contains("preuve[communiquer] doit etre une chaine non vide"))
            .anyMatch(v -> v.contains("preuve[interagir] doit citer un passage reel"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void accepte_une_preuve_avec_une_seule_flexion_non_ambigue() {
        Map<String, Object> feedback = validFeedback();
        List<Map<String, Object>> scores =
            (List<Map<String, Object>>) feedback.get("scores_criteres");
        for (Map<String, Object> score : scores) {
            score.put("preuve", "protéger notre environnement local");
        }
        scores.get(0).put("preuve",
            "la solution proposée reste tels pour protéger notre environnement local");

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4",
            "La solution proposée reste telle pour protéger notre environnement local."))
            .isEmpty();
    }

    @Test
    @SuppressWarnings("unchecked")
    void rejette_une_preuve_prise_dans_un_tour_examinateur() {
        Map<String, Object> feedback = validFeedback();
        List<Map<String, Object>> scores =
            (List<Map<String, Object>>) feedback.get("scores_criteres");
        for (Map<String, Object> score : scores) {
            score.put("preuve", "mon appartement se trouve près du parc");
        }
        scores.get(0).put("preuve", "votre logement est près de la gare");

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4",
            "Examinateur : Votre logement est près de la gare.\n"
                + "Candidat : Mon appartement se trouve près du parc."))
            .anyMatch(v -> v.contains("preuve[communiquer] doit citer un passage reel"));
    }

    // ------------------------------------------------------- contrat v5 (v8)

    @Test
    void accepte_une_sortie_v5_complete_avec_verdict_et_version_amelioree() {
        assertThat(EvaluationOutputValidator.violations(
            validFeedbackV5(), task(EpreuveType.TCF_EE), rubrics, "v5")).isEmpty();
    }

    @Test
    void v5_exige_le_verdict_et_son_resume() {
        Map<String, Object> feedback = validFeedbackV5();
        feedback.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of("libelle", "Consigne traitée", "obligatoire", true)),
            "points_oublies", List.of()));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v5"))
            .anyMatch(v -> v.contains("accomplissement.objectif doit valoir"))
            .anyMatch(v -> v.contains("accomplissement.objectif_resume"));
    }

    @Test
    void v5_rejette_un_verdict_hors_enum() {
        Map<String, Object> feedback = validFeedbackV5();
        feedback.put("accomplissement", accomplissement("PRESQUE_ATTEINT", List.of()));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v5"))
            .anyMatch(v -> v.contains("accomplissement.objectif doit valoir"));
    }

    @Test
    void v5_refuse_plus_de_deux_points_forts_et_plus_de_trois_exemples() {
        Map<String, Object> feedback = validFeedbackV5();
        feedback.put("points_forts", List.of("un", "deux", "trois"));
        feedback.put("exemples_corriges", List.of(
            exemple(), exemple(), exemple(), exemple()));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v5"))
            .anyMatch(v -> v.contains("points_forts contient plus de 2 entrees"))
            .anyMatch(v -> v.contains("exemples_corriges contient plus de 3 entrees"));
    }

    /** Le plafond de points forts est une regle v5 : v4 doit rester tolerante. */
    @Test
    void v4_ne_plafonne_ni_les_points_forts_ni_les_exemples() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("points_forts", List.of("un", "deux", "trois"));
        feedback.put("exemples_corriges", List.of(exemple(), exemple(), exemple(), exemple()));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4")).isEmpty();
    }

    @Test
    void v5_exige_la_version_amelioree_sur_une_tache_ecrite() {
        Map<String, Object> feedback = validFeedbackV5();
        feedback.remove("version_amelioree");

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v5"))
            .anyMatch(v -> v.contains("version_amelioree doit etre une chaine non vide"));

        feedback.put("version_amelioree", "  ");
        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v5"))
            .anyMatch(v -> v.contains("version_amelioree doit etre une chaine non vide"));
    }

    /**
     * A l'oral, la version amelioree n'est ni exigee ni bloquante : le serveur
     * la retire. Faire echouer une evaluation entiere pour ce champ couterait
     * au candidat sa note, pour rien.
     */
    @Test
    void v5_n_exige_pas_la_version_amelioree_a_l_oral_et_en_tolere_la_presence() {
        Map<String, Object> feedback = validFeedbackV5();
        feedback.remove("version_amelioree");

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v5")).isEmpty();

        feedback.put("version_amelioree", "Bonjour madame, je voudrais des renseignements.");
        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v5")).isEmpty();
    }

    /**
     * Non-regression : les champs v5 sont INCONNUS du contrat v4. Un rollback
     * v8/v5 -> v7/v4 doit continuer de rejeter tout ce qui deborde de v4.
     */
    @Test
    void v4_rejette_les_champs_de_restitution_v5() {
        Map<String, Object> feedback = validFeedbackV5();

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("racine contient un champ inattendu : version_amelioree"))
            .anyMatch(v -> v.contains("accomplissement contient un champ inattendu : objectif"));
    }

    private static ProductionTask task(EpreuveType epreuve) {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(epreuve);
        task.setTacheNumero((short) 1);
        return task;
    }

    private static Map<String, Object> validFeedbackV5() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("accomplissement", accomplissement("ATTEINT", List.of()));
        feedback.put("version_amelioree",
            "Salut Marie, j'ai déménagé samedi dernier parce que mon ancien logement était "
                + "trop petit. Mon nouvel appartement est lumineux et proche de la gare. "
                + "Viens le voir dimanche, tu peux apporter un dessert.");
        return feedback;
    }

    private static Map<String, Object> accomplissement(String objectif, List<Object> oublies) {
        Map<String, Object> acc = new LinkedHashMap<>();
        acc.put("objectif", objectif);
        acc.put("objectif_resume", "Tu annonces ton déménagement, tu décris le logement et tu invites ton amie.");
        acc.put("points_traites", List.of(Map.of("libelle", "Consigne traitée", "obligatoire", true)));
        acc.put("points_oublies", oublies);
        return acc;
    }

    private static Map<String, Object> exemple() {
        return Map.of(
            "original", "Je travaille ici.",
            "corrige", "Je travaille ici parce que ce poste me plaît.",
            "explication", "La raison développe le message.",
            "gain", "La subordination montre une structure plus variée.");
    }

    private static Map<String, Object> validFeedback() {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("note_globale", 7);
        feedback.put("niveau_cecrl", "B1");
        feedback.put("justification_niveau", "Les phrases sont développées et reliées par des connecteurs simples.");
        feedback.put("confiance", "HAUTE");
        feedback.put("confiance_raisons", List.of("marqueurs linguistiques nets"));
        feedback.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of("libelle", "Consigne traitée", "obligatoire", true)),
            "points_oublies", List.of()));
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7), score("interagir", 7),
            score("lexique", 7), score("morphosyntaxe", 7))));
        feedback.put("points_forts", List.of("Le message est clair et organisé."));
        feedback.put("points_a_ameliorer", List.of(Map.of(
            "constat", "Une idée reste peu développée.",
            "comment", "Ajoutez une raison introduite par « parce que » à cette idée.")));
        feedback.put("suggestions", List.of("Entraînez-vous à relier deux idées."));
        feedback.put("exemples_corriges", List.of(Map.of(
            "original", "Je travaille ici.",
            "corrige", "Je travaille ici parce que ce poste me plaît.",
            "explication", "La raison développe le message.",
            "gain", "La subordination montre une structure plus variée.")));
        return feedback;
    }

    private static Map<String, Object> score(String code, Number note) {
        Map<String, Object> score = new LinkedHashMap<>();
        score.put("code", code);
        score.put("note_sur_20", note);
        score.put("commentaire", "Commentaire centré sur le critère " + code + ".");
        score.put("preuve", "phrase du candidat");
        return score;
    }
}
