package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Corps de la requete d'emission du token ephemere Gemini (partie testable sans
 * reseau — aucun appel fournisseur n'est emis ici). Verrouille dans le token :
 * la VAD, la transcription in/out, la persona, la REPRISE de session et la
 * compression de contexte. Tout ce qui n'est pas dans ce setup ne peut pas etre
 * pose par le client (endpoint contraint).
 */
class GeminiTokenBrokerTest {

    private final RealtimeProperties props = new RealtimeProperties();
    private final GeminiTokenBroker broker = new GeminiTokenBroker(props, new ObjectMapper());

    @SuppressWarnings("unchecked")
    private Map<String, Object> setup(String handle) {
        Map<String, Object> body = broker.buildRequestBody(
                props.getGemini(), "persona verrouillee", handle, Instant.now());
        return (Map<String, Object>) body.get("bidiGenerateContentSetup");
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> aad() {
        Map<String, Object> ric = (Map<String, Object>) setup(null).get("realtimeInputConfig");
        return (Map<String, Object>) ric.get("automaticActivityDetection");
    }

    // ----- VAD -----

    @Test
    void locksVadOnCautiousEndOfSpeech() {
        Map<String, Object> aad = aad();

        assertThat(aad.get("disabled")).isEqualTo(false);
        assertThat(aad.get("startOfSpeechSensitivity")).isEqualTo("START_SENSITIVITY_HIGH");
        // LOW est le reglage le plus PRUDENT donc le plus LENT a declarer la fin
        // de parole ; c'est assume, le seul autre choix est HIGH, qui couperait
        // un apprenant A2 qui hesite. Il n'existe PAS de MEDIUM (cf. le test
        // ci-dessous) : l'avoir cru a coute 4 jours de temps reel.
        assertThat(aad.get("endOfSpeechSensitivity")).isEqualTo("END_SENSITIVITY_LOW");
        assertThat(aad.get("prefixPaddingMs")).isEqualTo(300);
        // Plancher recommande par le fournisseur (500-800) : en dessous, un
        // enonce se fragmente sur ses pauses naturelles.
        assertThat(aad.get("silenceDurationMs")).isEqualTo(500);
    }

    /**
     * 🛑 Le fournisseur n'expose que {@code UNSPECIFIED|LOW|HIGH} sur chaque
     * sensibilite. {@code END_SENSITIVITY_MEDIUM}, pose du 2026-08-12 au
     * 2026-08-16, faisait refuser CHAQUE token en 400 INVALID_ARGUMENT : tout le
     * temps reel basculait en asynchrone, en silence, sur les deux fronts. La
     * valeur est donc opposee au BOOT, jamais au premier candidat.
     */
    @Test
    void refusesAnUnknownVadSensitivityAtBoot() {
        RealtimeProperties.Vad vad = props.getGemini().getVad();

        assertThat(RealtimeProperties.Vad.END_SENSITIVITES)
                .containsExactlyInAnyOrder("END_SENSITIVITY_UNSPECIFIED",
                        "END_SENSITIVITY_LOW", "END_SENSITIVITY_HIGH");
        assertThat(RealtimeProperties.Vad.START_SENSITIVITES)
                .containsExactlyInAnyOrder("START_SENSITIVITY_UNSPECIFIED",
                        "START_SENSITIVITY_LOW", "START_SENSITIVITY_HIGH");

        // Le defaut livre, lui, doit passer.
        GeminiTokenBroker.assertVadSupportee(vad);

        vad.setEndSensitivity("END_SENSITIVITY_MEDIUM");
        assertThatThrownBy(() -> GeminiTokenBroker.assertVadSupportee(vad))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("end-sensitivity")
                .hasMessageContaining("END_SENSITIVITY_MEDIUM")
                .hasMessageContaining("END_SENSITIVITY_LOW");

        vad.setEndSensitivity("END_SENSITIVITY_HIGH");
        vad.setStartSensitivity("START_SENSITIVITY_MEDIUM");
        assertThatThrownBy(() -> GeminiTokenBroker.assertVadSupportee(vad))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("start-sensitivity");
    }

    @Test
    void vadIsFullyOverridable() {
        // Le proprietaire doit pouvoir essayer HIGH sans recompiler : les cinq
        // valeurs viennent de la configuration, aucune n'est en dur.
        RealtimeProperties.Vad vad = props.getGemini().getVad();
        vad.setStartSensitivity("START_SENSITIVITY_LOW");
        vad.setEndSensitivity("END_SENSITIVITY_HIGH");
        vad.setPrefixPaddingMs(120);
        vad.setSilenceDurationMs(800);
        vad.setDisabled(true);

        Map<String, Object> aad = aad();

        assertThat(aad.get("disabled")).isEqualTo(true);
        assertThat(aad.get("startOfSpeechSensitivity")).isEqualTo("START_SENSITIVITY_LOW");
        assertThat(aad.get("endOfSpeechSensitivity")).isEqualTo("END_SENSITIVITY_HIGH");
        assertThat(aad.get("prefixPaddingMs")).isEqualTo(120);
        assertThat(aad.get("silenceDurationMs")).isEqualTo(800);
    }

    // ----- setup verrouille -----

    @Test
    void keepsTranscriptionAndPersonaLockedInSetup() {
        assertThat(setup(null)).containsKeys("inputAudioTranscription", "outputAudioTranscription",
                "systemInstruction", "realtimeInputConfig");
    }

    // ----- reprise de session -----

    @Test
    void armsSessionResumptionWithoutHandleOnAFreshSession() {
        // sessionResumption present mais VIDE : c'est ce qui demande au
        // fournisseur d'emettre les handles que le client memorisera.
        assertThat(setup(null)).containsEntry("sessionResumption", Map.of());
        assertThat(broker.supportsResumption()).isTrue();
    }

    @Test
    void locksTheResumptionHandleServerSide() {
        // Le token est CONTRAINT : le client ne peut poser aucun champ de setup,
        // donc le handle ne peut entrer que par ici.
        assertThat(setup("handle-abc")).containsEntry("sessionResumption", Map.of("handle", "handle-abc"));
    }

    @Test
    void omitsResumptionWhenDisabled() {
        props.getGemini().getSessionResumption().setEnabled(false);

        assertThat(setup("handle-abc")).doesNotContainKey("sessionResumption");
        assertThat(broker.supportsResumption()).isFalse();
    }

    // ----- compression de contexte -----

    @Test
    void locksSlidingWindowContextCompression() {
        assertThat(setup(null)).containsEntry("contextWindowCompression", Map.of(
                "triggerTokens", 25600L,
                "slidingWindow", Map.of("targetTokens", 12800L)));
    }

    @Test
    void omitsContextCompressionWhenDisabled() {
        props.getGemini().getContextWindowCompression().setEnabled(false);

        assertThat(setup(null)).doesNotContainKey("contextWindowCompression");
    }

    @Test
    void leavesProviderDefaultsWhenThresholdsAreZero() {
        RealtimeProperties.ContextWindowCompression cwc = props.getGemini().getContextWindowCompression();
        cwc.setTriggerTokens(0);
        cwc.setTargetTokens(0);

        assertThat(setup(null)).containsEntry("contextWindowCompression",
                Map.of("slidingWindow", Map.of()));
    }

    // ----- fenetres du token -----

    @Test
    void mintsAReusableTokenWithAWindowThatSurvivesANetworkDrop() {
        Map<String, Object> body = broker.buildRequestBody(
                props.getGemini(), "persona", null, Instant.now());

        // 1 usage = toute coupure etait fatale ; 3 = ouverture + 2 reprises.
        assertThat(body.get("uses")).isEqualTo(3);
        assertThat(props.getGemini().getNewSessionExpireSeconds()).isEqualTo(600);
        assertThat(props.getGemini().getSessionExpireSeconds()).isEqualTo(1800);
        // La fenetre de reconnexion reste tres en deca de la duree de vie totale.
        assertThat(props.getGemini().getNewSessionExpireSeconds())
                .isLessThan(props.getGemini().getSessionExpireSeconds());
    }
}
