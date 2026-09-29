package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AppConfigResponse;
import com.sejourfr.app.service.AppConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;

/**
 * Configuration publique lue par l'application au demarrage, sans compte
 * (controle G, option a) : aujourd'hui la version minimale supportee par
 * systeme. Leger et cachable 5 min : l'app l'appelle a chaque lancement.
 */
@RestController
@RequestMapping("/api/public/app-config")
@RequiredArgsConstructor
public class PublicAppConfigController {

    private final AppConfigService service;

    @GetMapping
    public ResponseEntity<AppConfigResponse> get() {
        return ResponseEntity.ok().cacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic())
                .body(service.current());
    }
}
