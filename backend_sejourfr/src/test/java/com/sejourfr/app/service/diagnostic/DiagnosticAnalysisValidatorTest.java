package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.EvaluationProductionSegments;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class DiagnosticAnalysisValidatorTest {

    private final DiagnosticAnalysisValidator validator = new DiagnosticAnalysisValidator();
    private final EvaluationProductionSegments segments = EvaluationProductionSegments.of(
            "Je me présente clairement. Ensuite, je développe mon choix.", EpreuveType.TCF_EE);

    @Test
    void accepteUneAllowlistExacteEtResoutLaPreuveServeur() {
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "PRIORITY", 1, "HIGH", true),
                notObserved("EE1-C8")));

        assertThat(validator.violations(output, skills("EE1-C1", "EE1-C8"), segments)).isEmpty();
        assertThat(validator.normalize(output, segments))
                .extracting("skills")
                .asList()
                .first()
                .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.MAP)
                .containsEntry("evidence", "Je me présente clairement.");
    }

    @Test
    void refuseUnNumeroDeSegmentFractionnaireSansArrondiImplicite() {
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "TO_REINFORCE", 1.9d, "MEDIUM", false)));

        assertThat(validator.violations(output, skills("EE1-C1"), segments))
                .anyMatch(message -> message.contains("evidence_segment"));
    }

    @Test
    void verrouilleAllowlistCodesUniquesEtExhaustivite() {
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "TO_REINFORCE", 1, "MEDIUM", false),
                observed("EE1-C1", "TO_REINFORCE", 2, "MEDIUM", false),
                observed("EO3-C8", "TO_REINFORCE", 2, "MEDIUM", false)));

        assertThat(validator.violations(output, skills("EE1-C1", "EE1-C8"), segments))
                .anyMatch(message -> message.contains("dupliqué"))
                .anyMatch(message -> message.contains("hors allowlist"))
                .anyMatch(message -> message.contains("manquantes"));
    }

    @Test
    void refusePlusDeDeuxPrioritesEtLesIncoherencesNonObservees() {
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "PRIORITY", 1, "HIGH", true),
                observed("EE1-C8", "PRIORITY", 1, "HIGH", true),
                observed("EE2-C2", "PRIORITY", 2, "HIGH", true),
                skill("EE2-C3", false, "SOLID", 1, "MEDIUM", true)));

        assertThat(validator.violations(
                output, skills("EE1-C1", "EE1-C8", "EE2-C2", "EE2-C3"), segments))
                .anyMatch(message -> message.contains("maximum 2 priorités"))
                .anyMatch(message -> message.contains("non observée doit être NOT_OBSERVED"))
                .anyMatch(message -> message.contains("preuve interdite"))
                .anyMatch(message -> message.contains("confiance LOW"));
    }

    @Test
    void appliqueCoteServeurLesLongueursDuSchemaVersionne() {
        Map<String, Object> output = validOutput(List.of(notObserved("EE1-C1")));
        output.put("summary", "x".repeat(DiagnosticAnalysisValidator.MAX_SUMMARY_LENGTH + 1));
        output.put("strengths", List.of("x".repeat(
                DiagnosticAnalysisValidator.MAX_LIST_ITEM_LENGTH + 1)));
        @SuppressWarnings("unchecked")
        Map<String, Object> skill = (Map<String, Object>) ((List<?>) output.get("skills")).getFirst();
        skill.put("explanation", "x".repeat(
                DiagnosticAnalysisValidator.MAX_EXPLANATION_LENGTH + 1));

        assertThat(validator.violations(output, skills("EE1-C1"), segments))
                .anyMatch(message -> message.contains("summary dépasse"))
                .anyMatch(message -> message.contains("strengths[] dépasse"))
                .anyMatch(message -> message.contains("explanation dépasse"));
    }

    private static Map<String, Object> validOutput(List<Map<String, Object>> skillItems) {
        Map<String, Object> output = new LinkedHashMap<>();
        output.put("level_estimate", "B1");
        output.put("task_completion", "COMPLETED");
        output.put("communication_status", "EFFECTIVE");
        output.put("summary", "Une production compréhensible.");
        output.put("strengths", List.of("Intention claire"));
        output.put("weaknesses", List.of("Développement à préciser"));
        output.put("skills", new ArrayList<>(skillItems));
        return output;
    }

    private static Map<String, Object> observed(
            String code, String status, Number segment, String confidence, boolean priority) {
        return skill(code, true, status, segment, confidence, priority);
    }

    private static Map<String, Object> notObserved(String code) {
        return skill(code, false, "NOT_OBSERVED", null, "LOW", false);
    }

    private static Map<String, Object> skill(
            String code, boolean observed, String status, Number segment,
            String confidence, boolean priority) {
        Map<String, Object> skill = new LinkedHashMap<>();
        skill.put("skill_code", code);
        skill.put("observed", observed);
        skill.put("status", status);
        skill.put("evidence_segment", segment);
        skill.put("explanation", observed ? "Signal observé." : "Non observable dans cette production.");
        skill.put("confidence", confidence);
        skill.put("priority", priority);
        return skill;
    }

    private static List<Skill> skills(String... codes) {
        return java.util.Arrays.stream(codes).map(code -> {
            Skill skill = new Skill();
            skill.setCode(code);
            return skill;
        }).toList();
    }
}
