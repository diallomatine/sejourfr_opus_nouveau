package com.sejourfr.app.audioquestion.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "sejourfr.azure-speech")
public class AzureSpeechProperties {

    private String key = "";
    private String region = "francecentral";
    private String outputFormat = "audio-24khz-48kbitrate-mono-mp3";
    private int timeoutSec = 30;
    private int maxRetries = 2;

    public boolean isConfigured() {
        return key != null && !key.isBlank()
            && region != null && !region.isBlank();
    }

    public String getTtsEndpointUrl() {
        return "https://" + region + ".tts.speech.microsoft.com/cognitiveservices/v1";
    }

    public String getTokenEndpointUrl() {
        return "https://" + region + ".api.cognitive.microsoft.com/sts/v1.0/issueToken";
    }

    public String getKey() { return key; }
    public void setKey(String key) { this.key = key; }

    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }

    public String getOutputFormat() { return outputFormat; }
    public void setOutputFormat(String outputFormat) { this.outputFormat = outputFormat; }

    public int getTimeoutSec() { return timeoutSec; }
    public void setTimeoutSec(int timeoutSec) { this.timeoutSec = timeoutSec; }

    public int getMaxRetries() { return maxRetries; }
    public void setMaxRetries(int maxRetries) { this.maxRetries = maxRetries; }
}
