package com.sejourfr.app.service.email;

import com.sejourfr.app.enums.EmailType;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** La configuration des emails se charge, ou le demarrage echoue. */
class EmailAutomationConfigLoaderTest {

    private static final String VALIDE = """
            {"emailAutomationConfigVersion":1,
             "engagement":{"dailyCap":1},
             "retry":{"immediateDelaysSeconds":[30,120,300],"maxDeferredAttempts":3,
                      "eventWindowHours":24,"stalePendingMinutes":60},
             "batchSize":200,"retentionMonths":12,
             "scenarios":{
               "NO_PREMIUM_AFTER_7_DAYS":{"minDays":7,"maxDays":10,"minAccessAgeDays":0,"minAccessDurationDays":0},
               "NO_TRAINING_7_DAYS":{"minDays":7,"maxDays":14,"minAccessAgeDays":0,"minAccessDurationDays":0},
               "PREMIUM_INACTIVE_2_DAYS":{"minDays":2,"maxDays":5,"minAccessAgeDays":0,"minAccessDurationDays":0},
               "PREMIUM_ENDING_7_DAYS":{"minDays":2,"maxDays":7,"minAccessAgeDays":3,"minAccessDurationDays":14},
               "PREMIUM_ENDING_2_DAYS":{"minDays":0,"maxDays":2,"minAccessAgeDays":0,"minAccessDurationDays":0},
               "PREMIUM_ENDED":{"minDays":0,"maxDays":3,"minAccessAgeDays":0,"minAccessDurationDays":0}}}
            """;

    private static EmailAutomationConfig parse(String json) throws Exception {
        return EmailAutomationConfigLoader.parse(
                new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)), 1, "test.json");
    }

    @Test
    void laVersionLivreeSeChargeEtCouvreTousLesScenarios() {
        EmailAutomationConfig config = EmailAutomationConfigLoader.load(1);

        assertThat(config.engagement().dailyCap()).isEqualTo(1);
        assertThat(config.retry().immediateDelaysSeconds()).containsExactly(30, 120, 300);
        assertThat(config.retry().maxRowsPerKey()).isEqualTo(4);
        assertThat(config.retentionMonths()).isEqualTo(12);
        assertThat(config.scenarios().keySet())
                .containsExactlyInAnyOrderElementsOf(EmailAutomationConfigLoader.SCENARIOS);
        assertThat(config.window(EmailType.PREMIUM_ENDING_7_DAYS).minAccessAgeDays()).isEqualTo(3);
        assertThat(config.window(EmailType.PREMIUM_ENDING_7_DAYS).minAccessDurationDays()).isEqualTo(14);
    }

    @Test
    void leJsonDeReferenceEstValide() throws Exception {
        assertThat(parse(VALIDE).batchSize()).isEqualTo(200);
    }

    @Test
    void uneVersionInconnueEchoue() {
        assertThatThrownBy(() -> EmailAutomationConfigLoader.load(99))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void uneCleInconnueEchoue() {
        assertThatThrownBy(() -> parse(VALIDE.replace("\"batchSize\":200", "\"batchSize\":200,\"x\":1")))
                .isInstanceOf(Exception.class);
    }

    @Test
    void unScenarioManquantEchoue() {
        String sans = VALIDE.replaceAll(",\\s*\"PREMIUM_ENDED\":\\{[^}]*\\}", "");
        assertThat(sans).doesNotContain("PREMIUM_ENDED");
        assertThatThrownBy(() -> parse(sans))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("PREMIUM_ENDED");
    }

    @Test
    void uneFenetreInverseeEchoue() {
        assertThatThrownBy(() -> parse(VALIDE.replace("\"minDays\":7,\"maxDays\":14", "\"minDays\":14,\"maxDays\":7")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("NO_TRAINING_7_DAYS");
    }

    @Test
    void unPlafondNulEchoue() {
        assertThatThrownBy(() -> parse(VALIDE.replace("\"dailyCap\":1", "\"dailyCap\":0")))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void unDelaiNegatifEchoue() {
        assertThatThrownBy(() -> parse(VALIDE.replace("[30,120,300]", "[30,-1]")))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void unTypeNonScenarioEchoue() {
        assertThatThrownBy(() -> parse(VALIDE.replace("\"NO_TRAINING_7_DAYS\"", "\"WELCOME\"")))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void uneDureeMinimaleNegativeEchoue() {
        assertThatThrownBy(() -> parse(VALIDE.replace("\"minAccessDurationDays\":14", "\"minAccessDurationDays\":-1")))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void uneDureeMinimaleAbsenteEchoue() {
        assertThatThrownBy(() -> parse(VALIDE.replace(",\"minAccessDurationDays\":14", "")))
                .isInstanceOf(Exception.class);
    }
}
