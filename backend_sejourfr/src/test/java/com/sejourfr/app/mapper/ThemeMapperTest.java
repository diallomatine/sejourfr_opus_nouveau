package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ThemeDto;
import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ThemeMapperTest {

    private final ThemeMapper mapper = new ThemeMapper();

    private Theme theme(UUID id) {
        Theme t = new Theme();
        t.setId(id);
        t.setModule(Module.CIVIQUE);
        t.setCode("REPUBLIQUE");
        t.setName("La République");
        t.setDescription("Symboles et valeurs");
        t.setDisplayOrder(3);
        return t;
    }

    @Test
    void toAdminDto_mapsEveryFieldWithTotalCount() {
        UUID id = UUID.randomUUID();

        ThemeDto dto = mapper.toAdminDto(theme(id), 57L);

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.module()).isEqualTo(Module.CIVIQUE);
        assertThat(dto.code()).isEqualTo("REPUBLIQUE");
        assertThat(dto.name()).isEqualTo("La République");
        assertThat(dto.description()).isEqualTo("Symboles et valeurs");
        assertThat(dto.displayOrder()).isEqualTo(3);
        assertThat(dto.questionCount()).isEqualTo(57L);
    }

    @Test
    void toUserResponse_mapsEveryFieldWithActiveCount() {
        UUID id = UUID.randomUUID();

        ThemeUserResponse dto = mapper.toUserResponse(theme(id), 12);

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.module()).isEqualTo(Module.CIVIQUE);
        assertThat(dto.code()).isEqualTo("REPUBLIQUE");
        assertThat(dto.name()).isEqualTo("La République");
        assertThat(dto.description()).isEqualTo("Symboles et valeurs");
        assertThat(dto.displayOrder()).isEqualTo(3);
        assertThat(dto.questionCount()).isEqualTo(12);
    }
}
