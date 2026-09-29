package com.sejourfr.app.progression.domain;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;

import java.util.Map;

/**
 * La lecture d'un domaine receptif (CO ou CE) : ses trois paliers, ce qui est
 * satisfait par prerequis, et le seul niveau que le Plan a le droit de
 * prescrire (V4.2 §18, §19, §20).
 *
 * <p>🛑 <b>Invariant I15/I16 :</b> au plus un niveau CO et un niveau CE dans une
 * meme seance. {@code CO A2 + CO B1} le meme jour est interdit — y compris
 * pendant une revocation de prerequis, ou c'est la verification du WATCH qui
 * prend la main.
 *
 * @param prerequisiteSatisfied        derive a la lecture, <b>revocable</b>, et
 *                                     jamais enregistre comme acquis definitif
 *                                     (§18.4, invariant I21).
 * @param prerequisiteSatisfiedByLevel le niveau <b>directement</b> qualifie qui
 *                                     satisfait le prerequis — celui que l'UI
 *                                     nomme dans « Validé via B1 » (§18.5).
 * @param activeLearningLevel          le niveau normal d'apprentissage, ou
 *                                     {@code null} quand l'objectif est atteint.
 * @param prescriptionLevel            ce que le Plan prescrit reellement : le
 *                                     niveau en WATCH s'il y en a un, sinon
 *                                     {@code activeLearningLevel} (§19).
 */
public record DomainProjection(
        SkillSection section,
        TargetLevel objectiveLevel,
        Map<TargetLevel, ProgressionSnapshot> levels,
        Map<TargetLevel, Boolean> prerequisiteSatisfied,
        Map<TargetLevel, TargetLevel> prerequisiteSatisfiedByLevel,
        TargetLevel activeLearningLevel,
        TargetLevel prescriptionLevel
) {
}
