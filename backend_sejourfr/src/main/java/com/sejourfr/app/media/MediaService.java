package com.sejourfr.app.media;

import com.sejourfr.app.common.BusinessException;
import com.sejourfr.app.common.NotFoundException;
import com.sejourfr.app.media.enums.MediaType;
import com.sejourfr.app.storage.MediaStorageService;
import com.sejourfr.app.storage.dto.StoredFile;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@Service
@Transactional
public class MediaService {

    private final MediaRepository mediaRepository;
    private final MediaStorageService storage;

    public MediaService(MediaRepository mediaRepository, MediaStorageService storage) {
        this.mediaRepository = mediaRepository;
        this.storage = storage;
    }

    public MediaDto upload(MultipartFile file, MediaType type, Integer durationSec, String altText) {
        if (type == null) throw new BusinessException("Le type de media est requis");
        StoredFile stored = storage.store(file);

        Media m = new Media();
        m.setType(type);
        m.setUrl(stored.publicUrl());
        m.setStorageKey(stored.storageKey());
        m.setOriginalFilename(stored.originalFilename());
        m.setContentType(stored.contentType());
        m.setSizeBytes(stored.sizeBytes());
        m.setDurationSec(durationSec);
        m.setAltText(altText);
        return MediaDto.from(mediaRepository.save(m));
    }

    public MediaDto createFromUrl(MediaCreateFromUrlRequest req) {
        Media m = new Media();
        m.setType(req.type());
        m.setUrl(req.url());
        m.setStorageKey(null); // url externe : pas de cle de stockage
        m.setDurationSec(req.durationSec());
        m.setAltText(req.altText());
        return MediaDto.from(mediaRepository.save(m));
    }

    @Transactional(readOnly = true)
    public MediaDto getById(UUID id) {
        return MediaDto.from(loadOrThrow(id));
    }

    public void delete(UUID id) {
        Media m = loadOrThrow(id);
        if (m.getStorageKey() != null) {
            storage.delete(m.getStorageKey());
        }
        mediaRepository.delete(m);
    }

    private Media loadOrThrow(UUID id) {
        return mediaRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Media", id));
    }
}
