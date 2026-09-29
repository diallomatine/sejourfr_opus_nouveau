package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.QuestionType;

/**
 * Ce qu'il faut lancer pour mesurer un domaine du TCF qui ne l'a <b>jamais</b>
 * ete : l'epreuve concernee, la nature du parcours, et les parametres exacts du
 * demarrage.
 *
 * <p><b>Des faits, jamais une phrase</b> — le serveur dit quelle epreuve et quoi
 * demarrer, le titre et le sous-titre appartiennent aux fronts (meme doctrine
 * que {@code PlanRecommendedExerciseDto} pour les jalons). Le brief §7 va
 * jusqu'a interdire une formulation precise cote ecran ; raison de plus pour
 * qu'aucun libelle ne parte d'ici.
 *
 * <p><b>Derive a la lecture, jamais persiste</b> : aucune table, aucune
 * migration. Il se relit du profil TCF a chaque lecture du Plan, comme
 * {@code PlanCycleDto}, {@code SkillMasteryState} et {@code SituationDansNiveau}.
 *
 * <h2>Ce qui est renseigne selon la nature</h2>
 * <table>
 *   <caption>Champs par {@link #kind()}</caption>
 *   <tr><th>{@code kind}</th><th>renseigne</th><th>{@code null}</th></tr>
 *   <tr><td>{@code MODULE_MOCK_EXAM}</td>
 *       <td>{@link #epreuve()}, {@link #moduleExamQuestionType()},
 *           {@link #slotNumber()}, {@link #estimatedMinutes()}</td>
 *       <td>&mdash;</td></tr>
 *   <tr><td>{@code PRODUCTION_MOCK_EXAM}</td>
 *       <td>{@link #epreuve()}, {@link #slotNumber()}, et
 *           {@link #estimatedMinutes()} <b>a l'ecrit seulement</b></td>
 *       <td>{@code moduleExamQuestionType} ; {@code estimatedMinutes} a
 *           l'oral</td></tr>
 * </table>
 * Les deux formes se construisent par {@link #moduleMockExam} et
 * {@link #productionMockExam}, jamais par le constructeur canonique : c'est ce
 * qui interdit qu'un parametre hors sujet s'y glisse.
 *
 * @param epreuve               le domaine mesure — {@code TCF_CO}, {@code TCF_CE},
 *                              {@code TCF_EO} ou {@code TCF_EE}
 * @param kind                  le parcours <b>existant</b> a ouvrir
 * @param moduleExamQuestionType ce que {@code StartAttemptRequest} attend pour
 *                              composer l'examen d'epreuve ; {@code CO} ou
 *                              {@code CE}, jamais {@code CO_IMAGE} (un filtre
 *                              {@code CO} l'inclut deja partout dans le depot).
 *                              {@code null} sur un examen de production, qui ne
 *                              se compose d'aucun type de question
 * @param slotNumber            slot de la grille d'examens blancs a demarrer
 * @param estimatedMinutes      duree de l'epreuve, lue chez {@code DureeEpreuve}
 *                              et jamais ecrite en dur ; {@code null} quand
 *                              l'epreuve n'a pas de chrono opposable
 *                              (l'expression orale se chronometre par tache)
 */
public record PlanDomainAssessmentDto(
        EpreuveType epreuve,
        PlanDomainAssessmentKind kind,
        QuestionType moduleExamQuestionType,
        Integer slotNumber,
        Integer estimatedMinutes
) {

    /**
     * Un examen blanc de module CO ou CE, deja existant.
     *
     * <p>Le slot est celui que l'appelant a decide ; il ne se devine pas ici.
     */
    public static PlanDomainAssessmentDto moduleMockExam(
            EpreuveType epreuve, QuestionType questionType, int slotNumber, int estimatedMinutes) {
        return new PlanDomainAssessmentDto(
                epreuve, PlanDomainAssessmentKind.MODULE_MOCK_EXAM,
                questionType, slotNumber, estimatedMinutes);
    }

    /**
     * Un examen blanc de production EE ou EO — les 3 taches enchainees, deja
     * existantes.
     *
     * <p>Le slot est celui que l'appelant a decide, comme pour
     * {@link #moduleMockExam}. {@code estimatedMinutes} est <b>nullable</b> :
     * l'expression orale n'a pas de duree d'epreuve, et on n'annonce alors
     * aucune minute plutot qu'un chiffre invente.
     */
    public static PlanDomainAssessmentDto productionMockExam(
            EpreuveType epreuve, int slotNumber, Integer estimatedMinutes) {
        return new PlanDomainAssessmentDto(
                epreuve, PlanDomainAssessmentKind.PRODUCTION_MOCK_EXAM,
                null, slotNumber, estimatedMinutes);
    }
}
