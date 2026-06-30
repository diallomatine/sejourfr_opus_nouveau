package com.sejourfr.app.service;

import com.sejourfr.app.audioquestion.config.CloudflareR2Properties;
import com.sejourfr.app.audioquestion.exception.AudioServicesUnavailableException;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.exception.ProductionEvaluationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import software.amazon.awssdk.awscore.exception.AwsErrorDetails;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.net.URI;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Stockage R2 des audios EO (cf. {@link ProductionAudioStorageService}) :
 * convention de cle {@code submissions/<id>.<ext>}, garde « R2 non configure »,
 * mapping des erreurs SDK vers {@link ProductionEvaluationException}, URL signee.
 * Unitaire pur (S3Client + S3Presigner mockes — aucun appel reseau).
 */
class ProductionAudioStorageServiceTest {

    private S3Client s3Client;
    private S3Presigner s3Presigner;
    private CloudflareR2Properties r2Props;
    private ProductionEvaluationProperties evalProps;
    private ProductionAudioStorageService service;

    private final UUID submissionId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        s3Client = mock(S3Client.class);
        s3Presigner = mock(S3Presigner.class);
        r2Props = mock(CloudflareR2Properties.class);
        evalProps = mock(ProductionEvaluationProperties.class);
        service = new ProductionAudioStorageService(s3Client, s3Presigner, r2Props, evalProps);
        when(r2Props.isConfigured()).thenReturn(true);
        when(r2Props.getBucketName()).thenReturn("sejourfr-audio");
    }

    // ------------------------------------------------------------------------
    // ensureConfigured
    // ------------------------------------------------------------------------

    @Test
    void upload_refuse_si_R2_non_configure() {
        when(r2Props.isConfigured()).thenReturn(false);
        assertThatThrownBy(() -> service.upload(submissionId, new byte[]{1}, "audio/mpeg", "mp3"))
                .isInstanceOf(AudioServicesUnavailableException.class);
    }

    // ------------------------------------------------------------------------
    // upload : convention de cle + content-type
    // ------------------------------------------------------------------------

    @Test
    void upload_pose_la_cle_submissions_id_ext_et_le_cache_prive() {
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().build());

        ProductionAudioStorageService.StoredAudio stored =
                service.upload(submissionId, new byte[]{1, 2, 3}, "audio/mpeg", "MP3");

        assertThat(stored.objectKey()).isEqualTo("submissions/" + submissionId + ".mp3");
        assertThat(stored.contentType()).isEqualTo("audio/mpeg");

        ArgumentCaptor<PutObjectRequest> captor = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(s3Client).putObject(captor.capture(), any(RequestBody.class));
        PutObjectRequest req = captor.getValue();
        assertThat(req.bucket()).isEqualTo("sejourfr-audio");
        assertThat(req.key()).isEqualTo("submissions/" + submissionId + ".mp3");
        assertThat(req.contentType()).isEqualTo("audio/mpeg");
        assertThat(req.cacheControl()).isEqualTo("private, max-age=0, no-store");
        assertThat(req.contentLength()).isEqualTo(3L);
    }

    @Test
    void upload_extension_vide_retombe_sur_bin_et_content_type_par_defaut() {
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().build());

        ProductionAudioStorageService.StoredAudio stored =
                service.upload(submissionId, new byte[]{1}, "  ", "  ");

        assertThat(stored.objectKey()).isEqualTo("submissions/" + submissionId + ".bin");
        assertThat(stored.contentType()).isEqualTo("application/octet-stream");
    }

    @Test
    void upload_erreur_S3_est_mappee_en_ProductionEvaluationException() {
        S3Exception s3e = (S3Exception) S3Exception.builder()
                .statusCode(403)
                .awsErrorDetails(AwsErrorDetails.builder().errorMessage("denied").build())
                .message("denied")
                .build();
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class))).thenThrow(s3e);

        assertThatThrownBy(() -> service.upload(submissionId, new byte[]{1}, "audio/mpeg", "mp3"))
                .isInstanceOf(ProductionEvaluationException.class);
    }

    // ------------------------------------------------------------------------
    // download
    // ------------------------------------------------------------------------

    @Test
    void download_renvoie_les_octets() {
        byte[] data = {9, 8, 7};
        ResponseBytes<GetObjectResponse> resp =
                ResponseBytes.fromByteArray(GetObjectResponse.builder().build(), data);
        when(s3Client.getObjectAsBytes(any(GetObjectRequest.class))).thenReturn(resp);

        assertThat(service.download("submissions/x.mp3")).containsExactly(9, 8, 7);
    }

    @Test
    void download_cle_absente_mappee_en_ProductionEvaluationException() {
        when(s3Client.getObjectAsBytes(any(GetObjectRequest.class)))
                .thenThrow(NoSuchKeyException.builder().message("missing").build());

        assertThatThrownBy(() -> service.download("submissions/absent.mp3"))
                .isInstanceOf(ProductionEvaluationException.class)
                .hasMessageContaining("introuvable");
    }

    // ------------------------------------------------------------------------
    // presignGet
    // ------------------------------------------------------------------------

    @Test
    void presignGet_utilise_le_TTL_des_props_et_renvoie_l_url() throws Exception {
        when(evalProps.getPresignedUrlExpiryMinutes()).thenReturn(15);
        PresignedGetObjectRequest presigned = mock(PresignedGetObjectRequest.class);
        when(presigned.url()).thenReturn(URI.create("https://signed.example/submissions/x.mp3?sig=abc").toURL());
        when(s3Presigner.presignGetObject(any(GetObjectPresignRequest.class))).thenReturn(presigned);

        String url = service.presignGet("submissions/x.mp3");

        assertThat(url).isEqualTo("https://signed.example/submissions/x.mp3?sig=abc");

        ArgumentCaptor<GetObjectPresignRequest> captor = ArgumentCaptor.forClass(GetObjectPresignRequest.class);
        verify(s3Presigner).presignGetObject(captor.capture());
        assertThat(captor.getValue().signatureDuration()).isEqualTo(java.time.Duration.ofMinutes(15));
    }
}
