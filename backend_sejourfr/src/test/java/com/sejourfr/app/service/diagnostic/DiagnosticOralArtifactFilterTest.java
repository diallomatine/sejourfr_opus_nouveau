package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.service.TranscriptionQualityAudit;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * VOLET ORAL DU DIAGNOSTIC, mesure sur l'incident REEL relevé en base.
 *
 * <p>Le candidat a demandé les <b>horaires</b> ; notre transcription a écrit
 * <b>« horreurs »</b>. L'observation {@code EO2-C3} lui reprochait alors
 * <i>« « horreurs » pour « horaires » est une erreur lexicale qui peut
 * gêner »</i> — un défaut de notre chaîne technique, imputé au candidat sur le
 * tout premier écran du produit.
 *
 * <p>Ce qui est verrouillé ici : la purge retire une PHRASE, jamais un verdict,
 * jamais une observation, jamais rien à l'ÉCRIT — et elle ne fait jamais échouer
 * une analyse.
 */
class DiagnosticOralArtifactFilterTest {

    /** Transcription RÉELLE de la production orale diagnostique (verbatim base). */
    private static final String TRANSCRIPTION = """
        Bonjour, je me nomme Ilialo Mamadou, j'ai 21 ans, je suis d'origine guénéenne, \
        je viens d'arriver dans le quartier, j'habite vraiment, vraiment à côté de la mairie. \
        Aujourd'hui, je me présente à vous parce que j'ai beaucoup de questions. \
        J'aimerais savoir, est-ce que vous proposez des activités qui me permettent de \
        pratiquer mon français dans un groupe ? Quelles sont ces activités ? Est-ce que vous \
        avez, par exemple, le football ou bien d'autres types d'activités ? Personnellement, \
        je préfère le football. Si c'est le cas, j'aimerais savoir, c'est quoi les horreurs ? \
        Est-ce que c'est gratuit ou bien c'est payant ? Et c'est quoi aussi la modalité \
        d'inscription ? Personnellement, je préfère le football parce que le football, je me \
        sens bien, j'essaie aussi de jouer.""";

    /** L'explication RÉELLE de l'observation EO2-C3. */
    private static final String EXPLICATION_REELLE =
            "Demande les horaires et le tarif, mais « horreurs » pour « horaires » est une "
                    + "erreur lexicale qui peut gêner.";

    /** La faiblesse RÉELLE, bâtie sur le même artefact. */
    private static final String FAIBLESSE_REELLE =
            "Erreur lexicale récurrente : « horreurs » pour « horaires » (segment 7), qui peut "
                    + "gêner la compréhension.";

    private EvaluationPurgeMetrics metrics;
    private DiagnosticOralArtifactFilter filtre;

    @BeforeEach
    void setUp() {
        metrics = new EvaluationPurgeMetrics();
        filtre = new DiagnosticOralArtifactFilter(metrics);
    }

    // ------------------------------------------------------------ l'incident

    @Test
    void purge_le_reproche_bati_sur_un_mot_que_la_transcription_a_fabrique() {
        Map<String, Object> analysis = analyse(EXPLICATION_REELLE);

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(observation(analysis).get("explanation")).isEqualTo("");
        assertThat(metrics.compteurs())
                .containsEntry("ARTEFACT_ORAL_FORME_DIAGNOSTIC/remarques", 1L);
    }

    @Test
    void purge_la_faiblesse_batie_sur_le_meme_artefact_et_retire_l_entree_vide() {
        Map<String, Object> analysis = analyse("Réponse claire et complète.");
        analysis.put("weaknesses", new ArrayList<>(List.of(
                FAIBLESSE_REELLE,
                "Le débit reste hésitant sur la fin de la production.")));

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(analysis.get("weaknesses"))
                .isEqualTo(List.of("Le débit reste hésitant sur la fin de la production."));
        assertThat(metrics.compteurs())
                .containsEntry("ARTEFACT_ORAL_FORME_DIAGNOSTIC/entrees", 1L);
    }

    /** Une phrase du champ tombe, les autres restent : « la phrase, pas le champ ». */
    @Test
    void ne_retire_que_la_phrase_fautive_et_conserve_le_reste_de_l_explication() {
        Map<String, Object> analysis = analyse(
                "L'objectif est atteint. " + EXPLICATION_REELLE + " Le propos reste clair.");

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(observation(analysis).get("explanation"))
                .isEqualTo("L'objectif est atteint. Le propos reste clair.");
    }

    // ------------------------------------------------- ce qu'on ne purge pas

    /**
     * TROIS mots pleins et plus : c'est une STRUCTURE, elle est conservée. Ici
     * « quoi », « modalité » et « inscription » — verbatim réel de la base.
     */
    @Test
    void conserve_un_reproche_qui_cite_une_structure_de_trois_mots_pleins() {
        String structure = "Quelques formulations approximatives : « c'est quoi la modalité "
                + "d'inscription » reste oral mais peu précis.";
        Map<String, Object> analysis = analyse(structure);

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(observation(analysis).get("explanation")).isEqualTo(structure);
        assertThat(metrics.compteurs()).isEmpty();
    }

    /** ZÉRO mot plein : une citation de mots-outils seuls est une structure pure. */
    @Test
    void conserve_un_reproche_qui_ne_cite_que_des_mots_outils() {
        String structure = "La tournure « est-ce que c'est » est incorrecte dans une demande "
                + "formelle adressée à une association.";
        Map<String, Object> analysis = analyse(structure);

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(observation(analysis).get("explanation")).isEqualTo(structure);
        assertThat(metrics.compteurs()).isEmpty();
    }

    /** Un conseil qui cite un mot n'est pas un reproche : il reste intact. */
    @Test
    void conserve_un_conseil_qui_cite_un_mot_sans_rien_reprocher() {
        String conseil = "Reprends « les horreurs » et développe ta demande d'information.";
        Map<String, Object> analysis = analyse(conseil);

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(observation(analysis).get("explanation")).isEqualTo(conseil);
    }

    /** Un reproche général, non ancré sur la transcription, n'est jamais touché. */
    @Test
    void conserve_un_reproche_general_non_ancre_sur_la_transcription() {
        String general = "Le lexique reste pauvre et approximatif sur l'ensemble de la production.";
        Map<String, Object> analysis = analyse(general);

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(observation(analysis).get("explanation")).isEqualTo(general);
    }

    /** Les points forts ne sont jamais inspectés : on n'efface pas un compliment. */
    @Test
    void ne_touche_jamais_les_points_forts() {
        Map<String, Object> analysis = analyse(EXPLICATION_REELLE);
        analysis.put("strengths", List.of("Emploie « horreurs » sans erreur de construction."));

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(analysis.get("strengths"))
                .isEqualTo(List.of("Emploie « horreurs » sans erreur de construction."));
    }

    // ------------------------------------------------------ l'écrit, jamais

    @Test
    void ne_purge_rien_sur_la_production_ecrite_du_diagnostic() {
        Map<String, Object> analysis = analyse(EXPLICATION_REELLE);
        analysis.put("weaknesses", new ArrayList<>(List.of(FAIBLESSE_REELLE)));

        filtre.purge(analysis, EpreuveType.TCF_EE, TRANSCRIPTION);

        assertThat(observation(analysis).get("explanation")).isEqualTo(EXPLICATION_REELLE);
        assertThat(analysis.get("weaknesses")).isEqualTo(List.of(FAIBLESSE_REELLE));
        assertThat(metrics.compteurs()).isEmpty();
    }

    // ------------------------------------------------- le jugement ne bouge pas

    @Test
    void laisse_intacts_statut_priorite_confiance_et_niveau() {
        Map<String, Object> analysis = analyse(EXPLICATION_REELLE);

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(analysis.get("level_estimate")).isEqualTo("A2");
        assertThat(analysis.get("task_completion")).isEqualTo("PARTIAL");
        assertThat(analysis.get("communication_status")).isEqualTo("EFFECTIVE");
        Map<String, Object> observation = observation(analysis);
        assertThat(observation.get("skill_code")).isEqualTo("EO2-C3");
        assertThat(observation.get("status")).isEqualTo("TO_REINFORCE");
        assertThat(observation.get("confidence")).isEqualTo("MEDIUM");
        assertThat(observation.get("priority")).isEqualTo(Boolean.TRUE);
        assertThat(observation.get("observed")).isEqualTo(Boolean.TRUE);
        assertThat(observation.get("evidence"))
                .isEqualTo("Si c'est le cas, j'aimerais savoir, c'est quoi les horreurs ?");
    }

    /** L'observation SURVIT sans son explication : jamais de FAILED, jamais de perte. */
    @Test
    void une_purge_totale_conserve_l_observation_sans_son_explication() {
        Map<String, Object> analysis = analyse(EXPLICATION_REELLE);

        assertThatCode(() -> filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION))
                .doesNotThrowAnyException();

        assertThat(skills(analysis)).hasSize(1);
        assertThat(observation(analysis).get("explanation")).isEqualTo("");
        assertThat(observation(analysis).get("status")).isEqualTo("TO_REINFORCE");
    }

    /** Un résumé entièrement purgé ne reste jamais vide : il dit ce qui s'est passé. */
    @Test
    void remplace_un_resume_entierement_purge_au_lieu_de_le_vider() {
        Map<String, Object> analysis = analyse("Réponse claire.");
        analysis.put("summary", FAIBLESSE_REELLE);

        filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION);

        assertThat(analysis.get("summary")).isEqualTo(DiagnosticOralArtifactFilter.SUMMARY_PURGE);
    }

    // ------------------------------------------------------ transcription abîmée

    /**
     * Transcription DÉGRADÉE : le texte lu n'est pas celui qui a été dit, donc
     * plus aucun reproche ancré n'y est opposable — même sur trois mots pleins.
     */
    @Test
    void sur_une_transcription_degradee_meme_un_reproche_de_structure_tombe() {
        String abimee = """
            Bon jour je m ap pel le Ma dou et je vou drais vous par ler de mon quar tier. \
            Il y a beau coup de cho ses a fai re ici et j ai me bien les gens qui ha bi tent \
            la avec moi tous les jours de la se mai ne.""";
        assertThat(TranscriptionQualityAudit.degradee(abimee)).isTrue();
        String reproche = "La construction « beau coup de cho ses » est incorrecte.";
        Map<String, Object> analysis = analyse(reproche);

        filtre.purge(analysis, EpreuveType.TCF_EO, abimee);

        assertThat(observation(analysis).get("explanation")).isEqualTo("");
    }

    // ------------------------------------------------------------ robustesse

    @Test
    void ne_leve_jamais_meme_sur_une_sortie_incoherente() {
        Map<String, Object> analysis = new LinkedHashMap<>();
        analysis.put("summary", 42);
        analysis.put("weaknesses", "pas une liste");
        analysis.put("skills", List.of("pas un objet", 7));

        assertThatCode(() -> filtre.purge(analysis, EpreuveType.TCF_EO, TRANSCRIPTION))
                .doesNotThrowAnyException();
        assertThatCode(() -> filtre.purge(null, EpreuveType.TCF_EO, TRANSCRIPTION))
                .doesNotThrowAnyException();
        assertThatCode(() -> filtre.purge(analyse("x"), EpreuveType.TCF_EO, null))
                .doesNotThrowAnyException();
    }

    // ----------------------------------------------------------------- outils

    /** Sortie diagnostique déjà validée et normalisée, calquée sur la base. */
    private static Map<String, Object> analyse(String explication) {
        Map<String, Object> observation = new LinkedHashMap<>();
        observation.put("skill_code", "EO2-C3");
        observation.put("observed", Boolean.TRUE);
        observation.put("status", "TO_REINFORCE");
        observation.put("evidence_segment", 7);
        observation.put("evidence", "Si c'est le cas, j'aimerais savoir, c'est quoi les horreurs ?");
        observation.put("explanation", explication);
        observation.put("confidence", "MEDIUM");
        observation.put("priority", Boolean.TRUE);

        Map<String, Object> analysis = new LinkedHashMap<>();
        analysis.put("level_estimate", "A2");
        analysis.put("task_completion", "PARTIAL");
        analysis.put("communication_status", "EFFECTIVE");
        analysis.put("summary", "Le candidat se présente et pose ses questions.");
        analysis.put("strengths", List.of("Se présente clairement."));
        analysis.put("weaknesses", new ArrayList<String>());
        List<Map<String, Object>> skills = new ArrayList<>();
        skills.add(observation);
        analysis.put("skills", skills);
        return analysis;
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> skills(Map<String, Object> analysis) {
        return (List<Map<String, Object>>) analysis.get("skills");
    }

    private static Map<String, Object> observation(Map<String, Object> analysis) {
        return skills(analysis).getFirst();
    }
}
