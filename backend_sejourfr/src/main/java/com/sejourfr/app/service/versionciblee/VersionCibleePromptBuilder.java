package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.util.ProductionTextBounds;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * REND les deux prompts du second appel depuis
 * {@code production-version-ciblee-rubrics-<version>.json}.
 *
 * <p><b>Aucune consigne de contenu écrite ici</b> : ce builder assemble des
 * chaînes venues du JSON (system) et des données de l'exercice (user).
 *
 * <p><b>Contexte volontairement MINIMAL.</b> On envoie la consigne de la tâche,
 * les bornes de longueur, la production, le niveau observé et le niveau visé —
 * et rien d'autre. Ni la grille de notation, ni les critères, ni les
 * descripteurs, ni la note : c'est un petit appel, il doit rester petit. La
 * correction, elle, a déjà eu lieu dans un appel séparé dont ce prompt n'est
 * jamais le voisin.
 */
@Component
public class VersionCibleePromptBuilder {

    private final ObjectMapper objectMapper;
    private final VersionCibleeRubricsProvider rubrics;
    private volatile String systemPromptCache;

    public VersionCibleePromptBuilder(ObjectMapper objectMapper,
                                      VersionCibleeRubricsProvider rubrics) {
        this.objectMapper = objectMapper;
        this.rubrics = rubrics;
    }

    /** System prompt = bloc {@code commun} rendu. Identique pour toutes les tâches. */
    public String buildSystemPrompt() {
        String cached = systemPromptCache;
        if (cached != null) return cached;
        cached = renderCommun(rubrics.getCommun(), rubrics.contraintesLongueur());
        systemPromptCache = cached;
        return cached;
    }

    /**
     * @param task           la tâche EE (consigne, contexte).
     * @param production     le texte rendu par le candidat.
     * @param niveauConstate le niveau observé sur cette tâche par la correction.
     * @param niveauVise     le palier que le candidat vise (A2 / B1 / B2).
     * @param bornes         bornes de longueur RÉSOLUES depuis
     *                       {@code production_tasks.mots_min/mots_max} — source de
     *                       vérité unique, jamais une valeur en dur, et exactement
     *                       celles que le serveur vérifiera sur la sortie.
     */
    public String buildUserPrompt(ProductionTask task, String production,
                                  NiveauCecrl niveauConstate, TargetLevel niveauVise,
                                  ProductionTextBounds bornes) {
        Map<String, Object> entrees = new LinkedHashMap<>();
        entrees.put("consigne", task.getConsigne());
        if (task.getContexte() != null && !task.getContexte().isBlank()) {
            entrees.put("contexte", task.getContexte());
        }
        entrees.put("longueur_attendue", bornes.min() + " à " + bornes.max() + " mots");
        entrees.put("niveau_constate", niveauConstate == null ? null : niveauConstate.name());
        entrees.put("niveau_vise", niveauVise.name());
        entrees.put("production_du_candidat", production);

        // La longueur est REPETEE hors du JSON, dans la phrase d'action : c'est la
        // seule contrainte de la sortie que le tool-schema ne peut pas exprimer
        // (aucun `maxLength` ne compte des mots). Elle reste une donnee de
        // l'exercice, pas une consigne ecrite ici — et elle est de toute façon
        // verifiee serveur, la consigne n'etant que le premier filet.
        return "DONNÉES DE L'EXERCICE ET PRODUCTION DU CANDIDAT :\n"
            + serialize(entrees)
            + "\n\nRéécris cette réponse au niveau " + niveauVise.name()
            + ", en " + bornes.min() + " à " + bornes.max()
            + " mots (le serveur recompte, hors bornes la version est refusée), "
            + "puis nomme deux ou trois leviers pour y arriver, en appelant l'outil "
            + "`" + VersionCibleeFields.TOOL_NAME + "`.";
    }

    /** Concatène les {@code sections} (# titre / contenu), les plafonds et les ancres. */
    private String renderCommun(Map<String, Object> commun, Map<String, Integer> contraintes) {
        StringBuilder sb = new StringBuilder();
        if (commun.get("sections") instanceof List<?> sections) {
            for (Object s : sections) {
                if (s instanceof Map<?, ?> m) {
                    sb.append("# ").append(asString(m.get("titre"))).append('\n')
                        .append(asString(m.get("contenu"))).append("\n\n");
                }
            }
        }
        if (!contraintes.isEmpty()) {
            sb.append("# Plafonds de longueur (en mots, à respecter strictement)\n");
            contraintes.forEach((cle, max) -> sb.append("- ").append(cle).append(" : ")
                .append(max).append(" mots maximum par élément\n"));
            sb.append('\n');
        }
        if (commun.get("few_shot") instanceof List<?> fewShot && !fewShot.isEmpty()) {
            sb.append("# Exemples d'ancrage (production → version au niveau visé)\n\n");
            int i = 1;
            for (Object f : fewShot) {
                if (!(f instanceof Map<?, ?> m)) continue;
                sb.append("Exemple ").append(i++).append(" — ").append(asString(m.get("titre"))).append('\n');
                sb.append("Niveau constaté : ").append(asString(m.get("niveau_constate"))).append('\n');
                sb.append("Niveau visé : ").append(asString(m.get("niveau_vise"))).append('\n');
                sb.append("Consigne : ").append(asString(m.get("consigne"))).append('\n');
                sb.append("Longueur attendue : ").append(asString(m.get("bornes_mots"))).append('\n');
                sb.append("Production : \"").append(asString(m.get("production"))).append("\"\n");
                sb.append("Sortie attendue : ").append(serialize(m.get("attendu"))).append('\n');
                String pourquoi = asString(m.get("pourquoi"));
                if (!pourquoi.isBlank()) {
                    sb.append("Pourquoi : ").append(pourquoi).append('\n');
                }
                sb.append('\n');
            }
        }
        return sb.toString().trim();
    }

    private String serialize(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            return String.valueOf(value);
        }
    }

    private static String asString(Object o) {
        return o == null ? "" : o.toString();
    }
}
