package com.sejourfr.app.exception;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.context.request.WebRequest;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Depuis que l'audio d'un candidat n'est plus conserve, la transcription se fait
 * PENDANT la requete de soumission : son echec est une reponse HTTP que le
 * candidat lit, plus un statut {@code FAILED} qu'il pourra relancer. Le message
 * doit donc lui dire quoi faire — renvoyer — et surtout pas le laisser attendre
 * une correction qui n'arrivera jamais.
 */
class GlobalExceptionHandlerTranscriptionTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    private WebRequest request() {
        WebRequest req = mock(WebRequest.class);
        when(req.getDescription(false)).thenReturn("uri=/api/production-submissions");
        return req;
    }

    @Test
    void unEchecDeTranscriptionRend503EtDitQuIlFautRenvoyer() {
        ResponseEntity<Map<String, Object>> response = handler.handleTranscription(
                new TranscriptionException("Whisper indisponible apres plusieurs tentatives"),
                request());

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isNotNull();
        String message = String.valueOf(response.getBody().get("message"));
        // Ce que le candidat doit comprendre : rien n'a ete garde, et c'est a
        // lui de renvoyer.
        assertThat(message)
                .contains("n'a pas été conservé")
                .contains("renvoyez");
        // On ne lui reproche rien : l'echec vient du fournisseur.
        assertThat(response.getStatusCode().is4xxClientError()).isFalse();
    }
}
