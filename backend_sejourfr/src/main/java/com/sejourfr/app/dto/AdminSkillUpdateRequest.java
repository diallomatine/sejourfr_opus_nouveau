package com.sejourfr.app.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Modification d'une competence. {@code code}, {@code section} et
 * {@code taskCode} sont <b>absents et immuables</b> : les codes des sujets
 * ({@code EE1-C1-S1}) et les seeds s'y adossent, et deplacer une competence
 * d'une tache a l'autre invaliderait le palier de ses cinq sujets.
 *
 * <p><b>Semantique des nuls</b> — toutes les colonnes visees ici sont
 * {@code NOT NULL} en base : un champ absent ne peut donc pas vouloir dire
 * « efface », il veut dire « ne touche pas ». C'est l'inverse de
 * {@link AdminSkillPromptUpdateRequest}, dont les bornes de longueur SONT
 * nullables et ou un nul efface. La regle est la meme dans les deux cas — un
 * nul demande l'etat « vide » quand il existe — elle produit juste deux
 * comportements opposes selon la colonne.
 */
public record AdminSkillUpdateRequest(
        @Size(max = 160, message = "Le titre ne peut pas dépasser 160 caractères.")
        String title,

        String description,

        String generalCriterion,

        @Pattern(regexp = "A1|A2|B1|B2", message = "Le palier visé doit valoir A1, A2, B1 ou B2.")
        String targetLevel,

        @Min(value = 1, message = "Le rang d'affichage doit être compris entre 1 et 50.")
        @Max(value = 50, message = "Le rang d'affichage doit être compris entre 1 et 50.")
        Integer displayOrder,

        Boolean active
) {
}
