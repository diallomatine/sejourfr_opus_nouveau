package com.sejourfr.app.service.analytics;

import com.sejourfr.app.enums.SuiviIndicator;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.EnumMap;
import java.util.Map;
import java.util.Properties;

import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

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
        // D43 : tous les indicateurs datent de la mise en production du 2026-09-28
        // (V043 a V079 appliquees le 2026-09-28 a 00:09, heure de Paris).
        LocalDate miseEnProduction = LocalDate.of(2026, 9, 28);
        for (SuiviIndicator indicator : SuiviIndicator.values()) {
            assertThat(config.measurementStartOf(indicator)).as(indicator.name()).contains(miseEnProduction);
        }
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

    // ------------------------------------------------------------------------
    // Surcharge des dates de debut de mesure : profil dev seulement
    // ------------------------------------------------------------------------

    private static Map<SuiviIndicator, String> surcharge(String date) {
        Map<SuiviIndicator, String> overrides = new EnumMap<>(SuiviIndicator.class);
        overrides.put(SuiviIndicator.DIAGNOSTIC_SUBMITTED, date);
        overrides.put(SuiviIndicator.VISITORS, date);
        return overrides;
    }

    @Test
    @DisplayName("Sans surcharge, les dates restent celles du fichier versionné, profil dev ou non")
    void sansSurchargeLesDatesDuFichier() {
        AnalyticsConfig fichier = AnalyticsConfigLoader.load(1);

        for (boolean dev : new boolean[]{true, false}) {
            AnalyticsConfig config = AnalyticsConfigLoader.withMeasurementStartOverrides(
                    fichier, new EnumMap<>(SuiviIndicator.class), dev);
            assertThat(config).isSameAs(fichier);
            assertThat(config.measurementStartOf(SuiviIndicator.DIAGNOSTIC_SUBMITTED)).contains(LocalDate.of(2026, 9, 28));
            assertThat(config.measurementStartOf(SuiviIndicator.VISITORS)).contains(LocalDate.of(2026, 9, 28));
        }
        assertThat(AnalyticsConfigLoader.withMeasurementStartOverrides(fichier, null, false)).isSameAs(fichier);
    }

    @Test
    @DisplayName("Une surcharge hors profil dev fait échouer le démarrage")
    void surchargeHorsDevRefusee() {
        AnalyticsConfig fichier = AnalyticsConfigLoader.load(1);

        assertThatThrownBy(() -> AnalyticsConfigLoader.withMeasurementStartOverrides(
                fichier, surcharge("2026-01-01"), false))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("profil dev");
    }

    @Test
    @DisplayName("En profil dev, seules les dates surchargées changent, le reste de la config est intact")
    void surchargeEnDev() {
        AnalyticsConfig fichier = AnalyticsConfigLoader.load(1);

        AnalyticsConfig dev = AnalyticsConfigLoader.withMeasurementStartOverrides(
                fichier, surcharge("2026-01-01"), true);

        assertThat(dev.measurementStartOf(SuiviIndicator.DIAGNOSTIC_SUBMITTED)).contains(LocalDate.of(2026, 1, 1));
        assertThat(dev.measurementStartOf(SuiviIndicator.VISITORS)).contains(LocalDate.of(2026, 1, 1));
        assertThat(dev.measurementStartOf(SuiviIndicator.PURCHASES)).contains(LocalDate.of(2026, 9, 28));
        assertThat(dev.measurementStart()).hasSize(SuiviIndicator.values().length);
        assertThat(dev.cohortWindowDays()).isEqualTo(fichier.cohortWindowDays());
        assertThat(dev.civicSubmittedMinAnsweredRatio()).isEqualTo(fichier.civicSubmittedMinAnsweredRatio());
        assertThat(dev.utmSourceGroups()).isEqualTo(fichier.utmSourceGroups());
        // Le fichier charge n'est pas modifie en place.
        assertThat(fichier.measurementStartOf(SuiviIndicator.DIAGNOSTIC_SUBMITTED)).contains(LocalDate.of(2026, 9, 28));
    }

    @Test
    @DisplayName("Une date surchargée illisible est refusée")
    void surchargeIllisible() {
        assertThatThrownBy(() -> AnalyticsConfigLoader.withMeasurementStartOverrides(
                AnalyticsConfigLoader.load(1), surcharge("01/01/2026"), true))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("measurement-start-overrides");
    }

    /** Seul application-dev.yaml declare une surcharge : ni le socle, ni la prod, ni les tests. */
    @Test
    @DisplayName("Aucune surcharge des dates de mesure hors application-dev.yaml")
    void surchargeDeclareeSeulementEnDev() {
        for (String fichier : new String[]{"application.yaml", "application-prod.yaml", "application-test.yaml"}) {
            assertThat(surchargesDeclarees(fichier)).as(fichier).isEmpty();
        }
        assertThat(surchargesDeclarees("application-dev.yaml")).hasSize(SuiviIndicator.values().length);
    }

    private static Map<Object, Object> surchargesDeclarees(String fichier) {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource(fichier));
        Properties props = yaml.getObject();
        Map<Object, Object> declarees = new java.util.HashMap<>();
        if (props == null) return declarees;
        props.forEach((cle, valeur) -> {
            String c = cle.toString();
            if (c.startsWith("sejourfr.analytics.measurement-start-overrides")
                    && !"".equals(String.valueOf(valeur))) {
                declarees.put(cle, valeur);
            }
        });
        return declarees;
    }
}
