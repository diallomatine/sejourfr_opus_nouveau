package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class LogMaskTest {

    @Test
    void email_masksLocalPartKeepsDomain() {
        assertThat(LogMask.email("karim.test@sejourfr.fr")).isEqualTo("k***@sejourfr.fr");
    }

    @Test
    void email_nullOrBlank_absent() {
        assertThat(LogMask.email(null)).isEqualTo("(absent)");
        assertThat(LogMask.email("   ")).isEqualTo("(absent)");
    }

    @Test
    void email_noAtOrLeadingAt_fullyMasked() {
        assertThat(LogMask.email("not-an-email")).isEqualTo("***");
        assertThat(LogMask.email("@sejourfr.fr")).isEqualTo("***");
    }

    @Test
    void token_longValue_prefixAndLength() {
        String token = "abcdef0123456789";
        assertThat(LogMask.token(token)).isEqualTo("abcdef…(" + token.length() + ")");
    }

    @Test
    void token_shortValue_fullyMasked() {
        assertThat(LogMask.token("12345678")).isEqualTo("***");
        assertThat(LogMask.token("short")).isEqualTo("***");
    }

    @Test
    void token_nullOrBlank_absent() {
        assertThat(LogMask.token(null)).isEqualTo("(absent)");
        assertThat(LogMask.token("   ")).isEqualTo("(absent)");
    }
}
