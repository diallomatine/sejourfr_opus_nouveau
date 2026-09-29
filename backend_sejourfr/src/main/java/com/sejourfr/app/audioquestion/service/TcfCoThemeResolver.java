package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.repository.ThemeRepository;
import org.springframework.stereotype.Component;

/**
 * Resout le Theme TCF_CO (l'unique theme attache aux questions de comprehension orale).
 * Cache l'instance apres le premier lookup : le Theme ne change pas a chaud.
 */
@Component
public class TcfCoThemeResolver {

    private static final String CODE = "TCF_CO";

    private final ThemeRepository themeRepository;
    private volatile Theme cached;

    public TcfCoThemeResolver(ThemeRepository themeRepository) {
        this.themeRepository = themeRepository;
    }

    public Theme resolve() {
        Theme t = cached;
        if (t != null) return t;
        synchronized (this) {
            if (cached != null) return cached;
            cached = themeRepository.findByCode(CODE).orElseThrow(() ->
                new IllegalStateException(
                    "Theme " + CODE + " absent en base. Verifier le seed V2 (reference)."
                ));
            return cached;
        }
    }
}
