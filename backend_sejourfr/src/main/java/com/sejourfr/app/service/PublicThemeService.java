package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.enums.Module;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Variante publique (non authentifiee) de {@link ThemeUserService}.
 * <p>
 * Pour l'instant {@link ThemeUserResponse} ne contient pas de stats user
 * (favoris / erreurs / locked), donc on delegue directement. Si le DTO evolue
 * pour porter des champs dependant de l'utilisateur, c'est ici qu'on les
 * neutralisera (locked=false, stats null) avant exposition.
 */
@Service
@RequiredArgsConstructor
public class PublicThemeService {

    private final ThemeUserService themeUserService;

    @Transactional(readOnly = true)
    public List<ThemeUserResponse> list(Module module) {
        return themeUserService.list(module);
    }
}
