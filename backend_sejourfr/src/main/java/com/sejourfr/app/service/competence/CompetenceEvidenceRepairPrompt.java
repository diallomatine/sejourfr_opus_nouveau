package com.sejourfr.app.service.competence;

import com.sejourfr.app.service.EvaluationProductionSegments;

import java.util.List;

/**
 * Bloc ACTIONNABLE du reessai unique, quand la preuve du niveau n'a pas ete
 * retenue.
 *
 * <p><b>Pourquoi ce n'est pas la simple liste des violations.</b> Le depot l'a
 * mesure sur les productions completes : renvoyer au correcteur le seul libelle
 * brut de sa violation reparait <b>zero cas sur huit</b> — de son point de vue,
 * il avait deja repondu correctement, alors il resoumet la meme chose. Un
 * message de reessai ne vaut que s'il nomme ce qui a ete refuse, rappelle les
 * bornes REELLES et redonne la sortie sure. Meme technique que
 * {@code EvaluationRepairPrompt} et {@code VersionCibleeRepairPrompt}.
 *
 * <p><b>Aucun controle n'est relache ici.</b> Le serveur verifie exactement la
 * meme chose apres comme avant : on explique comment satisfaire une regle
 * inchangee. Et si le correcteur echoue quand meme, l'analyse n'est pas perdue —
 * le niveau est simplement abaisse d'un palier
 * ({@link CompetenceLevelEvidenceGuard}).
 */
final class CompetenceEvidenceRepairPrompt {

    private CompetenceEvidenceRepairPrompt() {
    }

    /**
     * @param preuvePartout contrat v5 : la preuve est attendue a TOUS les
     *                      paliers, donc la sortie sure « annonce plus bas »
     *                      s'accompagne elle aussi d'un numero. Sous v4 elle
     *                      s'accompagne d'une omission — le message doit dire
     *                      la verite du contrat charge, sinon il enseigne une
     *                      violation.
     */
    static void append(StringBuilder sb, List<String> violationsDePreuve,
                       EvaluationProductionSegments segments, boolean preuvePartout) {
        if (violationsDePreuve == null || violationsDePreuve.isEmpty()) return;
        int taille = segments == null ? 0 : segments.taille();

        sb.append("\n\nPREUVE DU NIVEAU REFUSEE — voici exactement ce que le serveur a rejete :");
        for (String violation : violationsDePreuve) {
            sb.append("\n- ").append(violation);
        }

        sb.append("\n\nREGLE DE `level_evidence` (le serveur la verifie, elle ne bouge pas) :")
            .append("\n- ce n'est PAS une citation : c'est le NUMERO, entre crochets, d'un ")
            .append("segment de la production affichee plus haut ;")
            .append("\n- les numeros disponibles vont de 1 a ").append(taille)
            .append(" — aucun autre entier n'existe pour cette production, et 0 n'existe pas ;")
            .append("\n- a l'oral, seuls les tours « Candidat : » portent un numero : les tours ")
            .append("de l'examinateur ne sont pas designables ;")
            .append("\n- relis les segments et choisis celui qui porte VRAIMENT le marqueur du ")
            .append("palier que tu annonces : pour le B2 une idee developpee ou une objection ")
            .append("traitee, pour le B1 une subordonnee et un enchainement.")
            .append("\n\nDEUX SORTIES SURES, choisis celle qui est vraie :")
            .append("\n1. un segment porte ce marqueur -> garde ton niveau et donne SON numero ;")
            .append(preuvePartout
                ? "\n2. aucun segment ne le porte -> annonce le palier INFERIEUR et donne le "
                    + "numero du segment qui fonde CE palier-la (aucun palier n'est dispense "
                    + "de designation, pas meme A1_NON_ATTEINT)."
                : "\n2. aucun segment ne le porte -> annonce le palier INFERIEUR et OMETS "
                    + "`level_evidence` (A2, A1 et A1_NON_ATTEINT n'ont rien a demontrer).")
            .append("\nReprends tes autres champs a l'identique : ne change QUE ce qui est signale.");
    }
}
