package com.sejourfr.app.service;

import com.sejourfr.app.audioquestion.service.CloudflareR2Client;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.dto.QuestionDto;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.MediaManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.mapper.QuestionMapper;
import com.sejourfr.app.service.ImageUploadSupport.ValidatedImage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

/**
 * Remplacement de l'image support d'une question (CO_IMAGE) par une image
 * uploadee, stockee sur R2 comme les audios. L'image_url prime : on vide
 * l'inline_svg du media pour eviter l'ambiguite d'affichage.
 */
@Service
@Transactional
@RequiredArgsConstructor
public class QuestionImageService {

    private final QuestionManager questionManager;
    private final MediaManager mediaManager;
    private final QuestionMapper mapper;
    private final CloudflareR2Client r2Client;

    public QuestionDto replaceImage(UUID questionId, MultipartFile file) {
        Question question = questionManager.findById(questionId)
                .orElseThrow(() -> NotFoundException.of("Question", questionId));

        ValidatedImage img = ImageUploadSupport.validate(file);
        String objectKey = "questions/images/" + questionId + "/" + UUID.randomUUID() + "." + img.extension();
        R2UploadResult r2 = r2Client.uploadImage(objectKey, img.bytes(), img.contentType());

        Media image = question.getMedia();
        String oldKey = null;
        if (image == null || image.getType() != MediaType.IMAGE) {
            image = new Media();
            image.setType(MediaType.IMAGE);
            question.setMedia(image);
        } else {
            oldKey = image.getStorageKey();
        }
        image.setUrl(r2.publicUrl());
        image.setStorageKey(r2.objectKey());
        image.setInlineSvg(null); // image_url prime sur le SVG genere
        image.setContentType(img.contentType());
        image.setSizeBytes((long) img.bytes().length);
        mediaManager.save(image);
        questionManager.save(question);

        if (oldKey != null && !oldKey.equals(r2.objectKey())) {
            r2Client.deleteObject(oldKey);
        }
        return mapper.toDto(question);
    }
}
