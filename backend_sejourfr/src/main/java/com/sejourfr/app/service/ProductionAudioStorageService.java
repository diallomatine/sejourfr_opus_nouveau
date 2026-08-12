package com.sejourfr.app.service;

import com.sejourfr.app.audioquestion.config.CloudflareR2Properties;
import com.sejourfr.app.audioquestion.exception.AudioServicesUnavailableException;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.exception.ProductionEvaluationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.exception.SdkException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.time.Duration;
import java.util.UUID;

/**
 * Stockage des audios soumis par les utilisateurs (epreuve EO). Reutilise
 * le bucket R2 deja configure pour l'audio CO, mais sous un prefix dedie
 * {@code submissions/} et avec un cache-control prive (URL signee 15 min).
 * <p>
 * Convention de cle : {@code submissions/<submissionId>.<ext>}.
 * Le content-type est fourni par l'orchestrateur (depuis le MultipartFile).
 */
@Service
public class ProductionAudioStorageService {

    private static final Logger log = LoggerFactory.getLogger(ProductionAudioStorageService.class);
    private static final String KEY_PREFIX = "submissions/";
    private static final String CACHE_CONTROL_PRIVATE = "private, max-age=0, no-store";

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    private final CloudflareR2Properties r2Props;
    private final ProductionEvaluationProperties evalProps;

    public ProductionAudioStorageService(
            S3Client s3Client,
            S3Presigner s3Presigner,
            CloudflareR2Properties r2Props,
            ProductionEvaluationProperties evalProps) {
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
        this.r2Props = r2Props;
        this.evalProps = evalProps;
    }

    public StoredAudio upload(UUID submissionId, byte[] bytes, String contentType, String extension) {
        ensureConfigured();
        String safeExt = (extension == null || extension.isBlank()) ? "bin" : extension.toLowerCase();
        String objectKey = KEY_PREFIX + submissionId + "." + safeExt;
        String safeContentType = (contentType == null || contentType.isBlank())
            ? "application/octet-stream"
            : contentType;

        PutObjectRequest request = PutObjectRequest.builder()
            .bucket(r2Props.getBucketName())
            .key(objectKey)
            .contentType(safeContentType)
            .contentLength((long) bytes.length)
            .cacheControl(CACHE_CONTROL_PRIVATE)
            .build();

        try {
            long start = System.currentTimeMillis();
            s3Client.putObject(request, RequestBody.fromBytes(bytes));
            long duration = System.currentTimeMillis() - start;
            log.info("R2 submission upload OK key={} size={}B contentType={} duration={}ms",
                objectKey, bytes.length, safeContentType, duration);
            return new StoredAudio(objectKey, safeContentType);
        } catch (S3Exception e) {
            throw new ProductionEvaluationException(
                "R2 upload submission " + e.statusCode() + " : " + e.awsErrorDetails().errorMessage(), e
            );
        } catch (SdkException e) {
            throw new ProductionEvaluationException("R2 upload submission erreur reseau : " + e.getMessage(), e);
        }
    }

    /** Telecharge l'integralite de l'audio en RAM (audio <= 25 Mo cf. props). */
    public byte[] download(String objectKey) {
        ensureConfigured();
        GetObjectRequest req = GetObjectRequest.builder()
            .bucket(r2Props.getBucketName())
            .key(objectKey)
            .build();
        try {
            ResponseBytes<GetObjectResponse> resp = s3Client.getObjectAsBytes(req);
            return resp.asByteArray();
        } catch (NoSuchKeyException e) {
            throw new ProductionEvaluationException("Audio submission introuvable : " + objectKey, e);
        } catch (S3Exception e) {
            throw new ProductionEvaluationException(
                "R2 download submission " + e.statusCode() + " : " + e.awsErrorDetails().errorMessage(), e
            );
        } catch (SdkException e) {
            throw new ProductionEvaluationException("R2 download submission erreur reseau : " + e.getMessage(), e);
        }
    }

    /** URL signee GET (TTL = sejourfr.production-evaluation.presigned-url-expiry-minutes). */
    public String presignGet(String objectKey) {
        ensureConfigured();
        Duration ttl = Duration.ofMinutes(evalProps.getPresignedUrlExpiryMinutes());
        GetObjectRequest get = GetObjectRequest.builder()
            .bucket(r2Props.getBucketName())
            .key(objectKey)
            .build();
        GetObjectPresignRequest presignReq = GetObjectPresignRequest.builder()
            .signatureDuration(ttl)
            .getObjectRequest(get)
            .build();
        PresignedGetObjectRequest presigned = s3Presigner.presignGetObject(presignReq);
        return presigned.url().toString();
    }

    /** Nettoyage best-effort d'un upload devenu orphelin (course de double soumission). */
    public void delete(String objectKey) {
        if (objectKey == null || objectKey.isBlank() || !r2Props.isConfigured()) return;
        try {
            s3Client.deleteObject(DeleteObjectRequest.builder()
                    .bucket(r2Props.getBucketName())
                    .key(objectKey)
                    .build());
            log.info("R2 submission delete OK key={}", objectKey);
        } catch (Exception e) {
            log.warn("R2 submission delete echoue pour {} : {}", objectKey, e.getMessage());
        }
    }

    private void ensureConfigured() {
        if (!r2Props.isConfigured()) {
            throw new AudioServicesUnavailableException(
                "Cloudflare R2 non configure (account-id, access-key-id, secret-access-key, public-url-base requis)."
            );
        }
    }

    public record StoredAudio(String objectKey, String contentType) {}
}
