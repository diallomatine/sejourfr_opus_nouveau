package com.sejourfr.app.service;

import com.sejourfr.app.dto.LotDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Calcul dynamique des lots d'entraînement. Un lot est un sous-ensemble
 * déterministe de questions filtrées par (module + critères), trié par
 * {@code createdAt ASC, id ASC}.
 *
 * <p>Deux modes :
 * <ul>
 *   <li><b>TCF</b> : filtré par {@code questionType + difficulty}, taille
 *       fixe par niveau (A2 = 15, B1 = 20, B2 = 25).</li>
 *   <li><b>Civique</b> : filtré par {@code themeId}, taille fixe à 15.</li>
 * </ul>
 *
 * <p>Aucune persistance côté schéma : la composition d'un lot est dérivée de
 * sa position dans le découpage du pool filtré. Tant que le pool ne change
 * pas, Lot 1 renvoie toujours les mêmes questions.
 *
 * <p>Règle de découpage (commune) :
 * <ul>
 *   <li>Pool == 0 → aucun lot</li>
 *   <li>Pool &lt; lotSize standard → 1 <b>lot partiel</b> avec tout le pool</li>
 *   <li>Pool &ge; lotSize → N lots complets de taille standard</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class LotService {

    /** Taille de lot standard par niveau TCF — exposée à {@link AttemptService}. */
    public static final int LOT_SIZE_A2 = 15;
    public static final int LOT_SIZE_B1 = 20;
    public static final int LOT_SIZE_B2 = 25;

    /** Taille fixe d'un lot civique, indépendamment du thème. */
    public static final int LOT_SIZE_CIVIQUE = 15;

    private final QuestionManager questionManager;
    private final AttemptManager attemptManager;

    // ------------------------------------------------------------------------
    // Mode TCF (questionType + difficulty)
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<LotDto> list(UUID userId, Module module, QuestionType questionType, Difficulty difficulty) {
        validateTcfInputs(module, difficulty);
        int lotSize = lotSizeFor(difficulty);
        long total = questionManager.countActiveMatching(module, null, difficulty, questionType);

        if (total == 0) {
            return List.of();
        }

        Map<Integer, Attempt> latestByLot = userId == null
                ? Map.of()
                : attemptManager.findLastFinishedByLots(userId, module, questionType, difficulty);

        if (total < lotSize) {
            return List.of(buildLotDto(1, difficulty, (int) total, latestByLot));
        }

        int lotCount = (int) (total / lotSize);
        List<LotDto> result = new ArrayList<>(lotCount);
        for (int i = 1; i <= lotCount; i++) {
            result.add(buildLotDto(i, difficulty, lotSize, latestByLot));
        }
        return result;
    }

    /**
     * Résout la fenêtre exacte d'un lot TCF demandé. Source de vérité partagée
     * avec {@link #list} pour éviter qu'{@link AttemptService} ne diverge.
     */
    @Transactional(readOnly = true)
    public int resolveLotSize(Module module, QuestionType questionType, Difficulty difficulty, int lotNumero) {
        validateTcfInputs(module, difficulty);
        if (lotNumero < 1) {
            throw new BusinessException("lotNumero doit être >= 1.");
        }
        int lotSize = lotSizeFor(difficulty);
        long total = questionManager.countActiveMatching(module, null, difficulty, questionType);

        if (total == 0) {
            throw new BusinessException("Aucune question disponible pour ces critères.");
        }
        if (total < lotSize) {
            if (lotNumero != 1) {
                throw new BusinessException("Lot " + lotNumero + " introuvable (pool partiel de " + total + " questions).");
            }
            return (int) total;
        }
        int lotCount = (int) (total / lotSize);
        if (lotNumero > lotCount) {
            throw new BusinessException("Lot " + lotNumero + " introuvable (" + lotCount + " lots disponibles).");
        }
        return lotSize;
    }

    // ------------------------------------------------------------------------
    // Mode Civique (themeId)
    // ------------------------------------------------------------------------

    /**
     * Liste les lots Civique disponibles pour un thème. Taille fixe 15.
     * Numérotation séquentielle (1..N), enrichie du dernier score du user
     * sur chaque lot quand l'attempt correspondant a été finalisé.
     */
    @Transactional(readOnly = true)
    public List<LotDto> listCivique(UUID userId, UUID themeId) {
        validateCiviqueInputs(themeId);
        int lotSize = LOT_SIZE_CIVIQUE;
        long total = questionManager.countActiveMatching(Module.CIVIQUE, themeId, null, null);

        if (total == 0) {
            return List.of();
        }

        Map<Integer, Attempt> latestByLot = userId == null
                ? Map.of()
                : attemptManager.findLastFinishedByLotsCivique(userId, themeId);

        if (total < lotSize) {
            // Pool partiel : un seul lot avec toutes les questions disponibles.
            return List.of(buildLotDto(1, null, (int) total, latestByLot));
        }

        int lotCount = (int) (total / lotSize);
        List<LotDto> result = new ArrayList<>(lotCount);
        for (int i = 1; i <= lotCount; i++) {
            result.add(buildLotDto(i, null, lotSize, latestByLot));
        }
        return result;
    }

    /**
     * Résout la taille d'un lot Civique demandé. Même contrat que la version
     * TCF, mais avec le filtre `themeId` à la place de `difficulty`.
     */
    @Transactional(readOnly = true)
    public int resolveLotSizeCivique(UUID themeId, int lotNumero) {
        validateCiviqueInputs(themeId);
        if (lotNumero < 1) {
            throw new BusinessException("lotNumero doit être >= 1.");
        }
        int lotSize = LOT_SIZE_CIVIQUE;
        long total = questionManager.countActiveMatching(Module.CIVIQUE, themeId, null, null);

        if (total == 0) {
            throw new BusinessException("Aucune question disponible pour ce thème.");
        }
        if (total < lotSize) {
            if (lotNumero != 1) {
                throw new BusinessException("Lot " + lotNumero + " introuvable (pool partiel de " + total + " questions).");
            }
            return (int) total;
        }
        int lotCount = (int) (total / lotSize);
        if (lotNumero > lotCount) {
            throw new BusinessException("Lot " + lotNumero + " introuvable (" + lotCount + " lots disponibles).");
        }
        return lotSize;
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private LotDto buildLotDto(int numero, Difficulty difficulty, int size, Map<Integer, Attempt> latestByLot) {
        Attempt last = latestByLot.get(numero);
        return new LotDto(
                numero,
                difficulty,
                size,
                last != null ? last.getScore() : null,
                last != null ? last.getFinishedAt() : null,
                last != null ? last.getId() : null
        );
    }

    /**
     * Taille d'un lot TCF pour un niveau donné. Statique pour permettre à
     * {@link AttemptService#start} de reconstruire la même fenêtre quand un
     * client passe {@code lotNumero}.
     */
    public static int lotSizeFor(Difficulty difficulty) {
        return switch (difficulty) {
            case A2 -> LOT_SIZE_A2;
            case B1 -> LOT_SIZE_B1;
            case B2 -> LOT_SIZE_B2;
            default -> throw new BusinessException(
                    "Les lots TCF ne sont définis que pour A2, B1, B2. Reçu : " + difficulty);
        };
    }

    private void validateTcfInputs(Module module, Difficulty difficulty) {
        if (module != Module.TCF) {
            throw new BusinessException("Cette branche est réservée au module TCF.");
        }
        if (difficulty == null) {
            throw new BusinessException("difficulty est obligatoire (A2 / B1 / B2).");
        }
    }

    private void validateCiviqueInputs(UUID themeId) {
        if (themeId == null) {
            throw new BusinessException("themeId est obligatoire pour les lots Civique.");
        }
    }
}
