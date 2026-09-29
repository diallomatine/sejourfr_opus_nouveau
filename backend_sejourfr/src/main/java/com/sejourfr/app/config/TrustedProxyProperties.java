package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.ArrayList;
import java.util.List;

/**
 * Reverse-proxies dont on accepte les en-tetes {@code X-Forwarded-For} /
 * {@code X-Real-IP} (cf. {@code util.ClientIpResolver}).
 *
 * <p><strong>Vide par defaut</strong> : sans configuration, l'IP retenue est
 * TOUJOURS celle de la socket ({@code getRemoteAddr()}). C'est ce qui rend les
 * rate-limits par IP et l'identite des attempts invites reellement efficaces :
 * n'importe qui pouvait sinon envoyer {@code X-Forwarded-For: 10.0.1.1} et se
 * fabriquer autant d'identites que voulu.
 *
 * <p>En production, renseigner les adresses/plages du (ou des) proxy(s) reels :
 * <pre>
 * sejourfr.trusted-proxies.ranges: 10.0.0.0/8,172.16.0.0/12
 * </pre>
 * Chaque entree est soit une adresse litterale (IPv4/IPv6), soit un CIDR. La
 * valeur speciale {@code *} fait confiance a tout appelant — a n'utiliser que si
 * l'application est strictement inaccessible en direct (PaaS a IP de LB
 * variable), car elle re-ouvre le spoofing a quiconque atteindrait le port.
 */
@ConfigurationProperties(prefix = "sejourfr.trusted-proxies")
public class TrustedProxyProperties {

    /** Adresses ou CIDR des proxys de confiance. Vide = on ne fait confiance a personne. */
    private List<String> ranges = new ArrayList<>();

    public List<String> getRanges() {
        return ranges;
    }

    public void setRanges(List<String> ranges) {
        this.ranges = ranges == null ? new ArrayList<>() : ranges;
    }
}
