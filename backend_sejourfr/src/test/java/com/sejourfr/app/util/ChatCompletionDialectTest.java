package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FIGE le choix du champ de plafond de sortie. Se tromper ne degrade pas la
 * notation : elle rate 100 % des appels en 400, donc toutes les soumissions.
 */
class ChatCompletionDialectTest {

    @ParameterizedTest(name = "{0} -> {1}")
    @CsvSource({
        // Generation raisonnement OpenAI : max_tokens y est REFUSE.
        "gpt-5.4,          max_completion_tokens",
        "gpt-5.4-mini,     max_completion_tokens",
        "gpt-5.5,          max_completion_tokens",
        "gpt-5.2,          max_completion_tokens",
        "gpt-5,            max_completion_tokens",
        "GPT-5.4,          max_completion_tokens",
        "o1,               max_completion_tokens",
        "o3-mini,          max_completion_tokens",
        "o4-mini,          max_completion_tokens",
        // Avant gpt-5 : c'est max_completion_tokens qui n'existe pas.
        "gpt-4.1,          max_tokens",
        "gpt-4o,           max_tokens",
        "gpt-4o-mini,      max_tokens",
        // DeepSeek passe par le MEME client : sa voie ne doit pas bouger.
        "deepseek-v4-flash, max_tokens",
        "deepseek-chat,     max_tokens",
        // Modele inconnu : on reste sur le champ historique, jamais sur un
        // champ que le fournisseur ignorerait en silence.
        "un-modele-inconnu, max_tokens",
    })
    void auto_deduit_le_champ_du_modele(String modele, String attendu) {
        assertThat(ChatCompletionDialect.maxTokensParam("auto", modele)).isEqualTo(attendu);
        assertThat(ChatCompletionDialect.maxTokensParam(null, modele)).isEqualTo(attendu);
        assertThat(ChatCompletionDialect.maxTokensParam("  ", modele)).isEqualTo(attendu);
    }

    @Test
    void une_valeur_explicite_l_emporte_sur_la_detection() {
        assertThat(ChatCompletionDialect.maxTokensParam("max_tokens", "gpt-5.4"))
            .as("echappatoire pour un endpoint OpenAI-compatible exotique")
            .isEqualTo("max_tokens");
        assertThat(ChatCompletionDialect.maxTokensParam("MAX_COMPLETION_TOKENS", "gpt-4o-mini"))
            .isEqualTo("max_completion_tokens");
    }

    @ParameterizedTest(name = "{0} -> temperature envoyee = {1}")
    @CsvSource({
        "gpt-5.4,           true",
        "gpt-5.4-mini,      true",
        "gpt-5.2,           true",
        "gpt-4.1,           true",
        "gpt-4o-mini,       true",
        "deepseek-v4-flash, true",
        // Seul refus VERIFIE contre l'API : « Only the default (1) value is
        // supported ». On omet le champ, on n'envoie pas 1.
        "gpt-5.5,           false",
        "gpt-5.5-mini,      false",
        "GPT-5.5,           false",
    })
    void auto_omet_la_temperature_sur_les_seuls_modeles_qui_la_refusent(String modele, boolean attendu) {
        assertThat(ChatCompletionDialect.sendTemperature("auto", modele)).isEqualTo(attendu);
        assertThat(ChatCompletionDialect.sendTemperature(null, modele)).isEqualTo(attendu);
    }

    @Test
    void la_temperature_peut_etre_forcee_dans_les_deux_sens() {
        assertThat(ChatCompletionDialect.sendTemperature("false", "gpt-5.4")).isFalse();
        assertThat(ChatCompletionDialect.sendTemperature("true", "gpt-5.5")).isTrue();
        assertThatThrownBy(() -> ChatCompletionDialect.sendTemperature("oui", "gpt-5.4"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("send-temperature invalide");
    }

    @Test
    void les_familles_utilisees_par_le_projet_sont_reconnues() {
        // Un modele reconnu ne doit pas declencher l'avertissement de demarrage.
        assertThat(ChatCompletionDialect.modeleInconnu("gpt-5.4")).isFalse();
        assertThat(ChatCompletionDialect.modeleInconnu("gpt-4o-mini")).isFalse();
        assertThat(ChatCompletionDialect.modeleInconnu("o3-mini")).isFalse();
        assertThat(ChatCompletionDialect.modeleInconnu("deepseek-v4-flash")).isFalse();
        assertThat(ChatCompletionDialect.modeleInconnu("mistral-large")).isTrue();
    }

    @Test
    void le_resume_dit_ce_qui_a_ete_deduit() {
        assertThat(ChatCompletionDialect.resume("auto", "auto", "gpt-5.4"))
            .contains("max_completion_tokens").contains("temperature=envoyee");
        assertThat(ChatCompletionDialect.resume("auto", "auto", "gpt-5.5"))
            .contains("temperature=omise");
        assertThat(ChatCompletionDialect.resume("auto", "auto", "mistral-large"))
            .contains("hors familles connues");
    }

    @Test
    void une_coquille_de_config_echoue_au_lieu_de_partir_sans_plafond() {
        // Un champ inconnu serait ignore par le fournisseur : la sortie partirait
        // SANS plafond, et c'est exactement le scenario « JSON tronque =
        // soumission perdue » que le plafond existe pour eviter.
        assertThatThrownBy(() -> ChatCompletionDialect.maxTokensParam("max_output_tokens", "gpt-5.4"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("max-tokens-param invalide");
    }
}
