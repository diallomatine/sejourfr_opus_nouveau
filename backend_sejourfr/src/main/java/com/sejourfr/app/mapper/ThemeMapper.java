package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ThemeDto;
import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.entity.Theme;
import org.springframework.stereotype.Component;

@Component
public class ThemeMapper {

    /** Vue admin : nombre total de questions (incluant inactives). */
    public ThemeDto toAdminDto(Theme t, long totalQuestionCount) {
        return new ThemeDto(
                t.getId(),
                t.getModule(),
                t.getCode(),
                t.getName(),
                t.getDescription(),
                t.getDisplayOrder(),
                totalQuestionCount
        );
    }

    /** Vue utilisateur : seules les questions actives sont comptees. */
    public ThemeUserResponse toUserResponse(Theme t, int activeQuestionCount) {
        return new ThemeUserResponse(
                t.getId(),
                t.getModule(),
                t.getCode(),
                t.getName(),
                t.getDescription(),
                t.getDisplayOrder(),
                activeQuestionCount
        );
    }
}
