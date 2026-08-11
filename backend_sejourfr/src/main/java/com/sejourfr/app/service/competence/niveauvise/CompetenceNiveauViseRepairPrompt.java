package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;

import java.util.List;
import java.util.Map;

/**
 * Message de la SEULE tentative de reparation d'un bloc « pour viser X » : des
 * leviers refuses parce qu'ils vendent un moyen deja acquis. <b>Une reparation
 * par bloc, tous motifs confondus</b> — deux appels de reparation seraient deux
 * appels payes sur un bloc de confort.
 *
 * <p><b>Un extrait introuvable ne se repare plus</b> (2026-08-12, alignement sur
 * les productions) : il ne coute plus qu'un surlignage — le segment est retire, le
 * texte modele reste servi ({@link com.sejourfr.app.util.SegmentsSurlignage}) — et
 * payer un appel pour un surlignage serait disproportionne.
 *
 * <p><b>Pourquoi un message et pas la liste brute des violations.</b> Le depot a
 * mesure la difference : sur 8 preuves rejetees, un reessai ne portant que le
 * libelle de la violation en reparait <b>zero</b> (cf.
 * {@code EvaluationRepairPrompt}). On dit donc au modele ce qu'il ne peut pas
 * deviner — ce qui a ete refuse et l'operation exacte a faire — et on lui rappelle
 * de ne rien changer d'autre.
 *
 * <p><b>Aucun controle n'est relache.</b> Le serveur revalide a l'identique ; si
 * la seconde sortie echoue encore, le bloc est abandonne. On ne « rattrape »
 * jamais un extrait en le rapprochant du texte a la main : un surlignage
 * approximatif afficherait au candidat un passage que le modele n'a pas ecrit.
 */
final class CompetenceNiveauViseRepairPrompt {

    private CompetenceNiveauViseRepairPrompt() {
    }

    /**
     * Reparation des LEVIERS qui vendent un moyen deja acquis au niveau vise.
     *
     * <p>Ecrit en français ACCENTUE : il nomme des tournures que le modele va
     * recopier dans sa sortie (« bien que », « c'est pourquoi », « a condition
     * que »), et un LLM imite la langue de son prompt — leçon mesuree des
     * rubriques v13 / tool-schema v7.
     *
     * @param refuses leviers retires par le filet, cites tels quels
     * @param gardes  leviers conserves, a reprendre a l'identique
     * @param vise    palier vise, celui que le levier pretendait faire atteindre
     */
    static String pourLeviers(String userPrompt, List<Map<String, Object>> refuses,
                              List<Map<String, Object>> gardes, TargetLevel vise) {
        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRÉCÉDENTE A ÉTÉ REFUSÉE PAR LE SERVEUR : ")
            .append(refuses.size() == 1 ? "un levier désignait" : "des leviers désignaient")
            .append(", comme moyen d'atteindre le niveau ").append(vise.name())
            .append(", un mot que ce niveau suppose DÉJÀ acquis.");

        sb.append("\n\nLEVIER(S) REFUSÉ(S) :");
        for (Map<String, Object> refuse : refuses) {
            sb.append("\n- ").append(CompetenceNiveauViseLevierFilter.libelle(refuse));
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
            .append("remplacer un mot passe-partout par un terme précis. `action` reste à ")
            .append("l'impératif en six mots au plus, `exemple` reste un bout de langue ")
            .append("recopiable en cinq mots au plus.");

        if (!gardes.isEmpty()) {
            sb.append("\n\nLEVIER(S) À REPRENDRE À L'IDENTIQUE :");
            for (Map<String, Object> garde : gardes) {
                sb.append("\n- ").append(CompetenceNiveauViseLevierFilter.libelle(garde));
            }
        }

        sb.append("\n\nReprends `exemple_cible` et `a_retenir` à l'identique : ne change QUE les ")
            .append("leviers refusés. Rappelle l'outil ")
            .append(CompetenceNiveauViseFields.TOOL_NAME).append('.');
        return sb.toString();
    }
}
