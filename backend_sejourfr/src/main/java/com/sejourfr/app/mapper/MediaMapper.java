package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.MediaDto;
import com.sejourfr.app.entity.Media;
import org.springframework.stereotype.Component;

/**
 * Vue admin d'un media (upload/listing). La vue publique embarquee dans une
 * question reste {@code MediaResponse} via {@link QuestionMapper}.
 */
@Component
public class MediaMapper {

    public MediaDto toDto(Media m) {
        return new MediaDto(
                m.getId(),
                m.getType(),
                m.getUrl(),
                m.getOriginalFilename(),
                m.getContentType(),
                m.getSizeBytes(),
                m.getDurationSec(),
                m.getAltText(),
                m.getCreatedAt()
        );
    }
}
