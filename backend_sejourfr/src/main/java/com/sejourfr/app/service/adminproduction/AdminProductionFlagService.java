package com.sejourfr.app.service.adminproduction;

import com.sejourfr.app.dto.AdminProductionFlagDto;
import com.sejourfr.app.dto.AdminProductionFlagRequest;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.AiEvaluationFlag;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AdminProductionReadManager;
import com.sejourfr.app.manager.AiEvaluationFlagManager;
import com.sejourfr.app.manager.AiEvaluationManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Signalements admin d'une évaluation IA (F-3 A, V085) : créer, marquer
 * vérifié, retirer. 🛑 N'écrit QUE dans {@code ai_evaluation_flags} : ni note,
 * ni niveau, ni feedback ne bougent, et le candidat voit exactement la même
 * chose avant et après. L'admin auteur vient du contexte de sécurité.
 */
@Service
@RequiredArgsConstructor
public class AdminProductionFlagService {

    private final AdminProductionReadManager readManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final AiEvaluationFlagManager flagManager;
    private final AdminProductionService productionService;

    /**
     * Signale la DERNIÈRE évaluation (celle que voit le candidat), NON_EVALUABLE
     * comprise.
     *
     * @throws NotFoundException    (404) production inconnue ou hors périmètre
     * @throws BusinessException    (422) aucune évaluation (en cours, échec)
     * @throws IllegalStateException (409) un signalement est déjà actif
     */
    @Transactional
    public AdminProductionFlagDto signaler(UUID submissionId, UUID adminId, AdminProductionFlagRequest request) {
        if (readManager.findLigne(submissionId).isEmpty()) {
            throw new NotFoundException("Production introuvable : " + submissionId);
        }
        AiEvaluation evaluation = aiEvaluationManager.findLatestBySubmissionId(submissionId)
                .orElseThrow(() -> new BusinessException(
                        "Cette production n'a pas d'évaluation : il n'y a rien à signaler."));
        if (flagManager.existsActiveForEvaluation(evaluation.getId())) {
            throw new IllegalStateException("Cette évaluation est déjà signalée.");
        }
        AiEvaluationFlag flag = new AiEvaluationFlag();
        flag.setEvaluationId(evaluation.getId());
        flag.setSubmissionId(submissionId);
        flag.setMotif(request.motif());
        flag.setCommentaire(blankToNull(request.commentaire()));
        flag.setCreatedBy(adminId);
        flag.setCreatedAt(Instant.now());
        return dto(flagManager.save(flag));
    }

    /**
     * Marque vérifié un signalement actif. Idempotent : déjà vérifié, il est
     * rendu tel quel.
     *
     * @throws IllegalStateException (409) le signalement a été retiré
     */
    @Transactional
    public AdminProductionFlagDto verifier(UUID flagId, UUID adminId) {
        AiEvaluationFlag flag = charger(flagId);
        if (flag.getRemovedAt() != null) {
            throw new IllegalStateException("Ce signalement a été retiré : il ne peut plus être vérifié.");
        }
        if (flag.getVerifiedAt() == null) {
            flag.setVerifiedAt(Instant.now());
            flag.setVerifiedBy(adminId);
            flag = flagManager.save(flag);
        }
        return dto(flag);
    }

    /**
     * Retire un signalement (soft : la ligne reste dans l'historique).
     * Idempotent : déjà retiré, il est rendu tel quel.
     */
    @Transactional
    public AdminProductionFlagDto retirer(UUID flagId, UUID adminId) {
        AiEvaluationFlag flag = charger(flagId);
        if (flag.getRemovedAt() == null) {
            flag.setRemovedAt(Instant.now());
            flag.setRemovedBy(adminId);
            flag = flagManager.save(flag);
        }
        return dto(flag);
    }

    private AiEvaluationFlag charger(UUID flagId) {
        return flagManager.findById(flagId)
                .orElseThrow(() -> new NotFoundException("Signalement introuvable : " + flagId));
    }

    private AdminProductionFlagDto dto(AiEvaluationFlag flag) {
        return productionService.signalements(List.of(flag)).getFirst();
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}
