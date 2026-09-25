package com.sejourfr.app.service.analytics;

import com.sejourfr.app.enums.SuiviIndicator;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** La configuration d'analytics se charge, ou le demarrage echoue. */
class AnalyticsConfigLoaderTest {

    private static final String DEBUTS = """
            "measurementStart":{"VISITORS":"2026-08-21","ACQUISITION_SOURCES":"2026-08-21",
              "DIAGNOSTIC_SUBJECT_VIEWED":null,"DIAGNOSTIC_SUBMITTED":null,"ACCOUNT_ATTACHED":null,
              "REPORT_VIEWED":null,"PLAN_VIEWED":null,"PLAN_UNLOCK_CLICKED":null,"PURCHASES":null,
              "PURCHASE_ORIGIN":null,"REVENUE_BREAKDOWN":null,"REFUNDS":null,"SIGNUP_CONTEXT":null,
              "SIGNUP_PLATFORM_DETAIL":null}""";

    private static String json(String timezone, String groupes, String debuts) {
        return """
                {"analyticsConfigVersion":1,"timezone":"%s","cohortWindowDays":14,"claimTokenTtlDays":2,
                 "civicSubmittedMinAnsweredRatio":0.8,"runReuseWindowHours":24,
                 "purchaseIntentTtlHours":24,"anonymousIdTtlDays":395,"rawEventRetentionDays":395,
                 "purgeBatchSize":1000,
                 "ingestion":{"maxBatchSize":50,"clockSkewToleranceMinutes":10,"maxEventAgeHours":168,
                   "rateLimit":{"perIpBurst":{"max":120,"windowSeconds":600},
                                "perIpDaily":{"max":3000,"windowSeconds":86400},
                                "perAnonymousIdBurst":{"max":60,"windowSeconds":600},
                                "perAnonymousIdDaily":{"max":1000,"windowSeconds":86400}}},
                 "diagnosticRunRateLimit":{"perIpBurst":{"max":30,"windowSeconds":600},
                                "perIpDaily":{"max":300,"windowSeconds":86400},
                                "perAnonymousIdBurst":{"max":20,"windowSeconds":600},
                                "perAnonymousIdDaily":{"max":100,"windowSeconds":86400}},
                 "utmSourceGroups":%s,"utmSourceFallbackGroup":"autre",
                 %s}
                """.formatted(timezone, groupes, debuts);
    }

    private static final String GROUPES = """
            {"instagram":["instagram","ig"],"tiktok":["tiktok","tt"],"facebook":["facebook","fb","meta"],
             "direct":["direct"]}""";

    private static AnalyticsConfig parse(String json) throws Exception {
        return AnalyticsConfigLoader.parse(
                new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)), 1, "test.json");
    }

    @Test
    @DisplayName("La version livrée se charge, avec les arbitrages du propriétaire")
    void laVersionLivreeSeCharge() {
        AnalyticsConfig config = AnalyticsConfigLoader.load(1);

        assertThat(config.rawEventRetentionDays()).isEqualTo(395);
        assertThat(config.anonymousIdTtlDays()).isEqualTo(395);
        assertThat(config.cohortWindowDays()).isEqualTo(14);
        assertThat(config.claimTokenTtlDays()).isEqualTo(2);
        assertThat(config.runReuseWindowHours()).isEqualTo(24);
        assertThat(config.civicSubmittedMinAnsweredRatio()).isEqualTo(0.8);
        assertThat(config.purchaseIntentTtlHours()).isEqualTo(24);
        assertThat(config.ingestion().maxBatchSize()).isEqualTo(50);
        assertThat(config.ingestion().clockSkewToleranceMinutes()).isEqualTo(10);
        assertThat(config.diagnosticRunRateLimit().perIpBurst().max()).isEqualTo(30);
        assertThat(config.diagnosticRunRateLimit().perAnonymousIdDaily().max()).isEqualTo(100);
        assertThat(config.claimTokenTtl()).isEqualTo(java.time.Duration.ofDays(2));
        // Q16 : un indicateur pas encore mesure n'a pas de date, jamais une date inventee.
        assertThat(config.measurementStartOf(SuiviIndicator.DIAGNOSTIC_SUBMITTED)).isEmpty();
        assertThat(config.measurementStartOf(SuiviIndicator.VISITORS)).contains(LocalDate.of(2026, 8, 21));
    }

    /** Scenario 17 : {@code ig} se range sous instagram, a la lecture. */
    @Test
    @DisplayName("Les sources déclarées se regroupent, le reste tombe dans « autre »")
    void regroupementDesSources() {
        AnalyticsConfig config = AnalyticsConfigLoader.load(1);

        assertThat(config.groupOfSource("IG")).isEqualTo("instagram");
        assertThat(config.groupOfSource(" tt ")).isEqualTo("tiktok");
        assertThat(config.groupOfSource("meta")).isEqualTo("facebook");
        assertThat(config.groupOfSource("whatsapp")).isEqualTo("autre");
        assertThat(config.groupOfSource(null)).isEqualTo("autre");
    }

    @Test
    @DisplayName("Le JSON de référence est valide")
    void jsonDeReferenceValide() throws Exception {
        assertThat(parse(json("Europe/Paris", GROUPES, DEBUTS)).purgeBatchSize()).isEqualTo(1000);
    }

    @Test
    @DisplayName("Une version inconnue échoue au démarrage")
    void versionInconnue() {
        assertThatThrownBy(() -> AnalyticsConfigLoader.load(99)).isInstanceOf(IllegalStateException.class);
    }

    /** FenetreMesure.PARIS fait autorite : la config ne peut que le confirmer. */
    @Test
    @DisplayName("Un autre fuseau qu'Europe/Paris est refusé")
    void fuseauImpose() {
        assertThatThrownBy(() -> parse(json("UTC", GROUPES, DEBUTS)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("timezone");
    }

    @Test
    @DisplayName("Une source rangée dans deux groupes est refusée")
    void sourceEnDoubleRefusee() {
        String groupes = """
                {"instagram":["instagram","ig"],"autre-reseau":["ig"]}""";
        assertThatThrownBy(() -> parse(json("Europe/Paris", groupes, DEBUTS)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("deux groupes");
    }

    @Test
    @DisplayName("Un indicateur sans entrée de début de mesure est refusé (null est permis, l'absence non)")
    void indicateurManquant() {
        String debuts = """
                "measurementStart":{"VISITORS":"2026-08-21"}""";
        assertThatThrownBy(() -> parse(json("Europe/Paris", GROUPES, debuts)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("measurementStart");
    }

    @Test
    @DisplayName("Une date de début illisible est refusée")
    void dateIllisible() {
        String debuts = DEBUTS.replace("\"VISITORS\":\"2026-08-21\"", "\"VISITORS\":\"21/08/2026\"");
        assertThatThrownBy(() -> parse(json("Europe/Paris", GROUPES, debuts)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("VISITORS");
    }

    @Test
    @DisplayName("Sans garde-fous des routes diagnostic_run, le démarrage échoue")
    void garde_fousDiagnosticRunObligatoires() {
        String json = json("Europe/Paris", GROUPES, DEBUTS);
        String sans = json.substring(0, json.indexOf("\"diagnosticRunRateLimit\""))
                + json.substring(json.indexOf("\"utmSourceGroups\""));
        // Refusee des la lecture (propriete de creation manquante) : jamais un defaut muet.
        assertThatThrownBy(() -> parse(sans)).hasMessageContaining("diagnosticRunRateLimit");
    }

    @Test
    @DisplayName("Une clé inconnue est refusée")
    void cleInconnue() {
        String avecIntrus = json("Europe/Paris", GROUPES, DEBUTS).replace("\"purgeBatchSize\":1000,",
                "\"purgeBatchSize\":1000,\"rawEventRetentionDay\":760,");
        assertThatThrownBy(() -> parse(avecIntrus)).isInstanceOf(Exception.class);
    }

    @Test
    @DisplayName("Une durée nulle est refusée")
    void dureeNulle() {
        String zero = json("Europe/Paris", GROUPES, DEBUTS).replace("\"rawEventRetentionDays\":395",
                "\"rawEventRetentionDays\":0");
        assertThatThrownBy(() -> parse(zero))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("rawEventRetentionDays");
    }

    @Test
    @DisplayName("Seuil civique hors ]0, 1] : le démarrage échoue")
    void seuilCiviqueHorsBornes() {
        for (String seuil : new String[]{"0", "1.2", "-0.5"}) {
            String json = json("Europe/Paris", GROUPES, DEBUTS).replace("\"civicSubmittedMinAnsweredRatio\":0.8",
                    "\"civicSubmittedMinAnsweredRatio\":" + seuil);
            assertThatThrownBy(() -> parse(json))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("civicSubmittedMinAnsweredRatio");
        }
    }
}
