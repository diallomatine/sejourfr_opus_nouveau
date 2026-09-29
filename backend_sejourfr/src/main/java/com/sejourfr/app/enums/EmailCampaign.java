package com.sejourfr.app.enums;

import java.util.Arrays;

/**
 * Les campagnes d'information de service, lancees par un admin
 * ({@code POST /api/admin/campaigns/{code}/send}). Le code est celui de l'URL et
 * de {@code email_campaign_log.campaign_code} (V080).
 */
public enum EmailCampaign {

    INCIDENT("incident", EmailType.CAMPAIGN_INCIDENT),
    REPRISE("reprise", EmailType.CAMPAIGN_REPRISE);

    private final String code;
    private final EmailType emailType;

    EmailCampaign(String code, EmailType emailType) {
        this.code = code;
        this.emailType = emailType;
    }

    public String code() {
        return code;
    }

    public EmailType emailType() {
        return emailType;
    }

    public static EmailCampaign fromCode(String code) {
        return Arrays.stream(values())
                .filter(c -> c.code.equals(code))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Campagne inconnue : " + code
                        + " (attendu : incident ou reprise)"));
    }
}
