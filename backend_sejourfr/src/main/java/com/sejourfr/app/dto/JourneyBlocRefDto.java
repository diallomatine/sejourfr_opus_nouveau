package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyBlocKind;

/**
 * Le <b>bloc</b> d'une etape ou d'un lot, tel qu'il est <b>servi</b>.
 *
 * <p>🛑 <b>Un seul contrat pour les deux modules</b>, et c'est une decision
 * assumee (2026-09-19). Le contrat precedent portait
 * {@code examType: EpreuveType}, qu'un bloc civique ne peut pas remplir. Deux
 * voies s'ouvraient :
 * <ul>
 *   <li>{@code examType} + {@code themeCode}, et <b>chaque front branche sur le
 *       module</b> ;</li>
 *   <li><b>retenue</b> : un bloc servi, {@code {kind, code, label}}, que le front
 *       affiche sans jamais brancher.</li>
 * </ul>
 *
 * <p>La seconde applique la doctrine du depot au lieu de la contourner :
 * « l'etat, son libelle et son ton arrivent <b>servis</b> », et « aucun front ne
 * fabrique sa table de libelles ». Un front qui branche sur le module finit par
 * afficher autre chose que son jumeau.
 *
 * <p>🛑 <b>Le {@link #label} est SERVI, et c'est la nouveaute.</b> Les fronts
 * tenaient un miroir gele des libelles d'epreuve
 * ({@code lib/tcf-epreuves.ts} ⇄ {@code core/utils/tcf_epreuves.dart}) ; il reste
 * pour ses autres emplois, mais l'ecran du cycle lit ce label-ci. C'est ce qui
 * garantit qu'une thematique civique et une epreuve TCF s'affichent par le meme
 * chemin — exigence de D-21, transposee par D-47.
 *
 * @param kind  la nature de l'axe : une epreuve TCF ou une thematique civique.
 * @param code  l'identifiant stable — {@code TCF_CO}, {@code CIV_PRINCIPES}. Ce
 *              que le front utilise comme cle, jamais ce qu'il affiche.
 * @param label ce que le <b>candidat lit</b> — « Comprehension orale »,
 *              « Principes et valeurs de la Republique ».
 */
public record JourneyBlocRefDto(JourneyBlocKind kind, String code, String label) {

    public JourneyBlocRefDto {
        if (kind == null || code == null || label == null) {
            throw new IllegalArgumentException(
                    "Un bloc servi porte toujours sa nature, son code et son libelle : "
                            + kind + " / " + code + " / " + label);
        }
    }

    /** Ce bloc est-il une epreuve du TCF ? */
    public boolean estEpreuve() {
        return kind == JourneyBlocKind.EPREUVE;
    }
}
