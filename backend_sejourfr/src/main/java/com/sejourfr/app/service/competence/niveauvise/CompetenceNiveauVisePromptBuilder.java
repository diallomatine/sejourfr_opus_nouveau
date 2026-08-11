package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * REND les deux prompts du SECOND appel depuis
 * {@code competence-niveau-vise-rubrics-<version>.json}.
 *
 * <p><b>Aucune consigne de contenu ecrite ici</b> : ce builder assemble des
 * chaines venues du JSON (system) et des donnees de l'exercice (user).
 *
 * <p><b>Contexte volontairement MINIMAL.</b> On envoie le sujet, son critere
 * unique, la production, le niveau observe et le niveau vise — et rien d'autre.
 * Ni la grille d'analyse, ni les trois verdicts, ni le verdict rendu : c'est un
 * petit appel, il doit rester petit. L'analyse, elle, a deja eu lieu dans un
 * appel separe dont ce prompt n'est jamais le voisin.
 *
 * <p><b>Le niveau vise est repete HORS du JSON</b>, dans la phrase d'action —
 * meme technique que {@code VersionCibleePromptBuilder} : c'est la seule
 * information de sortie que le tool-schema ne peut pas exprimer, puisque le
 * contrat ne prevoit aucun champ de niveau.
 */
@Component
public class CompetenceNiveauVisePromptBuilder {

    /** Le seul examen servi par ce module ; valeur figee de la specification. */
    private static final String EXAM = "TCF_IRN";

    private final ObjectMapper objectMapper;
    private final CompetenceNiveauViseRubricsProvider rubrics;
    private volatile String systemPromptCache;

    public CompetenceNiveauVisePromptBuilder(ObjectMapper objectMapper,
                                             CompetenceNiveauViseRubricsProvider rubrics) {
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
     *                   {@code candidateProduction} : le redacteur doit savoir
     *                   qu'il lit une transcription automatique, sinon il
     *                   corrigerait une ponctuation que le candidat n'a jamais
     *                   ecrite.
     * @param constate   le niveau demontre par cette production (appel 1).
     * @param vise       le palier qu'exige la demarche du candidat.
     */
    public String buildUserPrompt(SkillPrompt prompt, Skill skill, String production,
                                  boolean estOral, NiveauCecrl constate, TargetLevel vise) {
        Map<String, Object> entrees = new LinkedHashMap<>();
        entrees.put("exam", EXAM);
        entrees.put("section", skill.getSection() == null ? null : skill.getSection().name());
        entrees.put("taskCode", skill.getTaskCode() == null ? null : skill.getTaskCode().name());
        entrees.put("skillName", skill.getTitle());
        entrees.put("context", prompt.getContext());
        entrees.put("instruction", prompt.getInstruction());
        entrees.put("uniqueCriterion", prompt.getUniqueCriterion());
        entrees.put("niveau_constate", constate == null ? null : constate.name());
        entrees.put("niveau_vise", vise.name());
        entrees.put(estOral ? "transcript" : "candidateProduction", production);

        StringBuilder sb = new StringBuilder();
        sb.append("DONNÉES DE L'EXERCICE ET PRODUCTION DU CANDIDAT :\n");
        sb.append(serialize(entrees)).append('\n');
        if (estOral) {
            sb.append("\nRappel : `transcript` est une transcription automatique, pas l'audio. ")
                .append("Tu n'as aucun moyen d'entendre ce candidat.\n");
        }
        sb.append("\nDonne deux ou trois leviers vers le niveau ").append(vise.name())
            .append(", réécris SA réponse à ce niveau en gardant sa situation et sa longueur, ")
            .append("désigne deux ou trois passages recopiés MOT POUR MOT depuis ta version ")
            .append("(le serveur les y cherche, et abandonne tout le bloc s'il ne les trouve ")
            .append("pas), puis donne une tournure à retenir. Appelle l'outil `")
            .append(CompetenceNiveauViseFields.TOOL_NAME).append("`.");
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
            sb.append("# Exemples d'ancrage (production → plan vers le niveau visé)\n\n");
            int i = 1;
            for (Object f : fewShot) {
                if (!(f instanceof Map<?, ?> m)) continue;
                sb.append("Exemple ").append(i++).append(" — ").append(asString(m.get("titre")))
                    .append('\n');
                sb.append("Section : ").append(asString(m.get("section"))).append('\n');
                sb.append("Niveau constaté : ").append(asString(m.get("niveau_constate")))
                    .append('\n');
                sb.append("Niveau visé : ").append(asString(m.get("niveau_vise"))).append('\n');
                sb.append("Critère unique : ").append(asString(m.get("critere"))).append('\n');
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
            // Le prompt ne doit jamais faire echouer un enrichissement pour une
            // raison de serialisation : on degrade vers la representation Java.
            return String.valueOf(value);
        }
    }

    private static String asString(Object o) {
        return o == null ? "" : o.toString();
    }
}
