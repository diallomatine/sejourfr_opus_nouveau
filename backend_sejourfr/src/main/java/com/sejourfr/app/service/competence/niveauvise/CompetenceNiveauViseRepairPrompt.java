package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;

import java.util.List;
import java.util.Map;

/**
 * Message de la SEULE tentative de reparation d'un bloc « pour viser X ».
 * <b>Une reparation par bloc, tous motifs confondus</b> — deux appels de
 * reparation seraient deux appels payes sur un bloc de confort.
 *
 * <p>Deux defauts, et deux seulement, en ouvrent une, parce qu'ils sont
 * <b>mecaniques et nommables</b> :
 * <ul>
 *   <li>des <b>leviers</b> qui vendent un moyen deja acquis, ramenant la liste
 *       sous son minimum ;</li>
 *   <li>un <b>texte modele hors des bornes du sujet</b> — le candidat est invite
 *       a rejouer l'exercice avec ce modele sous les yeux, un modele trop long
 *       n'est plus « sa » reponse.</li>
 * </ul>
 * Quand les deux se presentent, ils partent dans le MEME message : on ne double
 * pas les appels.
 *
 * <p><b>Ce qui n'en ouvre PAS.</b> Un extrait de surlignage introuvable
 * (2026-08-12) et un <b>marqueur de palier</b> retire ne coutent que leur propre
 * mise en evidence — le texte modele reste servi, payer un appel pour cela serait
 * disproportionne. Une sortie structurellement fausse non plus : le bloc reste un
 * confort.
 *
 * <p><b>Pourquoi un message et pas la liste brute des violations.</b> Le depot a
 * mesure la difference : sur 8 preuves rejetees, un reessai ne portant que le
 * libelle de la violation en reparait <b>zero</b> (cf.
 * {@code EvaluationRepairPrompt}). On dit donc au modele ce qu'il ne peut pas
 * deviner — ce qui a ete refuse et l'operation exacte a faire — et on lui rappelle
 * de ne rien changer d'autre.
 *
 * <p><b>Aucun controle n'est relache.</b> Le serveur revalide a l'identique ; si
 * la seconde sortie echoue encore, la section fautive est abandonnee — les
 * leviers emportent le bloc, l'exemple cible tombe seul.
 */
final class CompetenceNiveauViseRepairPrompt {

    private CompetenceNiveauViseRepairPrompt() {
    }

    /**
     * LE message de reparation, ou {@code null} quand rien n'est reparable.
     *
     * <p>Ecrit en français ACCENTUE : il nomme des tournures que le modele va
     * recopier dans sa sortie (« bien que », « c'est pourquoi », « a condition
     * que »), et un LLM imite la langue de son prompt — leçon mesuree des
     * rubriques v13 / tool-schema v7.
     *
     * @param leviersRefuses leviers retires par le filet, cites tels quels
     * @param leviersGardes  leviers conserves, a reprendre a l'identique
     * @param palierCible    palier que le bloc doit reellement faire atteindre
     * @param texteRefuse    texte modele rendu, quand c'est lui qui est hors bornes
     * @param bornes         bornes du sujet, {@code null} quand il n'en declare pas
     */
    static String pour(String userPrompt, List<Map<String, Object>> leviersRefuses,
                       List<Map<String, Object>> leviersGardes, TargetLevel palierCible,
                       String texteRefuse, ProductionTextBounds bornes) {
        boolean leviers = leviersRefuses != null && !leviersRefuses.isEmpty();
        boolean longueur = texteRefuse != null && bornes != null;
        if (!leviers && !longueur) return null;

        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRÉCÉDENTE A ÉTÉ REFUSÉE PAR LE SERVEUR.");
        if (leviers) appendLeviers(sb, leviersRefuses, leviersGardes, palierCible);
        if (longueur) appendLongueur(sb, texteRefuse, bornes);

        sb.append("\n\nNe change QUE ce qui est demandé ci-dessus : reprends le reste de ta ")
            .append("sortie à l'identique. Rappelle l'outil ")
            .append(CompetenceNiveauViseFields.TOOL_NAME).append('.');
        return sb.toString();
    }

    /** Leviers qui vendent un moyen deja acquis au palier cible. */
    private static void appendLeviers(StringBuilder sb, List<Map<String, Object>> refuses,
                                      List<Map<String, Object>> gardes, TargetLevel palierCible) {
        sb.append("\n\nLES LEVIERS. ")
            .append(refuses.size() == 1 ? "Un levier désignait" : "Des leviers désignaient")
            .append(", comme moyen d'atteindre le niveau ").append(palierCible.name())
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

        if (gardes != null && !gardes.isEmpty()) {
            sb.append("\n\nLEVIER(S) À REPRENDRE À L'IDENTIQUE :");
            for (Map<String, Object> garde : gardes) {
                sb.append("\n- ").append(CompetenceNiveauViseLevierFilter.libelle(garde));
            }
        }
    }

    /**
     * Texte modele hors des bornes du sujet. Le message dit le compte obtenu, les
     * bornes attendues et le nombre exact de mots a retirer : c'est ce qui le rend
     * actionnable, par opposition au libelle brut de la violation.
     */
    private static void appendLongueur(StringBuilder sb, String texteRefuse,
                                       ProductionTextBounds bornes) {
        int mots = ProductionPayloadSupport.countWords(texteRefuse);
        sb.append("\n\nLA LONGUEUR DE `exemple_cible.texte`. Ta version fait ").append(mots)
            .append(" mots ; ce sujet en attend ").append(bornes.libelle())
            .append(". Le serveur compte les mots séparés par une espace, la ponctuation faisant ")
            .append("partie du mot qui la précède.");
        sb.append("\n\nTEXTE REFUSÉ :\n").append(texteRefuse);
        sb.append("\n\nCE QU'IL FAUT FAIRE : récris ce texte en RETIRANT au moins ")
            .append(Math.max(1, mots - bornes.max()))
            .append(" mots — supprime un détail secondaire ou fusionne deux phrases. Ne coupe ")
            .append("PAS le texte en cours de phrase : la version rendue doit rester complète, ")
            .append("se terminer normalement, et garder la situation, les prénoms, les chiffres ")
            .append("et l'intention du candidat. Garde aussi les procédés qui démontrent le ")
            .append("palier, et remets à jour `marqueurs_du_palier` si un passage a bougé.");
    }
}
