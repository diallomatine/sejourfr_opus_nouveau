package com.sejourfr.app.service.session;

import com.sejourfr.app.manager.RefreshTokenManager;
import com.sejourfr.app.security.JwtProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;

/**
 * Purge de {@code refresh_tokens} : une ligne part
 * {@code refresh-token-purge-grace-days} (7 j) apres son {@code expires_at},
 * revoquee ou non.
 *
 * <p>Pourquoi apres l'echeance et pas a la revocation : passe {@code exp}, le JWT
 * est refuse avant toute lecture de la ligne, qui n'a plus aucun usage. Avant
 * l'echeance, une ligne revoquee sert encore a detecter la reutilisation d'un
 * jeton vole ({@code SessionService.rotate}). La marge ne sert qu'a rapprocher un
 * tel signal d'une session pendant une analyse d'incident.
 *
 * <p>Par lots bornes, <b>une transaction par lot</b> (portee par le manager) :
 * cette methode n'est volontairement pas transactionnelle.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenPurgeService {

    private final RefreshTokenManager refreshTokenManager;
    private final JwtProperties properties;

    /** @return lignes supprimees */
    public int purge(Instant now) {
        int batch = properties.getRefreshTokenPurgeBatchSize();
        if (batch <= 0) {
            log.warn("Purge des refresh tokens ignoree : refresh-token-purge-batch-size={}", batch);
            return 0;
        }
        Instant cutoff = now.minus(Duration.ofDays(properties.getRefreshTokenPurgeGraceDays()));
        int total = 0;
        int deleted;
        do {
            deleted = refreshTokenManager.deleteExpiredBefore(cutoff, batch);
            total += deleted;
        } while (deleted == batch);
        if (total > 0) {
            log.info("Refresh tokens purges : {} (expires avant {})", total, cutoff);
        }
        return total;
    }
}
