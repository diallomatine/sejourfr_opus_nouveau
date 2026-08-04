package com.sejourfr.app.service;

import com.sejourfr.app.dto.CalibrationStatsDto;
import com.sejourfr.app.dto.HumanCalibrationNoteDto;
import com.sejourfr.app.dto.NiveauCalibrationStatsDto;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.HumanCalibrationNoteManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.HumanCalibrationNoteMapper;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Service backend de la console admin de calibration IA :
 * <ul>
 *   <li>selectionne les submissions a annoter ;</li>
 *   <li>enregistre une note humaine + calcule l'ecart vs derniere {@link AiEvaluation} ;</li>
 *   <li>produit un dashboard de fiabilite.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class AdminCalibrationService {

    /**
     * Seuil au-dela duquel un ecart est considere "hors cible" (spec section 3.2).
     */
    private static final BigDecimal SEUIL_HORS_CIBLE = new BigDecimal("3.0");
    private static final BigDecimal CIBLE_ECART_MOYEN_ABS = new BigDecimal("1.5");
    private static final BigDecimal CIBLE_POURCENTAGE_HORS = new BigDecimal("5");

    private static final BigDecimal NOTE_MIN = BigDecimal.ZERO;
    private static final BigDecimal NOTE_MAX = new BigDecimal("20");

    private static final int LIMIT_MIN = 1;
    private static final int LIMIT_MAX = 200;

    private final ProductionSubmissionManager submissionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final HumanCalibrationNoteManager humanNoteManager;
    private final UserManager userManager;
    private final ProductionSubmissionMapper submissionMapper;
    private final HumanCalibrationNoteMapper noteMapper;

    // ------------------------------------------------------------------------
    // Liste des submissions
    // ------------------------------------------------------------------------

    /**
     * Liste les submissions evaluees. {@code hasHumanNote=true} ne retourne que
     * les submissions DEJA annotees ; {@code false} ou absent, que celles encore
     * vierges. Seul {@code status=evaluated} est supporte pour l'instant.
     *
     * <p>Les ids annotes sont charges en UNE requete (et non par une lecture des
     * notes submission par submission) : la liste peut monter a
     * {@value #LIMIT_MAX} lignes.
     */
    @Transactional(readOnly = true)
    public List<ProductionSubmissionDto> listSubmissions(String status, Boolean hasHumanNote, int limit) {
        if (!"evaluated".equalsIgnoreCase(status)) {
            throw new BusinessException("status=evaluated est le seul filtre supporte pour l'instant.");
        }
        int safe = clampLimit(limit);

        List<ProductionSubmission> base = submissionManager
                .findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATED);

        Set<UUID> annotees = humanNoteManager.findAnnotatedSubmissionIds(
                base.stream().map(ProductionSubmission::getId).toList());
        boolean veutAnnotees = Boolean.TRUE.equals(hasHumanNote);

        List<ProductionSubmission> filtered = base.stream()
                .filter(s -> annotees.contains(s.getId()) == veutAnnotees)
                .limit(safe)
                .toList();

        return filtered.stream().map(submissionMapper::toDtoWithSignedAudio).toList();
    }

    /**
     * Derniere note humaine d'une submission, pour reafficher le formulaire
     * d'annotation pre-rempli. 404 si la submission n'a jamais ete annotee : la
     * console admin distingue ainsi "pas encore annotee" de "annotee avec ces
     * valeurs", sans avoir a deduire quoi que ce soit d'une difference de listes.
     */
    @Transactional(readOnly = true)
    public HumanCalibrationNoteDto latestHumanNote(UUID submissionId) {
        return humanNoteManager.findLatestBySubmission(submissionId)
                .map(noteMapper::toDto)
                .orElseThrow(() -> new NotFoundException(
                        "Aucune note humaine pour la submission " + submissionId));
    }

    // ------------------------------------------------------------------------
    // Enregistrement d'une note humaine
    // ------------------------------------------------------------------------

    @Transactional
    public HumanCalibrationNoteDto annoter(UUID submissionId, UUID evaluatorId, HumanCalibrationNoteDto dto) {
        validateNotePayload(dto);

        ProductionSubmission sub = submissionManager.findById(submissionId)
                .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        User evaluator = userManager.findById(evaluatorId)
                .orElseThrow(() -> new NotFoundException("Evaluateur introuvable : " + evaluatorId));

        BigDecimal ecart = computeEcart(submissionId, dto.noteHumaineSurVingt());

        HumanCalibrationNote note = new HumanCalibrationNote();
        note.setSubmission(sub);
        note.setEvaluator(evaluator);
        note.setNoteHumaineSur20(dto.noteHumaineSurVingt().setScale(1, RoundingMode.HALF_UP));
        note.setNiveauCecrlHumain(NiveauCecrl.valueOf(dto.niveauCecrlHumain().name()));
        note.setCommentaires(dto.commentaires());
        note.setEcartNote(ecart);

        return noteMapper.toDto(humanNoteManager.save(note));
    }

    // ------------------------------------------------------------------------
    // Dashboard de fiabilite
    // ------------------------------------------------------------------------

    /**
     * On parcourt toutes les notes pour calculer moyenne + ecart-type. A
     * l'echelle attendue (50-200 notes, max), ca reste negligeable. Si la
     * table explose, il faudra basculer sur des agregats SQL.
     *
     * <p><b>Une submission ne compte qu'une fois</b> : seule sa DERNIERE note
     * humaine entre dans l'agregat (cf. {@link #derniereNoteParSubmission}).
     * Les notes sont historisees — sans ce filtre, une production reannotee
     * trois fois pesait trois fois et biaisait silencieusement la mesure censee
     * nous dire si l'IA note juste.
     */
    @Transactional(readOnly = true)
    public CalibrationStatsDto stats() {
        List<BigDecimal> ecarts = new ArrayList<>();
        for (HumanCalibrationNote n : derniereNoteParSubmission()) {
            if (n.getEcartNote() != null) ecarts.add(n.getEcartNote());
        }
        long total = ecarts.size();
        if (total == 0) {
            return new CalibrationStatsDto(
                    0L, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO,
                    0L, BigDecimal.ZERO, SEUIL_HORS_CIBLE, false);
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
                total, moyenne, moyenneAbs, ecartType,
                horsCible, pourcentage, SEUIL_HORS_CIBLE, calibre);
    }

    /**
     * Ecart NIVEAU CECRL : LLM brut ({@code niveau_cecrl_ia}) vs calcule serveur
     * ({@code niveau_cecrl}). Le detail de la tendance (sous/sur-estimation) est
     * trace au fil de l'eau dans les logs d'{@code AiEvaluationService}.
     */
    @Transactional(readOnly = true)
    public NiveauCalibrationStatsDto niveauStats() {
        long total = aiEvaluationManager.countWithBothNiveaux();
        long divergents = aiEvaluationManager.countNiveauDivergent();
        BigDecimal pourcentage = total == 0
                ? BigDecimal.ZERO
                : BigDecimal.valueOf(divergents).multiply(BigDecimal.valueOf(100))
                    .divide(BigDecimal.valueOf(total), 1, RoundingMode.HALF_UP);
        return new NiveauCalibrationStatsDto(total, divergents, pourcentage);
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    /**
     * Derniere note de chaque submission. Le manager renvoie deja les notes de
     * la plus recente a la plus ancienne : la premiere rencontree pour une
     * submission donnee est donc la bonne. Une note orpheline (submission nulle)
     * est ignoree — elle ne peut pas etre dedupliquee, donc elle ne peut pas
     * etre comptee sans risque de doublon.
     */
    private List<HumanCalibrationNote> derniereNoteParSubmission() {
        Set<UUID> vues = new HashSet<>();
        List<HumanCalibrationNote> out = new ArrayList<>();
        for (HumanCalibrationNote n : humanNoteManager.findAllOrderedByCreatedAtDesc()) {
            if (n.getSubmission() == null || n.getSubmission().getId() == null) continue;
            if (vues.add(n.getSubmission().getId())) out.add(n);
        }
        return out;
    }

    private void validateNotePayload(HumanCalibrationNoteDto dto) {
        if (dto == null) throw new BusinessException("Payload manquant.");
        if (dto.noteHumaineSurVingt() == null) {
            throw new BusinessException("note_humaine_sur_20 requise.");
        }
        if (dto.noteHumaineSurVingt().compareTo(NOTE_MIN) < 0
                || dto.noteHumaineSurVingt().compareTo(NOTE_MAX) > 0) {
            throw new BusinessException("note_humaine_sur_20 doit etre dans [0, 20].");
        }
        if (dto.niveauCecrlHumain() == null) {
            throw new BusinessException("niveau_cecrl_humain requis.");
        }
    }

    private BigDecimal computeEcart(UUID submissionId, BigDecimal noteHumaine) {
        AiEvaluation ai = aiEvaluationManager.findLatestBySubmissionId(submissionId).orElse(null);
        if (ai == null || ai.getNoteSur20() == null) return null;
        return noteHumaine.subtract(ai.getNoteSur20()).setScale(1, RoundingMode.HALF_UP);
    }

    private int clampLimit(int limit) {
        return Math.max(LIMIT_MIN, Math.min(limit, LIMIT_MAX));
    }
}
