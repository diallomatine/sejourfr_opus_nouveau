package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.ClientPlatform;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

/**
 * Un visiteur anonyme, porteur de son attribution.
 *
 * <p><b>L'ecriture ne passe PAS par cette entite</b> : elle se fait par un
 * unique {@code INSERT ... ON CONFLICT} natif
 * ({@code AnalyticsVisitorRepository.upsert}), parce que c'est le seul moyen de
 * garantir <i>atomiquement</i> les deux invariants qui font toute la valeur de
 * la table : le first touch n'est jamais reecrit, le last touch ne l'est que
 * sur une source explicite. Un « lire puis ecrire » cote Java laisserait deux
 * requetes concurrentes du meme visiteur (deux onglets, un double-clic) poser
 * deux first touch differents.
 *
 * <p>Cette entite existe donc pour la <b>lecture</b>.
 */
@Entity
@Table(name = "analytics_visitor")
public class AnalyticsVisitor {

    @Id
    @Column(name = "anonymous_id", columnDefinition = "uuid")
    private UUID anonymousId;

    @Column(name = "first_seen_at", nullable = false)
    private Instant firstSeenAt;

    @Column(name = "last_seen_at", nullable = false)
    private Instant lastSeenAt;

    // --- First touch : fige a la premiere requete, jamais reecrit ------------

    @Column(name = "ft_source", nullable = false, length = 40)
    private String firstTouchSource;

    @Column(name = "ft_medium", length = 40)
    private String firstTouchMedium;

    @Column(name = "ft_campaign", length = 120)
    private String firstTouchCampaign;

    @Column(name = "ft_content", length = 120)
    private String firstTouchContent;

    @Column(name = "ft_term", length = 120)
    private String firstTouchTerm;

    @Column(name = "ft_landing_path", length = 160)
    private String firstTouchLandingPath;

    /** Hote seul, jamais l'URL complete. */
    @Column(name = "ft_referrer_host", length = 120)
    private String firstTouchReferrerHost;

    // --- Last touch : reecrit sur source explicite ---------------------------

    @Column(name = "lt_source", nullable = false, length = 40)
    private String lastTouchSource;

    @Column(name = "lt_medium", length = 40)
    private String lastTouchMedium;

    @Column(name = "lt_campaign", length = 120)
    private String lastTouchCampaign;

    @Column(name = "lt_content", length = 120)
    private String lastTouchContent;

    @Column(name = "lt_term", length = 120)
    private String lastTouchTerm;

    @Column(name = "lt_seen_at", nullable = false)
    private Instant lastTouchSeenAt;

    // --- Resolus serveur ----------------------------------------------------

    /** ISO alpha-2. {@code null} = inconnu, jamais « autre ». */
    @Column(name = "country_code", length = 2)
    private String countryCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "device_type", nullable = false, length = 16)
    private AnalyticsDeviceType deviceType;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", nullable = false, length = 16)
    private ClientPlatform platform;

    public UUID getAnonymousId() { return anonymousId; }
    public void setAnonymousId(UUID anonymousId) { this.anonymousId = anonymousId; }

    public Instant getFirstSeenAt() { return firstSeenAt; }
    public void setFirstSeenAt(Instant firstSeenAt) { this.firstSeenAt = firstSeenAt; }

    public Instant getLastSeenAt() { return lastSeenAt; }
    public void setLastSeenAt(Instant lastSeenAt) { this.lastSeenAt = lastSeenAt; }

    public String getFirstTouchSource() { return firstTouchSource; }
    public void setFirstTouchSource(String firstTouchSource) { this.firstTouchSource = firstTouchSource; }

    public String getFirstTouchMedium() { return firstTouchMedium; }
    public void setFirstTouchMedium(String firstTouchMedium) { this.firstTouchMedium = firstTouchMedium; }

    public String getFirstTouchCampaign() { return firstTouchCampaign; }
    public void setFirstTouchCampaign(String firstTouchCampaign) { this.firstTouchCampaign = firstTouchCampaign; }

    public String getFirstTouchContent() { return firstTouchContent; }
    public void setFirstTouchContent(String firstTouchContent) { this.firstTouchContent = firstTouchContent; }

    public String getFirstTouchTerm() { return firstTouchTerm; }
    public void setFirstTouchTerm(String firstTouchTerm) { this.firstTouchTerm = firstTouchTerm; }

    public String getFirstTouchLandingPath() { return firstTouchLandingPath; }
    public void setFirstTouchLandingPath(String firstTouchLandingPath) { this.firstTouchLandingPath = firstTouchLandingPath; }

    public String getFirstTouchReferrerHost() { return firstTouchReferrerHost; }
    public void setFirstTouchReferrerHost(String firstTouchReferrerHost) { this.firstTouchReferrerHost = firstTouchReferrerHost; }

    public String getLastTouchSource() { return lastTouchSource; }
    public void setLastTouchSource(String lastTouchSource) { this.lastTouchSource = lastTouchSource; }

    public String getLastTouchMedium() { return lastTouchMedium; }
    public void setLastTouchMedium(String lastTouchMedium) { this.lastTouchMedium = lastTouchMedium; }

    public String getLastTouchCampaign() { return lastTouchCampaign; }
    public void setLastTouchCampaign(String lastTouchCampaign) { this.lastTouchCampaign = lastTouchCampaign; }

    public String getLastTouchContent() { return lastTouchContent; }
    public void setLastTouchContent(String lastTouchContent) { this.lastTouchContent = lastTouchContent; }

    public String getLastTouchTerm() { return lastTouchTerm; }
    public void setLastTouchTerm(String lastTouchTerm) { this.lastTouchTerm = lastTouchTerm; }

    public Instant getLastTouchSeenAt() { return lastTouchSeenAt; }
    public void setLastTouchSeenAt(Instant lastTouchSeenAt) { this.lastTouchSeenAt = lastTouchSeenAt; }

    public String getCountryCode() { return countryCode; }
    public void setCountryCode(String countryCode) { this.countryCode = countryCode; }

    public AnalyticsDeviceType getDeviceType() { return deviceType; }
    public void setDeviceType(AnalyticsDeviceType deviceType) { this.deviceType = deviceType; }

    public ClientPlatform getPlatform() { return platform; }
    public void setPlatform(ClientPlatform platform) { this.platform = platform; }
}
