package com.sejourfr.app.service.examenblanc;

import com.sejourfr.app.dto.ExamSlotsDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.service.FullTcfExamService;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.ProductionExamCompositionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.function.IntPredicate;

/**
 * La grille <b>servie</b> des examens blancs d'une épreuve : un {@code locked}
 * par créneau, lu chez l'autorité que le démarrage oppose en 403 — jamais
 * recalculé ici, jamais déduit du rang par un front.
 *
 * <table>
 *   <tr><th>Grille</th><th>Autorité (403 et {@code locked})</th></tr>
 *   <tr><td>{@code TCF_CO} / {@code TCF_CE} / {@code TCF_STRUCTURE}</td>
 *       <td>{@link ExamenBlancAccessService#isExamenBlancVerrouille}</td></tr>
 *   <tr><td>{@code TCF_COMPLET} (compte)</td>
 *       <td>{@link ExamenBlancAccessService#isExamenBlancVerrouille}</td></tr>
 *   <tr><td>{@code TCF_COMPLET} (visiteur : l'examen de compréhension offert)
 *       et {@code CIVIQUE} (examens globaux)</td>
 *       <td>{@link ExamenBlancAccessService#isGrilleGabaritVerrouillee}</td></tr>
 *   <tr><td>{@code TCF_EE} / {@code TCF_EO} (compte ; fermés aux visiteurs)</td>
 *       <td>{@link ProductionAccessService#isProductionExamSlotLocked}</td></tr>
 * </table>
 */
@Service
@RequiredArgsConstructor
public class ExamSlotsService {

    private final ExamenBlancAccessService examenBlancAccess;
    private final ProductionAccessService productionAccessService;

    /** @param userId {@code null} pour un visiteur sans compte */
    @Transactional(readOnly = true)
    public ExamSlotsDto slots(UUID userId, EpreuveType epreuve) {
        List<ExamSlotsDto.Slot> slots = switch (epreuve) {
            case TCF_CO, TCF_CE, TCF_STRUCTURE -> grille(AttemptService.MOCK_EXAM_SLOTS,
                    slot -> examenBlancAccess.isExamenBlancVerrouille(userId, Module.TCF, slot));
            case TCF_COMPLET -> grille(FullTcfExamService.EXAM_SLOTS, userId == null
                    ? slot -> examenBlancAccess.isGrilleGabaritVerrouillee(null, Module.TCF, slot)
                    : slot -> examenBlancAccess.isExamenBlancVerrouille(userId, Module.TCF, slot));
            case CIVIQUE -> grille(AttemptService.MOCK_EXAM_SLOTS,
                    slot -> examenBlancAccess.isGrilleGabaritVerrouillee(userId, Module.CIVIQUE, slot));
            case TCF_EE, TCF_EO -> grille(ProductionExamCompositionService.EXAM_SLOTS_PER_EPREUVE,
                    userId == null
                            ? slot -> true
                            : slot -> productionAccessService.isProductionExamSlotLocked(userId, epreuve, slot));
        };
        return new ExamSlotsDto(epreuve, slots);
    }

    /** Les créneaux 1..{@code count}, chacun avec le verrou que rend {@code locked}. */
    public static List<ExamSlotsDto.Slot> grille(int count, IntPredicate locked) {
        List<ExamSlotsDto.Slot> slots = new ArrayList<>(count);
        for (int slot = 1; slot <= count; slot++) {
            slots.add(new ExamSlotsDto.Slot(slot, locked.test(slot)));
        }
        return slots;
    }
}
