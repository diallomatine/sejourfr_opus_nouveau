package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UnsubscribeTokenServiceTest {

    private final UUID userId = UUID.randomUUID();

    private static UnsubscribeTokenService service(int current, Map<Integer, String> keys) {
        EmailProperties p = new EmailProperties();
        p.getUnsubscribe().setCurrentKeyVersion(current);
        p.getUnsubscribe().setKeys(new LinkedHashMap<>(keys));
        UnsubscribeTokenService s = new UnsubscribeTokenService(p);
        s.verifierTrousseau();
        return s;
    }

    @Test
    void unJetonSigneSeRelit() {
        UnsubscribeTokenService s = service(1, Map.of(1, "k1"));

        String token = s.create(userId);

        assertThat(token.split("\\.")).hasSize(3);
        assertThat(token.split("\\.")[1]).isEqualTo("1");
        assertThat(s.verify(token)).contains(userId);
    }

    @Test
    void uneAncienneVersionDeCleResteAcceptee() {
        String ancien = service(1, Map.of(1, "k1")).create(userId);

        UnsubscribeTokenService apresRotation = service(2, Map.of(1, "k1", 2, "k2"));

        assertThat(apresRotation.verify(ancien)).contains(userId);
        assertThat(apresRotation.create(userId).split("\\.")[1]).isEqualTo("2");
    }

    @Test
    void uneSignatureAltereeEstRefusee() {
        UnsubscribeTokenService s = service(1, Map.of(1, "k1"));
        String token = s.create(userId);
        String[] parts = token.split("\\.");
        char last = parts[2].charAt(parts[2].length() - 1);
        String altere = parts[0] + "." + parts[1] + "."
                + parts[2].substring(0, parts[2].length() - 1) + (last == 'A' ? 'B' : 'A');

        assertThat(s.verify(altere)).isEmpty();
    }

    @Test
    void unAutreCompteNePeutPasEtreSubstitue() {
        UnsubscribeTokenService s = service(1, Map.of(1, "k1"));
        String[] parts = s.create(userId).split("\\.");
        String autre = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(UUID.randomUUID().toString().getBytes(StandardCharsets.UTF_8));

        assertThat(s.verify(autre + "." + parts[1] + "." + parts[2])).isEmpty();
    }

    @Test
    void uneCleRetireeDuTrousseauNeVerifiePlus() {
        String ancien = service(1, Map.of(1, "k1")).create(userId);

        assertThat(service(2, Map.of(2, "k2")).verify(ancien)).isEmpty();
    }

    @Test
    void lesJetonsMalFormesSontRefusesSansException() {
        UnsubscribeTokenService s = service(1, Map.of(1, "k1"));

        assertThat(s.verify(null)).isEmpty();
        assertThat(s.verify("")).isEmpty();
        assertThat(s.verify("a.b")).isEmpty();
        assertThat(s.verify("%%%.1.xyz")).isEmpty();
        assertThat(s.verify("YWJj.pasunnombre.xyz")).isEmpty();
        assertThat(s.verify("x".repeat(600))).isEmpty();
    }

    @Test
    void laCleCouranteAbsenteFaitEchouerLeDemarrage() {
        assertThatThrownBy(() -> service(2, Map.of(1, "k1")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("EMAIL_UNSUBSCRIBE_KEY_V2");
        assertThatThrownBy(() -> service(1, Map.of(1, " ")))
                .isInstanceOf(IllegalStateException.class);
    }
}
