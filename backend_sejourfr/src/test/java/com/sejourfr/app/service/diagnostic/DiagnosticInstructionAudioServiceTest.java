package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.audioquestion.config.AzureSpeechProperties;
import com.sejourfr.app.audioquestion.config.CloudflareR2Properties;
import com.sejourfr.app.audioquestion.service.AzureSpeechClient;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.ProductionTaskManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class DiagnosticInstructionAudioServiceTest {

    private static final UUID TASK_ID = UUID.fromString("d1a60000-0000-5000-8000-000000000002");
    private static final String CODE = "INITIAL_TCF";

    private ProductionTaskManager taskManager;
    private AzureSpeechClient azure;
    private CloudflareR2Client r2;
    private AzureSpeechProperties azureProperties;
    private CloudflareR2Properties r2Properties;
    private DiagnosticInstructionAudioService service;
    private ProductionTask task;

    @BeforeEach
    void setUp() {
        taskManager = mock(ProductionTaskManager.class);
        azure = mock(AzureSpeechClient.class);
        r2 = mock(CloudflareR2Client.class);
        azureProperties = new AzureSpeechProperties();
        r2Properties = new CloudflareR2Properties();
        service = new DiagnosticInstructionAudioService(
                taskManager, azure, r2, azureProperties, r2Properties);

        task = new ProductionTask();
        task.setId(TASK_ID);
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setDiagnosticCode(CODE);
        task.setDiagnosticVersion(1);
        task.setActive(true);
        task.setConsigne("Écoutez & répondez <naturellement>.");
        when(taskManager.findActiveDiagnostic(CODE, 1, EpreuveType.TCF_EO))
                .thenReturn(Optional.of(task));
        when(taskManager.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(r2.audioObjectKey(TASK_ID)).thenReturn("audio/" + TASK_ID + ".mp3");
    }

    @Test
    void statusNAppellePasR2QuandLaConfigurationEstAbsente() {
        var status = service.status(CODE, 1);

        assertThat(status.r2Configured()).isFalse();
        assertThat(status.azureConfigured()).isFalse();
        assertThat(status.objectPresent()).isFalse();
        verify(r2, never()).audioExists(any());
    }

    @Test
    void generationRefuseAvantLaSyntheseSiAzureEstAbsentEtObjetR2Absent() {
        configureR2();
        when(r2.audioExists(TASK_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.generate(CODE, 1))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Azure Speech");
        verify(azure, never()).synthesize(any());
        verify(r2, never()).uploadAudio(any(), any());
    }

    @Test
    void objetDejaPresentRepareLUrlSansRegenerer() {
        configureR2();
        when(r2.audioExists(TASK_ID)).thenReturn(true);
        when(r2.audioPublicUrl(TASK_ID)).thenReturn("https://audio.example/audio/fixe.mp3");

        var result = service.generate(CODE, 1);

        assertThat(result.generatedNow()).isFalse();
        assertThat(result.objectPresent()).isTrue();
        assertThat(task.getInstructionAudioUrl()).isEqualTo("https://audio.example/audio/fixe.mp3");
        verify(taskManager).save(task);
        verify(azure, never()).synthesize(any());
        verify(r2, never()).uploadAudio(any(), any());
    }

    @Test
    void objetDejaPresentSansForceNAppelleJamaisAzure() {
        configureExternalServices();
        when(r2.audioExists(TASK_ID)).thenReturn(true);
        when(r2.audioPublicUrl(TASK_ID)).thenReturn(canonicalUrl());
        task.setInstructionAudioUrl(canonicalUrl());

        var result = service.generate(CODE, 1);

        assertThat(result.generatedNow()).isFalse();
        verifyNoInteractions(azure);
        verify(r2, never()).uploadAudio(any(), any());
        verify(taskManager, never()).save(any());
    }

    @Test
    void forceRegenereSousLaMemeCleSansChangerLUrlEnBase() {
        configureExternalServices();
        when(r2.audioExists(TASK_ID)).thenReturn(true);
        task.setInstructionAudioUrl(canonicalUrl());
        task.setConsigne("Nouvelle consigne en trois etapes.");
        when(azure.synthesize(any())).thenReturn(new byte[]{4, 5, 6});
        when(r2.uploadAudio(eq(TASK_ID), any(byte[].class)))
                .thenReturn(new CloudflareR2Client.R2UploadResult(
                        "audio/" + TASK_ID + ".mp3", canonicalUrl()));

        var result = service.generate(CODE, 1, true);

        ArgumentCaptor<String> ssml = ArgumentCaptor.forClass(String.class);
        verify(azure, times(1)).synthesize(ssml.capture());
        assertThat(ssml.getValue()).contains("Nouvelle consigne en trois etapes.");
        verify(r2, times(1)).uploadAudio(eq(TASK_ID), any(byte[].class));
        // Ecrasement en place : jamais de suppression, donc jamais de 404 transitoire.
        verify(r2, never()).deleteAudio(any());
        verify(r2, never()).deleteObject(any());
        assertThat(result.generatedNow()).isTrue();
        assertThat(result.objectKey()).isEqualTo("audio/" + TASK_ID + ".mp3");
        assertThat(result.audioUrl()).isEqualTo(canonicalUrl());
        assertThat(task.getInstructionAudioUrl()).isEqualTo(canonicalUrl());
    }

    @Test
    void forceRefuseAvantLaSyntheseSiAzureEstAbsent() {
        configureR2();
        when(r2.audioExists(TASK_ID)).thenReturn(true);

        assertThatThrownBy(() -> service.generate(CODE, 1, true))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Azure Speech");
        verifyNoInteractions(azure);
        verify(r2, never()).uploadAudio(any(), any());
    }

    @Test
    void objetAbsentAvecForceGenereCommeSansForce() {
        configureExternalServices();
        when(r2.audioExists(TASK_ID)).thenReturn(false);
        when(azure.synthesize(any())).thenReturn(new byte[]{1});
        when(r2.uploadAudio(eq(TASK_ID), any(byte[].class)))
                .thenReturn(new CloudflareR2Client.R2UploadResult(
                        "audio/" + TASK_ID + ".mp3", canonicalUrl()));

        var result = service.generate(CODE, 1, true);

        verify(azure, times(1)).synthesize(any());
        verify(r2, times(1)).uploadAudio(eq(TASK_ID), any(byte[].class));
        assertThat(result.generatedNow()).isTrue();
        assertThat(result.audioUrl()).isEqualTo(canonicalUrl());
    }

    @Test
    void objetAbsentUtiliseLaCleStableEtLitExactementLaConsigneVisible() {
        configureExternalServices();
        when(r2.audioExists(TASK_ID)).thenReturn(false);
        when(azure.synthesize(any())).thenReturn(new byte[]{1, 2, 3});
        when(r2.uploadAudio(eq(TASK_ID), any(byte[].class)))
                .thenReturn(new CloudflareR2Client.R2UploadResult(
                        "audio/" + TASK_ID + ".mp3", "https://audio.example/audio/" + TASK_ID + ".mp3"));

        var result = service.generate(CODE, 1);

        ArgumentCaptor<String> ssml = ArgumentCaptor.forClass(String.class);
        verify(azure).synthesize(ssml.capture());
        assertThat(ssml.getValue())
                .contains("Écoutez &amp; répondez &lt;naturellement&gt;.")
                .doesNotContain("Diagnostic", "SejourFR");
        verify(r2).uploadAudio(eq(TASK_ID), any(byte[].class));
        assertThat(result.generatedNow()).isTrue();
        assertThat(result.audioUrl()).endsWith("/audio/" + TASK_ID + ".mp3");
    }

    private static String canonicalUrl() {
        return "https://audio.example/audio/" + TASK_ID + ".mp3";
    }

    private void configureExternalServices() {
        azureProperties.setKey("test-key");
        azureProperties.setRegion("francecentral");
        configureR2();
    }

    private void configureR2() {
        r2Properties.setAccountId("account");
        r2Properties.setAccessKeyId("access");
        r2Properties.setSecretAccessKey("secret");
        r2Properties.setBucketName("bucket");
        r2Properties.setPublicUrlBase("https://audio.example");
    }
}
