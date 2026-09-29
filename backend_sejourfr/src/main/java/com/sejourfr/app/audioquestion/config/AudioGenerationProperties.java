package com.sejourfr.app.audioquestion.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.math.BigDecimal;

@ConfigurationProperties(prefix = "sejourfr.audio-generation")
public class AudioGenerationProperties {

    private int globalTimeoutSec = 120;
    private int rateLimitPerMinute = 10;
    private BigDecimal duplicateSimilarityThreshold = new BigDecimal("0.85");

    public int getGlobalTimeoutSec() { return globalTimeoutSec; }
    public void setGlobalTimeoutSec(int globalTimeoutSec) { this.globalTimeoutSec = globalTimeoutSec; }

    public int getRateLimitPerMinute() { return rateLimitPerMinute; }
    public void setRateLimitPerMinute(int rateLimitPerMinute) { this.rateLimitPerMinute = rateLimitPerMinute; }

    public BigDecimal getDuplicateSimilarityThreshold() { return duplicateSimilarityThreshold; }
    public void setDuplicateSimilarityThreshold(BigDecimal duplicateSimilarityThreshold) {
        this.duplicateSimilarityThreshold = duplicateSimilarityThreshold;
    }
}
