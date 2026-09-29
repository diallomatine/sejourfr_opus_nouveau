package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.repository.ThemeRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TcfCoThemeResolverTest {

    @Mock
    private ThemeRepository themeRepository;

    private Theme tcfCoTheme() {
        Theme theme = new Theme();
        theme.setCode("TCF_CO");
        theme.setName("Comprehension orale");
        return theme;
    }

    @Test
    void resolve_renvoie_le_theme_code_TCF_CO() {
        Theme theme = tcfCoTheme();
        when(themeRepository.findByCode("TCF_CO")).thenReturn(Optional.of(theme));

        TcfCoThemeResolver resolver = new TcfCoThemeResolver(themeRepository);

        assertThat(resolver.resolve()).isSameAs(theme);
    }

    @Test
    void resolve_met_en_cache_apres_le_premier_lookup() {
        when(themeRepository.findByCode("TCF_CO")).thenReturn(Optional.of(tcfCoTheme()));

        TcfCoThemeResolver resolver = new TcfCoThemeResolver(themeRepository);
        resolver.resolve();
        resolver.resolve();

        verify(themeRepository, times(1)).findByCode("TCF_CO");
    }

    @Test
    void resolve_leve_si_le_theme_est_absent_en_base() {
        when(themeRepository.findByCode("TCF_CO")).thenReturn(Optional.empty());

        TcfCoThemeResolver resolver = new TcfCoThemeResolver(themeRepository);

        assertThatThrownBy(resolver::resolve)
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("TCF_CO");
    }
}
