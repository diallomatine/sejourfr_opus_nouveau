package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;

import java.util.List;

/**
 * Messages de la SEULE tentative de reparation d'un bloc « version au niveau
 * vise » : longueur du texte modele hors bornes, ou leviers refuses parce qu'ils
 * vendent un moyen deja acquis.
 *
 * <p><b>Pourquoi un message et pas la liste brute des violations.</b> Le depot a
 * mesure la difference : sur 8 preuves rejetees, un reessai ne portant que le
 * libelle de la violation en reparait <b>zero</b> (cf.
 * {@code EvaluationRepairPrompt}). On dit donc au modele ce qu'il ne peut pas
 * deviner — le nombre de mots qu'il a REELLEMENT ecrit, celui attendu, la façon
 * dont on compte, et l'operation exacte a faire (couper ou etoffer) — et on lui
 * rappelle de ne rien changer d'autre.
 *
 * <p><b>Aucun controle n'est relache.</b> Le serveur revalide avec exactement les
 * memes bornes ; si la seconde sortie est encore hors bornes, le bloc est
 * abandonne. On ne tronque JAMAIS le texte au mot pres : une version coupee au
 * milieu d'une phrase enseignerait une faute, et l'absence du bloc est un cas que
 * les fronts traitent deja proprement.
 */
final class VersionCibleeRepairPrompt {

    private VersionCibleeRepairPrompt() {
    }

    /** Reparation de la LONGUEUR du texte modele. */
    static String pourLongueur(String userPrompt, String texteRefuse, ProductionTextBounds bornes) {
        int mots = ProductionPayloadSupport.countWords(texteRefuse);
        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRECEDENTE A ETE REJETEE PAR LE SERVEUR : le champ `texte` fait ")
            .append(mots).append(" mots, alors que cette tache en attend ")
            .append(bornes.libelle()).append('.');
        sb.append("\n\nCE QUE LE SERVEUR COMPTE : les mots separes par une espace, ponctuation ")
            .append("comprise dans le mot qui la precede. Le candidat lui-meme ne peut pas ")
            .append("soumettre un texte hors de ces bornes : un modele hors bornes serait donc ")
            .append("irrecevable sur la plateforme ou il s'affiche.");
        sb.append("\n\nTEXTE REFUSE :\n").append(texteRefuse);
        if (mots > bornes.max()) {
            sb.append("\n\nCE QU'IL FAUT FAIRE : recris ce texte en RETIRANT au moins ")
                .append(mots - bornes.max())
                .append(" mots — supprime un detail secondaire ou fusionne deux phrases. ")
                .append("Ne coupe PAS le texte en cours de phrase : la version rendue doit ")
                .append("rester complete, se terminer normalement, et garder la situation, les ")
                .append("prenoms, les chiffres et la position du candidat.");
        } else {
            sb.append("\n\nCE QU'IL FAUT FAIRE : recris ce texte en AJOUTANT au moins ")
                .append(bornes.min() - mots)
                .append(" mots — developpe une idee deja presente chez le candidat plutot que ")
                .append("d'inventer un fait nouveau : aucune information absente de sa ")
                .append("production ne doit apparaitre.");
        }
        sb.append("\n\nReprends `ce_qui_manque` a l'identique : ne change QUE la longueur du ")
            .append("texte. Rappelle l'outil ").append(VersionCibleeFields.TOOL_NAME).append('.');
        return sb.toString();
    }

    /**
     * Reparation des LEVIERS qui vendent un moyen deja acquis au niveau vise.
     *
     * <p><b>Ecrit en français ACCENTUE</b>, contrairement au message de longueur
     * ci-dessus : celui-ci nomme des tournures que le modele va recopier dans sa
     * sortie (« bien que », « c'est pourquoi », « a condition que »), et un LLM
     * imite la langue de son prompt — c'est la leçon mesuree des rubriques
     * v13 / tool-schema v7 (ratio d'accents 0,0002 sur 96 k lettres cote prompts,
     * accents manquants cote sorties).
     *
     * <p>Le message NOMME le levier refuse et donne l'operation exacte a faire,
     * jamais le seul libelle de la violation : le depot a mesure qu'un reessai
     * non actionnable reparait <b>zero</b> cas sur huit.
     *
     * @param refuses leviers retires par le filet, cites tels quels
     * @param gardes  leviers conserves, a reprendre a l'identique
     * @param vise    palier vise, celui que le levier pretendait faire atteindre
     */
    static String pourLeviers(String userPrompt, List<String> refuses, List<String> gardes,
                              TargetLevel vise) {
        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRÉCÉDENTE A ÉTÉ REFUSÉE PAR LE SERVEUR : ")
            .append(refuses.size() == 1 ? "un levier désignait" : "des leviers désignaient")
            .append(", comme moyen d'atteindre le niveau ").append(vise.name())
            .append(", un mot que ce niveau suppose DÉJÀ acquis.");

        sb.append("\n\nLEVIER(S) REFUSÉ(S) :");
        for (String refuse : refuses) {
            sb.append("\n- ").append(refuse);
        }

        sb.append("\n\nPOURQUOI : « et », « mais », « alors », « après », « aussi » et ")
            .append("« parce que » sont des moyens attendus dès le niveau A2. Un candidat qui ")
            .append("les emploie déjà ne change pas de palier en les employant davantage. Ce ")
            .append("n'est pas théorique : un candidat a suivi un conseil de ce genre, a ")
            .append("réécrit sa réponse, et a obtenu exactement la même évaluation.");

        sb.append("\n\nCE QU'IL FAUT FAIRE : remplace chaque levier refusé par un moyen que le ")
            .append("niveau A2 n'a pas — subordonner (« bien que », « alors que », « ce qui »), ")
            .append("organiser le propos (« d'abord », « en revanche », « c'est pourquoi »), ")
            .append("nuancer ou traiter une objection (« à condition que », « même si »), ")
            .append("remplacer un mot passe-partout par un terme précis. Chaque levier reste ")
            .append("une seule phrase, commence par un verbe d'action et s'appuie sur la ")
            .append("situation du candidat.");

        if (!gardes.isEmpty()) {
            sb.append("\n\nLEVIER(S) À REPRENDRE À L'IDENTIQUE :");
            for (String garde : gardes) {
                sb.append("\n- ").append(garde);
            }
        }

        sb.append("\n\nReprends `texte` à l'identique : ne change QUE les leviers refusés. ")
            .append("Rappelle l'outil ").append(VersionCibleeFields.TOOL_NAME).append('.');
        return sb.toString();
    }
}
