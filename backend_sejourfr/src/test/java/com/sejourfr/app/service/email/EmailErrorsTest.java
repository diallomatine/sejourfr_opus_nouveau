package com.sejourfr.app.service.email;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class EmailErrorsTest {

    @Test
    void lesAdressesSontMasquees() {
        String out = EmailErrors.sanitize(new RuntimeException("550 Invalid recipients: karim.test@sejourfr.fr, x@y.com"));

        assertThat(out).contains("k***@sejourfr.fr").contains("x***@y.com")
                .doesNotContain("karim.test@");
    }

    @Test
    void lesJetonsSontRetires() {
        String out = EmailErrors.sanitize("GET https://sejourfr.fr/reset?token=SECRET123&x=1 failed");

        assertThat(out).doesNotContain("SECRET123").contains("token=***");
    }

    @Test
    void leMessageEstTronqueA500() {
        assertThat(EmailErrors.sanitize("a".repeat(900))).hasSize(500);
    }

    @Test
    void lesSautsDeLigneDisparaissent() {
        assertThat(EmailErrors.sanitize("ligne1\r\nligne2")).isEqualTo("ligne1 ligne2");
    }

    @Test
    void uneExceptionSansMessageGardeSonType() {
        assertThat(EmailErrors.sanitize(new IllegalStateException())).isEqualTo("IllegalStateException");
    }
}
