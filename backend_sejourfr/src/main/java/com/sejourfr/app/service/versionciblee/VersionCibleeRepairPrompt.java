package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;

import java.util.List;
import java.util.Map;

/**
 * Messages de LA SEULE tentative de reparation d'un bloc « version au niveau
 * vise ». <b>Une reparation par bloc, tous motifs confondus</b> : longueur du
 * texte modele, extrait introuvable, numero de segment hors bornes, leviers
 * refuses, reformulations retirees. Deux appels de reparation pour deux motifs
 * seraient deux appels payes sur un bloc de confort.
 *
 * <p><b>Pourquoi un message et pas la liste brute des violations.</b> Le depot a
 * mesure la difference : sur 8 preuves rejetees, un reessai ne portant que le
 * libelle de la violation en reparait <b>zero</b> (cf.
 * {@code EvaluationRepairPrompt}). On dit donc au modele ce qu'il ne peut pas
 * deviner — le nombre de mots qu'il a REELLEMENT ecrit, celui attendu, l'extrait
 * exact qui a ete cherche, l'intervalle de numeros valides, le levier refuse — et
 * l'operation exacte a faire, puis on lui rappelle de ne rien changer d'autre.
 *
 * <p><b>Ecrit en français ACCENTUE.</b> Ces messages nomment des tournures que le
 * modele va recopier dans sa sortie (« bien que », « c'est pourquoi »,
 * « a condition que »), et un LLM imite la langue de son prompt — leçon mesuree
 * des rubriques v13 / tool-schema v7.
 *
 * <p><b>Aucun controle n'est relache.</b> Le serveur revalide a l'identique ; si
 * la seconde sortie echoue encore, la SECTION fautive est abandonnee — le bloc
 * entier seulement quand ce sont les leviers qui tombent. On ne tronque JAMAIS un
 * texte modele et on ne « rattrape » jamais un extrait a la main : une version
 * coupee au milieu d'une phrase enseignerait une faute, et un surlignage
 * approximatif afficherait un passage que le modele n'a pas ecrit.
 */
final class VersionCibleeRepairPrompt {

    private VersionCibleeRepairPrompt() {
    }

    /**
     * Reparation des violations MECANIQUES, toutes familles confondues.
     *
     * @param violations violations retenues comme reparables
     *                   ({@link VersionCibleeValidator#uniquementReparables(List)})
     * @param texteRefuse texte modele rendu, vide a l'oral (il n'y en a pas)
     * @param bornes      bornes de la tache, null a l'oral
     */
    static String pourViolations(String userPrompt, List<String> violations, String texteRefuse,
                                 ProductionTextBounds bornes) {
        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRÉCÉDENTE A ÉTÉ REJETÉE PAR LE SERVEUR.");
        sb.append("\n\nCE QU'IL A REFUSÉ :");
        for (String violation : violations) {
            sb.append("\n- ").append(violation);
        }

        boolean longueur = contient(violations, VersionCibleeValidator.VIOLATION_LONGUEUR);
        boolean extrait = contient(violations, VersionCibleeValidator.VIOLATION_EXTRAIT);
        boolean segment = contient(violations, VersionCibleeValidator.VIOLATION_SEGMENT);

        if (longueur && bornes != null) {
            int mots = ProductionPayloadSupport.countWords(texteRefuse);
            sb.append("\n\nLA LONGUEUR. Le serveur compte les mots séparés par une espace, ")
                .append("ponctuation comprise dans le mot qui la précède. Le candidat lui-même ne ")
                .append("peut pas soumettre un texte hors de ces bornes : un modèle hors bornes ")
                .append("serait donc irrecevable sur la plateforme où il s'affiche.");
            sb.append("\n\nTEXTE REFUSÉ :\n").append(texteRefuse);
            if (mots > bornes.max()) {
                sb.append("\n\nCE QU'IL FAUT FAIRE : récris ce texte en RETIRANT au moins ")
                    .append(mots - bornes.max())
                    .append(" mots — supprime un détail secondaire ou fusionne deux phrases. ")
                    .append("Ne coupe PAS le texte en cours de phrase : la version rendue doit ")
                    .append("rester complète, se terminer normalement, et garder la situation, ")
                    .append("les prénoms, les chiffres et la position du candidat.");
            } else {
                sb.append("\n\nCE QU'IL FAUT FAIRE : récris ce texte en AJOUTANT au moins ")
                    .append(bornes.min() - mots)
                    .append(" mots — développe une idée déjà présente chez le candidat plutôt ")
                    .append("que d'inventer un fait nouveau : aucune information absente de sa ")
                    .append("production ne doit apparaître.");
            }
        }

        if (extrait) {
            sb.append("\n\nLES EXTRAITS. Le serveur cherche chaque `segments[].extrait` dans ")
                .append("`exemple_cible.texte`, caractère pour caractère — mêmes mots, mêmes ")
                .append("accents, mêmes espaces, même ponctuation, même apostrophe. Il ne ")
                .append("rattrape rien : une reformulation, un raccourci par points de ")
                .append("suspension, ou deux morceaux éloignés recollés sont introuvables, donc ")
                .append("refusés. Le front SURLIGNE ces passages dans le texte ; un extrait ")
                .append("absent ne se surligne pas.");
            sb.append("\n\nCE QU'IL FAUT FAIRE : choisis des extraits COURTS et CONTIGUS, que tu ")
                .append("recopies depuis ton propre texte par simple copie.");
        }

        if (segment) {
            sb.append("\n\nLES NUMÉROS DE PASSAGE. Chaque `segment_numero` doit être le numéro ")
                .append("entre crochets d'un passage du CANDIDAT, tel qu'il apparaît dans la ")
                .append("transcription numérotée ci-dessus. Les tours de l'examinateur n'ont pas ")
                .append("de numéro et ne se reformulent pas. Deux reformulations ne peuvent pas ")
                .append("désigner le même passage.");
            sb.append("\n\nCE QU'IL FAUT FAIRE : reprends la transcription numérotée, relis les ")
                .append("numéros disponibles, et choisis-en deux ou trois différents.");
        }

        sb.append("\n\nNe change QUE ce qui a été refusé, reprends le reste à l'identique. ")
            .append("Rappelle l'outil ").append(VersionCibleeFields.TOOL_NAME).append('.');
        return sb.toString();
    }

    /**
     * Reparation des PURGES : leviers qui vendent un moyen deja acquis, et/ou
     * reformulations qui ne changent que la forme d'un mot. Les deux tiennent
     * dans le MEME message — une seule reparation par bloc.
     *
     * @param leviersRefuses     leviers retires par le filet, cites tels quels
     * @param leviersGardes      leviers conserves, a reprendre a l'identique
     * @param reformulationsRefusees reformulations retirees par le filet oral
     * @param vise               palier vise, celui que le levier pretendait faire
     *                           atteindre
     */
    static String pourPurges(String userPrompt, List<Object> leviersRefuses,
                             List<Object> leviersGardes,
                             List<Map<String, Object>> reformulationsRefusees,
                             TargetLevel vise) {
        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRÉCÉDENTE A ÉTÉ REFUSÉE PAR LE SERVEUR.");

        if (!leviersRefuses.isEmpty()) {
            sb.append("\n\n").append(leviersRefuses.size() == 1 ? "Un levier désignait"
                    : "Des leviers désignaient")
                .append(", comme moyen d'atteindre le niveau ").append(vise.name())
                .append(", un mot que ce niveau suppose DÉJÀ acquis.");
            sb.append("\n\nLEVIER(S) REFUSÉ(S) :");
            for (Object refuse : leviersRefuses) {
                sb.append("\n- ").append(VersionCibleeLevierFilter.libelle(refuse));
            }
            sb.append("\n\nPOURQUOI : « et », « mais », « alors », « après », « aussi » et ")
                .append("« parce que » sont des moyens attendus dès le niveau A2. Un candidat qui ")
                .append("les emploie déjà ne change pas de palier en les employant davantage. Ce ")
                .append("n'est pas théorique : un candidat a suivi un conseil de ce genre, a ")
                .append("réécrit sa réponse, et a obtenu exactement la même évaluation.");
            sb.append("\n\nCE QU'IL FAUT FAIRE : remplace chaque levier refusé par un moyen que ")
                .append("le niveau A2 n'a pas — subordonner (« bien que », « alors que », « ce ")
                .append("qui »), organiser le propos (« d'abord », « en revanche », « c'est ")
                .append("pourquoi »), nuancer ou traiter une objection (« à condition que », ")
                .append("« même si »), remplacer un mot passe-partout par un terme précis.");
            if (!leviersGardes.isEmpty()) {
                sb.append("\n\nLEVIER(S) À REPRENDRE À L'IDENTIQUE :");
                for (Object garde : leviersGardes) {
                    sb.append("\n- ").append(VersionCibleeLevierFilter.libelle(garde));
                }
            }
        }

        if (!reformulationsRefusees.isEmpty()) {
            sb.append("\n\n").append(reformulationsRefusees.size() == 1
                    ? "Une reformulation ne changeait" : "Des reformulations ne changeaient")
                .append(" que la FORME d'un ou deux mots.");
            sb.append("\n\nREFORMULATION(S) REFUSÉE(S) :");
            for (Map<String, Object> refusee : reformulationsRefusees) {
                sb.append("\n- ").append(VersionCibleeReformulationFilter.libelle(refusee));
            }
            sb.append("\n\nPOURQUOI : ce que tu lis est une TRANSCRIPTION AUTOMATIQUE. Un mot ")
                .append("qui te paraît étrange vient presque toujours de notre machine, pas du ")
                .append("candidat — il a pu dire « j'habite » là où la transcription porte ")
                .append("« abit ». Corriger ce mot, c'est lui reprocher notre propre erreur.");
            sb.append("\n\nCE QU'IL FAUT FAIRE : choisis des passages où c'est la CONSTRUCTION ")
                .append("de la phrase qui peut monter — subordonner au lieu de juxtaposer, ")
                .append("annoncer une objection, nuancer, organiser le propos, construire une ")
                .append("question. Garde son intention, ses faits et une longueur du même ordre.");
        }

        sb.append("\n\nNe change QUE ce qui a été refusé, reprends le reste à l'identique. ")
            .append("Rappelle l'outil ").append(VersionCibleeFields.TOOL_NAME).append('.');
        return sb.toString();
    }

    private static boolean contient(List<String> violations, String prefixe) {
        return violations.stream().anyMatch(v -> v != null && v.startsWith(prefixe));
    }
}
