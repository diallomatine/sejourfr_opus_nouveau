package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillSection;

import java.util.UUID;

/**
 * L'exercice reellement disponible que le Plan recommande — sur une competence
 * (une etape) ou, d'un cran au-dessus, comme <b>jalon</b> du parcours.
 *
 * <p><b>Quatre natures, un seul champ</b> ({@link #kind}), et un jeu
 * d'identifiants <b>mutuellement exclusifs</b> par nature. Aucun front ne doit
 * deviner la nature d'un {@code null} : il lit {@code kind}.
 * <table>
 *   <caption>Ce qui est renseigne selon la nature</caption>
 *   <tr><th>{@code kind}</th><th>identifiants</th><th>vide</th></tr>
 *   <tr><td>{@code MICRO_TRAINING}</td><td>{@link #skillPromptId()}</td>
 *       <td>{@code productionTaskId}, {@code tacheNumero}, {@code epreuve},
 *           {@code slotNumber}</td></tr>
 *   <tr><td>{@code REASSESSMENT}</td>
 *       <td>{@link #productionTaskId()} + {@link #tacheNumero()}</td>
 *       <td>{@code skillPromptId}, {@code epreuve}, {@code slotNumber}</td></tr>
 *   <tr><td>{@code EPREUVE_MOCK_EXAM}</td>
 *       <td>{@link #epreuve()} (EE ou EO) + {@link #slotNumber()}</td>
 *       <td>tout le bloc competence : {@code skillId}, {@code skillCode},
 *           {@code title}, {@code section}, les deux identifiants de sujet</td></tr>
 *   <tr><td>{@code FULL_TCF_MOCK_EXAM}</td>
 *       <td>{@link #epreuve()} ({@code TCF_COMPLET}) + {@link #slotNumber()}</td>
 *       <td>idem</td></tr>
 * </table>
 *
 * <p><b>Un jalon ne porte ni titre ni competence, et c'est voulu.</b> Il ne
 * designe pas un contenu editorial mais une <b>session d'examen blanc deja
 * existante</b> ; sa phrase appartient aux fronts, comme pour
 * {@code PlanChangeDto} — le serveur expose des faits (quelle epreuve, quel
 * slot, verrouille ou non), jamais un libelle.
 *
 * <p>Les quatre formes se construisent par {@link #microTraining},
 * {@link #reassessment}, {@link #epreuveMockExam} et {@link #fullTcfMockExam},
 * jamais par le constructeur canonique : c'est ce qui garantit qu'un identifiant
 * hors sujet ne peut pas s'y glisser.
 */
public record PlanRecommendedExerciseDto(
        PlanExerciseKind kind,
        /** Micro-exercice uniquement ; {@code null} sur une verification. */
        UUID skillPromptId,
        /** Verification uniquement ; {@code null} sur un micro-exercice. */
        UUID productionTaskId,
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        /**
         * Numero de tache (1, 2 ou 3) du sujet de production — verification
         * uniquement, {@code null} sur un micro-exercice. Avec {@link #section()},
         * c'est ce qui permet au front d'ouvrir le bon ecran de production.
         */
        Short tacheNumero,
        int estimatedMinutes,
        /**
         * {@code true} quand ce candidat ne peut pas produire sur ce sujet : le
         * front affiche un cadenas sur l'exercice et renvoie vers le paiement.
         * L'exercice reste <b>designe et visible</b> — savoir quoi travailler
         * est justement ce que le Plan apporte.
         */
        boolean locked,
        /**
         * Jalons uniquement ; {@code null} sur un micro-exercice comme sur une
         * verification. {@code TCF_EE} / {@code TCF_EO} pour un examen blanc
         * d'epreuve, {@code TCF_COMPLET} pour l'examen blanc complet — c'est
         * <b>ce champ</b>, jamais {@link #section()}, qui dit vers quel examen
         * le front doit envoyer.
         */
        EpreuveType epreuve,
        /**
         * Slot de la grille d'examens blancs a demarrer — jalons uniquement,
         * {@code null} ailleurs. Le serveur designe le premier slot que ce
         * candidat n'a pas encore joue (plafonne a la taille de la grille) : le
         * front le repasse tel quel au demarrage, il ne le choisit pas.
         */
        Integer slotNumber
) {

    /** Un petit sujet du module Competences. */
    public static PlanRecommendedExerciseDto microTraining(
            UUID skillPromptId, UUID skillId, String skillCode, String title,
            SkillSection section, int estimatedMinutes, boolean locked) {
        return new PlanRecommendedExerciseDto(
                PlanExerciseKind.MICRO_TRAINING, skillPromptId, null, skillId, skillCode,
                title, section, null, estimatedMinutes, locked, null, null);
    }

    /** Une vraie tache TCF, pour verifier le transfert en situation. */
    public static PlanRecommendedExerciseDto reassessment(
            UUID productionTaskId, UUID skillId, String skillCode, String title,
            SkillSection section, Short tacheNumero, int estimatedMinutes, boolean locked) {
        return new PlanRecommendedExerciseDto(
                PlanExerciseKind.REASSESSMENT, null, productionTaskId, skillId, skillCode,
                title, section, tacheNumero, estimatedMinutes, locked, null, null);
    }

    /**
     * Le jalon d'une epreuve : 3 taches d'expression ecrite ou orale en
     * conditions d'examen.
     */
    public static PlanRecommendedExerciseDto epreuveMockExam(
            EpreuveType epreuve, int slotNumber, int estimatedMinutes, boolean locked) {
        return new PlanRecommendedExerciseDto(
                PlanExerciseKind.EPREUVE_MOCK_EXAM, null, null, null, null,
                null, null, null, estimatedMinutes, locked, epreuve, slotNumber);
    }

    /** Le jalon final : l'examen blanc TCF complet, les 4 epreuves enchainees. */
    public static PlanRecommendedExerciseDto fullTcfMockExam(
            int slotNumber, int estimatedMinutes, boolean locked) {
        return new PlanRecommendedExerciseDto(
                PlanExerciseKind.FULL_TCF_MOCK_EXAM, null, null, null, null,
                null, null, null, estimatedMinutes, locked,
                EpreuveType.TCF_COMPLET, slotNumber);
    }
}
