package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

/**
 * Fourchette de note officielle du TCF IRN correspondant a un niveau CECRL, sur
 * les epreuves d'expression (EE/EO). Structure brute et non une phrase toute
 * faite : chaque front la formule dans son ton (« niveau B1 — au TCF, cela
 * correspond a une note de 6 a 9 sur 20 »).
 *
 * <p>Source unique : {@link com.sejourfr.app.enums.BandeNoteTcf}.
 *
 * <p>N'accompagne que le <b>bilan d'une epreuve complete</b>. Jamais le
 * resultat d'une tache isolee : au TCF la note /20 porte sur les 3 taches
 * ensemble, une tache seule n'a pas de note officielle.
 */
public record CorrespondanceTcfDto(
        NiveauCecrl niveau,
        int scoreTcfMin,
        int scoreTcfMax
) {
}
