package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillReferenceLevel;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;

/**
 * Remplacement des trois productions de reference d'un sujet, d'un seul coup.
 *
 * <p><b>Un objet enveloppe, pas un tableau nu</b> : un corps racine de type
 * tableau ne peut plus accueillir de champ sans casser tous les clients, et le
 * jour ou ce PUT devra porter une option (« publier », « dupliquer depuis un
 * autre sujet »), l'enveloppe l'absorbera.
 *
 * <p>Les trois niveaux sont exiges, sans doublon : la table impose
 * {@code UNIQUE (skill_prompt_id, level)} et l'ecran de resultat du candidat
 * affiche trois onglets. En livrer deux ferait un onglet vide, et le tolerer
 * ici reviendrait a decider a la place de l'editeur qu'une reference manquante
 * est acceptable. Le remplacement est <b>atomique</b> : les anciennes lignes ne
 * disparaissent que si les trois nouvelles sont valides.
 */
public record AdminSkillReferencesRequest(
        @NotEmpty(message = "Les trois références sont obligatoires.")
        @Valid
        List<Item> references
) {
    /** Une reference. Meme forme que {@code SkillReferenceDto}, validation en plus. */
    public record Item(
            @NotNull(message = "Le niveau de la référence est obligatoire.")
            SkillReferenceLevel level,

            @NotBlank(message = "Le texte de la référence est obligatoire.")
            String text,

            @NotBlank(message = "La note pédagogique est obligatoire.")
            String pedagogicalNote
    ) {
    }
}
