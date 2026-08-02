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

    @GetMapping
    public PageViewStatsResponse stats(
            @RequestParam(defaultValue = "/reussir") String path,
            @RequestParam(defaultValue = "30") int days
    ) {
        return pageViewService.stats(path, days);
    }
}
