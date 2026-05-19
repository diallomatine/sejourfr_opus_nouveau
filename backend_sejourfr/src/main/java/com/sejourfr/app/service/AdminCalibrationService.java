package com.sejourfr.app.service;

import com.sejourfr.app.dto.CalibrationStatsDto;
import com.sejourfr.app.dto.HumanCalibrationNoteDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.repository.AiEvaluationRepository;
import com.sejourfr.app.repository.HumanCalibrationNoteRepository;
import com.sejourfr.app.repository.ProductionSubmissionRepository;
import com.sejourfr.app.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Service backend de la console admin de calibration IA :
 * - selectionne les submissions a annoter ;
 * - enregistre une note humaine + calcule l'ecart vs derniere {@link AiEvaluation} ;
 * - produit un dashboard de fiabilite.
 */
@Service
public class AdminCalibrationService {

    /** Seuil au-dela duquel un ecart est considere "hors cible" (spec section 3.2). */
    private static final BigDecimal SEUIL_HORS_CIBLE = new BigDecimal("3.0");
    private static final BigDecimal CIBLE_ECART_MOYEN_ABS = new BigDecimal("1.5");
    private static final BigDecimal CIBLE_POURCENTAGE_HORS = new BigDecimal("5");

    private final ProductionSubmissionRepository submissionRepository;
    private final AiEvaluationRepository aiEvaluationRepository;
    private final HumanCalibrationNoteRepository humanNoteRepository;
    private final UserRepository userRepository;

    public AdminCalibrationService(
            ProductionSubmissionRepository submissionRepository,
            AiEvaluationRepository aiEvaluationRepository,
            HumanCalibrationNoteRepository humanNoteRepository,
            UserRepository userRepository) {
        this.submissionRepository = submissionRepository;
        this.aiEvaluationRepository = aiEvaluationRepository;
        this.humanNoteRepository = humanNoteRepository;
        this.userRepository = userRepository;
    }

    /** Submissions deja evaluees mais pas encore annotees par un humain. */
    public List<ProductionSubmission> listAToAnnoter(int limit) {
        int safe = Math.max(1, Math.min(limit, 200));
        return submissionRepository.findByStatutOrderBySubmittedAtAsc(SubmissionStatut.EVALUATED).stream()
            .filter(s -> humanNoteRepository.findBySubmissionIdOrderByCreatedAtDesc(s.getId()).isEmpty())
            .limit(safe)
            .toList();
    }

    /** Toutes les submissions evaluees (annotees ou non). */
    public List<ProductionSubmission> listEvaluated(int limit) {
        int safe = Math.max(1, Math.min(limit, 200));
        return submissionRepository.findByStatutOrderBySubmittedAtAsc(SubmissionStatut.EVALUATED).stream()
            .limit(safe)
            .toList();
    }

    @Transactional
    public HumanCalibrationNote enregistrer(UUID submissionId, UUID evaluatorId, HumanCalibrationNoteDto dto) {
        if (dto == null) throw new BusinessException("Payload manquant.");
        if (dto.noteHumaineSurVingt() == null) {
            throw new BusinessException("note_humaine_sur_20 requise.");
        }
        if (dto.noteHumaineSurVingt().compareTo(BigDecimal.ZERO) < 0
                || dto.noteHumaineSurVingt().compareTo(new BigDecimal("20")) > 0) {
            throw new BusinessException("note_humaine_sur_20 doit etre dans [0, 20].");
        }
        if (dto.niveauCecrlHumain() == null) {
            throw new BusinessException("niveau_cecrl_humain requis.");
        }
        ProductionSubmission sub = submissionRepository.findById(submissionId)
            .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        User evaluator = userRepository.findById(evaluatorId)
            .orElseThrow(() -> new NotFoundException("Evaluateur introuvable : " + evaluatorId));

        BigDecimal ecart = null;
        AiEvaluation ai = aiEvaluationRepository
            .findFirstBySubmissionIdOrderByEvaluatedAtDesc(submissionId)
            .orElse(null);
        if (ai != null && ai.getNoteSur20() != null) {
            ecart = dto.noteHumaineSurVingt().subtract(ai.getNoteSur20()).setScale(1, RoundingMode.HALF_UP);
        }

        HumanCalibrationNote note = new HumanCalibrationNote();
        note.setSubmission(sub);
        note.setEvaluator(evaluator);
        note.setNoteHumaineSur20(dto.noteHumaineSurVingt().setScale(1, RoundingMode.HALF_UP));
        note.setNiveauCecrlHumain(NiveauCecrl.valueOf(dto.niveauCecrlHumain().name()));
        note.setCommentaires(dto.commentaires());
        note.setEcartNote(ecart);
        return humanNoteRepository.save(note);
    }

    public CalibrationStatsDto stats() {
        // On parcourt toutes les notes pour calculer moyenne + ecart-type. A
        // l'echelle attendue (50-200 notes, max), ca reste negligeable. Si la
        // table explose, il faudra basculer sur des aggregats SQL.
        List<HumanCalibrationNote> notes = humanNoteRepository.findAll();
        List<BigDecimal> ecarts = new ArrayList<>();
        for (HumanCalibrationNote n : notes) {
            if (n.getEcartNote() != null) ecarts.add(n.getEcartNote());
        }
        long total = ecarts.size();
        if (total == 0) {
            return new CalibrationStatsDto(
                0L,
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO,
                0L, BigDecimal.ZERO,
                SEUIL_HORS_CIBLE, false
            );
        }

        BigDecimal somme = BigDecimal.ZERO;
        BigDecimal sommeAbs = BigDecimal.ZERO;
        long horsCible = 0;
        for (BigDecimal e : ecarts) {
            somme = somme.add(e);
            BigDecimal abs = e.abs();
            sommeAbs = sommeAbs.add(abs);
            if (abs.compareTo(SEUIL_HORS_CIBLE) > 0) horsCible++;
        }
        BigDecimal totalBd = BigDecimal.valueOf(total);
        BigDecimal moyenne = somme.divide(totalBd, 2, RoundingMode.HALF_UP);
        BigDecimal moyenneAbs = sommeAbs.divide(totalBd, 2, RoundingMode.HALF_UP);

        BigDecimal sommeCarresEcartsAbs = BigDecimal.ZERO;
        for (BigDecimal e : ecarts) {
            BigDecimal d = e.abs().subtract(moyenneAbs);
            sommeCarresEcartsAbs = sommeCarresEcartsAbs.add(d.multiply(d));
        }
        BigDecimal variance = sommeCarresEcartsAbs.divide(totalBd, 4, RoundingMode.HALF_UP);
        BigDecimal ecartType = BigDecimal.valueOf(Math.sqrt(variance.doubleValue()))
            .setScale(2, RoundingMode.HALF_UP);

        BigDecimal pourcentage = BigDecimal.valueOf(horsCible)
            .multiply(BigDecimal.valueOf(100))
            .divide(totalBd, 1, RoundingMode.HALF_UP);

        boolean calibre = moyenneAbs.compareTo(CIBLE_ECART_MOYEN_ABS) < 0
            && pourcentage.compareTo(CIBLE_POURCENTAGE_HORS) < 0;

        return new CalibrationStatsDto(
            total, moyenne, moyenneAbs, ecartType, horsCible, pourcentage,
            SEUIL_HORS_CIBLE, calibre
        );
    }

    /** Convenience pour les controllers (pagination simple, sort par defaut). */
    @SuppressWarnings("unused")
    public PageRequest defaultPage() {
        return PageRequest.of(0, 50);
    }
}
