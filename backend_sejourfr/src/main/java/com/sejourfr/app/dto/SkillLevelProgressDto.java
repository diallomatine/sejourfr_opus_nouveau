package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SituationNiveauVise;
import com.sejourfr.app.enums.TargetLevel;

import java.util.List;

/**
 * Ou en est le candidat par rapport a son objectif, apres une micro-production.
 *
 * <p><b>Tout est DERIVE SERVEUR</b> (cf. {@code SkillLevelProgressResolver}) :
 * la situation, son libelle, l'echelle de la jauge et la position du curseur. Un
 * front n'a rien a calculer et surtout rien a supposer — ni l'ordre des paliers,
 * ni la regle « la demarche fait plancher », ni la façon de ramener un niveau
 * en dessous du premier cran. Cette table de correspondance a deja existe en six
 * copies divergentes dans le depot.
 *
 * @param levelReached  le niveau demontre par CETTE production (jamais C1/C2 :
 *                      profil TCF IRN)
 * @param targetLevel   le palier vise, {@link TargetLevel} — plancher pose par la
 *                      demarche du candidat
 * @param situation     ou il en est par rapport a l'objectif
 * @param situationLabel libelle FR pret a afficher, gele cote serveur
 * @param scale         les TROIS crans de la jauge, du plus bas au plus haut, le
 *                      dernier etant toujours le niveau vise
 * @param cursorIndex   index du niveau demontre DANS {@code scale} (0..2) ; un
 *                      niveau sous le premier cran est ramene a 0, un niveau
 *                      au-dessus du dernier a 2
 */
public record SkillLevelProgressDto(
        NiveauCecrl levelReached,
        TargetLevel targetLevel,
        SituationNiveauVise situation,
        String situationLabel,
        List<NiveauCecrl> scale,
        int cursorIndex
) {
}
