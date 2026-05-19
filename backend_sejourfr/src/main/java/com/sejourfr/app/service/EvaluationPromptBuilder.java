package com.sejourfr.app.service;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import jakarta.annotation.PostConstruct;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Construit les prompts system / user passes a {@link EvaluationAnthropicClient}.
 * Les gabarits sont charges depuis classpath:prompts/ au demarrage et versionnes
 * via {@code sejourfr.production-evaluation.anthropic.prompt-version}.
 */
@Component
public class EvaluationPromptBuilder {

    private static final String SYSTEM_PROMPT_PATH = "prompts/production-evaluation-system-v1.md";
    private static final String USER_TEMPLATE_PATH = "prompts/production-evaluation-user-template.md";

    private final ObjectMapper objectMapper;
    private String systemTemplate;
    private String userTemplate;

    public EvaluationPromptBuilder(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void loadTemplates() throws Exception {
        this.systemTemplate = loadResource(SYSTEM_PROMPT_PATH);
        this.userTemplate = loadResource(USER_TEMPLATE_PATH);
    }

    public String buildSystemPrompt(EpreuveType epreuve) {
        return systemTemplate.replace("{MODALITE}", modalite(epreuve));
    }

    /**
     * @param production texte EE rendu ou transcription Whisper (EO).
     * @param transcriptionLitterale true si la production vient d'une transcription
     *        Whisper en mode litteral (pour informer Claude que les fautes peuvent
     *        avoir ete partiellement lissees).
     */
    public String buildUserPrompt(ProductionTask task, String production, boolean transcriptionLitterale) {
        String contexteBlock = (task.getContexte() == null || task.getContexte().isBlank())
            ? ""
            : "CONTEXTE :\n\"" + task.getContexte() + "\"\n";
        String criteresJson;
        try {
            criteresJson = objectMapper.writeValueAsString(task.getCriteresEvaluation());
        } catch (Exception e) {
            criteresJson = "{}";
        }
        String litteralNotice = transcriptionLitterale
            ? "Note : la transcription provient d'un systeme automatique configure en mode litteral. "
              + "Elle peut contenir des erreurs grammaticales refletant la production orale reelle du "
              + "candidat (ex: \"j'habites\", \"les voitures rouge\"). Tiens compte de ces erreurs dans "
              + "ton evaluation."
            : "";

        return userTemplate
            .replace("{MODALITE}", modalite(task.getEpreuve()))
            .replace("{TACHE_NUMERO}", String.valueOf(task.getTacheNumero()))
            .replace("{NIVEAU}", task.getNiveauCible())
            .replace("{CONSIGNE}", nullSafe(task.getConsigne()))
            .replace("{CONTEXTE_BLOCK}", contexteBlock)
            .replace("{CRITERES}", criteresJson)
            .replace("{PRODUCTION}", nullSafe(production))
            .replace("{LITTERAL_NOTICE}", litteralNotice);
    }

    private static String modalite(EpreuveType epreuve) {
        return epreuve == EpreuveType.TCF_EO ? "orale" : "ecrite";
    }

    private static String nullSafe(String s) {
        return s == null ? "" : s;
    }

    private static String loadResource(String path) throws Exception {
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            return StreamUtils.copyToString(is, StandardCharsets.UTF_8);
        }
    }
}
