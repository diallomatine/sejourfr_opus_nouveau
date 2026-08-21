package com.sejourfr.app.controller;

import com.sejourfr.app.dto.PageViewStatsResponse;
import com.sejourfr.app.service.PageViewService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Lecture de l'audience des landings depuis la console admin. */
@RestController
@RequestMapping("/api/admin/page-views")
@RequiredArgsConstructor
public class AdminPageViewController {

    private final PageViewService pageViewService;

    /** Pages mesurées, pour alimenter le sélecteur côté admin. */
    @GetMapping("/paths")
    public List<String> trackedPaths() {
        return PageViewService.TRACKED_PATHS.stream().sorted().toList();
    }

    /**
     * {@code from}/{@code to} sont des dates ISO {@code yyyy-MM-dd}, bornes
     * <b>incluses</b>, en Europe/Paris. Fournies, elles l'emportent sur
     * {@code days} ; absentes, on retombe sur la fenêtre glissante. Une seule
     * des deux bornes est une erreur nommée (400) et jamais un repli muet — cf.
     * {@code FenetreMesure}.
     */
    @GetMapping
    public PageViewStatsResponse stats(
            @RequestParam(defaultValue = "/reussir") String path,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(defaultValue = "30") int days
    ) {
        return pageViewService.stats(path, from, to, days);
    }
}
