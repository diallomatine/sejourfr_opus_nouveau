package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Corps de la requete d'emission du token ephemere Gemini (partie testable sans
 * reseau). Verrouille la VAD (Levier A) dans le token : sensibilites + fenetre de
 * silence unique (la meme pour tous les niveaux), plus la transcription in/out
 * (indispensable a la notation).
 */
class GeminiTokenBrokerTest {

    private final RealtimeProperties props = new RealtimeProperties();
    private final GeminiTokenBroker broker = new GeminiTokenBroker(props, new ObjectMapper());

    @SuppressWarnings("unchecked")
    private Map<String, Object> aad() {
        Map<String, Object> body = broker.buildRequestBody(
                props.getGemini(), "persona verrouillee", Instant.now());
        Map<String, Object> setup = (Map<String, Object>) body.get("bidiGenerateContentSetup");
        Map<String, Object> ric = (Map<String, Object>) setup.get("realtimeInputConfig");
        return (Map<String, Object>) ric.get("automaticActivityDetection");
    }

    @Test
    void locksPatientVad() {
        Map<String, Object> aad = aad();

        assertThat(aad.get("disabled")).isEqualTo(false);
        assertThat(aad.get("startOfSpeechSensitivity")).isEqualTo("START_SENSITIVITY_HIGH");
        assertThat(aad.get("endOfSpeechSensitivity")).isEqualTo("END_SENSITIVITY_LOW");
        assertThat(aad.get("prefixPaddingMs")).isEqualTo(300);
        // Fenetre de silence unique, reglee a 500 ms (bas de la fourchette Google
        // 500-800) pour reduire ~de moitie l'attente avant que l'examinateur reponde.
        assertThat(aad.get("silenceDurationMs")).isEqualTo(500);
    }

    @Test
    @SuppressWarnings("unchecked")
    void keepsTranscriptionAndPersonaLockedInSetup() {
        Map<String, Object> body = broker.buildRequestBody(
                props.getGemini(), "persona verrouillee", Instant.now());
        Map<String, Object> setup = (Map<String, Object>) body.get("bidiGenerateContentSetup");

        assertThat(setup).containsKeys("inputAudioTranscription", "outputAudioTranscription",
                "systemInstruction", "realtimeInputConfig");
    }
}
