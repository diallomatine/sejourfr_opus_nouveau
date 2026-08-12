package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.DiagnosticTaskSkill;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.DiagnosticTaskSkillManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Assemble de façon déterministe les deux sorties structurées, sans troisième appel LLM. */
@Service
@RequiredArgsConstructor
public class DiagnosticSessionCoordinator {

    private final ProductionSubmissionManager submissionManager;
    private final DiagnosticProductionAnalysisManager analysisManager;
    private final DiagnosticSessionManager sessionManager;
    private final AttemptManager attemptManager;
    private final DiagnosticTaskSkillManager taskSkillManager;

    /**
     * Réserve atomiquement une relance. Le verrou de l'agrégat empêche deux
     * requêtes concurrentes de consommer le même état FAILED et de déclencher
     * chacune un nouveau pipeline payant.
     *
     * <p>Le caller lance les pipelines seulement après le retour de cette
     * méthode : la transaction et le verrou sont alors terminés, et les
     * workers async voient nécessairement l'état ANALYZING commité.</p>
     */
    @Transactional
    public RetryPlan beginRetry(UUID sessionId, UUID userId, int maxRetries) {
        DiagnosticSession session = sessionManager.findByIdForUpdate(sessionId)
                .filter(candidate -> candidate.getUser() != null
                        && userId.equals(candidate.getUser().getId()))
                .orElseThrow(() -> new NotFoundException(
                        "Diagnostic introuvable : " + sessionId));
        if (session.getStatus() != DiagnosticSessionStatus.FAILED) {
            throw new BusinessException("Seul un diagnostic en échec peut être relancé.");
        }
        if (session.getRetryCount() >= maxRetries) {
            throw new BusinessException(
                    "Plafond de " + maxRetries + " relances du diagnostic atteint.");
        }

        List<ProductionSubmission> submissions = submissions(session);
        if (submissions.isEmpty()) {
            throw new BusinessException("Aucune production diagnostic à relancer.");
        }
        List<UUID> failedSubmissionIds = new ArrayList<>();
        for (ProductionSubmission submission : submissions) {
            if (submission.getStatut() != SubmissionStatut.FAILED) continue;
            if (submission.getRetryCount() >= maxRetries) {
                throw new BusinessException(
                        "Plafond de " + maxRetries + " relances atteint.");
            }
            failedSubmissionIds.add(submission.getId());
        }

        session.setRetryCount((short) (session.getRetryCount() + 1));
        session.setStatus(DiagnosticSessionStatus.ANALYZING);
        session.setSummaryJson(null);
        session.setCompletedAt(null);
        session.setErrorMessage(null);
        sessionManager.save(session);
        return new RetryPlan(failedSubmissionIds, submissions.getFirst().getId());
    }

    @Transactional
    public void onAnalysisCompleted(UUID submissionId) {
        ProductionSubmission trigger = submissionManager.findById(submissionId).orElse(null);
        if (trigger == null) return;
        DiagnosticSession found = sessionManager
                .findByAttemptIdWithContent(trigger.getAttempt().getId()).orElse(null);
        if (found == null) return;
        DiagnosticSession session = sessionManager.findByIdForUpdate(found.getId()).orElse(null);
        if (session == null || session.getStatus() == DiagnosticSessionStatus.COMPLETED) return;

        ProductionSubmission written = onlySubmission(session.getWrittenAttempt().getId());
        ProductionSubmission oral = onlySubmission(session.getOralAttempt().getId());
        if (written == null || oral == null) {
            session.setStatus(DiagnosticSessionStatus.IN_PROGRESS);
            session.setErrorMessage(null);
            sessionManager.save(session);
            return;
        }
        // Une seconde étape peut être rendue après l'échec de la première. Ne
        // jamais écraser alors FAILED par ANALYZING : aucune analyse ne
        // redémarrera pour la première production avant le retry explicite.
        if (written.getStatut() == SubmissionStatut.FAILED
                || oral.getStatut() == SubmissionStatut.FAILED) {
            session.setStatus(DiagnosticSessionStatus.FAILED);
            sessionManager.save(session);
            return;
        }
        // Une analyse peut déjà être persistée alors que sa finalisation (par
        // exemple l'écriture des observations du Plan) a échoué. La présence
        // des deux JSON ne suffit donc jamais : les deux productions doivent
        // avoir achevé toute leur finalisation avant de compléter l'agrégat.
        if (written.getStatut() != SubmissionStatut.EVALUATED
                || oral.getStatut() != SubmissionStatut.EVALUATED) {
            session.setStatus(DiagnosticSessionStatus.ANALYZING);
            session.setErrorMessage(null);
            sessionManager.save(session);
            return;
        }
        DiagnosticProductionAnalysis writtenAnalysis =
                analysisManager.findBySubmissionId(written.getId()).orElse(null);
        DiagnosticProductionAnalysis oralAnalysis =
                analysisManager.findBySubmissionId(oral.getId()).orElse(null);
        if (writtenAnalysis == null || oralAnalysis == null) {
            session.setStatus(DiagnosticSessionStatus.ANALYZING);
            session.setErrorMessage(null);
            sessionManager.save(session);
            return;
        }

        session.setStatus(DiagnosticSessionStatus.ANALYZING);
        session.setSummaryJson(buildSummary(session, writtenAnalysis, oralAnalysis));
        session.setCompletedAt(Instant.now());
        session.setStatus(DiagnosticSessionStatus.COMPLETED);
        session.setErrorMessage(null);
        sessionManager.save(session);

        finishAttempt(session.getWrittenAttempt());
        finishAttempt(session.getOralAttempt());
    }

    private ProductionSubmission onlySubmission(UUID attemptId) {
        List<ProductionSubmission> submissions = submissionManager.findByAttemptId(attemptId);
        return submissions.isEmpty() ? null : submissions.getFirst();
    }

    private List<ProductionSubmission> submissions(DiagnosticSession session) {
        List<ProductionSubmission> result = new ArrayList<>();
        result.addAll(submissionManager.findByAttemptId(session.getWrittenAttempt().getId()));
        result.addAll(submissionManager.findByAttemptId(session.getOralAttempt().getId()));
        return result;
    }

    private Map<String, Object> buildSummary(
            DiagnosticSession session,
            DiagnosticProductionAnalysis written,
            DiagnosticProductionAnalysis oral) {
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("written_submission_id", written.getSubmission().getId().toString());
        summary.put("oral_submission_id", oral.getSubmission().getId().toString());

        LinkedHashSet<String> strengths = new LinkedHashSet<>();
        strengths.addAll(strings(written.getAnalysisJson().get("strengths")));
        strengths.addAll(strings(oral.getAnalysisJson().get("strengths")));
        summary.put("strengths", strengths.stream().limit(3).toList());

        List<Map<String, Object>> selected = mergePriorities(
                ranked(written.getAnalysisJson(), session.getWrittenTask().getId()),
                ranked(oral.getAnalysisJson(), session.getOralTask().getId()));
        summary.put("priority_skill_codes", selected.stream()
                .map(item -> String.valueOf(item.get("skill_code"))).toList());
        summary.put("main_priority_explanation", selected.isEmpty() ? null
                : selected.getFirst().get("explanation"));
        return summary;
    }

    /**
     * Ordonne les priorités d'UNE production : confiance décroissante, puis rang
     * de la compétence dans l'allowlist du sujet
     * ({@code diagnostic_task_skills.display_order}).
     *
     * <p>Ce rang n'est pas décoratif : c'est l'ordre éditorial d'importance des
     * huit compétences observables par ce sujet. Une compétence absente de
     * l'allowlist — cas qui ne devrait pas exister, le validateur la refuse —
     * passe en dernier, puis on retombe sur le code pour rester déterministe.
     */
    private List<RankedPriority> ranked(Map<String, Object> analysis, UUID taskId) {
        Map<String, Short> order = new LinkedHashMap<>();
        for (DiagnosticTaskSkill allowed : taskSkillManager.findActiveByTaskId(taskId)) {
            order.put(allowed.getSkill().getCode(), allowed.getDisplayOrder());
        }
        List<RankedPriority> priorities = new ArrayList<>();
        for (Map<String, Object> item : prioritySkills(analysis)) {
            String code = String.valueOf(item.get("skill_code"));
            priorities.add(new RankedPriority(
                    item, code, confidenceRank(item.get("confidence")),
                    order.getOrDefault(code, Short.MAX_VALUE)));
        }
        priorities.sort(Comparator
                .comparingInt(RankedPriority::confidence).reversed()
                .thenComparingInt(RankedPriority::order)
                .thenComparing(RankedPriority::skillCode));
        return priorities;
    }

    /** Une priorité et ses deux clés de tri, résolues une seule fois. */
    private record RankedPriority(
            Map<String, Object> item, String skillCode, int confidence, int order) {}

    /**
     * Fusionne les priorités des deux productions, au plus trois.
     *
     * <p><b>Pourquoi pas un tri global.</b> Le départage historique se faisait
     * sur l'ordre alphabétique du code de compétence : « EE… » précède toujours
     * « EO… », donc l'écrit passait mécaniquement devant l'oral et les
     * compétences C1/C2 devant les autres. Un rang alphabétique ne dit rien de
     * l'importance pédagogique.
     *
     * <p>La règle retenue, à confiance égale : le rang d'allowlist le plus bas
     * gagne ; à rang égal, on <b>alterne</b> écrit et oral plutôt que de servir
     * un bloc de trois priorités écrites — un plan qui ne parlerait que d'une
     * seule épreuve serait faux, le diagnostic en observe deux. La toute
     * première égalité parfaite revient à l'écrit, produit en premier dans le
     * parcours. Entièrement déterministe.
     */
    private static List<Map<String, Object>> mergePriorities(
            List<RankedPriority> written, List<RankedPriority> oral) {
        List<Map<String, Object>> merged = new ArrayList<>(3);
        int w = 0;
        int o = 0;
        Boolean lastWasWritten = null;
        while (merged.size() < 3 && (w < written.size() || o < oral.size())) {
            boolean takeWritten;
            if (o >= oral.size()) {
                takeWritten = true;
            } else if (w >= written.size()) {
                takeWritten = false;
            } else {
                int cmp = comparePriority(written.get(w), oral.get(o));
                takeWritten = cmp != 0 ? cmp < 0 : !Boolean.TRUE.equals(lastWasWritten);
            }
            merged.add(takeWritten ? written.get(w++).item() : oral.get(o++).item());
            lastWasWritten = takeWritten;
        }
        return merged;
    }

    /** Négatif = la priorité écrite passe devant ; zéro = égalité résiduelle. */
    private static int comparePriority(RankedPriority written, RankedPriority oral) {
        int byConfidence = Integer.compare(oral.confidence(), written.confidence());
        return byConfidence != 0 ? byConfidence : Integer.compare(written.order(), oral.order());
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> prioritySkills(Map<String, Object> analysis) {
        if (!(analysis.get("skills") instanceof List<?> raw)) return List.of();
        return raw.stream()
                .filter(Map.class::isInstance)
                .map(item -> (Map<String, Object>) item)
                .filter(item -> Boolean.TRUE.equals(item.get("priority")))
                .toList();
    }

    private static List<String> strings(Object raw) {
        if (!(raw instanceof List<?> list)) return List.of();
        return list.stream().filter(String.class::isInstance).map(String.class::cast).toList();
    }

    private static int confidenceRank(Object raw) {
        return switch (String.valueOf(raw)) {
            case "HIGH" -> 3;
            case "MEDIUM" -> 2;
            default -> 1;
        };
    }

    private void finishAttempt(com.sejourfr.app.entity.Attempt attempt) {
        attempt.setFinishedAt(Instant.now());
        attempt.setStatus(AttemptStatus.TERMINE);
        attemptManager.save(attempt);
    }

    public record RetryPlan(
            List<UUID> failedSubmissionIds,
            UUID assemblyTriggerSubmissionId) {
        public RetryPlan {
            failedSubmissionIds = List.copyOf(failedSubmissionIds);
        }
    }
}
