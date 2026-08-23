package com.sejourfr.app.progression.dto;

import com.sejourfr.app.progression.domain.ProgressionStateType;
import com.sejourfr.app.progression.domain.ProgressionStatus;

/**
 * <b>Le contrat de rendu front</b> (V4.2 §25 bis.2) — exactement ce qu'un écran
 * a le droit de recevoir, et rien de plus.
 *
 * <p>🛑 <b>Ni {@code masteryScore}, ni {@code confidence}, ni les accumulateurs
 * epoch.</b> Ce ne sont pas des oublis : ces valeurs sont internes au moteur, et
 * les servir permettrait à un front de reconstituer un seuil — donc de
 * reclasser un nombre en état pédagogique, ce que §25 bis interdit
 * explicitement (invariant I42). Elles n'existent que pour la console admin et
 * le journal de prédictions.
 *
 * <p>Le front consomme {@link #status}, {@link #statusLabel} et {@link #tone}
 * tels quels. Il ne les dérive de rien.
 *
 * @param visibleProgress {@code null} pour un palier sans la moindre preuve
 *                        directe (§18.6, invariant I41) — <b>jamais 0</b>. Le
 *                        front n'affiche alors aucun pourcentage, seulement
 *                        l'état textuel. Le candidat n'a pas régressé : il n'a
 *                        jamais été mesuré.
 * @param prerequisiteSatisfiedByLevel le niveau qui satisfait ce palier, pour le
 *                        libellé « Validé via B1 » (§18.5). Le pourcentage de ce
 *                        palier reste masqué : ce n'est pas un score TCF.
 */
public record ProgressionStateDto(
        String stateKey,
        ProgressionStateType stateType,
        ProgressionStatus status,
        String statusLabel,
        String tone,
        Integer visibleProgress,
        boolean directQualification,
        boolean prerequisiteSatisfied,
        String prerequisiteSatisfiedByLevel,
        String levelCycleId
) {
}
