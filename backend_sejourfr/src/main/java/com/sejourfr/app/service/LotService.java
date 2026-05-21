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
 * Calcul dynamique des lots d'entraînement TCF. Un lot est un sous-ensemble
 * déterministe de questions filtrées par (module, questionType, difficulty),
 * trié par {@code createdAt ASC, id ASC}.
 *
 * <p>Aucune persistance côté schéma : la composition d'un lot est dérivée de
 * sa position dans le découpage du pool filtré, avec une taille fixe par
 * niveau (A2 = 15, B1 = 20, B2 = 25). Tant que le pool ne change pas, Lot 1
 * renvoie toujours les mêmes questions.
 *
 * <p>Règle de découpage :
 * <ul>
 *   <li>Pool == 0 → aucun lot</li>
 *   <li>Pool &lt; lotSize standard → 1 <b>lot partiel</b> avec tout le pool
 *       (utile au démarrage quand le pool CO se remplit progressivement)</li>
 *   <li>Pool &ge; lotSize → N lots complets de taille standard, les questions
 *       au-delà du dernier multiple sont ignorées (elles seront exposées
 *       quand un nouveau multiple sera atteint)</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class LotService {

    /** Taille de lot standard par niveau TCF — exposée à {@link AttemptService}. */
    public static final int LOT_SIZE_A2 = 15;
    public static final int LOT_SIZE_B1 = 20;
    public static final int LOT_SIZE_B2 = 25;

    private final QuestionManager questionManager;
    private final AttemptManager attemptManager;

    @Transactional(readOnly = true)
    public List<LotDto> list(UUID userId, Module module, QuestionType questionType, Difficulty difficulty) {
        validateInputs(module, difficulty);
        int lotSize = lotSizeFor(difficulty);
        long total = questionManager.countActiveMatching(module, null, difficulty, questionType);

        if (total == 0) {
            return List.of();
        }

        // Dernier attempt fini par l'utilisateur sur chaque lot — sert à
        // afficher le score "déjà fait" côté mobile.
        Map<Integer, Attempt> latestByLot = userId == null
                ? Map.of()
                : attemptManager.findLastFinishedByLots(userId, module, questionType, difficulty);

        if (total < lotSize) {
            // Pool insuffisant pour un lot complet : on expose un unique lot
            // partiel pour ne pas masquer les questions disponibles.
            return List.of(buildLotDto(1, difficulty, (int) total, latestByLot));
        }

        int lotCount = (int) (total / lotSize);
        List<LotDto> result = new ArrayList<>(lotCount);
        for (int i = 1; i <= lotCount; i++) {
            result.add(buildLotDto(i, difficulty, lotSize, latestByLot));
        }
        return result;
    }

    private LotDto buildLotDto(int numero, Difficulty difficulty, int size, Map<Integer, Attempt> latestByLot) {
        Attempt last = latestByLot.get(numero);
        return new LotDto(
                numero,
                difficulty,
                size,
                last != null ? last.getScore() : null,
                last != null ? last.getFinishedAt() : null
        );
    }

    /**
     * Résout la fenêtre exacte d'un lot demandé : nombre de questions à
     * fetcher pour {@code lotNumero}. Source de vérité partagée avec
     * {@link #list} pour éviter qu'`AttemptService` ne diverge des lots
     * exposés au front. Lève {@link BusinessException} si le lot n'existe pas.
     */
    @Transactional(readOnly = true)
    public int resolveLotSize(Module module, QuestionType questionType, Difficulty difficulty, int lotNumero) {
        validateInputs(module, difficulty);
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

    /**
     * Taille d'un lot pour un niveau donné. Statique pour permettre à
     * {@link AttemptService#start} de reconstruire la même fenêtre quand un
     * client passe {@code lotNumero}.
     */
    public static int lotSizeFor(Difficulty difficulty) {
        return switch (difficulty) {
            case A2 -> LOT_SIZE_A2;
            case B1 -> LOT_SIZE_B1;
            case B2 -> LOT_SIZE_B2;
            default -> throw new BusinessException(
                    "Les lots ne sont définis que pour les niveaux TCF (A2, B1, B2). Reçu : " + difficulty);
        };
    }

    private void validateInputs(Module module, Difficulty difficulty) {
        if (module != Module.TCF) {
            throw new BusinessException("Les lots sont réservés au module TCF pour l'instant.");
        }
        if (difficulty == null) {
            throw new BusinessException("difficulty est obligatoire (A2 / B1 / B2).");
        }
    }
}
