package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifie que le system prompt et le user message sont RENDUS depuis
 * production-rubrics-v3.json (commun + bloc tache), sans aucun gabarit .md.
 */
class EvaluationPromptBuilderTest {

    private EvaluationPromptBuilder builder;

    @BeforeEach
    void setUp() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v3");
        ObjectMapper om = new ObjectMapper();
        ProductionRubricsProvider provider = new ProductionRubricsProvider(props, om);
        provider.load(); // charge le fichier v3 du classpath
        builder = new EvaluationPromptBuilder(om, provider);
    }

    @Test
    void systemPrompt_rendu_depuis_commun() {
        String system = builder.buildSystemPrompt();
        // Sections (titres rendus en "# titre")
        assertThat(system).contains("# Role");
        assertThat(system).contains("# Production hors-sujet (regle stricte)");
        assertThat(system).contains("examinateur officiel du TCF IRN");
        // Few-shot rendus
        assertThat(system).contains("# Exemples d'ancrage");
        assertThat(system).contains("niveau_cecrl : B2");
        // Aucune fuite de placeholder de gabarit
        assertThat(system).doesNotContain("{MODALITE}").doesNotContain("{CRITERES}");
    }

    @Test
    void userPrompt_EE_contient_donnees_et_bloc_tache() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 1);
        task.setNiveauCible("A2");
        task.setConsigne("Annoncez votre demenagement a un ami et invitez-le.");
        task.setMotsMin(30);
        task.setMotsMax(60);

        String user = builder.buildUserPrompt(task, "Salut Marie, j'ai demenage. Viens samedi !", false, null);

        assertThat(user).contains("ÉPREUVE : Expression ecrite, tâche 1");
        assertThat(user).contains("NIVEAU CIBLE DE LA TÂCHE : A2");
        assertThat(user).contains("LONGUEUR ATTENDUE : 30 à 60 mots");
        assertThat(user).contains("Annoncez votre demenagement");
        assertThat(user).contains("\"pertinence\""); // criteres JSON du bloc tache
        assertThat(user).contains("BARÈME DE LA NOTE /20");
        assertThat(user).contains("- A2 :"); // descripteurs formates
        assertThat(user).contains("submit_evaluation");
        // EE : pas de bloc duree
        assertThat(user).doesNotContain("DURÉE");
    }

    @Test
    void userPrompt_EO_injecte_duree_factuelle_sous_objectif() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setTacheNumero((short) 1);
        task.setNiveauCible("A2");
        task.setConsigne("Presentez-vous.");
        task.setDureeMaxSec(180);

        String user = builder.buildUserPrompt(task, "bonjour je m'appelle samuel", true, 90);

        assertThat(user).contains("ÉPREUVE : Expression orale, tâche 1");
        assertThat(user).contains("DURÉE (indicative) : 90 s (objectif 180 s)");
        // EO : pas de bloc longueur (specifique EE)
        assertThat(user).doesNotContain("LONGUEUR ATTENDUE");
    }
}
