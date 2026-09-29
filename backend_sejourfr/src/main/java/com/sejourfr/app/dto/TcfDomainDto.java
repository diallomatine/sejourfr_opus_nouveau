package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

/**
 * Un domaine du profil TCF d'un candidat : l'épreuve, le fait qu'elle ait été
 * évaluée, et le niveau estimé quand elle l'a été.
 *
 * <p>{@code evaluated == false} ⇔ {@code niveau == null} : le domaine n'a
 * jamais été réellement passé, donc son niveau est <b>inconnu</b> — jamais
 * {@code A1_NON_ATTEINT}. Les fronts affichent « Pas encore évaluée », et
 * <b>ne dérivent aucun niveau</b> : il est calculé serveur
 * ({@code TcfProfileService}).
 *
 * @param epreuve   {@code TCF_CO} | {@code TCF_CE} | {@code TCF_EO} | {@code TCF_EE}
 * @param evaluated {@code true} si le domaine porte un niveau opposable
 * @param niveau    niveau estimé, {@code null} si jamais évalué
 */
public record TcfDomainDto(
        EpreuveType epreuve,
        boolean evaluated,
        NiveauCecrl niveau
) {

    /** Domaine jamais évalué : rien à annoncer, et surtout pas un niveau bas. */
    public static TcfDomainDto notEvaluated(EpreuveType epreuve) {
        return new TcfDomainDto(epreuve, false, null);
    }

    /** Domaine évalué ({@code niveau} non null) ou non, selon la valeur reçue. */
    public static TcfDomainDto of(EpreuveType epreuve, NiveauCecrl niveau) {
        return niveau == null ? notEvaluated(epreuve) : new TcfDomainDto(epreuve, true, niveau);
    }
}
