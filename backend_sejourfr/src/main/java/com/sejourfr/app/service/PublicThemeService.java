package com.sejourfr.app.service;

import com.sejourfr.app.dto.ThemeUserResponse;
import com.sejourfr.app.enums.Module;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Variante publique (non authentifiée) de {@link ThemeUserService}.
 * <p>
 * Pour l'instant {@link ThemeUserResponse} ne contient pas de stats user
 * (favoris / erreurs / locked), donc on délègue directement. Si le DTO
 * évolue pour porter des champs dépendants de l'utilisateur, c'est ici
 * qu'on les neutralisera (locked=false, stats null) avant exposition.
 */
@Service
public class PublicThemeService {

    private final ThemeUserService themeUserService;

    public PublicThemeService(ThemeUserService themeUserService) {
        this.themeUserService = themeUserService;
    }

    @Transactional(readOnly = true)
    public List<ThemeUserResponse> list(Module module) {
        return themeUserService.list(module);
    }
}
