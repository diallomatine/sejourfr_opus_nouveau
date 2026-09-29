package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class EmailAllowlistTest {

    private static EmailAllowlist allowlist(boolean enabled, List<String> addresses) {
        EmailProperties p = new EmailProperties();
        p.getAllowlist().setEnabled(enabled);
        p.getAllowlist().setAddresses(addresses);
        return new EmailAllowlist(p);
    }

    @Test
    void desactiveeToutPasse() {
        assertThat(allowlist(false, List.of()).allows("qui@importe.fr")).isTrue();
    }

    @Test
    void activeeEtVideElleBloqueTout() {
        assertThat(allowlist(true, List.of()).allows("vrai.testeur@gmail.com")).isFalse();
        assertThat(allowlist(true, List.of("")).allows("vrai.testeur@gmail.com")).isFalse();
    }

    @Test
    void adresseExacteEtDomaine() {
        EmailAllowlist a = allowlist(true, List.of("Dev@Exemple.fr", "@sejourfr.fr"));

        assertThat(a.allows("dev@exemple.fr")).isTrue();
        assertThat(a.allows("karim.test@sejourfr.fr")).isTrue();
        assertThat(a.allows("autre@exemple.fr")).isFalse();
        assertThat(a.allows("x@faux-sejourfr.fr.evil.com")).isFalse();
    }
}
