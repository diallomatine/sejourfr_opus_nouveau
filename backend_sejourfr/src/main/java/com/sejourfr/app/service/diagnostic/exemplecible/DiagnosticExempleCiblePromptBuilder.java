package com.sejourfr.app.service.diagnostic.exemplecible;

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
 * REND les deux prompts du SECOND appel du diagnostic depuis
 * {@code diagnostic-exemple-cible-rubrics-<version>.json}.
 *
 * <p><b>Aucune consigne de contenu ecrite ici</b> : ce builder assemble des
 * chaines venues du JSON (system) et des donnees de l'exercice (user).
 *
 * <p><b>La production part DECOUPEE EN PHRASES NUMEROTEES</b>
 * ({@link EvaluationProductionSegments#rendu()}, la classe des productions
 * completes — <b>appelee, jamais recopiee</b>). C'est ce qui permet au modele de
 * DESIGNER la phrase du candidat au lieu de la recopier : la technique du contrat
 * v12, qui a fait tomber la premiere cause de refus du depot
 * ({@code PREUVE_NON_RATTACHEE}, 42,9 % des appels oraux).
 *
 * <p><b>Contexte volontairement MINIMAL.</b> On envoie la consigne, la production
 * numerotee, le niveau observe et le niveau vise — et rien d'autre. Ni la grille
 * du diagnostic, ni ses verdicts, ni les priorites retenues : l'analyse a deja eu
 * lieu dans un appel separe, dont ce prompt n'est jamais le voisin.
 *
 * <p><b>Le niveau vise est repete HORS du JSON</b>, dans la phrase d'action —
 * meme technique que {@code VersionCibleePromptBuilder} : c'est la seule
 * information de sortie que le tool-schema ne peut pas exprimer, puisque le
 * contrat ne prevoit aucun champ de niveau.
 */
@Component
public class DiagnosticExempleCiblePromptBuilder {

    /** Le seul examen servi par ce parcours ; valeur figee de la specification. */
    private static final String EXAM = "TCF_IRN";

    private final ObjectMapper objectMapper;
    private final DiagnosticExempleCibleRubricsProvider rubrics;
    private volatile String systemPromptCache;

    public DiagnosticExempleCiblePromptBuilder(ObjectMapper objectMapper,
                                               DiagnosticExempleCibleRubricsProvider rubrics) {
        this.objectMapper = objectMapper;
        this.rubrics = rubrics;
    }

    /** System prompt = bloc {@code commun} rendu. Identique pour tous les candidats. */
    public String buildSystemPrompt() {
        String cached = systemPromptCache;
        if (cached != null) return cached;
        cached = renderCommun(rubrics.getCommun(), rubrics.contraintesLongueur());
        systemPromptCache = cached;
        return cached;
    }

    /**
     * @param segments production ECRITE decoupee en phrases numerotees.
     * @param constate le niveau observe par l'analyse diagnostique.
     * @param vise     le palier qu'exige la demarche du candidat.
     * @param bornes   bornes de longueur de la tache, envoyees ET revalidees serveur.
     */
    public String buildUserPrompt(ProductionTask task, EvaluationProductionSegments segments,
                                  NiveauCecrl constate, TargetLevel vise,
                                  ProductionTextBounds bornes) {
        Map<String, Object> entrees = new LinkedHashMap<>();
        entrees.put("exam", EXAM);
        entrees.put("epreuve", task.getEpreuve() == null ? null : task.getEpreuve().name());
        entrees.put("consigne", task.getConsigne());
        entrees.put("niveau_constate", constate == null ? null : constate.name());
        entrees.put("niveau_vise", vise.name());
        entrees.put("numeros_disponibles", "1 a " + segments.taille());

        StringBuilder sb = new StringBuilder();
        sb.append("DONNÉES DE L'EXERCICE ÉCRIT :\n");
        sb.append(serialize(entrees)).append('\n');
        sb.append("\nPRODUCTION DU CANDIDAT, DÉCOUPÉE EN PHRASES NUMÉROTÉES :\n");
        sb.append(segments.rendu()).append('\n');
        sb.append("\nChoisis UNE phrase par son numéro (de 1 à ").append(segments.taille())
            .append("), réécris-la au niveau ").append(vise.name())
            .append(" en gardant sa situation, ses faits et son intention — ")
            .append(bornes.max()).append(" mots au maximum — puis désigne deux ou trois ")
            .append("passages recopiés MOT POUR MOT depuis ta version (le serveur les y ")
            .append("cherche, et retire ceux qu'il ne trouve pas). Appelle l'outil `")
            .append(DiagnosticExempleCibleFields.TOOL_NAME).append("`.");
        return sb.toString();
    }

    /** Concatene les {@code sections} (# titre / contenu), les plafonds et les ancres. */
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
                .append(max).append(" mots maximum\n"));
            sb.append('\n');
        }
        if (commun.get("few_shot") instanceof List<?> fewShot && !fewShot.isEmpty()) {
            sb.append("# Exemples d'ancrage (production numérotée → phrase réécrite)\n\n");
            int i = 1;
            for (Object f : fewShot) {
                if (!(f instanceof Map<?, ?> m)) continue;
                sb.append("Exemple ").append(i++).append(" — ").append(asString(m.get("titre")))
                    .append('\n');
                sb.append("Niveau constaté : ").append(asString(m.get("niveau_constate")))
                    .append('\n');
                sb.append("Niveau visé : ").append(asString(m.get("niveau_vise"))).append('\n');
                sb.append("Consigne : ").append(asString(m.get("consigne"))).append('\n');
                sb.append("Production :\n").append(asString(m.get("production"))).append('\n');
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
            // Le prompt ne doit jamais faire echouer un enrichissement pour une
            // raison de serialisation : on degrade vers la representation Java.
            return String.valueOf(value);
        }
    }

    private static String asString(Object o) {
        return o == null ? "" : o.toString();
    }
}
