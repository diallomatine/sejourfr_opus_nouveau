package com.sejourfr.app.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Handlers Spring Security pour distinguer proprement :
 *   - 401 Unauthorized : pas de token, token invalide ou expire
 *     -> declenche le refresh JWT cote admin (http.ts) et mobile (Dio interceptor)
 *   - 403 Forbidden : token valide mais role insuffisant
 *
 * Sans ces handlers, Spring renvoie 403 dans les deux cas et le client
 * ne peut pas distinguer "deconnecte" de "interdit".
 *
 * Format JSON aligne sur GlobalExceptionHandler.
 */
public class RestAuthEntryPoints {

    @Component
    public static class Unauthorized implements AuthenticationEntryPoint {

        private final ObjectMapper mapper;

        public Unauthorized(ObjectMapper mapper) {
            this.mapper = mapper;
        }

        @Override
        public void commence(HttpServletRequest request,
                             HttpServletResponse response,
                             AuthenticationException ex) throws IOException {
            writeJson(response, request, HttpStatus.UNAUTHORIZED, "Authentification requise", mapper);
        }
    }

    @Component
    public static class Forbidden implements AccessDeniedHandler {

        private final ObjectMapper mapper;

        public Forbidden(ObjectMapper mapper) {
            this.mapper = mapper;
        }

        @Override
        public void handle(HttpServletRequest request,
                           HttpServletResponse response,
                           AccessDeniedException ex) throws IOException {
            writeJson(response, request, HttpStatus.FORBIDDEN, "Acces interdit", mapper);
        }
    }

    private static void writeJson(HttpServletResponse response,
                                  HttpServletRequest request,
                                  HttpStatus status,
                                  String message,
                                  ObjectMapper mapper) throws IOException {
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", Instant.now().toString());
        body.put("status", status.value());
        body.put("error", status.getReasonPhrase());
        body.put("message", message);
        body.put("path", request.getRequestURI());

        mapper.writeValue(response.getOutputStream(), body);
    }

    private RestAuthEntryPoints() {}
}
