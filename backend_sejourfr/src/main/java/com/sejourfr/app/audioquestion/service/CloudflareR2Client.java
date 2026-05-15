package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.CloudflareR2Properties;
import com.sejourfr.app.audioquestion.exception.AudioGenerationException;
import com.sejourfr.app.audioquestion.exception.AudioServicesUnavailableException;
import com.sejourfr.app.audioquestion.exception.R2UploadException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.exception.SdkException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.util.UUID;

/**
 * Upload et suppression des MP3 audio sur Cloudflare R2.
 * Convention de cle : audio/&lt;media_uuid&gt;.mp3
 */
@Service
public class CloudflareR2Client {

    private static final Logger log = LoggerFactory.getLogger(CloudflareR2Client.class);
    private static final String CACHE_CONTROL = "public, max-age=31536000, immutable";
    private static final String CONTENT_TYPE = "audio/mpeg";

    private final S3Client s3Client;
    private final CloudflareR2Properties props;

    public CloudflareR2Client(S3Client s3Client, CloudflareR2Properties props) {
        this.s3Client = s3Client;
        this.props = props;
    }

    @Retryable(
        retryFor = R2UploadException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
    )
    public R2UploadResult uploadAudio(UUID mediaId, byte[] mp3Bytes) {
        if (!props.isConfigured()) {
            throw new AudioServicesUnavailableException(
                "R2 non configure (account-id, access-key-id, secret-access-key, public-url-base requis)"
            );
        }
        String objectKey = "audio/" + mediaId + ".mp3";
        PutObjectRequest request = PutObjectRequest.builder()
            .bucket(props.getBucketName())
            .key(objectKey)
            .contentType(CONTENT_TYPE)
            .contentLength((long) mp3Bytes.length)
            .cacheControl(CACHE_CONTROL)
            .build();

        try {
            long start = System.currentTimeMillis();
            s3Client.putObject(request, RequestBody.fromBytes(mp3Bytes));
            long duration = System.currentTimeMillis() - start;
            String publicUrl = props.getPublicUrlBase().replaceAll("/+$", "") + "/" + objectKey;
            log.info("R2 upload OK key={} size={}B duration={}ms", objectKey, mp3Bytes.length, duration);
            return new R2UploadResult(objectKey, publicUrl);
        } catch (S3Exception e) {
            throw new R2UploadException(
                "R2 upload " + e.statusCode() + " : " + e.awsErrorDetails().errorMessage(), e
            );
        } catch (SdkException e) {
            throw new R2UploadException("R2 upload erreur reseau : " + e.getMessage(), e);
        }
    }

    @Recover
    public R2UploadResult recoverUpload(R2UploadException ex, UUID mediaId, byte[] mp3Bytes) {
        log.error("R2 upload indisponible apres retries : {}", ex.getMessage());
        throw ex;
    }

    @Recover
    public R2UploadResult recoverPassthrough(AudioGenerationException ex, UUID mediaId, byte[] mp3Bytes) {
        throw ex;
    }

    /** Best-effort. N'echoue jamais (rollback contexte) : log + swallow. */
    public void deleteAudio(String objectKey) {
        if (!props.isConfigured()) {
            log.warn("R2 non configure, skip delete {}", objectKey);
            return;
        }
        try {
            s3Client.deleteObject(DeleteObjectRequest.builder()
                .bucket(props.getBucketName())
                .key(objectKey)
                .build());
            log.info("R2 delete OK key={}", objectKey);
        } catch (Exception e) {
            log.warn("R2 delete echoue pour {} : {}", objectKey, e.getMessage());
        }
    }

    public record R2UploadResult(String objectKey, String publicUrl) {}
}
