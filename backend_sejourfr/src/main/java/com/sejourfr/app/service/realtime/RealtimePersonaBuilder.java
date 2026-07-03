package com.sejourfr.app.service.realtime;

import com.sejourfr.app.entity.ProductionTask;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

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
 */
@Component
@RequiredArgsConstructor
public class RealtimePersonaBuilder {

    private static final int DEFAULT_DUREE_SEC = 180;

    private final RealtimePersonaTemplates templates;

    /**
     * @param task la consigne T1 ou T2 (EO). {@code dureeMaxSec} fixe la cible de
     *             temps annoncee au modele ; {@code consigne}/{@code contexte}
     *             portent la situation et le rôle pour T2.
     * @return la system instruction complete (regles + tache), en francais.
     */
    public String build(ProductionTask task) {
        int dureeSec = task.getDureeMaxSec() != null ? task.getDureeMaxSec() : DEFAULT_DUREE_SEC;
        short tache = task.getTacheNumero() != null ? task.getTacheNumero() : 1;

        String regles = fill(templates.regles(), dureeSec, null, null);
        String corps = (tache == 2)
                ? fill(templates.t2(), dureeSec,
                        nullSafe(task.getContexte(), "Tu joues le rôle indiqué dans la consigne."),
                        nullSafe(task.getConsigne(), ""))
                : fill(templates.t1(), dureeSec, null, null);
        return regles + "\n\n" + corps;
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
