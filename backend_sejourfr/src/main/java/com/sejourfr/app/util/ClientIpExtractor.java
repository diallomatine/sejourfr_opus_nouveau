package com.sejourfr.app.util;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Extrait l'IP du client depuis une requête HTTP en tenant compte des
 * reverse-proxies usuels (Cloudflare / Nginx / load balancers).
 * <p>
 * Ordre de résolution :
 * <ol>
 *   <li>Premier IP du header {@code X-Forwarded-For} (si présent et non vide) ;</li>
 *   <li>{@code X-Real-IP} (si présent et non vide) ;</li>
 *   <li>{@link HttpServletRequest#getRemoteAddr()} en dernier recours.</li>
 * </ol>
 * On normalise les valeurs vides / "unknown" en {@code null}. Utilisé par le
 * pipeline d'attempts démo pour appliquer un quota par IP.
 */
public final class ClientIpExtractor {

    private static final String HEADER_FORWARDED_FOR = "X-Forwarded-For";
    private static final String HEADER_REAL_IP = "X-Real-IP";
    private static final String FALLBACK_UNKNOWN = "unknown";

    private ClientIpExtractor() {
    }

    public static String extract(HttpServletRequest req) {
        if (req == null) return null;

        String forwarded = sanitize(req.getHeader(HEADER_FORWARDED_FOR));
        if (forwarded != null) {
            // X-Forwarded-For peut contenir une liste "client, proxy1, proxy2"
            int comma = forwarded.indexOf(',');
            String first = comma >= 0 ? forwarded.substring(0, comma).trim() : forwarded;
            String cleaned = sanitize(first);
            if (cleaned != null) return cleaned;
        }

        String realIp = sanitize(req.getHeader(HEADER_REAL_IP));
        if (realIp != null) return realIp;

        return sanitize(req.getRemoteAddr());
    }

    private static String sanitize(String raw) {
        if (raw == null) return null;
        String trimmed = raw.trim();
        if (trimmed.isEmpty()) return null;
        if (FALLBACK_UNKNOWN.equalsIgnoreCase(trimmed)) return null;
        return trimmed;
    }
}
