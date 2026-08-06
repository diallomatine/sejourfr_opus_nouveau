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

        appendGardeFouOral(sb, violations);

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

    /**
     * GARDE-FOU ORAL. Meme diagnostic que pour les preuves : le message ne
     * portait que le libelle brut ({@code exemples_corriges.explication fonde le
     * feedback oral sur un element non evaluable}), sans dire quel passage ni
     * quelle notion. Mesure du 2026-08-06 sur une tache d'examen blanc EO :
     * <b>zero violation reparee</b> sur deux, le correcteur resoumettant les
     * memes explications — la tache a ete perdue.
     *
     * <p><b>Aucun controle n'est relache</b> : le serveur rejette exactement les
     * memes notions. On dit au correcteur ce qu'il ne pouvait pas deviner, et on
     * lui donne la sortie sure — supprimer la remarque, ou la ramener sur ce qui
     * est observable dans une transcription.
     */
    private static void appendGardeFouOral(StringBuilder sb, List<String> violations) {
        List<String> orales = EvaluationOutputValidator.oralViolations(violations);
        if (orales.isEmpty()) return;

        sb.append("\n\nELEMENTS NON EVALUABLES A L'ORAL — le serveur a rejete ces passages ")
            .append("de ta sortie :");
        for (String violation : orales) {
            sb.append("\n- ").append(violation);
        }
        sb.append("\n\nREGLE DU GARDE-FOU ORAL (le serveur la verifie sur chaque champ ")
            .append("evaluatif) :")
            .append("\n- tu ne disposes que d'une TRANSCRIPTION AUTOMATIQUE : tu n'as jamais ")
            .append("entendu le candidat, tu ne peux donc rien conclure de sa facon de parler ;")
            .append("\n- INTERDIT partout (verdict, commentaires, conseils, explications, ")
            .append("exemples) : hesitations, repetitions, faux departs, discours hache, ")
            .append("pauses, debit, rythme, fluidite, aisance, prononciation, accent, ")
            .append("intonation, orthographe, ponctuation, duree ou temps de parole ;")
            .append("\n- c'est la NOTION qui est interdite, pas le mot : reformuler ")
            .append("« il hesite » en « il marque des arrets » ne passe pas davantage ;")
            .append("\n- CE QU'IL FAUT FAIRE : supprimer la remarque, ou la ramener sur ce qui ")
            .append("est visible dans le texte — choix et precision du lexique, construction ")
            .append("des phrases, enchainement des idees, adequation au destinataire, reponse ")
            .append("a la consigne ;")
            .append("\n- si un exemple corrige ne tient que par une remarque interdite, ")
            .append("SUPPRIME cet exemple : `exemples_corriges` peut etre une liste vide ;")
            .append("\n- seul `confiance_raisons` peut mentionner une transcription incertaine.")
            .append("\nReprends tes autres champs a l'identique : ne change QUE ce qui est signale.");
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
