package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillReferenceDto;
import com.sejourfr.app.entity.SkillReference;
import org.springframework.stereotype.Component;

/**
 * Mapper pur {@link SkillReference} -&gt; {@link SkillReferenceDto}. L'ordre
 * pedagogique de la liste est garanti en amont par
 * {@code SkillPromptManager.findReferencesByPromptId}.
 */
@Component
public class SkillReferenceMapper {

    public SkillReferenceDto toDto(SkillReference reference) {
        return new SkillReferenceDto(
                reference.getLevel(),
                reference.getText(),
                reference.getPedagogicalNote());
    }
}
