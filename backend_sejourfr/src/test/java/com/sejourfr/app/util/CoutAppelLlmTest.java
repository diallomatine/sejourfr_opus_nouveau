package com.sejourfr.app.util;

import com.sejourfr.app.config.TarifsLlm;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FIGE ce que coute un appel LLM — la grille a trois tarifs, les heures pleines,
 * et surtout la <b>fin de l'arrondi au centime superieur</b>.
 *
 * <p>Aucun appel reseau : ces tests sont de l'arithmetique sur des tarifs
 * simules et une horloge figee. C'est justement pour cela que l'horloge est un
 * parametre du calcul et non une lecture de {@code Instant.now()} enfouie dans
 * onze clients.
 */
class CoutAppelLlmTest {

    /** La grille DeepSeek-V4-Flash en vigueur depuis le 2026-08-16 16:00 UTC. */
    private static final TarifsLlm FLASH = tarifs(0.22, 0.007, 0.66, 2.0,
        "01:00-04:00,06:00-10:00");

    /** Un fournisseur sans cache ni heures pleines — le cas de repli. */
    private static final TarifsLlm SIMPLE = tarifs(2.50, 0.0, 15.00, 1.0, "");

    private static final Instant CREUSE = Instant.parse("2026-08-16T14:00:00Z");
    private static final Instant PLEINE = Instant.parse("2026-08-16T02:00:00Z");

    private static TarifsLlm tarifs(double entree, double cache, double sortie,
                                    double multiplicateur, String plages) {
        return new TarifsLlm() {
            @Override public double getCostPerMillionInputTokens() { return entree; }
            @Override public double getCostPerMillionOutputTokens() { return sortie; }
            @Override public double getCostPerMillionCachedInputTokens() { return cache; }
            @Override public double getPeakMultiplier() { return multiplicateur; }
            @Override public String getPeakUtcRanges() { return plages; }
        };
    }

    private static CoutAppelLlm a(TarifsLlm t, Instant quand) {
        return new CoutAppelLlm(t, Clock.fixed(quand, ZoneOffset.UTC));
    }

    // ------------------------------------------------------ fin de l'arrondi

    @Test
    void une_micro_analyse_ne_coute_plus_un_centime_entier() {
        // Le cas mesure : ~7 000 tokens d'entree, 200 de sortie. L'ancien calcul
        // arrondissait au cent SUPERIEUR, donc persistait 1 centime = 10 000
        // micro-dollars, soit ~6 fois le prix reel.
        Integer micro = a(FLASH, CREUSE).microDollars(7_000, null, 200);

        assertThat(micro).isNotNull();
        assertThat(micro / 1_000_000.0)
            .as("7000 x 0,22/1M + 200 x 0,66/1M")
            .isCloseTo(0.001672, org.assertj.core.data.Offset.offset(1e-6));
        assertThat(micro)
            .as("l'ancien Math.ceil au centime aurait rendu l'equivalent de 10 000 micro-dollars")
            .isLessThan(10_000);
    }

    @Test
    void deux_appels_s_additionnent_sans_gonfler_la_facture() {
        // C'est le vrai degat de l'arrondi au centime : une correction, c'est
        // souvent DEUX appels (evaluation + version ciblee, ou analyse + plan
        // d'action), et chacun etait arrondi separement.
        int un = a(FLASH, CREUSE).microDollars(7_000, null, 200);
        int deux = a(FLASH, CREUSE).microDollars(7_000, null, 200);

        assertThat(un + deux).isLessThan(10_000);
    }

    // ------------------------------------------------------------ le cache

    @Test
    void les_tokens_servis_par_le_cache_sont_factures_au_tarif_du_cache() {
        // 6 000 des 7 000 tokens d'entree viennent du cache : 31x moins chers.
        int avecCache = a(FLASH, CREUSE).microDollars(7_000, 6_000, 200);
        int sansCache = a(FLASH, CREUSE).microDollars(7_000, null, 200);

        assertThat(avecCache).isLessThan(sansCache);
        assertThat(avecCache / 1_000_000.0)
            .as("1000 x 0,22/1M + 6000 x 0,007/1M + 200 x 0,66/1M")
            .isCloseTo(0.000394, org.assertj.core.data.Offset.offset(1e-6));
    }

    @Test
    void un_decoupage_absent_facture_TOUT_au_plein_tarif() {
        // Hypothese PRUDENTE : on surestime, jamais l'inverse. Un fournisseur
        // qui ne rapporte pas son cache ne doit pas nous faire croire a une
        // depense plus basse que la reelle.
        assertThat(a(FLASH, CREUSE).microDollars(7_000, null, 200))
            .isEqualTo(a(FLASH, CREUSE).microDollars(7_000, 0, 200));
    }

    @Test
    void un_fournisseur_sans_tarif_de_cache_facture_ses_tokens_caches_au_plein_tarif() {
        // 0 = non declare. Le calcul ne doit pas les rendre gratuits.
        assertThat(a(SIMPLE, CREUSE).microDollars(1_000, 900, 100))
            .isEqualTo(a(SIMPLE, CREUSE).microDollars(1_000, null, 100));
    }

    @Test
    void un_cache_annonce_plus_grand_que_l_entree_ne_fabrique_pas_de_credit() {
        // Garde-fou : une reponse incoherente ne doit jamais produire un cout
        // negatif ni une entree comptee deux fois.
        Integer borne = a(FLASH, CREUSE).microDollars(1_000, 5_000, 100);
        assertThat(borne).isEqualTo(a(FLASH, CREUSE).microDollars(1_000, 1_000, 100));
        assertThat(borne).isPositive();
    }

    // ------------------------------------------------------- heures pleines

    @Test
    void les_heures_pleines_doublent_la_facture() {
        int creuse = a(FLASH, CREUSE).microDollars(7_000, 6_000, 200);
        int pleine = a(FLASH, PLEINE).microDollars(7_000, 6_000, 200);

        // « A un micro-dollar pres » et non « exactement » : l'arrondi est
        // desormais au MICRO-dollar superieur, donc deux arrondis peuvent
        // s'ecarter de 1 millionieme de dollar. C'est precisement l'ordre de
        // grandeur qu'on a gagne — l'ancien arrondi au centime creusait un
        // ecart 10 000 fois plus grand.
        assertThat(pleine).isBetween(creuse * 2 - 1, creuse * 2 + 1);
    }

    @Test
    void les_bornes_des_plages_sont_debut_inclus_fin_exclue() {
        assertThat(a(FLASH, Instant.parse("2026-08-16T01:00:00Z")).heurePleine()).isTrue();
        assertThat(a(FLASH, Instant.parse("2026-08-16T03:59:59Z")).heurePleine()).isTrue();
        assertThat(a(FLASH, Instant.parse("2026-08-16T04:00:00Z")).heurePleine()).isFalse();
        assertThat(a(FLASH, Instant.parse("2026-08-16T05:59:59Z")).heurePleine()).isFalse();
        assertThat(a(FLASH, Instant.parse("2026-08-16T06:00:00Z")).heurePleine()).isTrue();
        assertThat(a(FLASH, Instant.parse("2026-08-16T10:00:00Z")).heurePleine()).isFalse();
        assertThat(a(FLASH, Instant.parse("2026-08-16T23:30:00Z")).heurePleine()).isFalse();
    }

    @Test
    void sans_plage_declaree_il_n_y_a_jamais_d_heure_pleine() {
        assertThat(a(SIMPLE, PLEINE).heurePleine()).isFalse();
        assertThat(a(SIMPLE, PLEINE).microDollars(1_000, null, 100))
            .isEqualTo(a(SIMPLE, CREUSE).microDollars(1_000, null, 100));
    }

    @Test
    void une_plage_illisible_ne_fait_echouer_personne() {
        // Ce reglage ne decide que d'un montant estime persiste pour analyse :
        // une virgule mal placee dans un .env ne doit pas punir le candidat.
        TarifsLlm casse = tarifs(0.22, 0.007, 0.66, 2.0, "n'importe quoi,,25:99-30:00");
        assertThat(a(casse, PLEINE).heurePleine()).isFalse();
        assertThat(a(casse, PLEINE).microDollars(1_000, null, 100)).isPositive();
    }

    @Test
    void une_plage_a_cheval_sur_minuit_est_admise() {
        TarifsLlm nuit = tarifs(1.0, 0.0, 2.0, 2.0, "22:00-02:00");
        assertThat(a(nuit, Instant.parse("2026-08-16T23:00:00Z")).heurePleine()).isTrue();
        assertThat(a(nuit, Instant.parse("2026-08-16T01:00:00Z")).heurePleine()).isTrue();
        assertThat(a(nuit, Instant.parse("2026-08-16T12:00:00Z")).heurePleine()).isFalse();
    }

    // ----------------------------------------------------------- cas limites

    @Test
    void aucun_token_ne_donne_aucun_cout() {
        // null, pas 0 : un cout de 0 persiste se lirait « gratuit », ce qui est
        // une affirmation, alors qu'on n'a rien mesure.
        assertThat(a(FLASH, CREUSE).microDollars(null, null, null)).isNull();
        assertThat(a(FLASH, CREUSE).microDollars(0, 0, 0)).isNull();
    }

    // -------------------------------------------- lecture du decoupage recu

    @Test
    void le_decoupage_se_lit_dans_les_deux_dialectes_du_fournisseur() {
        ObjectMapper om = new ObjectMapper();
        // DeepSeek : a plat.
        assertThat(CoutAppelLlm.lireCacheHitTokens(
            om.readTree("{\"prompt_cache_hit_tokens\":6016,\"prompt_cache_miss_tokens\":984}")))
            .isEqualTo(6016);
        // OpenAI : imbrique.
        assertThat(CoutAppelLlm.lireCacheHitTokens(
            om.readTree("{\"prompt_tokens_details\":{\"cached_tokens\":4096}}")))
            .isEqualTo(4096);
        // Rien : on ne devine pas, l'appelant facturera plein tarif.
        assertThat(CoutAppelLlm.lireCacheHitTokens(om.readTree("{\"prompt_tokens\":7000}")))
            .isNull();
        assertThat(CoutAppelLlm.lireCacheHitTokens(null)).isNull();
    }
}
