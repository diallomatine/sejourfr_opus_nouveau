package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillDifficulty;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

/**
 * Modification d'un petit sujet. {@code skillId} et {@code code} sont absents :
 * un sujet ne change pas de competence (son critere unique n'aurait plus de
 * sens ailleurs) et son code editorial est immuable.
 *
 * <p><b>⚠ Les trois bornes de longueur ont une semantique de REMPLACEMENT, pas
 * de fusion : un nul veut dire « efface », pas « ne touche pas ».</b> C'est
 * contre-intuitif pour un PATCH, et c'est voulu — sans cela, une borne posee
 * par erreur deviendrait ineffacable depuis la console. Corriger un sujet
 * publie a tort en EE (donc porteur d'une fourchette de mots) demanderait alors
 * une intervention SQL. La regle est aussi ce qui rend la coherence EE/EO
 * atteignable : basculer un sujet vers l'oral suppose de pouvoir vider ses
 * bornes de mots dans le meme appel ou l'on pose sa duree, sinon le CHECK
 * {@code chk_skill_prompts_ee_eo_coherence} refuse l'etat intermediaire.
 *
 * <p><b>Les quatre champs de guidage suivent la meme regle</b>, pour la meme
 * raison : leurs colonnes sont nullables (V026), un nul y designe donc un etat
 * atteignable — « ce sujet n'a pas de guidage » — et non un etat impossible.
 *
 * <p>Les autres champs visent des colonnes {@code NOT NULL} : un nul y demande
 * un etat impossible, il vaut donc « ne touche pas ». Le front, lui, envoie
 * toujours tous les champs — les deux lectures coincident.
 */
public record AdminSkillPromptUpdateRequest(
        @Size(max = 160, message = "Le titre ne peut pas dépasser 160 caractères.")
        String title,

        String context,

        String instruction,

        String uniqueCriterion,

        /**
         * Guidage de l'ecran de saisie. <b>Meme semantique de REMPLACEMENT que
         * les bornes : un nul efface.</b> Ces colonnes sont nullables (V026),
         * donc un nul y designe un etat atteignable — a l'inverse des colonnes
         * {@code NOT NULL} ci-dessus, ou il ne peut vouloir dire que « ne touche
         * pas ». Sans cela, une check-list posee par erreur serait ineffacable
         * depuis la console.
         */
        java.util.List<String> checklist,

        java.util.List<SkillConstraintTagInput> constraintTags,

        String answerStarter,

        /** Sans le prefixe « Astuce : ». Nul = efface. */
        String tip,

        /** Nul = efface. Voir la note de remplacement ci-dessus. */
        @Min(value = 1, message = "Le nombre de mots minimum doit être positif.")
        Integer recommendedMinWords,

        @Min(value = 1, message = "Le nombre de mots maximum doit être positif.")
        Integer recommendedMaxWords,

        @Min(value = 1, message = "La durée conseillée doit être positive.")
        Integer recommendedDurationSeconds,

        SkillDifficulty difficultyLevel,

        @Min(value = 1, message = "Le rang d'affichage doit être compris entre 1 et 20.")
        @Max(value = 20, message = "Le rang d'affichage doit être compris entre 1 et 20.")
        Integer displayOrder,

        Boolean active
) {
}
