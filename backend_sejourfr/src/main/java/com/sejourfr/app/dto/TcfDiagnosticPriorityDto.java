package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

/**
 * Une priorite du diagnostic : l'epreuve et la tache qui bloquent le candidat.
 *
 * <p>🛑 <b>Le score n'est PAS expose.</b> C'est un rang de tri interne ; le
 * montrer inviterait a le comparer d'un diagnostic a l'autre, alors qu'il
 * depend de la cible du candidat.
 */
public record TcfDiagnosticPriorityDto(
        int rang,
        EpreuveType epreuve,
        /** « EE1 »… « EO3 ». {@code null} en comprehension : la priorite porte sur l'epreuve. */
        String taskCode,
        NiveauCecrl niveauTache,
        NiveauCecrl niveauEpreuve
) {
}
