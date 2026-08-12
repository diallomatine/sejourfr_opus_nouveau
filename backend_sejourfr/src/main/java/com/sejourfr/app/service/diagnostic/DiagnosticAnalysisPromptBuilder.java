package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.EvaluationProductionSegments;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Rend les prompts depuis les rubriques versionnées et des données explicites. */
@Component
public class DiagnosticAnalysisPromptBuilder {

    private final DiagnosticRubricsProvider rubrics;
    private final ObjectMapper objectMapper;
    private volatile String systemPrompt;

    public DiagnosticAnalysisPromptBuilder(
            DiagnosticRubricsProvider rubrics, ObjectMapper objectMapper) {
        this.rubrics = rubrics;
        this.objectMapper = objectMapper;
    }

    public String buildSystemPrompt() {
        String cached = systemPrompt;
        if (cached != null) return cached;
        StringBuilder builder = new StringBuilder();
        for (Map<String, Object> section : rubrics.sections()) {
            builder.append("# ").append(section.getOrDefault("title", "")).append('\n')
                    .append(section.getOrDefault("content", "")).append("\n\n");
        }
        cached = builder.toString().trim();
        systemPrompt = cached;
        return cached;
    }

    public String buildUserPrompt(
            ProductionTask task,
            List<Skill> allowedSkills,
            EvaluationProductionSegments segments,
            String targetLevel,
            boolean initialDiagnostic) {
        Map<String, Object> input = new LinkedHashMap<>();
        input.put("analysis_type", initialDiagnostic
                ? "INITIAL_DIAGNOSTIC" : "LEARNING_PLAN_PRODUCTION_OBSERVATION");
        input.put("modality", task.getEpreuve() == EpreuveType.TCF_EO ? "EO" : "EE");
        input.put("candidate_target_level", targetLevel);
        input.put("subject_title", task.getTitre());
        input.put("instruction", task.getConsigne());
        input.put("context", task.getContexte());
        input.put("allowed_skills", allowedSkills.stream().map(skill -> Map.of(
                "skill_code", skill.getCode(),
                "title", skill.getTitle(),
                "criterion", skill.getGeneralCriterion(),
                "target_level", skill.getTargetLevel())).toList());
        input.put(task.getEpreuve() == EpreuveType.TCF_EO
                ? "numbered_transcript" : "numbered_candidate_production", segments.rendu());
        input.put("available_evidence_segments", segments.taille());

        return "DONNÉES DU SUJET, ALLOWLIST ET PRODUCTION :\n"
                + serialize(input)
                + "\n\nRetourne exactement une entrée `skills` par code de `allowed_skills`, "
                + "sans en ajouter ni en omettre, puis appelle `submit_diagnostic_analysis`.";
    }

    public String buildRepairPrompt(
            String original, List<String> violations, Map<String, Object> rejected) {
        return original
                + "\n\nSORTIE PRÉCÉDENTE REFUSÉE PAR LE SERVEUR. Corrige toutes les violations "
                + "sans relâcher le contrat :\n- " + String.join("\n- ", violations)
                + "\n\nSORTIE REFUSÉE :\n" + serialize(rejected)
                + "\n\nRappelle maintenant `submit_diagnostic_analysis`.";
    }

    private String serialize(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            return String.valueOf(value);
        }
    }
}
