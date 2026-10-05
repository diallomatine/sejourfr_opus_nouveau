package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.SkillMasteryEngine;
import com.sejourfr.app.service.SkillMasteryResolver;
import com.sejourfr.app.service.TcfProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Ce que la COMPREHENSION recoit dans un cycle TCF</b> — le palier unique
 * (D-72) et le complement d'un bloc vide (D-70), lus <b>une seule fois</b> pour
 * l'ecriture et pour le nombre annonce.
 *
 * <p>🛑 <b>Une composition, trois lecteurs</b> : l'actualisation
 * ({@code JourneyCycleService.actualiser}, qui retient le palier puis complete
 * les blocs vides), la lecture qui repare un cycle promu
 * ({@code JourneyService.completerLesBlocsVides}) et le nombre servi sous
 * « Actualiser mon plan » ({@code JourneyCycleSuivant.prioritesIdentifiees},
 * D-67). Le nombre annonce ne peut donc pas dire autre chose que ce que
 * l'actualisation posera.
 *
 * <p>La regle elle-meme (quel palier, quelles competences) vit chez
 * {@link JourneyLotBuilder} ; ce composant ne fait que <b>lire</b> ce dont elle a
 * besoin (niveau du domaine, mesure, referentiel, maitrise du jour).
 */
@Component
@RequiredArgsConstructor
public class JourneyPalierDuCycle {

    private final TcfProfileService profileService;
    private final NiveauActuelEpreuveResolver mesureResolver;
    private final LearningPlanObservationManager observationManager;
    private final JourneyEvaluationFilter evaluationFilter;
    private final SkillMasteryResolver masteryResolver;
    private final SkillManager skillManager;
    private final JourneyLotBuilder lotBuilder;

    /**
     * Ce que le palier du cycle lit d'un candidat : son objectif, le niveau de
     * ses domaines (lecture Plan, D-2), et — <b>seulement si un bloc vide doit
     * etre complete</b> — le referentiel de comprehension et ses maitrises du
     * jour, charges une fois.
     */
    public final class Lecture {
        private final UUID userId;
        private final TargetLevel cible;
        private final TcfLevelProfile profil;
        private List<Skill> comprehension;
        private Set<UUID> maitrisees;

        private Lecture(UUID userId, TargetLevel cible, TcfLevelProfile profil) {
            this.userId = userId;
            this.cible = cible;
            this.profil = profil;
        }

        public TargetLevel cible() {
            return cible;
        }

        public TcfLevelProfile profil() {
            return profil;
        }

        /** D-72 — le palier que cette epreuve travaille, ou {@code null} (regle inapplicable). */
        public TargetLevel palier(EpreuveType epreuve) {
            return JourneyLotBuilder.palierDuCycle(epreuve, profil, cible);
        }

        /**
         * Une etape d'entrainement que l'actualisation garde : toute etape hors
         * CO/CE, et en CO/CE celle du palier du cycle seulement.
         */
        public boolean garde(JourneyStep step) {
            if (step.getType() != JourneyStepType.TRAIN_SKILL) return true;
            TargetLevel palier = palier(step.getExamType());
            return palier == null || JourneyLotBuilder.palierDe(step.getSkill()) == palier;
        }

        private void chargerLeReferentiel() {
            if (comprehension != null) return;
            List<LearningPlanObservation> tout = observationManager.findAllByUserWithSkill(userId);
            maitrisees = maitriseesCeJour(tout, evaluationFilter.retenir(tout));
            comprehension = skillManager.findActiveComprehension();
        }
    }

    /**
     * Ce qu'un bloc VIDE recoit (D-70, restreint par D-72) : {@code lot} quand la
     * comprehension mesuree sous l'objectif a son palier a travailler,
     * sinon {@code null} et l'appelant pose l'examen blanc seul —
     * {@code REASSESS} si {@code mesuree}, {@code INITIAL_ASSESSMENT} sinon.
     */
    public record Complement(JourneyLotBuilder.Lot lot, boolean mesuree) {
        public int entrainements() {
            return lot == null ? 0 : lot.priorites().size();
        }
    }

    public Lecture lire(UUID userId, TargetLevel cible) {
        return new Lecture(userId, cible, profileService.levelProfile(userId));
    }

    /** Le complement D-70 d'un bloc vide, sur cette lecture. */
    public Complement complement(Lecture lecture, EpreuveType epreuve) {
        NiveauActuelEpreuveResolver.Mesure mesure = mesureResolver.mesure(lecture.userId, epreuve);
        if (!mesure.mesuree()) return new Complement(null, false);
        if (lecture.palier(epreuve) == null) return new Complement(null, true);
        lecture.chargerLeReferentiel();
        return new Complement(
                lotBuilder.versLObjectif(epreuve, mesure.attemptId(),
                        JourneyLotBuilder.niveauDuDomaine(lecture.profil, epreuve),
                        lecture.cible, lecture.comprehension, lecture.maitrisees),
                true);
    }

    /** L'examen qui a mesure l'epreuve, ou {@code null} : il signe une etape ecartee. */
    public UUID mesureePar(UUID userId, EpreuveType epreuve) {
        return mesureResolver.mesure(userId, epreuve).attemptId();
    }

    /**
     * Les competences dont le transfert est prouve <b>aujourd'hui</b> parmi
     * celles que les evaluations ont observees ({@code SkillMasteryEngine}).
     * Elles ne rentrent jamais dans un lot : ce serait redemander ce qui est
     * acquis.
     */
    public Set<UUID> maitriseesCeJour(
            List<LearningPlanObservation> tout, List<LearningPlanObservation> evaluations) {
        Set<UUID> candidates = new LinkedHashSet<>();
        for (LearningPlanObservation observation : evaluations) {
            if (observation.getSkill() != null) candidates.add(observation.getSkill().getId());
        }
        if (candidates.isEmpty()) return Set.of();
        // 🛑 Le moteur recoit TOUT l'historique, pas seulement les evaluations :
        // un petit sujet reussi compte dans la maitrise (c'est le sens meme du
        // module Competences), meme s'il ne peut pas creer d'etape.
        Map<UUID, SkillMasteryEngine.SkillMastery> maitrise =
                masteryResolver.fromObservations(tout, candidates);
        Set<UUID> prouvees = new LinkedHashSet<>();
        maitrise.forEach((skillId, etat) -> {
            if (etat != null && etat.transferProven()) prouvees.add(skillId);
        });
        return prouvees;
    }
}
