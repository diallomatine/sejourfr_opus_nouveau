package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.manager.AttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * <b>R1 — seules les EVALUATIONS alimentent la file</b> (arbitrage du
 * proprietaire D-6, 2026-09-17).
 *
 * <h2>Le probleme que cette classe existe pour resoudre</h2>
 * <p>R1 etait <b>faux dans l'existant</b>, et l'audit de Phase 0 l'a etabli :
 * {@code AttemptInteractionService.doFinish} appelle
 * {@code ComprehensionObservationService.record} pour <b>toute</b> session TCF
 * terminee — {@code TRAINING}, {@code REVIEW}, {@code MOCK_EXAM}, section de
 * diagnostic confondues. Une serie ciblee de 20 questions CO-B1 ecrit donc de
 * vraies observations {@code TCF_CO}, qui deviendraient de vraies priorites.
 *
 * <p>🛑 <b>Ce comportement ne change pas</b>, et c'est volontaire : la doctrine
 * du 2026-08-21 tient — « en comprehension, une bonne reponse est une bonne
 * reponse ; il n'y a ni assistance ni filet dont l'absence rendrait l'examen
 * plus probant ». Les entrainements continuent de nourrir le profil, le niveau
 * et la maitrise. C'est <b>la file</b> qui filtre, et elle filtre <b>ici</b>.
 *
 * <h2>Une seule classe, deux appelants</h2>
 * <p>{@code JourneyService.onAssessmentCompleted} <b>et</b> le bootstrap R19
 * passent par elle. Deux copies finiraient par admettre deux ensembles de
 * preuves differents — un candidat verrait alors, au bootstrap, une file
 * qu'aucune evaluation ulterieure ne saurait reproduire.
 *
 * <h2>Ce qu'un entrainement garde le droit de faire</h2>
 * <p>Il <b>fait avancer et peut clore</b> une etape deja presente (R8, §7.3). Il
 * n'en cree jamais. La difference n'est pas cosmetique : c'est ce qui rend vraie
 * la phrase « le Plan n'apprend rien des entrainements, il apprend des
 * evaluations ».
 */
@Component
@RequiredArgsConstructor
public class JourneyEvaluationFilter {

    private final AttemptManager attemptManager;

    /**
     * Les observations qui viennent d'une <b>evaluation</b>, dans l'ordre recu.
     *
     * <p><b>Une requete au plus</b>, quelle que soit la taille de l'historique :
     * les identifiants de session de comprehension sont demandes <b>en lot</b>.
     * Un {@code findById} par observation serait un N+1 pur a chaque lecture.
     *
     * @param observations tout l'historique du candidat, tel que
     *                     {@code LearningPlanObservationManager.findAllByUserWithSkill}
     *                     le rend (de la plus recente a la plus ancienne).
     */
    public List<LearningPlanObservation> retenir(List<LearningPlanObservation> observations) {
        if (observations == null || observations.isEmpty()) return List.of();
        Set<UUID> examens = examensParmiLesSessionsDeComprehension(observations);
        return observations.stream()
                .filter(observation -> estUneEvaluation(observation, examens))
                .toList();
    }

    /**
     * Cette observation vient-elle d'une evaluation ?
     *
     * @param examens les sessions de comprehension qui sont des examens blancs,
     *                telles que {@link #examensParmiLesSessionsDeComprehension}
     *                les a resolues. Passees en parametre plutot que relues :
     *                cette methode est appelee une fois par observation.
     */
    public boolean estUneEvaluation(LearningPlanObservation observation, Set<UUID> examens) {
        LearningPlanSourceType source = observation.getSourceType();
        if (source == null) return false;
        return switch (source) {
            // Le diagnostic rapide et les productions d'examen : des evaluations
            // par construction de leur source_type.
            case DIAGNOSTIC_EE, DIAGNOSTIC_EO, MOCK_EXAM_EE, MOCK_EXAM_EO -> true;
            // 🛑 L'entrainement libre de production et le petit sujet cible ne
            // creent JAMAIS d'etape. PRODUCTION_EE/EO est bien un
            // ENTRAINEMENT : le discriminant « examen » cote production est
            // `slot_number` ou `parent_attempt_id`, et c'est lui qui a deja
            // range ces lignes en MOCK_EXAM_* quand c'en etait un.
            case PRODUCTION_EE, PRODUCTION_EO, SKILL_TRAINING -> false;
            // En comprehension, la source ne distingue pas l'examen de la serie
            // ciblee — c'est la session qui le dit.
            case TCF_CO, TCF_CE -> examens.contains(observation.getSourceId());
            // 🛑 CIVIQUE : LA SOURCE SUFFIT, et c'est voulu (D-49). Contrairement
            // a la comprehension TCF, ou il faut relire la session pour savoir si
            // c'etait un examen, le civique porte la distinction DANS son
            // `source_type` -- `CIVIQUE_SERIE` pour une serie ciblee du Plan,
            // `CIVIQUE_EXAMEN` pour un examen de theme ou global. C'est ce qui
            // rend R3 lisible sans requete : l'entrainement n'alimente jamais le
            // cycle en attente, seuls les examens le font.
            case CIVIQUE_SERIE -> false;
            case CIVIQUE_EXAMEN -> true;
        };
    }

    /**
     * Parmi les sessions de comprehension de cet historique, lesquelles sont des
     * <b>examens blancs</b> ?
     *
     * <p>Rendue publique parce que les appelants qui filtrent plusieurs fois le
     * meme historique (le bootstrap, qui cherche une evaluation de reference par
     * epreuve) doivent pouvoir la resoudre <b>une fois</b>.
     */
    public Set<UUID> examensParmiLesSessionsDeComprehension(
            List<LearningPlanObservation> observations) {
        Set<UUID> sessions = new LinkedHashSet<>();
        for (LearningPlanObservation observation : observations) {
            LearningPlanSourceType source = observation.getSourceType();
            if (source != null && source.isComprehension() && observation.getSourceId() != null) {
                sessions.add(observation.getSourceId());
            }
        }
        return attemptManager.findMockExamIdsAmong(sessions);
    }
}
