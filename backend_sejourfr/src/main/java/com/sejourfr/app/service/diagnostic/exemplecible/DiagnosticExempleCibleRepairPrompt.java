package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;

import java.util.List;

/**
 * Message de LA SEULE tentative de reparation du bloc « avant / apres ».
 *
 * <p><b>Une reparation par bloc, tous motifs confondus</b> : numero de phrase
 * hors bornes ET longueur du texte tiennent dans le meme message. Deux appels de
 * reparation pour deux motifs seraient deux appels payes sur un bloc de confort.
 *
 * <p><b>Un extrait introuvable ne se repare pas</b> : il ne coute qu'un
 * surlignage — le segment est retire, la phrase reecrite reste servie — et payer
 * un appel pour un surlignage serait disproportionne. Une sortie structurellement
 * fausse non plus : elle est condamnee, payer ne rachetterait rien.
 *
 * <p><b>Pourquoi un message et pas la liste brute des violations.</b> Le depot a
 * mesure la difference : sur 8 preuves rejetees, un reessai ne portant que le
 * libelle de la violation en reparait <b>zero</b> (cf.
 * {@code EvaluationRepairPrompt}). On dit donc au modele ce qu'il ne peut pas
 * deviner — l'intervalle de numeros reellement disponibles, le nombre de mots
 * qu'il a REELLEMENT ecrit, celui attendu — et l'operation exacte a faire, puis on
 * lui rappelle de ne rien changer d'autre.
 *
 * <p><b>Ecrit en français ACCENTUE</b> : ce message nomme des tournures que le
 * modele va recopier dans sa sortie, et un LLM imite la langue de son prompt —
 * leçon mesuree des rubriques v13 / tool-schema v7.
 *
 * <p><b>Aucun controle n'est relache.</b> Le serveur revalide a l'identique ; si
 * la seconde sortie echoue encore, le bloc est abandonne. On ne tronque JAMAIS un
 * texte modele : une version coupee au milieu d'une phrase enseignerait une faute.
 */
final class DiagnosticExempleCibleRepairPrompt {

    private DiagnosticExempleCibleRepairPrompt() {
    }

    /**
     * @param violations  violations retenues comme reparables
     *                    ({@link DiagnosticExempleCibleValidator#toutesReparables(List)})
     * @param texteRefuse texte rendu par le modele, tel quel
     * @param nbSegments  nombre de phrases citables de la production
     * @param bornes      bornes de longueur de la tache
     */
    static String pourViolations(String userPrompt, List<String> violations, String texteRefuse,
                                 int nbSegments, ProductionTextBounds bornes) {
        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRÉCÉDENTE A ÉTÉ REJETÉE PAR LE SERVEUR.");
        sb.append("\n\nCE QU'IL A REFUSÉ :");
        for (String violation : violations) {
            sb.append("\n- ").append(violation);
        }

        if (contient(violations, DiagnosticExempleCibleValidator.VIOLATION_NUMERO)) {
            sb.append("\n\nLE NUMÉRO DE PHRASE. `segment_numero` doit être le numéro entre ")
                .append("crochets d'une phrase du candidat, telle qu'elle apparaît dans la ")
                .append("production numérotée ci-dessus. Les numéros disponibles vont de 1 à ")
                .append(nbSegments).append(", il n'y en a pas d'autre.");
            sb.append("\n\nCE QU'IL FAUT FAIRE : relis la production numérotée, et choisis le ")
                .append("numéro de la phrase où la montée vers le niveau visé se voit le mieux.");
        }

        if (contient(violations, DiagnosticExempleCibleValidator.VIOLATION_LONGUEUR)
                && bornes != null) {
            int mots = ProductionPayloadSupport.countWords(texteRefuse);
            sb.append("\n\nLA LONGUEUR. Le serveur compte les mots séparés par une espace. Tu ")
                .append("réécris UNE phrase, pas la production entière : ta version doit rester ")
                .append("proche de la longueur de la phrase d'origine, et ne peut en aucun cas ")
                .append("dépasser ").append(bornes.max()).append(" mots.");
            sb.append("\n\nTEXTE REFUSÉ :\n").append(texteRefuse);
            sb.append("\n\nCE QU'IL FAUT FAIRE : récris cette phrase en RETIRANT au moins ")
                .append(Math.max(1, mots - bornes.max()))
                .append(" mots — supprime un détail secondaire plutôt que d'abréger la fin. ")
                .append("Ne coupe PAS en cours de phrase : la version rendue doit rester ")
                .append("complète, se terminer normalement, et garder la situation, les ")
                .append("prénoms, les chiffres et l'intention du candidat.");
        }

        sb.append("\n\nNe change QUE ce qui a été refusé, reprends le reste à l'identique. ")
            .append("Rappelle l'outil ").append(DiagnosticExempleCibleFields.TOOL_NAME).append('.');
        return sb.toString();
    }

    private static boolean contient(List<String> violations, String prefixe) {
        return violations.stream().anyMatch(v -> v != null && v.startsWith(prefixe));
    }
}
