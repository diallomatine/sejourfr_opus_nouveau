package com.sejourfr.app.service.competence;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * REND les deux prompts de l'analyse ciblee a partir du fichier
 * {@code competence-analysis-rubrics-<version>.json}.
 *
 * <p><b>Aucune consigne de notation ecrite ici.</b> Ce builder assemble des
 * chaines venues du JSON (system) et des donnees du sujet et du candidat
 * (user). Une regle de comportement se change dans le fichier de consignes, et
 * nulle part ailleurs.
 *
 * <ul>
 *   <li><b>system</b> = {@code commun.sections} rendues {@code # titre\ncontenu},
 *       puis les plafonds de longueur, la definition des trois verdicts et les
 *       ancres {@code few_shot}. Identique pour toutes les competences → calcule
 *       une fois et mis en cache.</li>
 *   <li><b>user</b> = <b>uniquement des donnees</b>, exactement les entrees
 *       minimales de la specification : {@code exam}, {@code section},
 *       {@code taskCode}, {@code skillId}, {@code skillName},
 *       {@code targetLevel}, {@code context}, {@code instruction},
 *       {@code uniqueCriterion}, et {@code candidateProduction} (ecrit) ou
 *       {@code transcript} (oral).</li>
 * </ul>
 *
 * <p><b>Ce qui n'est deliberement PAS envoye.</b> La duree de l'enregistrement
 * (garde-fou oral : le correcteur ne peut pas fonder son verdict sur une
 * information qu'il n'a pas), et les longueurs recommandees du sujet — elles
 * sont indicatives, les envoyer inviterait a reprocher une brievete que la
 * consigne autorise (regles 14 et 15 de la specification).
 */
@Component
public class CompetenceAnalysisPromptBuilder {

    /** Le seul examen servi par ce module ; valeur figee de la specification. */
    private static final String EXAM = "TCF_IRN";

    private final ObjectMapper objectMapper;
    private final CompetenceRubricsProvider rubrics;
    private volatile String systemPromptCache;

    public CompetenceAnalysisPromptBuilder(ObjectMapper objectMapper, CompetenceRubricsProvider rubrics) {
        this.objectMapper = objectMapper;
        this.rubrics = rubrics;
    }

    /** System prompt = bloc {@code commun} rendu. Identique pour tous les sujets. */
    public String buildSystemPrompt() {
        String cached = systemPromptCache;
        if (cached != null) return cached;
        cached = renderCommun(rubrics.getCommun(), rubrics.contraintesLongueur());
        systemPromptCache = cached;
        return cached;
    }

    /**
     * @param production texte du candidat (EE) ou transcription Whisper (EO).
     * @param estOral    choisit la cle {@code transcript} plutot que
     *                   {@code candidateProduction} : le correcteur doit savoir
     *                   qu'il lit une transcription automatique, c'est ce qui
     *                   declenche le garde-fou oral des consignes.
     */
    public String buildUserPrompt(SkillPrompt prompt, Skill skill, String production, boolean estOral) {
        Map<String, Object> entrees = new LinkedHashMap<>();
        entrees.put("exam", EXAM);
        entrees.put("section", skill.getSection() == null ? null : skill.getSection().name());
        entrees.put("taskCode", skill.getTaskCode() == null ? null : skill.getTaskCode().name());
        entrees.put("skillId", skill.getCode());
        entrees.put("skillName", skill.getTitle());
        entrees.put("targetLevel", skill.getTargetLevel());
        entrees.put("context", prompt.getContext());
        entrees.put("instruction", prompt.getInstruction());
        entrees.put("uniqueCriterion", prompt.getUniqueCriterion());
        entrees.put(estOral ? "transcript" : "candidateProduction", production);

        StringBuilder sb = new StringBuilder();
        sb.append("DONNEES DE L'EXERCICE ET PRODUCTION DU CANDIDAT :\n");
        sb.append(serialize(entrees)).append('\n');
        if (estOral) {
            sb.append("\nRappel : `transcript` est une transcription automatique, pas l'audio. ")
                .append("Tu n'as aucun moyen d'entendre ce candidat.\n");
        }
        sb.append("\nAnalyse UNIQUEMENT `uniqueCriterion` et appelle l'outil ")
            .append("`submit_competence_analysis`.");
        return sb.toString();
    }

    /**
     * Message du REESSAI unique, quand le serveur a rejete la sortie precedente.
     *
     * <p>Il rappelle les violations exactes et la sortie refusee : sans la
     * sortie, le correcteur ne sait pas laquelle de ses phrases posait probleme
     * et resoumet la meme. <b>Aucun controle n'est relache</b> — on explique
     * comment satisfaire un controle inchange.
     */
    public String buildRepairPrompt(String userPrompt, List<String> violations,
                                    Map<String, Object> refusee) {
        StringBuilder sb = new StringBuilder(userPrompt);
        sb.append("\n\nTA SORTIE PRECEDENTE A ETE REJETEE PAR LE SERVEUR. ")
            .append("Corrige exactement ces violations et rappelle l'outil ")
            .append("`submit_competence_analysis` :\n- ")
            .append(String.join("\n- ", violations));
        if (refusee != null && !refusee.isEmpty()) {
            sb.append("\n\nSORTIE REFUSEE :\n").append(serialize(refusee));
        }
        sb.append("\n\nRAPPELS : cinq champs, aucun de plus, aucun vide. ")
            .append("`status` vaut exactement VALIDATED, PARTIAL ou NOT_VALIDATED. ")
            .append("Une seule priorite d'amelioration. Si un champ depassait la longueur ")
            .append("autorisee, RECRIS-LE PLUS COURT sans changer ton verdict.");
        return sb.toString();
    }

    /** Concatene les {@code sections} (# titre / contenu), les plafonds, les verdicts et les ancres. */
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
            sb.append("# Plafonds de longueur (en mots, a respecter strictement)\n");
            contraintes.forEach((cle, max) -> sb.append("- ").append(cle).append(" : ")
                .append(max).append(" mots maximum\n"));
            sb.append('\n');
        }

        if (commun.get("statuts") instanceof Map<?, ?> statuts) {
            sb.append("# Valeurs autorisees de `status`\n");
            for (Map.Entry<?, ?> e : statuts.entrySet()) {
                sb.append("- ").append(asString(e.getKey())).append(" : ")
                    .append(asString(e.getValue())).append('\n');
            }
            sb.append('\n');
        }

        if (commun.get("few_shot") instanceof List<?> fewShot && !fewShot.isEmpty()) {
            sb.append("# Exemples d'ancrage (sujet → production → analyse attendue)\n\n");
            int i = 1;
            for (Object f : fewShot) {
                if (!(f instanceof Map<?, ?> m)) continue;
                sb.append("Exemple ").append(i++).append(" — ").append(asString(m.get("titre"))).append('\n');
                sb.append("Section : ").append(asString(m.get("section"))).append('\n');
                sb.append("Competence : ").append(asString(m.get("skill"))).append('\n');
                sb.append("Contexte : ").append(asString(m.get("contexte"))).append('\n');
                sb.append("Consigne : ").append(asString(m.get("instruction"))).append('\n');
                sb.append("Critere unique : ").append(asString(m.get("critere"))).append('\n');
                sb.append("Production : \"").append(asString(m.get("production"))).append("\"\n");
                sb.append("Analyse attendue : ").append(serialize(m.get("attendu"))).append('\n');
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
            // Le prompt ne doit jamais faire echouer une analyse pour une raison
            // de serialisation : on degrade vers la representation Java.
            return String.valueOf(value);
        }
    }

    private static String asString(Object o) {
        return o == null ? "" : o.toString();
    }
}
