package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * JSON de conduite (prompts/realtime-conduct-v*.json) : la v1 porte les valeurs
 * du brief et ne pilote que la persona v4 ; la v0 reproduit le comportement
 * d'avant pour les personas v1 à v3 ; tout mélange échoue au BOOT.
 */
class RealtimeConductConfigTest {

    private static RealtimeConductConfig charger(String persona, String conduite) {
        RealtimeProperties props = new RealtimeProperties();
        props.setPersonaVersion(persona);
        props.setConductVersion(conduite);
        RealtimeConductConfig c = new RealtimeConductConfig(props, new ObjectMapper());
        c.load();
        return c;
    }

    @Test
    void les_defauts_livres_sont_persona_v4_et_conduite_v1() {
        RealtimeProperties props = new RealtimeProperties();
        assertThat(props.getPersonaVersion()).isEqualTo("v4");
        assertThat(props.getConductVersion()).isEqualTo("v1");
        assertThat(props.getGemini().getVad().getSilenceDurationMs()).isEqualTo(1500);
    }

    @Test
    void la_v1_porte_les_valeurs_du_brief() {
        RealtimeConductConfig c = charger("v4", "v1");
        JsonNode j = c.client();

        assertThat(c.version()).isEqualTo("v1");
        assertThat(j.get("welcomePrimer").asString()).isEqualTo("Bonjour.");
        assertThat(j.get("welcomeGuardMs").asInt()).isEqualTo(8000);
        assertThat(j.get("halfDuplexHoldMs").asInt()).isEqualTo(120);
        assertThat(j.get("voiceActivity").get("energyThreshold").asDouble()).isEqualTo(0.02);
        assertThat(j.get("voiceActivity").get("minSpeechMs").asInt()).isEqualTo(200);
        assertThat(j.get("voiceActivity").get("hangoverMs").asInt()).isEqualTo(600);
        assertThat(j.get("silenceRelance").get("afterMs").asInt()).isEqualTo(7000);
        assertThat(j.get("silenceRelance").get("maxConsecutive").asInt()).isEqualTo(2);
        assertThat(j.get("silenceRelance").get("disabledLastSec").asInt()).isEqualTo(15);
        assertThat(j.get("silenceRelance").get("message").asString()).isEqualTo("[SILENCE]");
        assertThat(j.get("timeUp").get("graceMaxMs").asInt()).isEqualTo(10000);
        assertThat(j.get("timeUp").get("message").asString()).isEqualTo("[FIN]");
        assertThat(j.get("timeUp").get("closeIdleMs").asInt()).isEqualTo(1200);
        assertThat(j.get("timeUp").get("closeMaxMs").asInt()).isEqualTo(15000);
        assertThat(j.get("resume").get("message").asString()).isEqualTo("[REPRISE]");
        assertThat(j.get("resume").get("contextTurns").asInt()).isEqualTo(3);
    }

    @Test
    void la_v0_reproduit_le_comportement_d_avant() {
        JsonNode j = charger("v3", "v0").client();

        assertThat(j.get("silenceRelance").get("maxConsecutive").asInt()).isZero();
        assertThat(j.get("timeUp").get("graceMaxMs").asInt()).isZero();
        assertThat(j.get("timeUp").get("closeMaxMs").asInt()).isEqualTo(12000);
        assertThat(j.get("timeUp").get("message").asString()).isEqualTo(
                "[Le temps de cette partie est écoulé. Remerciez brièvement le candidat et concluez maintenant.]");
        assertThat(j.get("resume").get("contextTurns").asInt()).isZero();
    }

    @Test
    void une_conduite_qui_ne_pilote_pas_la_persona_echoue_au_boot() {
        assertThatThrownBy(() -> charger("v3", "v1"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("incompatible avec la persona v3");
        assertThatThrownBy(() -> charger("v4", "v0"))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void une_version_inconnue_echoue_au_boot() {
        assertThatThrownBy(() -> charger("v4", "v99"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("realtime-conduct-v99.json");
    }
}
