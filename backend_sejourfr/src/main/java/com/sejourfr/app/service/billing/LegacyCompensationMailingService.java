package com.sejourfr.app.service.billing;

import com.sejourfr.app.dto.LegacyCompensationMailingResponse;
import com.sejourfr.app.entity.LegacyPassCompensation;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.LegacyPassCompensationManager;
import com.sejourfr.app.service.MailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Envoi en lot de l'annonce « SejourFR a changé » aux acheteurs de l'ancien
 * catalogue Intégral compensés par la migration V038.
 *
 * <p>Déclenché à la main depuis la console admin, pas par un job planifié : c'est
 * une opération unique, et on veut voir le nombre de destinataires ({@code
 * dryRun}) avant d'écrire à de vrais clients payants.
 *
 * <p><b>Ce qui garantit qu'on n'écrit pas deux fois</b> : {@code mailed_at} n'est
 * posé qu'après un envoi réussi, et la contrainte unique sur {@code user_id} de
 * {@code legacy_pass_compensations} empêche structurellement un compte d'avoir
 * deux lignes. Rappeler l'endpoint reprend donc exactement les échecs, sans
 * jamais renvoyer à ceux qui ont reçu.
 *
 * <p>Un échec d'envoi ne rollbacke rien et n'interrompt pas la boucle : les
 * destinataires suivants doivent être servis.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LegacyCompensationMailingService {

    private final LegacyPassCompensationManager compensationManager;
    private final MailService mailService;

    @Transactional
    public LegacyCompensationMailingResponse envoyer(boolean dryRun) {
        List<LegacyPassCompensation> aEnvoyer = compensationManager.findAEnvoyer();
        long total = compensationManager.countTotal();
        long dejaEnvoyes = compensationManager.countDejaEnvoyes();

        if (dryRun) {
            log.info("Mailing anciens acheteurs (dry-run) : {} destinataire(s) sur {} compensation(s)",
                    aEnvoyer.size(), total);
            return new LegacyCompensationMailingResponse(
                    total, dejaEnvoyes, aEnvoyer.size(), 0, 0, true);
        }

        Instant now = Instant.now();
        int envoyes = 0;
        int echecs = 0;
        for (LegacyPassCompensation compensation : aEnvoyer) {
            User user = compensation.getUser();
            if (user == null || user.getEmail() == null || user.getEmail().isBlank()) {
                echecs++;
                continue;
            }
            boolean parti;
            try {
                parti = mailService.sendNouveautesAnciensAcheteursEmail(
                        user.getEmail(),
                        user.getFirstName(),
                        compensation.getDaysGranted(),
                        compensation.getSessionsAfter(),
                        compensation.getEndsAtAfter());
            } catch (RuntimeException e) {
                log.warn("Annonce anciens acheteurs échouée pour compensation={} : {}",
                        compensation.getId(), e.getMessage());
                parti = false;
            }
            if (parti) {
                compensation.setMailedAt(now);
                compensationManager.save(compensation);
                envoyes++;
            } else {
                echecs++;
            }
        }
        log.info("Mailing anciens acheteurs : {} envoyé(s), {} échec(s) sur {} destinataire(s)",
                envoyes, echecs, aEnvoyer.size());
        return new LegacyCompensationMailingResponse(
                total, dejaEnvoyes, aEnvoyer.size(), envoyes, echecs, false);
    }
}
