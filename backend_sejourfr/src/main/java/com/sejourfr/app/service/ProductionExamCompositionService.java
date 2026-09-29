package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.ProductionTaskManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Composition déterministe des examens blancs production (EE / EO) : un examen
 * = 3 sujets, un par tâche, choisis côté backend — les fronts ne piochent plus
 * dans le catalogue (avant : le mobile embarquait tout le pool en session, le
 * web prenait toujours les 3 premiers sujets → 10 examens identiques).
 *
 * <p>Deux modes :
 * <ul>
 *   <li><b>Examen module</b> ({@code slot_number} 1-10, pas de parent) :
 *       difficulté progressive par bande — slots 1-3 sujets A2, 4-6 B1,
 *       7-10 B2 (alignée sur les chips facile/moyen/difficile de la grille).
 *       Le sujet est le n-ième du pool de la bande (ordre stable
 *       created_at puis id), modulo la taille du pool.</li>
 *   <li><b>Sous-épreuve d'un examen TCF complet</b> (parent TCF_COMPLET) :
 *       niveau = {@code users.target_level} (fallback B1, comme le choix
 *       front historique), sujet = (slot du parent - 1) modulo le pool du
 *       niveau.</li>
 * </ul>
 *
 * <p>EO tâche 1 (3 variantes « se présenter », une par niveau) est couverte
 * par le même algorithme : pool de taille 1 par niveau → toujours la variante
 * du niveau de la bande.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionExamCompositionService {

    /** Nombre d'examens blancs proposés par épreuve EE/EO (grille des fronts). */
    public static final int EXAM_SLOTS_PER_EPREUVE = 10;

    /** Bornes des bandes de difficulté : slots 1-3 → A2, 4-6 → B1, 7-10 → B2. */
    private static final int BAND_A2_END = 3;
    private static final int BAND_B1_END = 6;

    private static final Comparator<ProductionTask> STABLE_ORDER =
            Comparator.comparing(ProductionTask::getCreatedAt,
                            Comparator.nullsLast(Comparator.naturalOrder()))
                    .thenComparing(ProductionTask::getId);

    private final ProductionTaskManager taskManager;

    /**
     * Les 3 sujets (T1, T2, T3) de l'examen porté par cet attempt. L'attempt
     * doit être une session d'examen production ({@code slot_number} posé) ou
     * une sous-épreuve d'un examen TCF complet (parent non null). Les callers
     * doivent être transactionnels (lazy-load parent + user).
     */
    public List<ProductionTask> composeFor(Attempt attempt) {
        EpreuveType epreuve = attempt.getEpreuve();
        if (epreuve != EpreuveType.TCF_EE && epreuve != EpreuveType.TCF_EO) {
            throw new BusinessException("Composition d'examen réservée aux attempts TCF_EE / TCF_EO.");
        }
        Attempt parent = attempt.getParentAttempt();
        boolean fullExamSub = parent != null;
        if (!fullExamSub && attempt.getSlotNumber() == null) {
            throw new BusinessException(
                    "Composition d'examen réservée aux sessions d'examen blanc (entraînement libre : "
                            + "le candidat choisit son sujet).");
        }

        List<ProductionTask> out = new ArrayList<>(3);
        if (fullExamSub) {
            int slot = clampSlot(parent.getSlotNumber());
            String niveau = targetNiveau(attempt);
            for (short tache = 1; tache <= 3; tache++) {
                out.add(pick(epreuve, tache, niveau, slot - 1));
            }
        } else {
            int slot = clampSlot(attempt.getSlotNumber());
            String niveau = bandNiveau(slot);
            int index = indexInBand(slot);
            for (short tache = 1; tache <= 3; tache++) {
                out.add(pick(epreuve, tache, niveau, index));
            }
        }
        return out;
    }

    /** Niveau de la bande d'un slot (1-3 → A2, 4-6 → B1, 7-10 → B2). */
    private static String bandNiveau(int slot) {
        if (slot <= BAND_A2_END) return TargetLevel.A2.name();
        if (slot <= BAND_B1_END) return TargetLevel.B1.name();
        return TargetLevel.B2.name();
    }

    /** Position du slot dans sa bande (0-based) — l'index du sujet dans le pool. */
    private static int indexInBand(int slot) {
        if (slot <= BAND_A2_END) return slot - 1;
        if (slot <= BAND_B1_END) return slot - BAND_A2_END - 1;
        return slot - BAND_B1_END - 1;
    }

    private static int clampSlot(Integer slot) {
        if (slot == null) return 1;
        return Math.max(1, Math.min(EXAM_SLOTS_PER_EPREUVE * 2, slot));
    }

    /** Niveau cible de l'utilisateur pour un examen TCF complet (fallback B1). */
    private static String targetNiveau(Attempt attempt) {
        TargetLevel target = attempt.getUser() != null ? attempt.getUser().getTargetLevel() : null;
        return (target != null ? target : TargetLevel.B1).name();
    }

    /**
     * Sujet {@code index} (modulo la taille du pool) parmi les sujets actifs
     * du (épreuve, tâche, niveau), en ordre stable. Pool vide pour ce niveau →
     * fallback sur le pool toutes-bandes de la tâche (catalogue incomplet,
     * loggé WARN — on ne casse pas l'examen pour autant).
     */
    private ProductionTask pick(EpreuveType epreuve, short tache, String niveau, int index) {
        List<ProductionTask> pool = new ArrayList<>(taskManager.findActive(epreuve, niveau, tache));
        if (pool.isEmpty()) {
            log.warn("Aucun sujet actif pour {} T{} niveau {} — fallback toutes bandes.",
                    epreuve, tache, niveau);
            pool = new ArrayList<>(taskManager.findActive(epreuve, null, tache));
            if (pool.isEmpty()) {
                throw new BusinessException("Aucun sujet actif pour " + epreuve + " tâche " + tache + ".");
            }
        }
        pool.sort(STABLE_ORDER);
        return pool.get(Math.floorMod(index, pool.size()));
    }
}
