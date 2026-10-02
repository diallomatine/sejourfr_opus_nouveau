package com.sejourfr.app.service.adminuser;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.service.SubscriptionService;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;

/**
 * Empreinte de l'état d'accès d'un compte (décisions courantes + achats), lue
 * par la modale et renvoyée avec l'action : si elle a changé entre-temps (autre
 * admin, webhook de remboursement), l'action est refusée en 409 (G-11). Verrou
 * optimiste sans colonne {@code version}.
 */
final class VersionAcces {

    private VersionAcces() {}

    static String de(SubscriptionService.DonneesAcces d) {
        List<String> parts = new ArrayList<>();
        for (AccessOverride o : d.decisions()) {
            if (o.estCourante()) parts.add("o:" + o.getId());
        }
        for (UserSubscription s : d.achats()) {
            parts.add("s:" + s.getId() + ":" + s.getStatus() + ":" + s.getEndsAt() + ":" + s.getPaymentStatus());
        }
        parts.sort(String::compareTo);
        try {
            byte[] h = MessageDigest.getInstance("SHA-256")
                    .digest(String.join("|", parts).getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(h, 0, 8);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponible", e);
        }
    }
}
