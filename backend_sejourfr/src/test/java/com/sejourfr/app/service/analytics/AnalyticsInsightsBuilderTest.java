package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AdminAnalyticsResponse;
import com.sejourfr.app.util.TrafficSource;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les trois seuils d'honnetete, et ce qui se passe en dessous.
 *
 * <p>Sur un petit volume, « TikTok convertit le mieux » n'est pas une
 * observation, c'est du bruit : un seul paiement de plus renverse le classement.
 * Ce qui est verrouille ici, c'est que sous le seuil on <b>enonce les chiffres
 * et on dit pourquoi on s'arrete la</b> — on masque une conclusion, jamais une
 * donnee.
 */
class AnalyticsInsightsBuilderTest {

    private static final Pattern BALISE = Pattern.compile("</?([a-zA-Z0-9]+)[^>]*>");

    private final AnalyticsInsightsBuilder builder = new AnalyticsInsightsBuilder();

    @Test
    @DisplayName("Sous 10 diagnostics commencés, aucune étape n'est désignée comme celle qui fuit")
    void sousLeSeuilAucuneFuiteDesignee() {
        AdminAnalyticsResponse.Metrics total = metrics(200, 9, 3, 0, 0);
        List<AdminAnalyticsResponse.Insight> insights =
                builder.build(total, AdminAnalyticsResponse.Metrics.ZERO, List.of(), abandon(6));

        assertThat(texte(insights)).contains(
                "Sous " + AnalyticsInsightsBuilder.MIN_SIGNUPS_POUR_DESIGNER_UNE_FUITE
                        + " diagnostics commencés");
        // Les chiffres restent dits : on masque la conclusion, pas la donnee.
        assertThat(texte(insights)).contains("200 visiteurs");
    }

    @Test
    @DisplayName("Sous 20 inscrits, les provenances ne se comparent pas")
    void sousLeSeuilAucuneComparaisonDeReseaux() {
        AdminAnalyticsResponse.Metrics total = metrics(500, 40, 19, 5, 5);
        List<AdminAnalyticsResponse.Insight> insights = builder.build(
                total, AdminAnalyticsResponse.Metrics.ZERO,
                List.of(source("tiktok", 15, 5), source("instagram", 4, 0)), abandon(30));

        assertThat(texte(insights)).contains(
                "au moins " + AnalyticsInsightsBuilder.MIN_SIGNUPS_POUR_COMPARER_LES_RESEAUX
                        + " inscrits pour comparer");
        assertThat(texte(insights)).doesNotContain("convertit le mieux");
    }

    /**
     * Un total eleve n'empeche pas un reseau d'y peser trois comptes : le seuil
     * par reseau existe pour ca.
     */
    @Test
    @DisplayName("Un réseau à moins de 5 inscrits n'est jamais désigné")
    void unReseauTropPetitNEstJamaisDesigne() {
        AdminAnalyticsResponse.Metrics total = metrics(900, 60, 40, 12, 6);
        List<AdminAnalyticsResponse.Insight> insights = builder.build(
                total, AdminAnalyticsResponse.Metrics.ZERO,
                List.of(source("tiktok", 4, 4), source("instagram", 36, 2)), abandon(50));

        assertThat(texte(insights)).contains("Instagram").contains("convertit le mieux");
        assertThat(texte(insights)).doesNotContain("TikTok");
    }

    /**
     * 🛑 Trier sur le taux seul hisserait en tete une provenance a 1 inscrit et
     * 1 payant (100 %), qui n'a rien demontre.
     */
    @Test
    @DisplayName("Le classement met les payants d'abord, le taux ensuite — inconnu toujours dernier")
    void classementPayantsPuisTaux() {
        List<AdminAnalyticsResponse.SourceRow> rows = new ArrayList<>(List.of(
                source(TrafficSource.UNKNOWN, 300, 30),
                source("instagram", 1, 1),
                source("tiktok", 100, 10),
                source("facebook", 50, 10)));
        rows.sort(AnalyticsInsightsBuilder.CLASSEMENT);

        assertThat(rows.stream().map(AdminAnalyticsResponse.SourceRow::id).toList())
                // facebook et tiktok ont 10 payants : facebook convertit mieux.
                .containsExactly("facebook", "tiktok", "instagram", TrafficSource.UNKNOWN);
    }

    @Test
    @DisplayName("Au plus quatre lectures, jamais davantage")
    void auPlusQuatre() {
        AdminAnalyticsResponse.Metrics total = metrics(900, 120, 60, 20, 10);
        AdminAnalyticsResponse.Metrics prev = metrics(600, 90, 30, 10, 4);
        List<AdminAnalyticsResponse.Insight> insights = builder.build(
                total, prev, List.of(source("tiktok", 40, 8), source("instagram", 20, 2)),
                abandon(100));

        assertThat(insights).hasSizeLessThanOrEqualTo(AnalyticsInsightsBuilder.MAX_INSIGHTS);
        assertThat(insights).isNotEmpty();
    }

    /**
     * La console assainit deja le HTML — on ne s'en remet pas a elle : on n'emet
     * rien d'autre, et la regle devient vraie par construction.
     */
    @Test
    @DisplayName("Le HTML servi ne contient que <b>, <strong>, <em> et <i>")
    void htmlBorne() {
        AdminAnalyticsResponse.Metrics total = metrics(900, 120, 60, 20, 10);
        AdminAnalyticsResponse.Metrics prev = metrics(600, 90, 30, 10, 4);
        List<AdminAnalyticsResponse.Insight> insights = builder.build(
                total, prev, List.of(source("tiktok", 40, 8)), abandon(100));

        for (AdminAnalyticsResponse.Insight insight : insights) {
            Matcher matcher = BALISE.matcher(insight.html());
            while (matcher.find()) {
                assertThat(matcher.group(1).toLowerCase())
                        .isIn("b", "strong", "em", "i");
            }
            assertThat(insight.tone()).isIn("OK", "WARN", "BAD", "NEUTRAL");
        }
    }

    @Test
    @DisplayName("Une période sans rien du tout le dit, au lieu d'inventer un constat")
    void periodeVide() {
        List<AdminAnalyticsResponse.Insight> insights = builder.build(
                AdminAnalyticsResponse.Metrics.ZERO, AdminAnalyticsResponse.Metrics.ZERO,
                List.of(), List.of());

        assertThat(insights.get(0).html()).isEqualTo("Aucune visite mesurée sur cette période.");
        assertThat(insights.get(0).tone()).isEqualTo("NEUTRAL");
    }

    // ------------------------------------------------------------------------

    private static String texte(List<AdminAnalyticsResponse.Insight> insights) {
        return String.join(" ",
                insights.stream().map(AdminAnalyticsResponse.Insight::html).toList());
    }

    private static AdminAnalyticsResponse.Metrics metrics(long v, long start, long sig,
                                                          long prem, long pay) {
        return new AdminAnalyticsResponse.Metrics(
                v, 0, 0, start, 0, 0, 0, 0, 0, 0, sig, prem, 0, pay, 0);
    }

    private static AdminAnalyticsResponse.SourceRow source(String id, long sig, long pay) {
        return new AdminAnalyticsResponse.SourceRow(id,
                com.sejourfr.app.util.AnalyticsLibelles.source(id),
                new AdminAnalyticsResponse.Metrics(
                        sig * 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, sig, 0, 0, pay, 0));
    }

    /**
     * Une seule marche qui perd, pour que « la pire » soit sans ambiguite.
     * {@code base} est une CLE de metrique : le denominateur se lit sur le
     * vecteur, jamais sur la ligne.
     */
    private static List<AdminAnalyticsResponse.AbandonRow> abandon(long perdus) {
        return List.of(new AdminAnalyticsResponse.AbandonRow(
                "DURING_EO", "Pendant l'oral", "L'oral est commencé mais jamais rendu.",
                perdus / 2, "start", true));
    }
}
