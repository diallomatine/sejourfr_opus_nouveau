package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SubscriptionSource;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Bug Q11 : le mobile envoie {@code amountCents} / {@code currency}, le backend
 * n'attendait que {@code rawPrice} / {@code currencyCode} — Jackson ignorait le
 * champ en silence. Les deux formes se lisent désormais, et l'intention d'achat
 * aussi.
 */
class VerifyReceiptRequestJsonTest {

    private final JsonMapper mapper = JsonMapper.builder().build();

    @Test
    @DisplayName("La charge utile réelle du mobile est lue : amountCents, currency, purchaseIntentId")
    void chargeUtileDuMobile() {
        VerifyReceiptRequest r = mapper.readValue("""
                {"source":"GOOGLE","receipt":"tok","productId":"integral_pass_2m",
                 "amountCents":2999,"currency":"EUR","purchaseIntentId":"a3f4b1c2-0000-4000-8000-000000000001"}
                """, VerifyReceiptRequest.class);

        assertThat(r.source()).isEqualTo(SubscriptionSource.GOOGLE);
        assertThat(r.amountCents()).isEqualTo(2999L);
        assertThat(r.currency()).isEqualTo("EUR");
        assertThat(r.purchaseIntentId()).isEqualTo("a3f4b1c2-0000-4000-8000-000000000001");
        assertThat(r.rawPrice()).isNull();
    }

    @Test
    @DisplayName("L'ancienne forme rawPrice / currencyCode reste lue")
    void ancienneForme() {
        VerifyReceiptRequest r = mapper.readValue("""
                {"source":"APPLE","receipt":"jws","productId":"p","rawPrice":9.99,"currencyCode":"EUR"}
                """, VerifyReceiptRequest.class);

        assertThat(r.rawPrice()).isEqualTo(9.99);
        assertThat(r.currencyCode()).isEqualTo("EUR");
        assertThat(r.amountCents()).isNull();
        assertThat(r.purchaseIntentId()).isNull();
    }
}
