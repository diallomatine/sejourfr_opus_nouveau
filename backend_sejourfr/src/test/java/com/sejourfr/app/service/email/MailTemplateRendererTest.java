package com.sejourfr.app.service.email;

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
        // premium-access-extended.html contient {{greeting}} (échappé)
        String html = renderer.render("email/premium-access-extended.html",
                Map.of("greeting", "<script>steal()</script>"));

        assertThat(html)
                .contains("&lt;script&gt;steal()&lt;/script&gt;")
                .doesNotContain("<script>steal()");
    }

    @Test
    void render_missingKey_leavesPlaceholderUntouched() {
        // on ne fournit pas offerName : son placeholder doit rester en clair
        String html = renderer.render("email/premium-access-extended.html",
                Map.of("greeting", "Karim"));

        assertThat(html).contains("{{offerName}}");
        assertThat(html).contains("Karim");
    }

    @Test
    void render_tripleBrace_isNotEscaped() {
        // layout.html contient {{{body}}} (brut, fragment HTML déjà sûr)
        String html = renderer.render("email/layout.html",
                Map.of("body", "<b>Bonjour</b>"));

        assertThat(html).contains("<b>Bonjour</b>");
        assertThat(html).doesNotContain("&lt;b&gt;");
    }

    @Test
    void render_uneValeurInjecteeNestJamaisRelueCommePlaceholder() {
        String html = renderer.render("email/layout.html",
                java.util.Map.of("body", "{{subject}}", "subject", "<b>T</b>"));

        assertThat(html).contains("{{subject}}").contains("&lt;b&gt;T&lt;/b&gt;");
    }

    @Test
    void renderText_nEchappeRien() {
        assertThat(renderer.renderInline("Votre accès {{x}}", java.util.Map.of("x", "TCF & Civique")))
                .isEqualTo("Votre accès TCF & Civique");
    }

    @Test
    void uneLigneDontTousLesPlaceholdersSontVidesDisparait() {
        String t = "avant\n<p>{{a}}</p>\n<p>{{a}} et {{b}}</p>\n<p>fixe</p>\n{{inconnu}}\napres";

        String out = renderer.renderInline(t, java.util.Map.of("a", "", "b", "B"));

        assertThat(out).isEqualTo("avant\n<p> et B</p>\n<p>fixe</p>\n{{inconnu}}\napres");
    }
}
