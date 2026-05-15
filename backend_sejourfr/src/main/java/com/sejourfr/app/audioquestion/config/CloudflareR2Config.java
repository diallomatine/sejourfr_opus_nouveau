package com.sejourfr.app.audioquestion.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

import java.net.URI;

/**
 * Bean S3Client pointe sur l'endpoint Cloudflare R2 (compatible S3 v2).
 * Le client est toujours instancie meme sans credentials reels : le service
 * {@code CloudflareR2Client} verifie {@link CloudflareR2Properties#isConfigured()}
 * avant chaque appel pour eviter de toucher R2 quand l'environnement est vide.
 */
@Configuration
public class CloudflareR2Config {

    @Bean
    public S3Client r2S3Client(CloudflareR2Properties props) {
        String key = blankOrDefault(props.getAccessKeyId(), "MISSING_R2_ACCESS_KEY");
        String secret = blankOrDefault(props.getSecretAccessKey(), "MISSING_R2_SECRET");
        String endpoint = props.getAccountId() == null || props.getAccountId().isBlank()
            ? "https://placeholder.r2.cloudflarestorage.com"
            : props.getEndpoint();

        return S3Client.builder()
            .endpointOverride(URI.create(endpoint))
            .credentialsProvider(StaticCredentialsProvider.create(
                AwsBasicCredentials.create(key, secret)
            ))
            .region(Region.of("auto"))
            .serviceConfiguration(S3Configuration.builder()
                // R2 ne supporte que path-style addressing
                .pathStyleAccessEnabled(true)
                .build())
            .build();
    }

    private static String blankOrDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
