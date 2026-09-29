package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Locale;

/**
 * La liste blanche des destinataires, active en dev (arbitrage n°11).
 *
 * <p>🛑 Une liste VIDE bloque tout : un nouveau mail ajoute au systeme ne peut
 * pas partir par accident vers un vrai utilisateur depuis un poste de dev, tant
 * que la liste n'est pas explicitement configuree ({@code EMAIL_DEV_ALLOWLIST}).
 * Une entree {@code @domaine.fr} autorise tout le domaine.
 */
@Component
@RequiredArgsConstructor
public class EmailAllowlist {

    private final EmailProperties properties;

    public boolean isEnabled() {
        return properties.getAllowlist().isEnabled();
    }

    public boolean allows(String recipient) {
        if (!isEnabled()) return true;
        if (recipient == null || recipient.isBlank()) return false;
        String r = recipient.trim().toLowerCase(Locale.ROOT);
        for (String raw : properties.getAllowlist().getAddresses()) {
            if (raw == null || raw.isBlank()) continue;
            String entry = raw.trim().toLowerCase(Locale.ROOT);
            if (entry.startsWith("@") ? r.endsWith(entry) : r.equals(entry)) {
                return true;
            }
        }
        return false;
    }
}
