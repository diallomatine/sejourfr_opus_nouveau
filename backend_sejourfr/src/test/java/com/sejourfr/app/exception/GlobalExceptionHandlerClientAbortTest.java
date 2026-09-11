package com.sejourfr.app.exception;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotWritableException;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.context.request.async.AsyncRequestNotUsableException;

import java.io.IOException;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Une reponse qu'on n'arrive pas a ecrire, c'est deux accidents tres
 * differents sous une seule exception.
 *
 * <p>Le client qui raccroche — onglet ferme, navigation, rechargement a chaud —
 * n'est PAS une panne : le traitement metier a reussi, il n'y a simplement plus
 * personne pour lire. Le logger en {@code ERROR 500} remplit le flux d'erreurs
 * de fausses alertes, et le jour ou une vraie panne arrive, elle s'y noie.
 *
 * <p>Un DTO qui ne sait pas se serialiser, lui, est un defaut de code et doit
 * rester un 500 bruyant. Ces deux tests gelent la distinction, parce qu'elle ne
 * se voit pas en lisant l'exception : il faut remonter sa chaine de causes.
 */
class GlobalExceptionHandlerClientAbortTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    private WebRequest request() {
        WebRequest req = mock(WebRequest.class);
        when(req.getDescription(false)).thenReturn("uri=/api/admin/civic-notions");
        return req;
    }

    @Test
    void leClientQuiRaccrocheNeProduitAucuneReponse() {
        // La chaine reelle observee en dev : Jackson enveloppe l'echec
        // d'ecriture, qui enveloppe la coupure de socket.
        HttpMessageNotWritableException e = new HttpMessageNotWritableException(
                "Could not write JSON: ServletOutputStream failed to write",
                new AsyncRequestNotUsableException(
                        "ServletOutputStream failed to write",
                        new IOException("Broken pipe")));

        ResponseEntity<Map<String, Object>> reponse = handler.handleNotWritable(e, request());

        // 🛑 `null`, pas un 500 vide : ecrire un corps d'erreur sur une socket
        // morte leverait une SECONDE exception par-dessus la premiere.
        assertThat(reponse).isNull();
    }

    @Test
    void unDtoQuiNeSaitPasSeSerialiserResteUnErreurServeur() {
        HttpMessageNotWritableException e = new HttpMessageNotWritableException(
                "Could not write JSON", new IllegalStateException("getter en echec"));

        ResponseEntity<Map<String, Object>> reponse = handler.handleNotWritable(e, request());

        assertThat(reponse).isNotNull();
        assertThat(reponse.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
