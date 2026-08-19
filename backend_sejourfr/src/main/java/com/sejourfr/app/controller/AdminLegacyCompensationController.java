package com.sejourfr.app.controller;

import com.sejourfr.app.dto.LegacyCompensationMailingResponse;
import com.sejourfr.app.service.billing.LegacyCompensationMailingService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Déclenchement manuel du mailing d'annonce aux acheteurs de l'ancien catalogue
 * Intégral (compensés par la migration V038).
 *
 * <p>{@code dryRun=true} par défaut : un appel sans paramètre ne fait que
 * compter les destinataires. Il faut écrire {@code ?dryRun=false} pour envoyer —
 * on n'écrit pas à de vrais clients par accident.
 *
 * <p>Sécurité : {@code /api/admin/**} → ROLE_ADMIN (cf. SecurityConfig).
 */
@RestController
@RequestMapping("/api/admin/mailing")
@RequiredArgsConstructor
public class AdminLegacyCompensationController {

    private final LegacyCompensationMailingService legacyCompensationMailingService;

    @PostMapping("/anciens-acheteurs")
    public LegacyCompensationMailingResponse anciensAcheteurs(
            @RequestParam(defaultValue = "true") boolean dryRun) {
        return legacyCompensationMailingService.envoyer(dryRun);
    }
}
