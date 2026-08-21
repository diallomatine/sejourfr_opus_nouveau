package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AudienceFunnelResponse;
import com.sejourfr.app.service.AudienceFunnelService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Funnel d'acquisition par compte, lu depuis la console admin.
 *
 * <p>A ne pas confondre avec {@code /api/admin/page-views}, qui sert l'agregat
 * ANONYME du pre-inscription. Les deux mesures cohabitent et ne se melangent
 * jamais dans une meme reponse.
 */
@RestController
@RequestMapping("/api/admin/audience")
@RequiredArgsConstructor
public class AdminAudienceController {

    private final AudienceFunnelService audienceFunnelService;

    /**
     * {@code from}/{@code to} sont des dates ISO {@code yyyy-MM-dd}, bornes
     * <b>incluses</b>, en Europe/Paris — {@code from == to} est le cas normal
     * « une seule journée ». Fournies, elles l'emportent sur {@code days} ;
     * absentes, on retombe sur la fenêtre glissante (défaut 30, borné 1..365).
     * Une seule des deux bornes est une erreur nommée (400), jamais un repli
     * muet — cf. {@code FenetreMesure}.
     */
    @GetMapping("/funnel")
    public AudienceFunnelResponse funnel(
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(defaultValue = "30") int days
    ) {
        return audienceFunnelService.funnel(from, to, days);
    }
}
