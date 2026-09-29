package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import java.util.List;

@ConfigurationProperties(prefix = "sejourfr.storage")
public class StorageProperties {

    /** "local" pour l'instant. "s3" plus tard. */
    private String provider = "local";
    private long maxFileSizeBytes = 26_214_400L; // 25 MB
    private List<String> allowedImageTypes = List.of("image/png", "image/jpeg", "image/webp");
    private List<String> allowedAudioTypes = List.of("audio/mpeg", "audio/mp3", "audio/ogg", "audio/wav");
    private Local local = new Local();

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public long getMaxFileSizeBytes() { return maxFileSizeBytes; }
    public void setMaxFileSizeBytes(long maxFileSizeBytes) { this.maxFileSizeBytes = maxFileSizeBytes; }

    public List<String> getAllowedImageTypes() { return allowedImageTypes; }
    public void setAllowedImageTypes(List<String> allowedImageTypes) { this.allowedImageTypes = allowedImageTypes; }

    public List<String> getAllowedAudioTypes() { return allowedAudioTypes; }
    public void setAllowedAudioTypes(List<String> allowedAudioTypes) { this.allowedAudioTypes = allowedAudioTypes; }

    public Local getLocal() { return local; }
    public void setLocal(Local local) { this.local = local; }

    public static class Local {
        private String root = "./var/uploads";
        private String publicBaseUrl = "http://localhost:8080/files";

        public String getRoot() { return root; }
        public void setRoot(String root) { this.root = root; }

        public String getPublicBaseUrl() { return publicBaseUrl; }
        public void setPublicBaseUrl(String publicBaseUrl) { this.publicBaseUrl = publicBaseUrl; }
    }
}
