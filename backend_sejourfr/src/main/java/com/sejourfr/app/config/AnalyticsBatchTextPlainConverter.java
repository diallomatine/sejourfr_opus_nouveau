package com.sejourfr.app.config;

import com.sejourfr.app.dto.AnalyticsBatchRequest;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.HttpOutputMessage;
import org.springframework.http.MediaType;
import org.springframework.http.converter.AbstractHttpMessageConverter;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.http.converter.HttpMessageNotWritableException;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;

/**
 * Lit un lot d'analytics envoye en {@code text/plain} (controle N7, chantier
 * Suivi) : le web vide sa file a la fermeture d'une page par
 * {@code navigator.sendBeacon}, et un Blob {@code application/json} vers une
 * API d'un autre domaine declenche une pre-verification CORS que
 * {@code sendBeacon} ne sait pas faire — le lot, et le first-touch avec lui,
 * serait perdu. {@code text/plain} est un type « simple » : pas de
 * pre-verification.
 *
 * <p>🛑 <b>Borne a {@link AnalyticsBatchRequest}</b> : aucun autre corps
 * {@code text/plain} de l'API n'est lu en JSON. Le contenu est desserialise par
 * l'{@link ObjectMapper} de l'application, exactement comme le JSON : la
 * validation ({@code @Valid}, taille du lot), le rate-limit et le CORS sont ceux
 * de l'endpoint, inchanges. Un corps illisible repond 400, comme en JSON.
 */
@Component
public class AnalyticsBatchTextPlainConverter extends AbstractHttpMessageConverter<AnalyticsBatchRequest> {

    private final ObjectMapper objectMapper;

    public AnalyticsBatchTextPlainConverter(ObjectMapper objectMapper) {
        super(MediaType.TEXT_PLAIN);
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean supports(Class<?> clazz) {
        return AnalyticsBatchRequest.class.equals(clazz);
    }

    @Override
    protected boolean canWrite(MediaType mediaType) {
        return false;
    }

    @Override
    protected AnalyticsBatchRequest readInternal(Class<? extends AnalyticsBatchRequest> clazz,
                                                 HttpInputMessage inputMessage) throws IOException {
        try {
            return objectMapper.readValue(inputMessage.getBody(), AnalyticsBatchRequest.class);
        } catch (JacksonException e) {
            throw new HttpMessageNotReadableException("Lot d'analytics illisible : " + e.getOriginalMessage(),
                    e, inputMessage);
        }
    }

    @Override
    protected void writeInternal(AnalyticsBatchRequest request, HttpOutputMessage outputMessage) {
        throw new HttpMessageNotWritableException("Lecture seule : un lot d'analytics n'est jamais ecrit.");
    }
}
