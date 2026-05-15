package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

import java.util.Map;

/** Claude a renvoye un contenu (tool_use input) qui ne respecte pas le schema attendu. */
public class AnthropicContentInvalidException extends AudioGenerationException {

    public AnthropicContentInvalidException(String message) {
        super(message);
    }

    public AnthropicContentInvalidException(String message, Map<String, Object> details) {
        super(message, details);
    }

    public AnthropicContentInvalidException(String message, Throwable cause) {
        super(message, cause);
    }

    @Override public String getCode() { return "ANTHROPIC_CONTENT_INVALID"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.UNPROCESSABLE_CONTENT; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_ANTHROPIC_PARSE; }
}
