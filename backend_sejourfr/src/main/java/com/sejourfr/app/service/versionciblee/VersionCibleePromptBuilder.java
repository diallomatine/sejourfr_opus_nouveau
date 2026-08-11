package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.service.EvaluationProductionSegments;
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
 *
 * <p><b>À L'ORAL, la production part DÉCOUPÉE ET NUMÉROTÉE</b>
 * ({@link EvaluationProductionSegments}, le découpage du contrat de correction
 * v12) : le modèle désigne un passage par son numéro au lieu de le recopier, ce
 * qui a fait tomber le premier poste de refus oral. Les tours de l'examinateur
 * sont montrés sans numéro — reformuler l'examinateur devient impossible par
 * construction, pas « interdit ».
 *
 * <p><b>La DURÉE n'est jamais envoyée</b>, ici comme au correcteur : rien de ce
 * qui s'entend (débit, pauses, hésitations) ne doit peser sur ce que le candidat
 * reçoit.
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
     * Prompt d'une production ÉCRITE.
     *
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
        Map<String, Object> entrees = entreesCommunes(task, niveauConstate, niveauVise);
        entrees.put("longueur_attendue", bornes.min() + " à " + bornes.max() + " mots");
        entrees.put("production_du_candidat", production);

        // La longueur est REPETEE hors du JSON, dans la phrase d'action : c'est la
        // seule contrainte de la sortie que le tool-schema ne peut pas exprimer
        // (aucun `maxLength` ne compte des mots). Elle reste une donnee de
        // l'exercice, pas une consigne ecrite ici — et elle est de toute façon
        // verifiee serveur, la consigne n'etant que le premier filet.
        StringBuilder sb = new StringBuilder("DONNÉES DE L'EXERCICE ET PRODUCTION DU CANDIDAT :\n")
            .append(serialize(entrees));
        if (!rubrics.contrat().planDAction()) {
            sb.append("\n\nRéécris cette réponse au niveau ").append(niveauVise.name())
                .append(", en ").append(bornes.min()).append(" à ").append(bornes.max())
                .append(" mots (le serveur recompte, hors bornes la version est refusée), ")
                .append("puis nomme deux ou trois leviers pour y arriver, en appelant l'outil ")
                .append("`").append(VersionCibleeFields.TOOL_NAME).append("`.");
            return sb.toString();
        }
        sb.append("\n\nDonne deux ou trois leviers vers le niveau ").append(niveauVise.name())
            .append(", réécris SA réponse à ce niveau en ").append(bornes.min()).append(" à ")
            .append(bornes.max())
            .append(" mots (le serveur recompte, hors bornes la version est refusée), ")
            .append("désigne deux ou trois passages recopiés MOT POUR MOT depuis ta version ")
            .append("(le serveur les y cherche, et abandonne tout le bloc s'il ne les trouve ")
            .append("pas), puis donne une tournure à retenir. Appelle l'outil `")
            .append(VersionCibleeFields.TOOL_NAME).append("`.");
        return sb.toString();
    }

    /**
     * Prompt d'une production ORALE. La production n'y figure QUE sous sa forme
     * découpée et numérotée : c'est ce qui rend le numéro désignable et le tour
     * de l'examinateur non désignable.
     *
     * @param segments découpage de la transcription servie au candidat — le même
     *                 texte que celui affiché, jamais un second découpage.
     */
    public String buildUserPromptOral(ProductionTask task, EvaluationProductionSegments segments,
                                      NiveauCecrl niveauConstate, TargetLevel niveauVise) {
        Map<String, Object> entrees = entreesCommunes(task, niveauConstate, niveauVise);
        entrees.put("passages_reformulables", segments.taille());

        return "DONNÉES DE L'EXERCICE :\n" + serialize(entrees)
            + "\n\nTRANSCRIPTION AUTOMATIQUE DU CANDIDAT, DÉCOUPÉE ET NUMÉROTÉE.\n"
            + "Seuls les passages précédés d'un numéro entre crochets sont ceux du candidat : "
            + "ce sont les seuls que tu peux reformuler. Les tours de l'examinateur n'ont pas de "
            + "numéro.\n\n"
            + segments.rendu()
            + "\n\nDonne deux ou trois leviers vers le niveau " + niveauVise.name()
            + ", puis redis à ce niveau deux ou trois de ses passages, chacun désigné par son "
            + "NUMÉRO (`segment_numero`, entre 1 et " + segments.taille() + ") — tu ne réécris "
            + "PAS toute sa production —, puis donne une tournure à retenir. Appelle l'outil `"
            + VersionCibleeFields.TOOL_NAME + "`.";
    }

    private static Map<String, Object> entreesCommunes(ProductionTask task,
                                                       NiveauCecrl niveauConstate,
                                                       TargetLevel niveauVise) {
        Map<String, Object> entrees = new LinkedHashMap<>();
        entrees.put("epreuve", task.getEpreuve() == null ? null : task.getEpreuve().name());
        entrees.put("consigne", task.getConsigne());
        if (task.getContexte() != null && !task.getContexte().isBlank()) {
            entrees.put("contexte", task.getContexte());
        }
        entrees.put("niveau_constate", niveauConstate == null ? null : niveauConstate.name());
        entrees.put("niveau_vise", niveauVise.name());
        return entrees;
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
                ligne(sb, "Épreuve", m.get("epreuve"));
                sb.append("Niveau constaté : ").append(asString(m.get("niveau_constate"))).append('\n');
                sb.append("Niveau visé : ").append(asString(m.get("niveau_vise"))).append('\n');
                sb.append("Consigne : ").append(asString(m.get("consigne"))).append('\n');
                ligne(sb, "Longueur attendue", m.get("bornes_mots"));
                if (m.get("production") != null) {
                    sb.append("Production : \"").append(asString(m.get("production"))).append("\"\n");
                }
                if (m.get("production_numerotee") != null) {
                    sb.append("Production découpée et numérotée :\n")
                        .append(asString(m.get("production_numerotee"))).append('\n');
                }
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

    private static void ligne(StringBuilder sb, String libelle, Object valeur) {
        if (valeur == null || asString(valeur).isBlank()) return;
        sb.append(libelle).append(" : ").append(asString(valeur)).append('\n');
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
