package com.sejourfr.app.util;

import com.sejourfr.app.config.TrustedProxyProperties;
import jakarta.annotation.PostConstruct;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;

/**
 * Determine l'IP reelle de l'appelant. Sert d'identite a tout ce qui est
 * compte par IP : rate-limits anti-abus (login, inscription, mot de passe
 * oublie, contact, demo) et attempts invites ({@code attempts.client_ip}).
 *
 * <p><strong>Regle</strong> : {@code X-Forwarded-For} / {@code X-Real-IP} ne
 * sont lus QUE si la connexion arrive d'un proxy declare de confiance
 * ({@link TrustedProxyProperties}). Sinon on retient l'IP de la socket. Ces
 * en-tetes sont posables par n'importe quel client : leur faire confiance
 * inconditionnellement rendait tous les compteurs par IP decoratifs (un
 * en-tete different a chaque requete = un compteur neuf a chaque requete).
 *
 * <p>Quand la connexion vient bien d'un proxy de confiance, on retient la
 * <em>derniere</em> adresse de la chaine {@code X-Forwarded-For} qui n'est pas
 * elle-meme un proxy de confiance : les valeurs qu'un client aurait injectees
 * se retrouvent a GAUCHE de celle ajoutee par notre proxy, donc ignorees.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ClientIpResolver {

    private static final String HEADER_FORWARDED_FOR = "X-Forwarded-For";
    private static final String HEADER_REAL_IP = "X-Real-IP";
    private static final String FALLBACK_UNKNOWN = "unknown";
    private static final String TRUST_ALL = "*";

    private final TrustedProxyProperties properties;

    private boolean trustAll;
    private List<CidrRange> trustedRanges = List.of();

    @PostConstruct
    void parseRanges() {
        List<CidrRange> parsed = new ArrayList<>();
        boolean all = false;
        for (String raw : properties.getRanges()) {
            String entry = raw == null ? "" : raw.trim();
            if (entry.isEmpty()) continue;
            if (TRUST_ALL.equals(entry)) {
                all = true;
                continue;
            }
            CidrRange range = CidrRange.parse(entry);
            if (range == null) {
                log.warn("Proxy de confiance ignore (adresse/CIDR illisible) : {}", entry);
                continue;
            }
            parsed.add(range);
        }
        this.trustAll = all;
        this.trustedRanges = List.copyOf(parsed);
        if (trustAll) {
            log.warn("sejourfr.trusted-proxies.ranges contient '*' : les en-tetes X-Forwarded-For "
                    + "sont acceptes de n'importe quel appelant. A reserver aux deploiements dont "
                    + "le port n'est joignable que par le load balancer.");
        } else if (trustedRanges.isEmpty()) {
            log.info("Aucun proxy de confiance configure : l'IP client est celle de la socket "
                    + "(X-Forwarded-For ignore).");
        }
    }

    /** IP retenue pour l'appelant, ou {@code null} si non determinable. */
    public String resolve(HttpServletRequest request) {
        if (request == null) return null;

        String remoteAddr = sanitize(request.getRemoteAddr());
        if (remoteAddr == null || !isTrustedProxy(remoteAddr)) {
            // Connexion directe (ou proxy inconnu) : les en-tetes sont ceux du
            // client lui-meme, donc sans valeur — seule la socket fait foi.
            return remoteAddr;
        }

        String forwarded = lastUntrusted(request.getHeader(HEADER_FORWARDED_FOR));
        if (forwarded != null) return forwarded;

        String realIp = sanitize(request.getHeader(HEADER_REAL_IP));
        if (realIp != null) return realIp;

        return remoteAddr;
    }

    /** Vrai si {@code ip} appartient a un proxy declare de confiance. */
    public boolean isTrustedProxy(String ip) {
        if (trustAll) return true;
        if (trustedRanges.isEmpty() || ip == null) return false;
        byte[] address = toBytes(ip);
        if (address == null) return false;
        for (CidrRange range : trustedRanges) {
            if (range.contains(address)) return true;
        }
        return false;
    }

    /**
     * Derniere adresse de la chaine qui n'est pas un proxy de confiance
     * (parcours de droite a gauche). {@code null} si la chaine est vide ou
     * entierement composee de proxys connus.
     */
    private String lastUntrusted(String headerValue) {
        String header = sanitize(headerValue);
        if (header == null) return null;
        String[] hops = header.split(",");
        if (trustAll) {
            // Toute la chaine est reputee de confiance : le parcours de droite a
            // gauche n'aurait rien a retenir. On prend la premiere entree,
            // convention usuelle quand on delegue entierement au LB.
            for (String hop : hops) {
                String cleaned = sanitize(hop);
                if (cleaned != null) return cleaned;
            }
            return null;
        }
        for (int i = hops.length - 1; i >= 0; i--) {
            String hop = sanitize(hops[i]);
            if (hop == null) continue;
            if (!isTrustedProxy(hop)) return hop;
        }
        return null;
    }

    private static String sanitize(String raw) {
        if (raw == null) return null;
        String trimmed = raw.trim();
        if (trimmed.isEmpty()) return null;
        if (FALLBACK_UNKNOWN.equalsIgnoreCase(trimmed)) return null;
        return trimmed;
    }

    /** Octets d'une adresse LITTERALE (aucune resolution DNS). */
    private static byte[] toBytes(String literal) {
        String candidate = literal;
        int percent = candidate.indexOf('%'); // zone IPv6 (fe80::1%eth0)
        if (percent > 0) candidate = candidate.substring(0, percent);
        if (candidate.isEmpty() || Character.isLetter(candidate.charAt(0))
                && candidate.indexOf(':') < 0) {
            return null; // nom d'hote : on ne resout pas
        }
        try {
            return InetAddress.getByName(candidate).getAddress();
        } catch (UnknownHostException | SecurityException e) {
            return null;
        }
    }

    /** Plage d'adresses (CIDR ou adresse seule = prefixe complet). */
    private record CidrRange(byte[] network, int prefixBits) {

        static CidrRange parse(String entry) {
            int slash = entry.indexOf('/');
            String host = slash < 0 ? entry : entry.substring(0, slash);
            byte[] network = toBytes(host);
            if (network == null) return null;
            int bits = network.length * 8;
            if (slash >= 0) {
                try {
                    bits = Integer.parseInt(entry.substring(slash + 1).trim());
                } catch (NumberFormatException e) {
                    return null;
                }
                if (bits < 0 || bits > network.length * 8) return null;
            }
            return new CidrRange(network, bits);
        }

        boolean contains(byte[] address) {
            if (address.length != network.length) return false;
            int fullBytes = prefixBits / 8;
            for (int i = 0; i < fullBytes; i++) {
                if (address[i] != network[i]) return false;
            }
            int remainingBits = prefixBits % 8;
            if (remainingBits == 0) return true;
            int mask = 0xFF << (8 - remainingBits);
            return (address[fullBytes] & mask) == (network[fullBytes] & mask);
        }
    }
}
