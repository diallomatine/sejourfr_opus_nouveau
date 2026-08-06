package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillDifficulty;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Creation d'un petit sujet.
 *
 * <p><b>Aucune {@code section} n'est acceptee.</b> Elle est deduite de la
 * competence parente : la colonne est denormalisee et verrouillee par la cle
 * etrangere composite {@code (skill_id, section)}, si bien qu'une section
 * venue du client ne pourrait qu'etre redondante ou fausse. Dans le second cas
 * l'insertion echouerait sur la FK, en 500, pour une valeur que le serveur
 * connaissait deja.
 *
 * <p>Les trois bornes sont exclusives selon cette section : un sujet ecrit
 * porte une fourchette de mots et aucune duree, un sujet oral l'inverse. Le
 * service le verifie avant l'insertion pour rendre un 422 lisible plutot que la
 * violation du CHECK {@code chk_skill_prompts_ee_eo_coherence}.
 */
public record AdminSkillPromptCreateRequest(
        @NotNull(message = "La compétence parente est obligatoire.")
        java.util.UUID skillId,

        @NotBlank(message = "Le code éditorial est obligatoire.")
        @Size(max = 24, message = "Le code éditorial ne peut pas dépasser 24 caractères.")
        String code,

        @NotBlank(message = "Le titre est obligatoire.")
        @Size(max = 160, message = "Le titre ne peut pas dépasser 160 caractères.")
        String title,

        @NotBlank(message = "Le contexte est obligatoire.")
        String context,

        @NotBlank(message = "La consigne est obligatoire.")
        String instruction,

        @NotBlank(message = "Le critère unique est obligatoire.")
        String uniqueCriterion,

        /**
         * Guidage de l'ecran de saisie — <b>facultatif</b> : les quatre champs
         * qui suivent peuvent etre absents, un sujet naitra alors sans guidage
         * et les fronts se degraderont sur la consigne. Fournis, ils sont
         * valides par le service (2 a 4 gestes, 1 a 3 etiquettes, icone dans la
         * liste fermee) : les bornes vivent la-bas et non en annotation, pour
         * rendre un message qui explique la regle au lieu de la reciter.
         */
        java.util.List<String> checklist,

        java.util.List<SkillConstraintTagInput> constraintTags,

        String answerStarter,

        /** Sans le prefixe « Astuce : » — les fronts l'ajoutent. */
        String tip,

        /** Section EE uniquement. Conseil d'ecriture, jamais un plafond. */
        @Min(value = 1, message = "Le nombre de mots minimum doit être positif.")
        Integer recommendedMinWords,

        @Min(value = 1, message = "Le nombre de mots maximum doit être positif.")
        Integer recommendedMaxWords,

        /** Section EO uniquement. Conseil de duree, jamais un plafond. */
        @Min(value = 1, message = "La durée conseillée doit être positive.")
        Integer recommendedDurationSeconds,

        @NotNull(message = "La difficulté est obligatoire.")
        SkillDifficulty difficultyLevel,

        @NotNull(message = "Le rang d'affichage est obligatoire.")
        @Min(value = 1, message = "Le rang d'affichage doit être compris entre 1 et 20.")
        @Max(value = 20, message = "Le rang d'affichage doit être compris entre 1 et 20.")
        Integer displayOrder,

        /** Absent = sujet publie. */
        Boolean active
) {
}
