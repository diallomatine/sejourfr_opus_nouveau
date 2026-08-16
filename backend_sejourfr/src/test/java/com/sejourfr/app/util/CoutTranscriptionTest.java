package com.sejourfr.app.util;

import com.sejourfr.app.config.EvaluationConfigFixture;
import com.sejourfr.app.config.OpenAiProperties;
import com.sejourfr.app.config.TarifsLlm;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Properties;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FIGE ce que coute une transcription Whisper — et surtout la <b>fin de
 * l'arrondi au centime superieur</b>, dernier endroit du depot qui le
 * pratiquait.
 *
 * <p>Aucun appel reseau : de l'arithmetique sur une duree et un tarif.
 */
class CoutTranscriptionTest {

    /** whisper-1, releve le 2026-08-16 : 0,006 USD la minute d'audio. */
    private static final CoutTranscription WHISPER = new CoutTranscription(0.006);

    /** {@code ${VAR:defaut}} — la forme qui rend une cle surchargeable sans editer le yaml. */
    private static final Pattern PLACEHOLDER =
        Pattern.compile("^\\$\\{[A-Za-z_][A-Za-z0-9_]*:.*}$");

    // -------------------------------------------------------- fin de l'arrondi

    @Test
    void l_audio_median_du_depot_est_facture_a_son_prix() {
        // 95 s = 0,0095 $. L'ancien calcul arrondissait au centime SUPERIEUR et
        // persistait 1 centime, soit ~5 % de trop.
        Integer micro = WHISPER.microDollars(95);

        assertThat(micro).isEqualTo(9_500);
        assertThat(micro)
            .as("l'ancien Math.ceil au centime aurait rendu l'equivalent de 10 000 micro-dollars")
            .isLessThan(10_000);
    }

    @Test
    void une_transcription_tres_courte_ne_coute_plus_un_centime_entier() {
        // 3 s = 0,0003 $. L'ancien calcul facturait 1 centime : 33 fois le prix.
        assertThat(WHISPER.microDollars(3)).isEqualTo(300);
    }

    @Test
    void un_audio_long_reste_juste() {
        // 5 min, le plafond d'une submission EO : 0,03 $ exactement. Sur ce cas
        // l'ancien arrondi tombait juste — la distorsion croit quand la duree
        // diminue, elle ne disparait jamais des durees courtes.
        assertThat(WHISPER.microDollars(300)).isEqualTo(30_000);
    }

    @Test
    void deux_transcriptions_s_additionnent_sans_gonfler_la_facture() {
        int un = WHISPER.microDollars(95);
        int deux = WHISPER.microDollars(95);

        assertThat(un + deux).isEqualTo(19_000);
    }

    // ------------------------------------------------------------ cas limites

    @Test
    void aucune_duree_ne_donne_aucun_cout() {
        // null, pas 0 : un cout de 0 persiste se lirait « gratuit », ce qui est
        // une affirmation, alors qu'on n'a rien mesure.
        assertThat(WHISPER.microDollars(null)).isNull();
        assertThat(WHISPER.microDollars(0)).isNull();
        assertThat(WHISPER.microDollars(-10)).isNull();
    }

    @Test
    void sans_tarif_configure_aucun_montant_n_est_invente() {
        assertThat(new CoutTranscription(0).microDollars(120)).isNull();
        assertThat(new CoutTranscription(-1).microDollars(120)).isNull();
    }

    @Test
    void une_duree_d_une_seconde_reste_mesurable() {
        // La granularite du micro-dollar tient toute la gamme : meme la plus
        // courte transcription possible vaut encore 100 unites.
        assertThat(WHISPER.microDollars(1)).isEqualTo(100);
    }

    // ----------------------------------- la regle d'arrondi est bien PARTAGEE

    @Test
    void la_regle_d_arrondi_est_la_meme_que_pour_un_appel_llm() {
        // Deux formules distinctes (a la minute / au token), une seule unite et
        // un seul arrondi : MicroDollars. Deux copies de cette regle auraient
        // fini par diverger — c'est le motif qui a fait supprimer les 11
        // `estimateCostCents`.
        assertThat(MicroDollars.depuisUsd(0.0095)).isEqualTo(WHISPER.microDollars(95));

        // Arrondi au SUPERIEUR des deux cotes, jamais a l'inferieur.
        assertThat(MicroDollars.depuisUsd(0.0000001)).isEqualTo(1);
        assertThat(unAppelLlm().microDollars(1, null, 0))
            .as("1 token a 0,22 $/1M vaut 0,22 micro-dollar, arrondi a 1")
            .isEqualTo(1);
        assertThat(new CoutTranscription(0.006).microDollars(1)).isEqualTo(100);
    }

    @Test
    void un_montant_nul_ou_absurde_ne_produit_jamais_de_cout() {
        assertThat(MicroDollars.depuisUsd(0)).isNull();
        assertThat(MicroDollars.depuisUsd(-1)).isNull();
        assertThat(MicroDollars.depuisUsd(Double.NaN)).isNull();
        assertThat(MicroDollars.depuisUsd(Double.POSITIVE_INFINITY)).isNull();
    }

    // ------------------------------------------- le tarif vit en configuration

    @Test
    void le_tarif_a_la_minute_est_surchargeable_par_variable_d_environnement() {
        Properties yaml = EvaluationConfigFixture.yamlBrut();
        String brut = yaml.getProperty("sejourfr.openai.whisper.cost-per-minute-usd");

        assertThat(brut)
            .as("le tarif de transcription doit etre declare dans application.yaml")
            .isNotNull();
        assertThat(brut.strip())
            .as("le tarif de transcription doit rester surchargeable par variable "
                + "d'environnement (forme ${VAR:defaut}) : il voyage AVEC le modele, dans la "
                + "meme source, et le cout est PERSISTE dans transcriptions.cout_micro_usd.")
            .matches(PLACEHOLDER.asMatchPredicate());
    }

    @Test
    void le_defaut_du_yaml_et_celui_du_pojo_ne_divergent_pas() {
        Properties yaml = EvaluationConfigFixture.yamlBrut();
        String brut = yaml.getProperty("sejourfr.openai.whisper.cost-per-minute-usd").strip();
        double defautYaml = Double.parseDouble(
            brut.substring(brut.indexOf(':') + 1, brut.length() - 1));

        assertThat(new OpenAiProperties().getWhisper().getCostPerMinuteUsd())
            .as("un defaut POJO different du defaut YAML fait facturer deux prix selon "
                + "la facon dont la configuration est chargee")
            .isEqualTo(defautYaml);
        assertThat(defautYaml).isGreaterThan(0.0).isLessThan(1.0);
    }

    private static CoutAppelLlm unAppelLlm() {
        TarifsLlm tarifs = new TarifsLlm() {
            @Override public double getCostPerMillionInputTokens() { return 0.22; }
            @Override public double getCostPerMillionOutputTokens() { return 0.66; }
        };
        return new CoutAppelLlm(tarifs,
            Clock.fixed(Instant.parse("2026-08-16T14:00:00Z"), ZoneOffset.UTC));
    }
}
