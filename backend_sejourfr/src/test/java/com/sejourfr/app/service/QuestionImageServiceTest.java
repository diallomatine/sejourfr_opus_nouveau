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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class QuestionImageServiceTest {

    @Mock
    private QuestionManager questionManager;
    @Mock
    private MediaManager mediaManager;
    @Mock
    private QuestionMapper mapper;
    @Mock
    private CloudflareR2Client r2Client;

    @InjectMocks
    private QuestionImageService service;

    private MultipartFile pngFile() {
        return new MockMultipartFile("file", "image.png", "image/png", new byte[]{1, 2, 3, 4});
    }

    @Test
    void replaceImageOnQuestionWithoutMediaCreatesImageMedia() {
        UUID questionId = UUID.randomUUID();
        Question question = new Question();
        when(questionManager.findById(questionId)).thenReturn(Optional.of(question));
        when(r2Client.uploadImage(anyString(), any(), eq("image/png")))
                .thenReturn(new R2UploadResult("questions/images/new.png", "https://r2/new.png"));
        when(mapper.toDto(question)).thenReturn(dummyDto());

        service.replaceImage(questionId, pngFile());

        Media attached = question.getMedia();
        assertThat(attached).isNotNull();
        assertThat(attached.getType()).isEqualTo(MediaType.IMAGE);
        assertThat(attached.getUrl()).isEqualTo("https://r2/new.png");
        assertThat(attached.getStorageKey()).isEqualTo("questions/images/new.png");
        assertThat(attached.getInlineSvg()).isNull();
        assertThat(attached.getContentType()).isEqualTo("image/png");
        assertThat(attached.getSizeBytes()).isEqualTo(4L);

        verify(mediaManager).save(attached);
        verify(questionManager).save(question);
        // Pas d'ancienne clé → pas de suppression R2.
        verify(r2Client, never()).deleteObject(anyString());
    }

    @Test
    void replaceImageReusesExistingMediaAndDeletesOldObject() {
        UUID questionId = UUID.randomUUID();
        Question question = new Question();
        Media existing = new Media();
        existing.setType(MediaType.IMAGE);
        existing.setStorageKey("questions/images/old.png");
        question.setMedia(existing);

        when(questionManager.findById(questionId)).thenReturn(Optional.of(question));
        when(r2Client.uploadImage(anyString(), any(), eq("image/png")))
                .thenReturn(new R2UploadResult("questions/images/new.png", "https://r2/new.png"));
        when(mapper.toDto(question)).thenReturn(dummyDto());

        service.replaceImage(questionId, pngFile());

        assertThat(question.getMedia()).isSameAs(existing);
        assertThat(existing.getStorageKey()).isEqualTo("questions/images/new.png");
        verify(r2Client).deleteObject("questions/images/old.png");
    }

    @Test
    void replaceImageOnUnknownQuestionThrowsNotFound() {
        UUID questionId = UUID.randomUUID();
        when(questionManager.findById(questionId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.replaceImage(questionId, pngFile()))
                .isInstanceOf(NotFoundException.class);
        verify(r2Client, never()).uploadImage(anyString(), any(), anyString());
    }

    private QuestionDto dummyDto() {
        return new QuestionDto(
                UUID.randomUUID(), null, null, null, null, null, null,
                null, null, null, null, null, null, null, null,
                "stmt", null, true, null, null, java.util.List.of());
    }
}
