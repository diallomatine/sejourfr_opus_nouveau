package com.sejourfr.app.service;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;

/**
 * REND les prompts envoyes a un {@link EvaluationLlmClient} a partir du fichier
 * {@code production-rubrics-<version>.json} (via {@link ProductionRubricsProvider}).
 *
 * <p><b>Aucune instruction de notation en dur ici</b> : ce builder ne fait
 * qu'assembler des chaines issues du JSON (bloc {@code commun} pour le system
 * prompt) et des donnees de la tache (DB + bloc tache du fichier pour le user
 * message). Plus aucun gabarit {@code .md} n'est charge ; le contrat de sortie
 * (tool-schema) reste gere par les clients LLM, separement.
 *
 * <ul>
 *   <li><b>system</b> = {@code commun.sections} rendues {@code # titre\ncontenu},
 *       suivies des {@code commun.few_shot} (ancres de calibration). Identique pour
 *       toutes les taches → calcule une fois et mis en cache.</li>
 *   <li><b>user</b> = donnees seulement : epreuve/tache, niveau cible (DB),
 *       consigne (DB), longueur attendue (DB, EE), contexte (DB), puis criteres /
 *       bareme / descripteurs / consignes du bloc tache et production. La duree
 *       EO reste hors du materiau de notation.</li>
 * </ul>
 */
@Component
public class EvaluationPromptBuilder {

    private static final List<String> NIVEAUX = List.of("A1", "A2", "B1", "B2");

    private final ObjectMapper objectMapper;
    private final ProductionRubricsProvider rubrics;
    private volatile String systemPromptCache;

    public EvaluationPromptBuilder(ObjectMapper objectMapper, ProductionRubricsProvider rubrics) {
        this.objectMapper = objectMapper;
        this.rubrics = rubrics;
    }

    /**
     * System prompt = bloc {@code commun} rendu (sections + few-shot). Identique
     * pour toutes les taches/epreuves (le global porte deja la regle orale).
     */
    public String buildSystemPrompt() {
        String cached = systemPromptCache;
        if (cached != null) return cached;
        cached = renderCommun(rubrics.getCommun());
        systemPromptCache = cached;
        return cached;
    }

    /**
     * @param production texte EE rendu ou transcription Whisper (EO).
     * @param transcriptionLitterale conserve pour la signature ; la notice de
     *        transcription vit dans le bloc {@code commun} (section orale).
     * @param dureeProductionSec conserve pour compatibilite d'appel ; la duree
     *        n'est jamais injectee dans le prompt de notation.
     */
    public String buildUserPrompt(ProductionTask task, String production,
                                  boolean transcriptionLitterale, Integer dureeProductionSec) {
        Map<String, Object> rubric = rubrics.getTask(task.getEpreuve(), task.getTacheNumero()).orElse(Map.of());

        String criteresJson;
        try {
            Object criteres = rubric.get("criteres");
            criteresJson = objectMapper.writeValueAsString(criteres != null ? criteres : List.of());
        } catch (Exception e) {
            criteresJson = "[]";
        }

        StringBuilder sb = new StringBuilder();
        sb.append("ÉPREUVE : Expression ").append(modalite(task.getEpreuve()))
            .append(", tâche ").append(task.getTacheNumero()).append('\n');
        sb.append("NIVEAU CIBLE DE LA TÂCHE : ").append(nullSafe(task.getNiveauCible())).append("\n\n");

        sb.append("CONSIGNE DONNÉE AU CANDIDAT :\n\"").append(nullSafe(task.getConsigne())).append("\"\n\n");

        String longueur = buildLongueurBlock(task);
        if (!longueur.isBlank()) sb.append(longueur).append('\n');

        if (task.getContexte() != null && !task.getContexte().isBlank()) {
            sb.append("CONTEXTE :\n\"").append(task.getContexte()).append("\"\n\n");
        }

        sb.append("GRILLE D'ÉVALUATION (critères et pondérations propres à cette tâche) :\n")
            .append(criteresJson).append("\n\n");
        sb.append("BARÈME DE LA NOTE /20 (propre à cette tâche) :\n")
            .append(asString(rubric.get("bareme_note"))).append("\n\n");
        sb.append("DESCRIPTEURS DE NIVEAU POUR CETTE TÂCHE :\n")
            .append(formatDescripteurs(rubric.get("descripteurs"))).append("\n\n");
        sb.append("CONSIGNES SPÉCIFIQUES AU CORRECTEUR POUR CETTE TÂCHE :\n")
            .append(asString(rubric.get("consignes_correcteur"))).append("\n\n");

        sb.append("PRODUCTION DU CANDIDAT :\n\"").append(nullSafe(production)).append("\"\n");

        sb.append("\nÉvalue cette production en appelant l'outil `submit_evaluation`.");
        return sb.toString();
    }

    /** Concatene les {@code commun.sections} (# titre / contenu) + les few-shot. */
    private static String renderCommun(Map<String, Object> commun) {
        StringBuilder sb = new StringBuilder();
        if (commun.get("sections") instanceof List<?> sections) {
            for (Object s : sections) {
                if (s instanceof Map<?, ?> m) {
                    sb.append("# ").append(asString(m.get("titre"))).append('\n')
                        .append(asString(m.get("contenu"))).append("\n\n");
                }
            }
        }
        if (commun.get("few_shot") instanceof List<?> fewShot && !fewShot.isEmpty()) {
            sb.append("# Exemples d'ancrage (production → scores → niveau)\n\n");
            int i = 1;
            for (Object f : fewShot) {
                if (!(f instanceof Map<?, ?> m)) continue;
                sb.append("Exemple ").append(i++).append(" — ").append(asString(m.get("contexte"))).append('\n');
                sb.append("Production : \"").append(asString(m.get("texte"))).append("\"\n");
                sb.append("Scores : ").append(asString(m.get("scores"))).append('\n');
                sb.append("niveau_cecrl : ").append(asString(m.get("niveau_cecrl"))).append('\n');
                sb.append("Justification : ").append(asString(m.get("justification"))).append("\n\n");
            }
        }
        return sb.toString().trim();
    }

    /** Formate les descripteurs du profil actif A1..B2, dans l'ordre. */
    private static String formatDescripteurs(Object o) {
        if (!(o instanceof Map<?, ?> m)) return "";
        StringBuilder sb = new StringBuilder();
        for (String niv : NIVEAUX) {
            Object v = m.get(niv);
            if (v != null && !v.toString().isBlank()) {
                sb.append("- ").append(niv).append(" : ").append(v).append('\n');
            }
        }
        return sb.toString().trim();
    }

    /**
     * EE uniquement : longueur attendue (donnee factuelle, bornes DB). Une
     * production hors bornes est deja bloquee avant l'appel au correcteur.
     */
    private static String buildLongueurBlock(ProductionTask task) {
        if (task.getEpreuve() != EpreuveType.TCF_EE
                || task.getMotsMin() == null || task.getMotsMax() == null) {
            return "";
        }
        return "LONGUEUR ATTENDUE : " + task.getMotsMin() + " à " + task.getMotsMax() + " mots.\n";
    }

    private static String modalite(EpreuveType epreuve) {
        return epreuve == EpreuveType.TCF_EO ? "orale" : "ecrite";
    }

    private static String asString(Object o) {
        return o == null ? "" : o.toString();
    }

    private static String nullSafe(String s) {
        return s == null ? "" : s;
    }
}
