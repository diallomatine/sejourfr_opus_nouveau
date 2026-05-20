package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.PassageDto;
import com.sejourfr.app.entity.Passage;
import org.springframework.stereotype.Component;

@Component
public class PassageMapper {

    /**
     * Vue admin d'un passage. Le {@code questionCount} est calcule par
     * l'appelant (le mapper reste pur, sans dependance vers un repo).
     */
    public PassageDto toDto(Passage p, long questionCount) {
        return new PassageDto(
                p.getId(),
                p.getType(),
                p.getContent(),
                p.getTheme() != null ? p.getTheme().getId() : null,
                p.getTheme() != null ? p.getTheme().getName() : null,
                p.getMedia() != null ? p.getMedia().getId() : null,
                p.getMedia() != null ? p.getMedia().getUrl() : null,
                p.getMedia() != null ? p.getMedia().getType() : null,
                questionCount
        );
    }
}
