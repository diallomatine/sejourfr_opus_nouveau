package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

import java.util.List;

/**
 * L'AVANT / APRES de l'ecran de resultat du diagnostic : la phrase du candidat,
 * et la meme phrase reecrite au palier qu'il vise.
 *
 * <p><b>Nullable, et son absence est un cas NORMAL</b> — jamais une erreur, jamais
 * une attente a annoncer. Il vient d'un second appel LLM best-effort, lance apres
 * l'analyse : il peut manquer parce que le coupe-circuit est ouvert, parce que le
 * candidat vise deja son palier, parce que le fournisseur n'a pas repondu, ou
 * simplement parce que l'analyse est anterieure a la mise en service. Les analyses
 * deja en base n'ont pas ce bloc : legacy intact, champ absent.
 *
 * <p><b>ECRIT SEULEMENT</b> : la production orale n'est jamais reecrite.
 *
 * @param original   la phrase du candidat, <b>sous-chaine exacte</b> de sa
 *                   production ecrite. Resolue serveur depuis le numero de segment
 *                   designe par le modele, qui ne recopie jamais rien lui-meme.
 * @param texte      la meme phrase, reecrite au niveau vise.
 * @param segments   passages a mettre en evidence DANS {@code texte} ; chaque
 *                   {@code extrait} est une <b>sous-chaine exacte</b> de
 *                   {@code texte}, donc surlignable par simple recherche de
 *                   chaine. La liste peut etre <b>vide</b> : un texte sans
 *                   surlignage reste un texte modele.
 * @param niveauVise palier de la reecriture. <b>Donnee de logique, pas une
 *                   etiquette a coller sur le texte</b> : une phrase reecrite ne
 *                   suffit pas a demontrer un palier.
 */
public record DiagnosticExempleCibleDto(
        String original,
        String texte,
        List<Segment> segments,
        NiveauCecrl niveauVise
) {

    /**
     * Un passage a surligner.
     *
     * @param extrait sous-chaine exacte du texte reecrit
     * @param apport  ce que ce passage apporte, 3 mots maximum
     */
    public record Segment(String extrait, String apport) {
    }
}
