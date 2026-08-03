package com.sejourfr.app.service.realtime;

import com.sejourfr.app.entity.AgentRoleCard;
import com.sejourfr.app.entity.ProductionTask;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Construit la "system instruction" de l'examinateur IA (couche CONDUITE) pour
 * une tache T1 ou T2, en remplissant les gabarits externalises et versionnes de
 * {@link RealtimePersonaTemplates}. Ce texte vit cote serveur et est VERROUILLE
 * dans le token ephemere Gemini : il n'est jamais expose au client en clair.
 *
 * <p>Separation stricte conduite ≠ notation : ce persona conduit l'echange, il
 * ne note pas, ne corrige pas, ne donne aucun indice. La notation reste faite
 * apres coup par le pipeline existant a partir du transcript.
 *
 * <p>Le comportement est IDENTIQUE en entrainement et en examen — seul
 * l'emballage (enchainement, chrono, quota) differe, invisible pour le candidat.
 * L'examinateur parle un francais normal a tout le monde : il n'adapte PAS son
 * registre au niveau vise (ce n'est pas son rôle — l'epreuve est adaptative, pas
 * lui). Le niveau cible ne sert qu'a la VAD (patience serveur), pas a la persona.
 * On injecte : la duree cible ({@code dureeSec}), et pour la T2 le rôle
 * examinateur ({@code contexte}) + la situation candidat ({@code consigne}).
 *
 * <p><b>Fiche de scenario T2</b> ({@link AgentRoleCard}, colonne
 * {@code production_tasks.agent_role_card}) : quand la tache en porte une ET que
 * la version de persona chargee sait la rendre, ses faits sont injectes dans le
 * prompt via {@code {ficheScenario}}. L'agent connait alors ses chiffres a
 * l'avance et ne peut plus se contredire. Sans fiche — ou sur une version de
 * persona qui l'ignore (v1) — le placeholder disparait et la T2 est rendue
 * exactement comme avant.
 */
@Component
@RequiredArgsConstructor
public class RealtimePersonaBuilder {

    private static final int DEFAULT_DUREE_SEC = 180;
    private static final String FICHE_PLACEHOLDER = "{ficheScenario}";
    private static final String PUCE = "- ";

    private final RealtimePersonaTemplates templates;

    /**
     * @param task la consigne T1 ou T2 (EO). {@code dureeMaxSec} fixe la cible de
     *             temps annoncee au modele ; {@code consigne}/{@code contexte}
     *             portent la situation et le rôle pour T2, {@code agentRoleCard}
     *             les faits que l'agent detient.
     * @return la system instruction complete (regles + tache), en francais.
     */
    public String build(ProductionTask task) {
        int dureeSec = task.getDureeMaxSec() != null ? task.getDureeMaxSec() : DEFAULT_DUREE_SEC;
        short tache = task.getTacheNumero() != null ? task.getTacheNumero() : 1;

        String regles = fill(templates.regles(), dureeSec, null, null);
        String corps = (tache == 2)
                ? buildT2(task, dureeSec)
                : fill(templates.t1(), dureeSec, null, null);
        return regles + "\n\n" + corps;
    }

    private String buildT2(ProductionTask task, int dureeSec) {
        String t2 = fill(templates.t2(), dureeSec,
                nullSafe(task.getContexte(), "Tu joues le rôle indiqué dans la consigne."),
                nullSafe(task.getConsigne(), ""));
        return injectFiche(t2, renderFiche(task.getAgentRoleCard()));
    }

    /**
     * Remplace le placeholder par le bloc fiche, ou le fait disparaitre avec sa
     * ligne quand il n'y a rien a injecter — le rendu redevient alors mot pour mot
     * celui d'une persona sans fiche.
     */
    private static String injectFiche(String t2, String fiche) {
        return fiche.isEmpty()
                ? t2.replace("\n" + FICHE_PLACEHOLDER, "").replace(FICHE_PLACEHOLDER, "")
                : t2.replace(FICHE_PLACEHOLDER, fiche);
    }

    private String renderFiche(AgentRoleCard card) {
        String gabarit = templates.t2Fiche();
        if (card == null || gabarit.isBlank()) {
            return "";
        }
        return gabarit
                .replace("{roleAgent}", nullSafe(card.roleAgent(), "le rôle indiqué dans le contexte"))
                .replace("{relation}", renderRelation(card))
                .replace("{objectifCandidat}", nullSafe(card.objectifCandidat(), "obtenir des informations auprès de toi"))
                .replace("{phraseOuverture}", nullSafe(card.phraseOuverture(), "Bonjour, que puis-je pour vous ?"))
                .replace("{informations}", renderInformations(card))
                .replace("{contraintesAgent}", renderContraintes(card));
    }

    private String renderRelation(AgentRoleCard card) {
        if (card.relation() == null) {
            return "vouvoie le candidat et tiens un registre courant et poli.";
        }
        return templates.relations().getOrDefault(card.relation().name(), card.relation().name());
    }

    private static String renderInformations(AgentRoleCard card) {
        List<String> lignes = card.toutesInformations().stream()
                .map(AgentRoleCard.Info::valeur)
                .filter(v -> v != null && !v.isBlank())
                .map(v -> PUCE + v.trim())
                .toList();
        return lignes.isEmpty() ? PUCE + "Aucun fait imposé : reste plausible et cohérent d'un bout à l'autre."
                : String.join("\n", lignes);
    }

    private static String renderContraintes(AgentRoleCard card) {
        List<String> contraintes = card.contraintesAgent() == null ? List.of() : card.contraintesAgent();
        List<String> lignes = contraintes.stream()
                .filter(c -> c != null && !c.isBlank())
                .map(c -> PUCE + c.trim())
                .toList();
        return lignes.isEmpty() ? PUCE + "Aucune contrainte particulière : joue ton rôle avec naturel." : String.join("\n", lignes);
    }

    private static String fill(String template, int dureeSec, String contexte, String consigne) {
        String out = template.replace("{dureeSec}", Integer.toString(dureeSec));
        if (contexte != null) {
            out = out.replace("{contexte}", contexte);
        }
        if (consigne != null) {
            out = out.replace("{consigne}", consigne);
        }
        return out;
    }

    private static String nullSafe(String v, String fallback) {
        return (v == null || v.isBlank()) ? fallback : v.trim();
    }
}
