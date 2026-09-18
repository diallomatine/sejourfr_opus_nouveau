package com.sejourfr.app.service.journey;

import com.sejourfr.app.config.TcfJourneyProperties;
import com.sejourfr.app.enums.JourneyLotSelectionStrategy;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * La configuration du parcours se charge, ou le demarrage echoue.
 *
 * <p>🛑 Ce test est le garde-fou de l'invariant « <b>aucune valeur de file en
 * dur</b> » : si quelqu'un remet un plafond dans le Java, il n'aura pas d'entree
 * ici et la config cessera d'etre l'autorite sans que rien ne le signale.
 *
 * <p>Les fichiers {@code v900} / {@code v901} / {@code v902} vivent dans
 * {@code src/test/resources/plan/} : ce sont des <b>configurations volontairement
 * fausses</b>, qui n'existent que pour prouver que le chargeur refuse.
 */
class TcfJourneyConfigLoaderTest {

    /** La version reellement servie en production, defaut de {@code application.yaml}. */
    private static final int VERSION_LIVREE = 2;

    @Test
    @DisplayName("La version livree se charge et porte toutes ses valeurs")
    void laVersionLivreeSeCharge() {
        TcfJourneyConfig config = TcfJourneyConfigLoader.load(VERSION_LIVREE);

        assertThat(config.journeyConfigVersion()).isEqualTo(VERSION_LIVREE);
        assertThat(config.maxPrioritiesPerLot()).isPositive();
        assertThat(config.trainSeriesQuota()).isPositive();
        assertThat(config.trainSeriesFallbackQuota()).isPositive();
        assertThat(config.lotSelectionStrategy())
                .isEqualTo(JourneyLotSelectionStrategy.TOP_SEVERITY);
        assertThat(config.display().recentCompletedVisible()).isNotNegative();
        assertThat(config.display().upcomingVisible()).isPositive();
    }

    /**
     * 🛑 <b>Le defaut du YAML et la version reellement livree ne peuvent pas
     * diverger.</b> Sans ce verrou, bumper le fichier sans bumper
     * {@code application.yaml} aurait fait tourner la production sur l'ancienne
     * semantique de {@code trainSeriesQuota} — « series terminees » au lieu de
     * « series reussies » — sans que rien n'echoue.
     */
    @Test
    @DisplayName("Le defaut de application.yaml pointe la version livree")
    void leDefautDuYamlPointeLaVersionLivree() {
        assertThat(new TcfJourneyProperties().getConfigVersion()).isEqualTo(VERSION_LIVREE);
    }

    /**
     * R2 — le lot retient <b>3</b> priorites par epreuve. D-16 clot une etape de
     * comprehension apres <b>2</b> series <b>reussies</b>, ou <b>4</b> series
     * <b>terminees</b>. Ces trois chiffres sont ceux que le proprietaire a
     * tranches : les verrouiller ici evite qu'un reglage d'affichage les deplace
     * par ricochet.
     */
    @Test
    @DisplayName("Les trois valeurs arbitrees sont celles de D-16 et D-20")
    void lesTroisValeursArbitreesSontCellesDesArbitrages() {
        TcfJourneyConfig config = TcfJourneyConfigLoader.load(VERSION_LIVREE);

        assertThat(config.maxPrioritiesPerLot()).isEqualTo(3);
        assertThat(config.trainSeriesQuota()).isEqualTo(2);
        assertThat(config.trainSeriesFallbackQuota()).isEqualTo(4);
    }

    /**
     * 🛑 <b>v1 reste chargeable, et un retour arriere reste une variable
     * d'environnement</b> — jamais une migration. Elle porte
     * {@code trainSeriesFallbackQuota = trainSeriesQuota = 2}, et comme les
     * series reussies sont toujours un sous-ensemble des terminees, « 2 reussies
     * OU 2 terminees » <b>est</b> mot pour mot l'ancienne regle de D-5
     * (« 2 series terminees »).
     */
    @Test
    @DisplayName("v1 se charge encore, et y redit exactement l'ancienne regle D-5")
    void laVersionPrecedenteResteChargeable() {
        TcfJourneyConfig v1 = TcfJourneyConfigLoader.load(1);

        assertThat(v1.journeyConfigVersion()).isEqualTo(1);
        assertThat(v1.trainSeriesQuota()).isEqualTo(2);
        assertThat(v1.trainSeriesFallbackQuota()).isEqualTo(v1.trainSeriesQuota());
    }

    /** Une version absente ne demarre pas en silence sur des valeurs par defaut. */
    @Test
    @DisplayName("Une version inconnue fait echouer le demarrage")
    void uneVersionInconnueFaitEchouerLeDemarrage() {
        assertThatThrownBy(() -> TcfJourneyConfigLoader.load(999))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("tcf-journey-config-v999.json");
    }

    /**
     * Le fichier dit {@code journeyConfigVersion: 1} alors qu'on demande la 900 :
     * charger quand meme servirait une <b>autre</b> semantique que celle que le
     * code attend.
     */
    @Test
    @DisplayName("Une version DISCORDANTE dans le fichier fait echouer le demarrage")
    void uneVersionDiscordanteFaitEchouerLeDemarrage() {
        assertThatThrownBy(() -> TcfJourneyConfigLoader.load(900))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("journeyConfigVersion=1")
                .hasMessageContaining("version demandee est 900");
    }

    /**
     * Une cle inconnue est une <b>faute de frappe ou une valeur qu'on croit
     * active</b> : {@code trainSkillQuota} n'entre pas dans ce fichier (le quota
     * d'expression <b>est</b> {@code LearningPlanStep.PROMPTS_PAR_ETAPE}, D-5).
     * L'ignorer aurait laisse quelqu'un croire l'avoir reglee.
     */
    @Test
    @DisplayName("Une cle INCONNUE fait echouer le demarrage")
    void uneCleInconnueFaitEchouerLeDemarrage() {
        assertThatThrownBy(() -> TcfJourneyConfigLoader.load(901))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("tcf-journey-config-v901.json");
    }

    /**
     * D-16 — l'echappatoire est un <b>filet</b>, pas la regle. Sous le quota de
     * reussite, elle closerait toujours la premiere et « 2 series reussies » ne
     * voudrait plus rien dire.
     */
    @Test
    @DisplayName("Une echappatoire INFERIEURE au quota de reussite fait echouer le demarrage")
    void uneEchappatoireSousLeQuotaFaitEchouerLeDemarrage() {
        assertThatThrownBy(() -> TcfJourneyConfigLoader.load(902))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("trainSeriesFallbackQuota=2")
                .hasMessageContaining("trainSeriesQuota=4");
    }
}
