package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AnthropicProperties;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

/**
 * Charge le prompt systeme audio depuis classpath au demarrage,
 * en fonction de {@link AnthropicProperties#getPromptVersion()}.
 * Le prompt est immutable apres chargement.
 */
@Component
public class PromptLoader {

    private static final Logger log = LoggerFactory.getLogger(PromptLoader.class);
    private static final String PROMPT_PATH_TEMPLATE = "prompts/audio-question-system-%s.md";

    private final AnthropicProperties properties;
    private String systemPrompt;

    public PromptLoader(AnthropicProperties properties) {
        this.properties = properties;
    }

    @PostConstruct
    void load() throws IOException {
        String path = PROMPT_PATH_TEMPLATE.formatted(properties.getPromptVersion());
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            this.systemPrompt = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
        }
        log.info("Prompt audio charge : {} ({} caracteres)", path, systemPrompt.length());
    }

    public String getSystemPrompt() {
        return systemPrompt;
    }
}
