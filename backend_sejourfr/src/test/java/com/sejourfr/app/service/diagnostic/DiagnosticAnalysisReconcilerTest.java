package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.EvaluationProductionSegments;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le serveur dérive {@code priority} et tronque le plafond de priorités : ces
 * deux motifs ne peuvent plus faire échouer une analyse — c'est exactement ce
 * qui avait détruit un diagnostic réel, donc les deux productions du candidat.
 */
class DiagnosticAnalysisReconcilerTest {

    private final DiagnosticReconciliationMetrics metrics = new DiagnosticReconciliationMetrics();
    private final DiagnosticAnalysisReconciler reconciler = new DiagnosticAnalysisReconciler(metrics);
    private final DiagnosticAnalysisValidator validator = new DiagnosticAnalysisValidator();
    private final EvaluationProductionSegments segments = EvaluationProductionSegments.of(
            "Je me présente clairement. Ensuite, je développe mon choix. "
                    + "Enfin, je conclus poliment. Merci beaucoup.",
            EpreuveType.TCF_EE);

    @Test
    void statusPrioritySansDrapeauPoseLaPrioriteAuLieuDeRefuser() {
        List<Skill> allowed = skills("EE1-C1", "EE1-C2");
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "PRIORITY", 1, "HIGH", false),
                observed("EE1-C2", "SOLID", 2, "HIGH", false)));

        Map<String, Object> reconciled = reconciler.reconcile(output, allowed);

        assertThat(validator.violations(reconciled, allowed, segments)).isEmpty();
        assertThat(priority(reconciled, "EE1-C1")).isEqualTo(true);
        assertThat(priority(reconciled, "EE1-C2")).isEqualTo(false);
        assertThat(metrics.compteurs()).containsEntry("PRIORITE_DERIVEE_POSEE", 1L);
    }

    @Test
    void drapeauSansStatusPriorityEstRetireAuLieuDeRefuser() {
        List<Skill> allowed = skills("EE1-C1", "EE1-C2");
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "TO_REINFORCE", 1, "HIGH", true),
                observed("EE1-C2", "SOLID", 2, "HIGH", false)));

        Map<String, Object> reconciled = reconciler.reconcile(output, allowed);

        assertThat(validator.violations(reconciled, allowed, segments)).isEmpty();
        assertThat(priority(reconciled, "EE1-C1")).isEqualTo(false);
        assertThat(metrics.compteurs()).containsEntry("PRIORITE_DERIVEE_RETIREE", 1L);
    }

    @Test
    void uneCompetenceNonObserveeNestJamaisPrioritaire() {
        List<Skill> allowed = skills("EE1-C1");
        Map<String, Object> output = validOutput(List.of(
                skill("EE1-C1", false, "NOT_OBSERVED", null, "LOW", true)));

        Map<String, Object> reconciled = reconciler.reconcile(output, allowed);

        assertThat(validator.violations(reconciled, allowed, segments)).isEmpty();
        assertThat(priority(reconciled, "EE1-C1")).isEqualTo(false);
    }

    /** La confiance prime : le rang d'allowlist ne départage qu'à confiance égale. */
    @Test
    void troisPrioritesSontTronqueesALaConfianceDecroissante() {
        List<Skill> allowed = skills("EE1-C1", "EE1-C2", "EE1-C3");
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "PRIORITY", 1, "LOW", true),
                observed("EE1-C2", "PRIORITY", 2, "HIGH", true),
                observed("EE1-C3", "PRIORITY", 3, "MEDIUM", true)));

        Map<String, Object> reconciled = reconciler.reconcile(output, allowed);

        assertThat(validator.violations(reconciled, allowed, segments)).isEmpty();
        assertThat(priorityCodes(reconciled)).containsExactlyInAnyOrder("EE1-C2", "EE1-C3");
        assertThat(status(reconciled, "EE1-C1")).isEqualTo("TO_REINFORCE");
        assertThat(status(reconciled, "EE1-C2")).isEqualTo("PRIORITY");
        assertThat(metrics.compteurs()).containsEntry("PRIORITE_TRONQUEE", 1L);
    }

    /**
     * À confiance égale, c'est le rang d'allowlist ({@code display_order}) qui
     * tranche — <b>jamais</b> l'alphabet du code. L'allowlist est ici
     * volontairement à l'envers de l'ordre alphabétique : un départage
     * alphabétique garderait C1 et C2, il doit garder C4 et C3.
     */
    @Test
    void quatrePrioritesSontDepartageesParDisplayOrderJamaisParLAlphabet() {
        List<Skill> allowed = skills("EO1-C4", "EO1-C3", "EO1-C2", "EO1-C1");
        Map<String, Object> output = validOutput(List.of(
                observed("EO1-C1", "PRIORITY", 1, "HIGH", true),
                observed("EO1-C2", "PRIORITY", 2, "HIGH", true),
                observed("EO1-C3", "PRIORITY", 3, "HIGH", true),
                observed("EO1-C4", "PRIORITY", 4, "HIGH", true)));

        Map<String, Object> reconciled = reconciler.reconcile(output, allowed);

        assertThat(validator.violations(reconciled, allowed, segments)).isEmpty();
        assertThat(priorityCodes(reconciled)).containsExactlyInAnyOrder("EO1-C4", "EO1-C3");
        assertThat(status(reconciled, "EO1-C1")).isEqualTo("TO_REINFORCE");
        assertThat(status(reconciled, "EO1-C2")).isEqualTo("TO_REINFORCE");
        assertThat(metrics.compteurs()).containsEntry("PRIORITE_TRONQUEE", 2L);
    }

    @Test
    void laSortieNormaliseePorteLesValeursReconciliees() {
        List<Skill> allowed = skills("EE1-C1", "EE1-C2", "EE1-C3");
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "PRIORITY", 1, "HIGH", false),
                observed("EE1-C2", "PRIORITY", 2, "MEDIUM", true),
                observed("EE1-C3", "PRIORITY", 3, "LOW", true)));

        Map<String, Object> normalized = validator.normalize(
                reconciler.reconcile(output, allowed), segments);

        assertThat(priority(normalized, "EE1-C1")).isEqualTo(true);
        assertThat(priority(normalized, "EE1-C3")).isEqualTo(false);
        assertThat(status(normalized, "EE1-C3")).isEqualTo("TO_REINFORCE");
        assertThat(item(normalized, "EE1-C1")).containsEntry("evidence", "Je me présente clairement.");
    }

    /** La réconciliation n'assouplit rien d'autre : les vraies violations restent. */
    @Test
    void laisseIntactesLesViolationsQuiNeConcernentPasLaPriorite() {
        List<Skill> allowed = skills("EE1-C1", "EE1-C2");
        Map<String, Object> output = validOutput(List.of(
                observed("EE1-C1", "PRIORITY", 99, "HIGH", false),
                observed("EE3-C7", "PRIORITY", 1, "HIGH", true)));
        output.put("level_estimate", "C1");
        @SuppressWarnings("unchecked")
        Map<String, Object> first = (Map<String, Object>) ((List<?>) output.get("skills")).getFirst();
        first.put("champ_invente", "x");

        assertThat(validator.violations(reconciler.reconcile(output, allowed), allowed, segments))
                .anyMatch(message -> message.contains("evidence_segment"))
                .anyMatch(message -> message.contains("hors allowlist"))
                .anyMatch(message -> message.contains("manquantes"))
                .anyMatch(message -> message.contains("champs hors contrat"))
                .anyMatch(message -> message.contains("plafonné à B2"));
    }

    @Test
    void uneSortieSansListeDeCompetencesEstLaisseeAuValidateur() {
        Map<String, Object> output = validOutput(List.of());
        output.put("skills", "pas une liste");

        assertThat(reconciler.reconcile(output, skills("EE1-C1"))).isSameAs(output);
        assertThat(metrics.compteurs()).isEmpty();
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> item(Map<String, Object> output, String code) {
        return ((List<?>) output.get("skills")).stream()
                .map(raw -> (Map<String, Object>) raw)
                .filter(skill -> code.equals(skill.get("skill_code")))
                .findFirst().orElseThrow();
    }

    private static Object priority(Map<String, Object> output, String code) {
        return item(output, code).get("priority");
    }

    private static String status(Map<String, Object> output, String code) {
        return String.valueOf(item(output, code).get("status"));
    }

    @SuppressWarnings("unchecked")
    /** Les codes restés prioritaires, dans l'ordre du document. */
    private static List<String> priorityCodes(Map<String, Object> output) {
        return ((List<?>) output.get("skills")).stream()
                .map(raw -> (Map<String, Object>) raw)
                .filter(skill -> Boolean.TRUE.equals(skill.get("priority")))
                .map(skill -> String.valueOf(skill.get("skill_code")))
                .toList();
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

    private static Map<String, Object> skill(
            String code, boolean observed, String status, Number segment,
            String confidence, boolean priority) {
        Map<String, Object> skill = new LinkedHashMap<>();
        skill.put("skill_code", code);
        skill.put("observed", observed);
        skill.put("status", status);
        skill.put("evidence_segment", segment);
        skill.put("explanation", observed ? "Signal observé." : "Non observable ici.");
        skill.put("confidence", confidence);
        skill.put("priority", priority);
        return skill;
    }

    private static List<Skill> skills(String... codes) {
        return Arrays.stream(codes).map(code -> {
            Skill skill = new Skill();
            skill.setCode(code);
            return skill;
        }).toList();
    }
}
