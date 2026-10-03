package com.sejourfr.app.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "sejourfr.security.jwt")
public class JwtProperties {

    private String issuer = "sejourfr-backend";
    private String secret;
    private int accessTokenTtlMinutes = 60;
    private int refreshTokenTtlDays = 30;

    /**
     * Purge de {@code refresh_tokens} ({@code RefreshTokenPurgeJob}, Europe/Paris).
     * {@code "-"} l'eteint (profil de test). Apres la purge analytics de 04:10.
     */
    private String refreshTokenPurgeCron = "0 25 4 * * *";

    /**
     * Une ligne est purgee ce nombre de jours apres son {@code expires_at},
     * revoquee ou non. Une ligne revoquee NON expiree reste : elle sert a la
     * detection de reutilisation. Vie maximale d'une ligne : TTL + marge (37 j).
     */
    private int refreshTokenPurgeGraceDays = 7;

    /** Lignes supprimees par transaction de purge. */
    private int refreshTokenPurgeBatchSize = 1000;

    public String getIssuer() { return issuer; }
    public void setIssuer(String issuer) { this.issuer = issuer; }

    public String getSecret() { return secret; }
    public void setSecret(String secret) { this.secret = secret; }

    public int getAccessTokenTtlMinutes() { return accessTokenTtlMinutes; }
    public void setAccessTokenTtlMinutes(int accessTokenTtlMinutes) { this.accessTokenTtlMinutes = accessTokenTtlMinutes; }

    public int getRefreshTokenTtlDays() { return refreshTokenTtlDays; }
    public void setRefreshTokenTtlDays(int refreshTokenTtlDays) { this.refreshTokenTtlDays = refreshTokenTtlDays; }

    public String getRefreshTokenPurgeCron() { return refreshTokenPurgeCron; }
    public void setRefreshTokenPurgeCron(String refreshTokenPurgeCron) { this.refreshTokenPurgeCron = refreshTokenPurgeCron; }

    public int getRefreshTokenPurgeGraceDays() { return refreshTokenPurgeGraceDays; }
    public void setRefreshTokenPurgeGraceDays(int refreshTokenPurgeGraceDays) {
        this.refreshTokenPurgeGraceDays = refreshTokenPurgeGraceDays;
    }

    public int getRefreshTokenPurgeBatchSize() { return refreshTokenPurgeBatchSize; }
    public void setRefreshTokenPurgeBatchSize(int refreshTokenPurgeBatchSize) {
        this.refreshTokenPurgeBatchSize = refreshTokenPurgeBatchSize;
    }
}
