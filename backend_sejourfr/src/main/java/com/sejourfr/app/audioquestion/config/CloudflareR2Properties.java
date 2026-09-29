package com.sejourfr.app.audioquestion.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "sejourfr.r2")
public class CloudflareR2Properties {

    private String accountId = "";
    private String accessKeyId = "";
    private String secretAccessKey = "";
    private String bucketName = "sejourfr-audio";
    private String publicUrlBase = "";
    private int timeoutSec = 30;

    public boolean isConfigured() {
        return notBlank(accountId)
            && notBlank(accessKeyId)
            && notBlank(secretAccessKey)
            && notBlank(bucketName)
            && notBlank(publicUrlBase);
    }

    public String getEndpoint() {
        return "https://" + accountId + ".r2.cloudflarestorage.com";
    }

    private static boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    public String getAccountId() { return accountId; }
    public void setAccountId(String accountId) { this.accountId = accountId; }

    public String getAccessKeyId() { return accessKeyId; }
    public void setAccessKeyId(String accessKeyId) { this.accessKeyId = accessKeyId; }

    public String getSecretAccessKey() { return secretAccessKey; }
    public void setSecretAccessKey(String secretAccessKey) { this.secretAccessKey = secretAccessKey; }

    public String getBucketName() { return bucketName; }
    public void setBucketName(String bucketName) { this.bucketName = bucketName; }

    public String getPublicUrlBase() { return publicUrlBase; }
    public void setPublicUrlBase(String publicUrlBase) { this.publicUrlBase = publicUrlBase; }

    public int getTimeoutSec() { return timeoutSec; }
    public void setTimeoutSec(int timeoutSec) { this.timeoutSec = timeoutSec; }
}
