package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AnthropicProperties;
import org.junit.jupiter.api.Test;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PromptLoaderTest {

    private PromptLoader loaderFor(String version) {
        AnthropicProperties props = new AnthropicProperties();
        props.setPromptVersion(version);
        return new PromptLoader(props);
    }

    @Test
    void load_lit_le_prompt_classpath_de_la_version_demandee() throws IOException {
        PromptLoader loader = loaderFor("v2");

        loader.load();

        String prompt = loader.getSystemPrompt();
        assertThat(prompt).isNotBlank();
        assertThat(prompt).contains("TCF IRN");
    }

    @Test
    void load_propage_io_exception_si_la_version_est_introuvable() {
        PromptLoader loader = loaderFor("version-inexistante");

        assertThatThrownBy(loader::load)
            .isInstanceOf(IOException.class);
    }
}
