package com.sejourfr.app.exception;

import com.sejourfr.app.service.social.InvalidSocialTokenException;
import jakarta.persistence.EntityNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.core.MethodParameter;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.exc.InvalidFormatException;
import tools.jackson.databind.exc.MismatchedInputException;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Mappe les exceptions vers des réponses JSON cohérentes,
 * compatibles avec le client mobile (qui lit 'message' et 'fieldErrors').
 *
 * <p>Le log est centralisé dans {@link #build} : chaque exception gérée est
 * tracée une seule fois, avec sa stack, au niveau adapté au status HTTP
 * (5xx → {@code error}, 4xx → {@code warn}). Les handlers n'ont donc plus à
 * logger eux-mêmes.</p>
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFoundCustom(NotFoundException e, WebRequest req) {
        return build(HttpStatus.NOT_FOUND, e.getMessage(), req, null, e);
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(EntityNotFoundException e, WebRequest req) {
        return build(HttpStatus.NOT_FOUND, e.getMessage(), req, null, e);
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Map<String, Object>> handleBusiness(BusinessException e, WebRequest req) {
        return build(HttpStatus.UNPROCESSABLE_ENTITY, e.getMessage(), req, null, e);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleForbidden(AccessDeniedException e, WebRequest req) {
        return build(HttpStatus.FORBIDDEN, e.getMessage(), req, null, e);
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, Object>> handleBadCredentials(BadCredentialsException e, WebRequest req) {
        return build(HttpStatus.UNAUTHORIZED, "Identifiants invalides", req, null, e);
    }

    @ExceptionHandler(InvalidSocialTokenException.class)
    public ResponseEntity<Map<String, Object>> handleInvalidSocialToken(InvalidSocialTokenException e, WebRequest req) {
        return build(HttpStatus.UNAUTHORIZED, e.getMessage(), req, null, e);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleBadRequest(IllegalArgumentException e, WebRequest req) {
        return build(HttpStatus.BAD_REQUEST, e.getMessage(), req, null, e);
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, Object>> handleConflict(IllegalStateException e, WebRequest req) {
        return build(HttpStatus.CONFLICT, e.getMessage(), req, null, e);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String, Object>> handleMaxUpload(MaxUploadSizeExceededException e, WebRequest req) {
        return build(HttpStatus.PAYLOAD_TOO_LARGE, "Fichier trop volumineux", req, null, e);
    }

    /**
     * La transcription echoue PENDANT la soumission d'une production orale —
     * c'est le seul moment ou elle peut avoir lieu, l'audio n'etant pas
     * conserve. Rien n'a donc ete enregistre, et il n'y a rien a relancer : le
     * candidat doit RENVOYER, depuis l'enregistrement encore present sur son
     * appareil. Le message le dit, parce qu'un 500 opaque le laisserait attendre
     * une correction qui n'arrivera jamais.
     *
     * <p>503 et non 4xx : l'echec vient de nous (fournisseur indisponible), pas
     * de ce qu'il a envoye.
     */
    @ExceptionHandler(TranscriptionException.class)
    public ResponseEntity<Map<String, Object>> handleTranscription(TranscriptionException e, WebRequest req) {
        return build(HttpStatus.SERVICE_UNAVAILABLE,
                "Nous n'avons pas pu retranscrire votre enregistrement. Il n'a pas été "
                        + "conservé : renvoyez-le, ou refaites-le si vous avez quitté l'écran.",
                req, null, e);
    }

    /**
     * Depassement d'une limite anti-abus. Renvoie 429 + header {@code Retry-After}
     * (secondes) pour que les clients reessaient apres le delai indique.
     */
    @ExceptionHandler(RateLimitException.class)
    public ResponseEntity<Map<String, Object>> handleRateLimit(RateLimitException e, WebRequest req) {
        ResponseEntity<Map<String, Object>> logged =
                build(HttpStatus.TOO_MANY_REQUESTS, e.getMessage(), req, null, e);
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .header(HttpHeaders.RETRY_AFTER, String.valueOf(e.getRetryAfterSeconds()))
                .body(logged.getBody());
    }

    /**
     * Les {@link ResponseStatusException} (ex: 409 "email déjà utilisé" levée par
     * le sign-in social) sont sinon rendues par le handler d'erreur par défaut de
     * Spring — qui n'expose pas {@code reason} dans {@code message} et peut
     * remonter la stack trace. On les normalise dans notre format JSON pour que
     * les fronts lisent {@code message} proprement.
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatus(ResponseStatusException e, WebRequest req) {
        HttpStatus status = HttpStatus.resolve(e.getStatusCode().value());
        if (status == null) {
            status = HttpStatus.INTERNAL_SERVER_ERROR;
        }
        return build(status, e.getReason(), req, null, e);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(
            MethodArgumentNotValidException e,
            WebRequest req
    ) {
        List<Map<String, String>> fieldErrors = e.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(this::fieldErrorToMap)
                .collect(Collectors.toList());
        return build(
                HttpStatus.BAD_REQUEST,
                "Validation échouée",
                req,
                fieldErrors,
                e
        );
    }

    // ------------------------------------------------------------------------
    // Requêtes mal formées : ce sont des erreurs CLIENT (400/404/405), pas des
    // bugs serveur. Sans ces handlers, elles tombaient dans handleAny → 500 +
    // stack trace en ERROR à chaque paramètre mal typé, et les fronts recevaient
    // « Erreur interne du serveur » là où le vrai problème était leur requête
    // (cf. le ?epreuve= manquant sur /api/full-tcf-exams/{id}/begin).
    // Les messages nomment le paramètre fautif SANS exposer d'interne (pas de
    // type Java, pas de message Jackson, pas de nom de classe).
    // ------------------------------------------------------------------------

    /**
     * Paramètre présent mais non convertible (enum inconnu, UUID malformé,
     * entier non numérique).
     *
     * <p>Dans un segment de CHEMIN, une valeur non convertible veut dire que la
     * ressource demandée n'existe pas : on répond 404, comme pour un id valide
     * mais inconnu ({@code GET /api/attempts/mine} ne doit pas révéler qu'il
     * existe une route {@code /api/attempts/{uuid}}). Dans un paramètre de
     * requête, c'est bien une requête malformée : 400.
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String, Object>> handleTypeMismatch(
            MethodArgumentTypeMismatchException e, WebRequest req) {
        if (isPathVariable(e)) {
            return build(HttpStatus.NOT_FOUND, "Ressource introuvable.", req, null, e);
        }
        String message = "Paramètre « " + e.getName() + " » invalide";
        String allowed = allowedValues(e);
        if (allowed != null) {
            message += " : valeurs acceptées " + allowed;
        }
        return build(HttpStatus.BAD_REQUEST, message + ".", req, null, e);
    }

    private boolean isPathVariable(MethodArgumentTypeMismatchException e) {
        MethodParameter parameter = e.getParameter();
        return parameter != null && parameter.hasParameterAnnotation(PathVariable.class);
    }

    /** Paramètre de requête obligatoire absent. */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, Object>> handleMissingParam(
            MissingServletRequestParameterException e, WebRequest req) {
        return build(HttpStatus.BAD_REQUEST,
                "Paramètre « " + e.getParameterName() + " » requis.", req, null, e);
    }

    /**
     * Corps de requête illisible : JSON tronqué / invalide, body absent, ou
     * valeur non désérialisable. Message volontairement générique — les
     * messages Jackson exposent des noms de classes internes.
     *
     * <p><b>Exception : une valeur d'enum inconnue est nommée</b> (champ, valeur
     * reçue, valeurs acceptées), comme le fait déjà
     * {@link #handleTypeMismatch} pour les paramètres de requête. Un
     * {@code targetProcedure} fautif doit dire au front <i>lequel</i> et
     * <i>pourquoi</i> : c'est le silence sur ce champ qui a créé des comptes
     * sans démarche ni palier.
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleUnreadableBody(
            HttpMessageNotReadableException e, WebRequest req) {
        MismatchedInputException enumMismatch = findEnumMismatch(e);
        if (enumMismatch != null) {
            String field = lastPropertyName(enumMismatch);
            String message = "Valeur invalide pour « " + field + " »";
            if (enumMismatch instanceof InvalidFormatException ife && ife.getValue() != null) {
                message += " : « " + ife.getValue() + " »";
            }
            message += ". Valeurs acceptées : " + enumConstants(enumMismatch.getTargetType()) + ".";
            return build(HttpStatus.BAD_REQUEST, message, req,
                    List.of(Map.of("field", field, "message", message)), e);
        }
        return build(HttpStatus.BAD_REQUEST,
                "Corps de requête absent ou mal formé (JSON attendu).", req, null, e);
    }

    /**
     * Première cause de type « valeur non convertible vers un enum » dans la
     * chaîne. {@code null} si l'échec de lecture vient d'autre chose (JSON
     * tronqué, UUID malformé…), auquel cas on garde le message générique.
     */
    private MismatchedInputException findEnumMismatch(Throwable e) {
        for (Throwable cause = e; cause != null; cause = cause.getCause()) {
            if (cause instanceof MismatchedInputException mie) {
                Class<?> target = mie.getTargetType();
                if (target != null && target.isEnum()) return mie;
            }
            if (cause.getCause() == cause) break;
        }
        return null;
    }

    /** Dernier segment nommé du chemin Jackson, ou un repli neutre. */
    private String lastPropertyName(MismatchedInputException e) {
        String name = null;
        for (JacksonException.Reference ref : e.getPath()) {
            if (ref.getPropertyName() != null) name = ref.getPropertyName();
        }
        return name != null ? name : "un champ du corps de requête";
    }

    private String enumConstants(Class<?> enumType) {
        Object[] constants = enumType.getEnumConstants();
        return constants == null ? "" : java.util.Arrays.stream(constants)
                .map(Object::toString)
                .collect(Collectors.joining(", "));
    }

    /** Chemin inexistant : 404, pas 500 (et pas de fuite sur le routage interne). */
    @ExceptionHandler({NoResourceFoundException.class, NoHandlerFoundException.class})
    public ResponseEntity<Map<String, Object>> handleNoHandler(Exception e, WebRequest req) {
        return build(HttpStatus.NOT_FOUND, "Ressource introuvable.", req, null, e);
    }

    /** Bonne route, mauvaise méthode HTTP. */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<Map<String, Object>> handleMethodNotSupported(
            HttpRequestMethodNotSupportedException e, WebRequest req) {
        return build(HttpStatus.METHOD_NOT_ALLOWED,
                "Méthode " + e.getMethod() + " non autorisée sur cette ressource.", req, null, e);
    }

    /**
     * Valeurs acceptées d'un paramètre enum, pour rendre le 400 actionnable
     * côté front. {@code null} pour les autres types (un UUID n'a pas de liste).
     */
    private String allowedValues(MethodArgumentTypeMismatchException e) {
        Class<?> required = e.getRequiredType();
        if (required == null || !required.isEnum()) return null;
        Object[] constants = required.getEnumConstants();
        if (constants == null || constants.length == 0) return null;
        return java.util.Arrays.stream(constants)
                .map(Object::toString)
                .collect(Collectors.joining(", "));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleAny(Exception e, WebRequest req) {
        return build(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "Erreur interne du serveur",
                req,
                null,
                e
        );
    }

    private Map<String, String> fieldErrorToMap(FieldError fe) {
        return Map.of(
                "field", fe.getField(),
                "message", fe.getDefaultMessage() != null ? fe.getDefaultMessage() : "invalide"
        );
    }

    private ResponseEntity<Map<String, Object>> build(
            HttpStatus status,
            String message,
            WebRequest req,
            List<Map<String, String>> fieldErrors,
            Throwable e
    ) {
        String path = req.getDescription(false).replace("uri=", "");
        // Log centralisé : toutes les erreurs gérées passent ici.
        // - 5xx (bug serveur) → error AVEC la stack trace (diagnostic).
        // - 4xx (erreur client attendue : validation, 404, 401…) → warn d'une
        //   seule ligne, SANS stack trace (sinon une simple validation déverse
        //   tout le filter chain Spring dans les logs pour rien).
        if (status.is5xxServerError()) {
            log.error("{} {} -> {} : {}", status.value(), path, status.getReasonPhrase(), message, e);
        } else {
            log.warn("{} {} -> {} : {} ({})",
                    status.value(), path, status.getReasonPhrase(), message, e.getClass().getSimpleName());
        }

        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("timestamp", Instant.now().toString());
        body.put("status", status.value());
        body.put("error", status.getReasonPhrase());
        body.put("message", message != null ? message : status.getReasonPhrase());
        body.put("path", path);
        if (fieldErrors != null && !fieldErrors.isEmpty()) {
            body.put("fieldErrors", fieldErrors);
        }
        return ResponseEntity.status(status).body(body);
    }
}
