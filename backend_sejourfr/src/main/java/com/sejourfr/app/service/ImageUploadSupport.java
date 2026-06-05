package com.sejourfr.app.service;

import com.sejourfr.app.exception.BusinessException;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

/**
 * Validation commune des images uploadees (remplacement d'image des questions
 * CO_IMAGE et de leurs drafts) : formats autorises + taille max + extension
 * deduite du content-type. Partage entre {@code QuestionImageService} et
 * {@code AudioDraftService}.
 */
public final class ImageUploadSupport {

    public static final long MAX_BYTES = 5L * 1024 * 1024; // 5 Mo

    private static final Map<String, String> ALLOWED_CONTENT_TYPES = Map.of(
            "image/jpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp"
    );

    /** Image validee : octets bruts + content-type normalise + extension. */
    public record ValidatedImage(byte[] bytes, String contentType, String extension) {}

    public static ValidatedImage validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("Fichier image manquant");
        }
        if (file.getSize() > MAX_BYTES) {
            throw new BusinessException("Image trop volumineuse (max 5 Mo)");
        }
        String contentType = file.getContentType() != null ? file.getContentType().toLowerCase() : null;
        String extension = contentType != null ? ALLOWED_CONTENT_TYPES.get(contentType) : null;
        if (extension == null) {
            throw new BusinessException("Format non supporte (jpg, png ou webp attendu)");
        }
        try {
            return new ValidatedImage(file.getBytes(), contentType, extension);
        } catch (IOException e) {
            throw new BusinessException("Lecture du fichier image impossible");
        }
    }

    private ImageUploadSupport() {}
}
