package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;

import java.util.List;
import java.util.Map;

/**
 * Construit le message du REESSAI unique envoye au correcteur quand sa sortie a
 * ete rejetee par le serveur.
 *
 * <p><b>Pourquoi ce n'est pas qu'une liste de violations.</b> Mesure du
 * diagnostic : sur 8 preuves rejetees, le reessai en reparait <b>zero</b>. Le
 * message ne portait que le libelle brut de la violation
 * ({@code preuve[lexique] doit citer un passage reel de la production}), sans
 * dire QUELLE citation avait ete refusee, ni POURQUOI, ni la regle a respecter.
 * Du point de vue du modele, sa citation etait deja reelle : il la resoumettait
 * mot pour mot.
 *
 * <p><b>Ce message ne relache aucun controle.</b> Il n'ajoute aucune tolerance
 * cote serveur : il explique au correcteur comment satisfaire un controle
 * inchange, et lui suggere la sortie la plus sure — re-citer PLUS COURT. C'est
 * la voie qui renforce la garantie « une preuve inventee ou ambigue ne passe
 * pas », au lieu de la diluer.
 */
final class EvaluationRepairPrompt {

    private EvaluationRepairPrompt() {
    }

    static String build(String userPrompt, List<String> violations,
                        Map<String, Object> feedback, EpreuveType epreuve) {
        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRECEDENTE A ETE REJETEE PAR LE SERVEUR. ")
            .append("Corrige exactement ces violations et rappelle l'outil submit_evaluation :\n- ")
            .append(String.join("\n- ", violations));

        List<String> codes = EvaluationOutputValidator.unmatchedProofCodes(violations);
        if (codes.isEmpty()) return sb.toString();

        sb.append("\n\nCITATIONS REFUSEES — le serveur ne les a PAS retrouvees dans la ")
            .append("production, telles que tu les as ecrites :");
        for (String code : codes) {
            sb.append("\n- critere ").append(code).append(" : ")
                .append(citationRefusee(feedback, code));
        }

        sb.append("\n\nREGLE DE LA PREUVE (le serveur la verifie caractere par caractere) :")
            .append("\n- une preuve est UN SEUL passage CONTIGU de la production, recopie TEL ")
            .append("QU'IL APPARAIT : memes mots, meme ordre, meme ponctuation, et meme les ")
            .append("hesitations telles qu'elles sont ecrites ;")
            .append("\n- INTERDIT : les points de suspension « ... » pour sauter un morceau, la ")
            .append("recomposition de deux fragments eloignes, la reformulation, la correction ")
            .append("d'une faute, le changement d'un mot, d'un nombre ou d'une negation ;");
        if (epreuve == EpreuveType.TCF_EO) {
            sb.append("\n- ce dialogue est ORAL : la citation doit tenir dans UN SEUL tour ")
                .append("« Candidat : ». Ne cite jamais l'examinateur, ne colle jamais deux ")
                .append("tours bout a bout ;");
        }
        sb.append("\n- RE-CITE PLUS COURT : un passage bref et exact (3 a 6 mots) vaut mieux ")
            .append("qu'un passage long reconstitue. Choisis une suite de mots que tu peux ")
            .append("relire lettre a lettre dans la production ci-dessus, puis recopie-la.")
            .append("\nReprends tes autres champs a l'identique : ne change QUE ce qui est signale.");
        return sb.toString();
    }

    /** Citation telle que le correcteur l'avait rendue, ou une mention explicite. */
    private static String citationRefusee(Map<String, Object> feedback, String code) {
        if (feedback != null && feedback.get("scores_criteres") instanceof List<?> scores) {
            for (Object score : scores) {
                if (!(score instanceof Map<?, ?> m) || !code.equals(String.valueOf(m.get("code")))) {
                    continue;
                }
                Object preuve = m.get("preuve");
                if (preuve != null && !preuve.toString().isBlank()) {
                    return "tu as cite « " + preuve + " » — introuvable telle quelle.";
                }
            }
        }
        return "une preuve absente ou vide.";
    }
}
