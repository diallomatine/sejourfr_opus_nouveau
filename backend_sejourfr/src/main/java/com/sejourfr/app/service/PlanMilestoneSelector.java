package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.AttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Choisit LE jalon du Plan : l'examen blanc que ce candidat a merite de passer,
 * ou rien.
 *
 * <p><b>Troisieme et dernier selecteur d'exercice, jumeau de
 * {@link RecommendedExerciseSelector} et {@link ReassessmentExerciseSelector}</b>,
 * et pour la meme raison qu'eux : la designation n'existe qu'a un seul endroit.
 * Deux copies auraient fini par proposer deux jalons differents — exactement le
 * defaut qui a impose l'extraction de {@link LearningPlanPriorityResolver}.
 *
 * <h2>On escalade, on ne reporte pas</h2>
 * <pre>
 *   Etape (5 sujets) -&gt; Verification ciblee (1 tache, ~4 min)
 *          |   c'est elle qui debloque SOLID
 *   Epreuve transferee -&gt; Examen blanc d'epreuve (EE ou EO, 3 taches)
 *          |
 *   Les deux epreuves -&gt; Examen blanc TCF complet (4 epreuves, 90 min)
 * </pre>
 * Attendre « les 3 etapes finies » aurait ete inatteignable (un compte gratuit
 * plafonne a 2 des 5 sujets d'une etape) et aurait fige les competences en
 * consolidation : {@code SOLID} exige une preuve contextualisee, et la
 * verification ciblee est la seule voie qui l'apporte. L'echelle est deja
 * <b>tarifee</b> par le moteur de maitrise — poids micro-entrainement 0.45 &lt;
 * diagnostic 0.80 &lt; production 1.00 &lt; examen blanc 1.20 — il ne manquait
 * que le declencheur.
 *
 * <h2>Les declencheurs</h2>
 * <ol>
 *   <li><b>Jalon d'epreuve</b> (EE ou EO) : les competences <b>observees</b> de
 *       cette epreuve sont majoritairement <b>transferees</b> ({@code SOLID}),
 *       avec un plancher en nombre absolu — et aucun examen blanc de cette
 *       epreuve n'a ete passe recemment. Pourquoi {@code SOLID} et pas le score :
 *       {@code SOLID} est le seul etat qui exige une preuve <b>en situation</b>,
 *       donc le seul qui dise « ce moyen tient hors du micro-exercice ». Envoyer
 *       en examen blanc un candidat encore en consolidation lui ferait mesurer
 *       un echec, pas un progres.</li>
 *   <li><b>Jalon complet</b> : les deux epreuves ont franchi le leur <b>et l'ont
 *       prouve</b> (un examen blanc de chaque, recent). Ce qui reste a verifier
 *       n'est plus une epreuve, c'est de les tenir <b>ensemble</b> en 90 minutes
 *       — c'est la seule chose que l'examen complet ajoute.</li>
 * </ol>
 *
 * <p><b>Derive, jamais persiste</b> (philosophie {@link SkillStatusResolver} /
 * {@link SkillMasteryResolver}) : aucune table, aucune colonne, aucune
 * migration. Recalibrer un seuil dans {@code application.yaml} relit l'historique
 * au prochain appel. <b>Aucun nombre n'est ecrit en Java</b> : tout vit sous
 * {@code sejourfr.learning-plan.milestone}.
 *
 * <p><b>Aucun contenu n'est cree.</b> Un jalon designe une session d'examen
 * blanc <b>deja existante</b> par son epreuve et son slot de grille : aucune
 * generation, aucune banque, aucun appel LLM, aucune route de plus.
 *
 * <h2>Cout</h2>
 * Zero requete tant qu'aucun jalon n'est atteint — le cas de l'immense majorite
 * des lectures : tout se decide sur l'historique <b>deja charge</b> par
 * {@link LearningPlanService} et sur les etats de maitrise deja calcules. Quand
 * un jalon est atteint, deux a trois requetes bornees (le compte de sessions de
 * la grille et le verrou d'acces), jamais une par competence.
 */
@Component
@RequiredArgsConstructor
public class PlanMilestoneSelector {

    private final LearningPlanProperties properties;
    private final ProductionAccessService productionAccessService;
    private final AttemptManager attemptManager;

    /**
     * Le jalon a proposer a ce candidat, ou vide — <b>l'absence de jalon est le
     * cas normal</b>, pas une erreur.
     *
     * @param latestObserved la derniere observation probante de chaque
     *                       competence (ce que rend
     *                       {@code LearningPlanPriorityResolver.latestObservedBySkill}),
     *                       deja chargee avec sa competence.
     * @param mastery        l'etat de maitrise de <b>toutes</b> ces competences,
     *                       deja calcule sur le meme historique.
     * @param allObservations tout l'historique du candidat : c'est la qu'on lit
     *                        les preuves d'examen blanc deja apportees, sans une
     *                        requete de plus.
     */
    public Optional<PlanRecommendedExerciseDto> select(
            UUID userId,
            Collection<LearningPlanObservation> latestObserved,
            Map<UUID, SkillMasteryEngine.SkillMastery> mastery,
            Collection<LearningPlanObservation> allObservations,
            Instant now) {
        LearningPlanProperties.Milestone config = properties.getMilestone();
        Instant proofStart = now.minus(Duration.ofDays(config.getProofDays()));

        Map<SkillSection, Tally> tallies = new EnumMap<>(SkillSection.class);
        for (SkillSection section : SkillSection.values()) {
            tallies.put(section, new Tally());
        }
        for (LearningPlanObservation observation : latestObserved) {
            if (observation.getSkill() == null || observation.getSkill().getSection() == null) continue;
            Tally tally = tallies.get(observation.getSkill().getSection());
            tally.observed++;
            SkillMasteryEngine.SkillMastery state =
                    mastery.get(observation.getSkill().getId());
            if (state != null && state.state() == SkillMasteryState.SOLID) tally.solid++;
        }

        Map<SkillSection, Boolean> proven = new EnumMap<>(SkillSection.class);
        for (SkillSection section : SkillSection.values()) {
            proven.put(section, hasRecentMockExamProof(allObservations, section, proofStart));
        }

        boolean ecritPret = reached(tallies.get(SkillSection.EE), config);
        boolean oralPret = reached(tallies.get(SkillSection.EO), config);

        // Barreau du haut d'abord : les deux epreuves tenues separement, il reste
        // a les tenir ensemble.
        if (ecritPret && oralPret
                && Boolean.TRUE.equals(proven.get(SkillSection.EE))
                && Boolean.TRUE.equals(proven.get(SkillSection.EO))) {
            return fullExamMilestone(userId, proofStart);
        }

        // Sinon l'epreuve la mieux transferee qui n'a pas encore fait ses
        // preuves. A egalite, l'ECRIT passe devant l'oral — meme depart que le
        // diagnostic, ou la premiere egalite parfaite revient a l'ecrit.
        SkillSection choix = null;
        if (ecritPret && !Boolean.TRUE.equals(proven.get(SkillSection.EE))) choix = SkillSection.EE;
        if (oralPret && !Boolean.TRUE.equals(proven.get(SkillSection.EO))
                && (choix == null
                        || tallies.get(SkillSection.EO).solid > tallies.get(SkillSection.EE).solid)) {
            choix = SkillSection.EO;
        }
        if (choix == null) return Optional.empty();
        return Optional.of(epreuveMilestone(userId, choix));
    }

    // ------------------------------------------------------------------------
    // Interne
    // ------------------------------------------------------------------------

    /**
     * Une epreuve est « transferee » quand elle compte assez de competences
     * {@code SOLID} <b>en valeur absolue</b> ET en <b>part</b> de ses
     * competences observees. Les deux ensemble, jamais l'une ou l'autre : la
     * part seule declarerait prete une epreuve ou une unique competence a ete
     * vue, le nombre seul ignorerait la moitie de l'epreuve restee fragile.
     */
    private static boolean reached(Tally tally, LearningPlanProperties.Milestone config) {
        if (tally == null || tally.observed == 0) return false;
        return tally.solid >= config.getEpreuveMinSolidSkills()
                && tally.solid >= config.getEpreuveSolidRatio() * tally.observed;
    }

    /**
     * Une production d'examen blanc de cette epreuve a-t-elle ete observee
     * recemment ? Lu sur l'historique deja charge, via le type de source — un
     * examen blanc d'epreuve comme une sous-epreuve d'examen complet ecrivent
     * tous deux {@code MOCK_EXAM_EE} / {@code MOCK_EXAM_EO}.
     */
    private static boolean hasRecentMockExamProof(
            Collection<LearningPlanObservation> observations, SkillSection section, Instant since) {
        LearningPlanSourceType attendu = section == SkillSection.EO
                ? LearningPlanSourceType.MOCK_EXAM_EO : LearningPlanSourceType.MOCK_EXAM_EE;
        return observations.stream()
                .filter(item -> item.getSourceType() == attendu)
                .filter(item -> item.getObservedAt() != null)
                .anyMatch(item -> !item.getObservedAt().isBefore(since));
    }

    private PlanRecommendedExerciseDto epreuveMilestone(UUID userId, SkillSection section) {
        EpreuveType epreuve = section == SkillSection.EO
                ? EpreuveType.TCF_EO : EpreuveType.TCF_EE;
        int slot = nextSlot(
                attemptManager.countProductionExamSessions(userId, epreuve),
                ProductionExamCompositionService.EXAM_SLOTS_PER_EPREUVE);
        int minutes = (epreuve == EpreuveType.TCF_EO
                ? AttemptService.PRODUCTION_EO_EXAM_SECONDS
                : AttemptService.PRODUCTION_EE_EXAM_SECONDS) / 60;
        // Le verrou est REPORTE, jamais applique a la designation : un jalon
        // verrouille reste designe avec son cadenas. La regle est lue chez
        // l'autorite que le serveur oppose au demarrage, jamais recopiee.
        return PlanRecommendedExerciseDto.epreuveMockExam(
                epreuve, slot, minutes, productionAccessService.isProductionExamLocked(userId));
    }

    /**
     * Le jalon final, sauf si un examen complet a deja ete passe dans la fenetre
     * de validite : un jalon est une etape, pas une boucle. Dans ce cas le Plan
     * n'affiche <b>aucun</b> jalon — cas normal, le candidat vient de se mesurer.
     */
    private Optional<PlanRecommendedExerciseDto> fullExamMilestone(UUID userId, Instant proofStart) {
        List<Attempt> complets = attemptManager.findByUserAndEpreuve(
                userId, EpreuveType.TCF_COMPLET, FullTcfExamService.EXAM_SLOTS);
        boolean recent = complets.stream()
                .map(Attempt::getStartedAt)
                .anyMatch(startedAt -> startedAt != null && !startedAt.isBefore(proofStart));
        if (recent) return Optional.empty();
        return Optional.of(PlanRecommendedExerciseDto.fullTcfMockExam(
                nextSlot(complets.size(), FullTcfExamService.EXAM_SLOTS),
                FullTcfExamService.FULL_EXAM_TOTAL_SECONDS / 60,
                productionAccessService.isFullExamProductionLocked(userId)));
    }

    /**
     * Le premier slot que ce candidat n'a pas encore joue, <b>plafonne a la
     * taille de la grille</b> : servir toujours le slot 1 lui resservirait la
     * meme composition, et depasser la grille ferait echouer le demarrage sur la
     * validation du slot.
     */
    private static int nextSlot(long dejaJoues, int slots) {
        return (int) Math.min(Math.max(1, dejaJoues + 1), slots);
    }

    /** Ce qu'on sait d'une epreuve : combien de competences vues, combien transferees. */
    private static final class Tally {
        private int observed;
        private int solid;
    }
}
