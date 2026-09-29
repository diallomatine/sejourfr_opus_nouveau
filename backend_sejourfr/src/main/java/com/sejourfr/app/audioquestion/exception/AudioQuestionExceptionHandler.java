package com.sejourfr.app.audioquestion.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Handler dedie aux exceptions de la pipeline de generation audio.
 * Garde le format de reponse du GlobalExceptionHandler existant
 * ({@code timestamp/status/error/message/path}) et ajoute :
 *   - {@code code} : code applicatif consomme par le front admin
 *   - {@code details} : objet libre pour porter des indices de diagnostic
 *   - {@code Retry-After} en header pour le rate-limiting (HTTP 429)
 *
 * Ordre prioritaire (HIGHEST_PRECEDENCE) pour eviter que le handler
 * generic {@code @ExceptionHandler(Exception.class)} ne capture nos exceptions.
 */
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class AudioQuestionExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(AudioQuestionExceptionHandler.class);

    @ExceptionHandler(AudioGenerationException.class)
    public ResponseEntity<Map<String, Object>> handle(AudioGenerationException ex, WebRequest req) {
        HttpStatus status = ex.getHttpStatus();
        if (status.is5xxServerError()) {
            log.error("Audio pipeline {} : {}", ex.getCode(), ex.getMessage(), ex);
        } else {
            log.warn("Audio pipeline {} : {}", ex.getCode(), ex.getMessage());
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", Instant.now().toString());
        body.put("status", status.value());
        body.put("error", status.getReasonPhrase());
        body.put("code", ex.getCode());
        body.put("message", ex.getMessage());
        body.put("path", req.getDescription(false).replace("uri=", ""));
        if (ex.getDetails() != null && !ex.getDetails().isEmpty()) {
            body.put("details", ex.getDetails());
        }

        ResponseEntity.BodyBuilder builder = ResponseEntity.status(status);
        if (ex instanceof RateLimitExceededException rate) {
            builder.header(HttpHeaders.RETRY_AFTER, String.valueOf(rate.getRetryAfterSeconds()));
        }
        return builder.body(body);
    }
}
