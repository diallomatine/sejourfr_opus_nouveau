package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/** Echec definitif de l'upload du MP3 sur Cloudflare R2. */
public class R2UploadException extends AudioGenerationException {

    public R2UploadException(String message) {
        super(message);
    }

    public R2UploadException(String message, Throwable cause) {
        super(message, cause);
    }

    @Override public String getCode() { return "R2_UPLOAD_ERROR"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.BAD_GATEWAY; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_R2_UPLOAD; }
}
