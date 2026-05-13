package com.sejourfr.app.service;

import com.sejourfr.app.config.StorageProperties;
import com.sejourfr.app.dto.StoredFile;
import com.sejourfr.app.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
@ConditionalOnProperty(prefix = "sejourfr.storage", name = "provider", havingValue = "local", matchIfMissing = true)
@EnableConfigurationProperties(StorageProperties.class)
public class LocalFileStorageService implements MediaStorageService {

    private static final Logger log = LoggerFactory.getLogger(LocalFileStorageService.class);
    private static final DateTimeFormatter MONTH_FMT = DateTimeFormatter.ofPattern("yyyy/MM");

    private final StorageProperties properties;
    private final Path rootDir;

    public LocalFileStorageService(StorageProperties properties) {
        this.properties = properties;
        this.rootDir = Paths.get(properties.getLocal().getRoot()).toAbsolutePath().normalize();
    }

    @PostConstruct
    void init() {
        try {
            Files.createDirectories(rootDir);
            log.info("Local storage initialise : {}", rootDir);
        } catch (IOException ex) {
            throw new IllegalStateException("Impossible de creer le repertoire de stockage : " + rootDir, ex);
        }
    }

    @Override
    public StoredFile store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("Fichier vide ou absent");
        }
        if (file.getSize() > properties.getMaxFileSizeBytes()) {
            throw new BusinessException("Fichier trop volumineux (max " + properties.getMaxFileSizeBytes() + " octets)");
        }

        String contentType = file.getContentType();
        validateContentType(contentType);

        String monthPath = LocalDate.now().format(MONTH_FMT);
        String safeName = sanitizeFilename(file.getOriginalFilename());
        String storageKey = monthPath + "/" + UUID.randomUUID() + "-" + safeName;
        Path target = rootDir.resolve(storageKey).normalize();

        if (!target.startsWith(rootDir)) {
            throw new BusinessException("Chemin de fichier invalide");
        }

        try {
            Files.createDirectories(target.getParent());
            try (var in = file.getInputStream()) {
                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException ex) {
            throw new BusinessException("Echec de l'ecriture du fichier : " + ex.getMessage());
        }

        String publicUrl = properties.getLocal().getPublicBaseUrl() + "/" + storageKey;
        return new StoredFile(storageKey, publicUrl, contentType, file.getSize(), safeName);
    }

    @Override
    public void delete(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) return;
        Path target = rootDir.resolve(storageKey).normalize();
        if (!target.startsWith(rootDir)) return;
        try {
            Files.deleteIfExists(target);
        } catch (IOException ex) {
            log.warn("Suppression impossible {} : {}", target, ex.getMessage());
        }
    }

    private void validateContentType(String contentType) {
        if (contentType == null) {
            throw new BusinessException("Content-Type manquant");
        }
        boolean ok = properties.getAllowedImageTypes().contains(contentType)
                || properties.getAllowedAudioTypes().contains(contentType);
        if (!ok) {
            throw new BusinessException("Type de fichier non autorise : " + contentType);
        }
    }

    private String sanitizeFilename(String name) {
        if (name == null || name.isBlank()) return "file";
        String base = Paths.get(name).getFileName().toString();
        return base.replaceAll("[^a-zA-Z0-9._-]", "_");
    }
}
