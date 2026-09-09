package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * <b>Ce qui a bouge depuis le diagnostic precedent</b> — la moitie manquante de
 * la boucle de reevaluation (10_ §4.6, 30_ §7 bloc 2).
 *
 * <p>Une reevaluation qui rendrait un palier sans le <b>comparer</b> ne
 * mesurerait rien : c'est pourtant tout ce qu'on vend au candidat qui la paye.
 *
 * <p>🛑 <b>Comparaison, pas verdict.</b> Le serveur dit d'ou a ou ; « Vous avez
 * progresse ! » appartient aux fronts. Et une epreuve non evaluee d'un cote
 * rend {@code INCONNUE}, jamais {@code STABLE}.
 *
 * <p>🛑 <b>Derive a la lecture, jamais persiste.</b> Aucune table d'historique
 * de niveaux : les deux diagnostics existent, la comparaison se refait.
 *
 * @param previousSessionId   le diagnostic auquel on compare
 * @param previousCompletedAt sa date de cloture
 * @param previousNiveauGlobal son palier global ; {@code null} = non evalue
 * @param niveauGlobal        l'evolution du palier global
 * @param epreuves            les 4 epreuves, dans l'ordre d'affichage
 */
public record TcfDiagnosticProgressionDto(
        UUID previousSessionId,
        Instant previousCompletedAt,
        NiveauCecrl previousNiveauGlobal,
        NiveauEvolution niveauGlobal,
        List<EpreuveEvolution> epreuves
) {
    /**
     * L'evolution d'une epreuve. {@code avant} et {@code apres} peuvent etre
     * nuls independamment — non evaluee alors, non evaluee maintenant, ou les
     * deux.
     */
    public record EpreuveEvolution(
            EpreuveType epreuve,
            NiveauCecrl avant,
            NiveauCecrl apres,
            NiveauEvolution evolution) {
    }
}
