package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Creation d'une competence depuis la console.
 *
 * <p>{@link #generalCriterion} est <b>obligatoire</b> : la colonne est
 * {@code NOT NULL} en base, et une competence sans critere general laisserait
 * le candidat sans la seule phrase qui lui dit sur quoi il travaille. L'omettre
 * ferait echouer l'insertion sur une violation de contrainte, en 500 ; on la
 * refuse ici, en 400, en nommant le champ.
 *
 * <p><b>{@link #section} et {@link #taskCode} sont facultatifs
 * individuellement, jamais ensemble.</b> Pour une competence d'EXPRESSION, la
 * tache suffit : la section s'en deduit (« EE1 » vit dans « EE »), et fournie
 * elle doit concorder — le serveur refuse plutot que d'ignorer silencieusement
 * une valeur client contradictoire. Pour une competence de COMPREHENSION, il
 * n'existe aucune tache : c'est la section (CO ou CE) qui est fournie, seule.
 */
public record AdminSkillCreateRequest(
        SkillSection section,

        /**
         * La tache d'appartenance, <b>omise pour une competence de
         * comprehension</b> — celles-ci n'appartiennent a aucune des 6 taches
         * officielles. Le couple (section, taskCode) est arbitre par le service.
         */
        SkillTaskCode taskCode,

        @NotBlank(message = "Le code éditorial est obligatoire.")
        @Size(max = 16, message = "Le code éditorial ne peut pas dépasser 16 caractères.")
        String code,

        @NotBlank(message = "Le titre est obligatoire.")
        @Size(max = 160, message = "Le titre ne peut pas dépasser 160 caractères.")
        String title,

        @NotBlank(message = "La description est obligatoire.")
        String description,

        @NotBlank(message = "Le critère général est obligatoire.")
        String generalCriterion,

        @NotBlank(message = "Le palier visé est obligatoire.")
        @Pattern(regexp = "A1|A2|B1|B2", message = "Le palier visé doit valoir A1, A2, B1 ou B2.")
        String targetLevel,

        @NotNull(message = "Le rang d'affichage est obligatoire.")
        @Min(value = 1, message = "Le rang d'affichage doit être compris entre 1 et 50.")
        @Max(value = 50, message = "Le rang d'affichage doit être compris entre 1 et 50.")
        Integer displayOrder,

        /** Absent = competence publiee. Une creation sert le plus souvent a publier. */
        Boolean active
) {
}
