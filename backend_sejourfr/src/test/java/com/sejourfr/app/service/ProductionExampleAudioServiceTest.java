package com.sejourfr.app.service;

import com.sejourfr.app.audioquestion.service.AzureSpeechClient;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client;
import com.sejourfr.app.dto.ExampleAudioBatchResultDto;
import com.sejourfr.app.dto.ExampleAudioDto;
import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ExampleAudioStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ProductionTaskManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Generation batch + publication des audios d'exemples EO (cf.
 * {@link ProductionExampleAudioService}) : transitions de statut, resilience du
 * batch (un echec n'interrompt pas le lot), garde « EO uniquement ». Unitaire
 * pur (Azure + R2 + manager mockes — aucun appel reseau).
 */
class ProductionExampleAudioServiceTest {

    private ProductionTaskManager taskManager;
    private AzureSpeechClient azureSpeechClient;
    private CloudflareR2Client r2Client;
    private ProductionExampleAudioService service;

    @BeforeEach
    void setUp() {
        taskManager = mock(ProductionTaskManager.class);
        azureSpeechClient = mock(AzureSpeechClient.class);
        r2Client = mock(CloudflareR2Client.class);
        service = new ProductionExampleAudioService(taskManager, azureSpeechClient, r2Client);
        when(taskManager.saveExample(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private ProductionExample example(ExampleAudioStatus status) {
        ProductionExample e = new ProductionExample();
        e.setTaskId(UUID.randomUUID());
        e.setContenu("Bonjour. Je m'appelle Karim.");
        e.setDisplayOrder(0);
        e.setAudioStatus(status);
        return e;
    }

    private void stubEoTask(ProductionExample e) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(EpreuveType.TCF_EO);
        when(taskManager.findById(e.getTaskId())).thenReturn(Optional.of(t));
    }

    // ------------------------------------------------------------------------
    // countPendingAudio
    // ------------------------------------------------------------------------

    @Test
    void countPendingAudio_delegue_au_manager() {
        when(taskManager.countEoExamplesNeedingAudio(any())).thenReturn(7L);
        assertThat(service.countPendingAudio()).isEqualTo(7L);
    }

    // ------------------------------------------------------------------------
    // generateBatchAudio
    // ------------------------------------------------------------------------

    @Test
    void generateBatchAudio_succes_passe_l_exemple_en_GENERATED_avec_url() {
        ProductionExample e = example(ExampleAudioStatus.PENDING);
        when(taskManager.findEoExamplesNeedingAudio(any(), org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn(List.of(e));
        when(azureSpeechClient.synthesize(any())).thenReturn(new byte[6000]);
        when(r2Client.uploadAudio(any(), any()))
                .thenReturn(new CloudflareR2Client.R2UploadResult("audio/x.mp3", "https://cdn/x.mp3"));

        ExampleAudioBatchResultDto result = service.generateBatchAudio(10);

        assertThat(result.requested()).isEqualTo(1);
        assertThat(result.succeeded()).isEqualTo(1);
        assertThat(result.failed()).isZero();
        assertThat(result.outcomes()).singleElement()
                .satisfies(o -> assertThat(o.success()).isTrue());
        assertThat(e.getAudioStatus()).isEqualTo(ExampleAudioStatus.GENERATED);
        assertThat(e.getAudioUrl()).isEqualTo("https://cdn/x.mp3");
    }

    @Test
    void generateBatchAudio_echec_azure_marque_ERROR_sans_interrompre_le_lot() {
        ProductionExample ok = example(ExampleAudioStatus.PENDING);
        ProductionExample ko = example(ExampleAudioStatus.PENDING);
        when(taskManager.findEoExamplesNeedingAudio(any(), org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn(List.of(ok, ko));
        when(r2Client.uploadAudio(any(), any()))
                .thenReturn(new CloudflareR2Client.R2UploadResult("audio/x.mp3", "https://cdn/x.mp3"));
        // 1er OK, 2e leve.
        when(azureSpeechClient.synthesize(any()))
                .thenReturn(new byte[6000])
                .thenThrow(new RuntimeException("Azure 500"));

        ExampleAudioBatchResultDto result = service.generateBatchAudio(10);

        assertThat(result.succeeded()).isEqualTo(1);
        assertThat(result.failed()).isEqualTo(1);
        assertThat(ok.getAudioStatus()).isEqualTo(ExampleAudioStatus.GENERATED);
        assertThat(ko.getAudioStatus()).isEqualTo(ExampleAudioStatus.ERROR);
        assertThat(ko.getAudioError()).contains("Azure 500");
    }

    // ------------------------------------------------------------------------
    // publishExampleAudio
    // ------------------------------------------------------------------------

    @Test
    void publishExampleAudio_passe_GENERATED_a_PUBLISHED() {
        ProductionExample e = example(ExampleAudioStatus.GENERATED);
        when(taskManager.findExampleById(any())).thenReturn(Optional.of(e));
        stubEoTask(e);

        ExampleAudioDto dto = service.publishExampleAudio(UUID.randomUUID());

        assertThat(e.getAudioStatus()).isEqualTo(ExampleAudioStatus.PUBLISHED);
        assertThat(dto.audioStatus()).isEqualTo(ExampleAudioStatus.PUBLISHED);
    }

    @Test
    void publishExampleAudio_statut_non_GENERATED_refuse() {
        ProductionExample e = example(ExampleAudioStatus.PENDING);
        when(taskManager.findExampleById(any())).thenReturn(Optional.of(e));
        stubEoTask(e);

        assertThatThrownBy(() -> service.publishExampleAudio(UUID.randomUUID()))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void publishExampleAudio_exemple_introuvable_renvoie_404() {
        when(taskManager.findExampleById(any())).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.publishExampleAudio(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void publishExampleAudio_exemple_non_EO_refuse() {
        ProductionExample e = example(ExampleAudioStatus.GENERATED);
        when(taskManager.findExampleById(any())).thenReturn(Optional.of(e));
        ProductionTask ee = new ProductionTask();
        ee.setEpreuve(EpreuveType.TCF_EE);
        when(taskManager.findById(e.getTaskId())).thenReturn(Optional.of(ee));

        assertThatThrownBy(() -> service.publishExampleAudio(UUID.randomUUID()))
                .isInstanceOf(BusinessException.class);
    }

    // ------------------------------------------------------------------------
    // regenerateExampleAudio
    // ------------------------------------------------------------------------

    @Test
    void regenerate_succes_repasse_en_GENERATED() {
        ProductionExample e = example(ExampleAudioStatus.GENERATED);
        UUID id = UUID.randomUUID();
        when(taskManager.findExampleById(id)).thenReturn(Optional.of(e));
        stubEoTask(e);
        when(azureSpeechClient.synthesize(any())).thenReturn(new byte[12000]);
        when(r2Client.uploadAudio(any(), any()))
                .thenReturn(new CloudflareR2Client.R2UploadResult("audio/y.mp3", "https://cdn/y.mp3"));

        ExampleAudioDto dto = service.regenerateExampleAudio(id, "fr-FR-DeniseNeural");

        assertThat(dto.audioStatus()).isEqualTo(ExampleAudioStatus.GENERATED);
        assertThat(e.getAudioVoice()).isEqualTo("fr-FR-DeniseNeural");
    }

    @Test
    void regenerate_echec_marque_ERROR_sans_propager() {
        ProductionExample e = example(ExampleAudioStatus.GENERATED);
        UUID id = UUID.randomUUID();
        when(taskManager.findExampleById(id)).thenReturn(Optional.of(e));
        stubEoTask(e);
        when(azureSpeechClient.synthesize(any())).thenThrow(new RuntimeException("Azure KO"));

        ExampleAudioDto dto = service.regenerateExampleAudio(id, null);

        assertThat(dto.audioStatus()).isEqualTo(ExampleAudioStatus.ERROR);
        verify(r2Client, never()).uploadAudio(any(), any());
    }
}
