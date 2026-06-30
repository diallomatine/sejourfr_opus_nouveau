package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class MailTemplateRendererTest {

    private final MailTemplateRenderer renderer = new MailTemplateRenderer();

    @Test
    void escape_neutralizesHtmlMetacharacters() {
        String out = MailTemplateRenderer.escape("<script>alert(\"x\")</script> & co");
        assertThat(out)
                .isEqualTo("&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; co")
                .doesNotContain("<script>");
    }

    @Test
    void escape_null_returnsEmpty() {
        assertThat(MailTemplateRenderer.escape(null)).isEmpty();
    }

    @Test
    void render_escapedPlaceholder_preventsInjection() {
        // access-expiring.html contient {{greeting}} (échappé)
        String html = renderer.render("access-expiring.html",
                Map.of("greeting", "<script>steal()</script>"));

        assertThat(html)
                .contains("&lt;script&gt;steal()&lt;/script&gt;")
                .doesNotContain("<script>steal()");
    }

    @Test
    void render_missingKey_leavesPlaceholderUntouched() {
        // on ne fournit pas planName : son placeholder doit rester en clair
        String html = renderer.render("access-expiring.html",
                Map.of("greeting", "Karim"));

        assertThat(html).contains("{{planName}}");
        assertThat(html).contains("Karim");
    }

    @Test
    void render_tripleBrace_isNotEscaped() {
        // layout.html contient {{{body}}} (brut, fragment HTML déjà sûr)
        String html = renderer.render("layout.html",
                Map.of("body", "<b>Bonjour</b>"));

        assertThat(html).contains("<b>Bonjour</b>");
        assertThat(html).doesNotContain("&lt;b&gt;");
    }
}
