package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.dto.PublicDiagnosticResponse;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

/**
 * La surface publique ne doit rendre que du contenu : ni identifiant de
 * session, ni attempt, ni submission — ces champs n'existent pas dans le DTO,
 * et rien ne doit être écrit pour construire la réponse.
 */
class PublicDiagnosticServiceTest {

    private final DiagnosticContentResolver content = mock(DiagnosticContentResolver.class);
    private final PublicDiagnosticService service = new PublicDiagnosticService(content);

    @Test
    void sertLesDeuxSujetsDeLaVersionActiveAvecLeursBornes() {
        ProductionTask written = task(EpreuveType.TCF_EE, "Une nouvelle activité", 100, 130, null, null, null);
        ProductionTask oral = task(EpreuveType.TCF_EO, "Trouver une activité", null, null, 120, 180,
                "https://cdn.example/audio.mp3");
        when(content.activeCode()).thenReturn("INITIAL_TCF");
        when(content.activeVersion("INITIAL_TCF")).thenReturn(1);
        when(content.drawWrittenTask("INITIAL_TCF", 1)).thenReturn(written);
        when(content.oralTask("INITIAL_TCF", 1)).thenReturn(Optional.of(oral));

        PublicDiagnosticResponse response = service.current();

        assertThat(response.diagnosticCode()).isEqualTo("INITIAL_TCF");
        assertThat(response.diagnosticVersion()).isEqualTo(1);
        assertThat(response.written().productionTaskId()).isEqualTo(written.getId());
        assertThat(response.written().epreuve()).isEqualTo(EpreuveType.TCF_EE);
        assertThat(response.written().title()).isEqualTo("Une nouvelle activité");
        assertThat(response.written().instruction()).isEqualTo(written.getConsigne());
        assertThat(response.written().helperText())
                .isEqualTo(DiagnosticContentResolver.WRITTEN_HELPER);
        assertThat(response.written().wordsMin()).isEqualTo(100);
        assertThat(response.written().wordsMax()).isEqualTo(130);
        assertThat(response.written().durationMinSeconds()).isNull();
        assertThat(response.written().durationMaxSeconds()).isNull();
        assertThat(response.written().instructionAudioUrl()).isNull();

        assertThat(response.oral().epreuve()).isEqualTo(EpreuveType.TCF_EO);
        assertThat(response.oral().helperText()).isEqualTo(DiagnosticContentResolver.ORAL_HELPER);
        assertThat(response.oral().wordsMin()).isNull();
        assertThat(response.oral().durationMinSeconds()).isEqualTo(120);
        assertThat(response.oral().durationMaxSeconds()).isEqualTo(180);
        assertThat(response.oral().instructionAudioUrl()).isEqualTo("https://cdn.example/audio.mp3");
    }

    @Test
    void diagnosticRapideSansEtapeOrale() {
        ProductionTask written = task(EpreuveType.TCF_EE, "Vous et votre quotidien",
                100, 300, null, null, null);
        when(content.activeCode()).thenReturn("QUICK_TCF");
        when(content.activeVersion("QUICK_TCF")).thenReturn(1);
        when(content.drawWrittenTask("QUICK_TCF", 1)).thenReturn(written);
        when(content.oralTask("QUICK_TCF", 1)).thenReturn(Optional.empty());

        PublicDiagnosticResponse response = service.current();

        // 🛑 `oral` NUL est une FORME, pas une panne (L3, `50_` §3.2). Un front
        // qui le traiterait comme une erreur bloquerait tout le parcours.
        assertThat(response.oral()).isNull();
        assertThat(response.written().productionTaskId()).isEqualTo(written.getId());
        // Le sujet écrit doit rester servi avec son identité : c'est lui que le
        // client renvoie à la création de session.
        assertThat(response.written().epreuve()).isEqualTo(EpreuveType.TCF_EE);
    }

    @Test
    void neToucheQuAuCatalogueDeContenu() {
        when(content.activeCode()).thenReturn("INITIAL_TCF");
        when(content.activeVersion("INITIAL_TCF")).thenReturn(1);
        when(content.drawWrittenTask("INITIAL_TCF", 1))
                .thenReturn(task(EpreuveType.TCF_EE, "EE", 100, 130, null, null, null));
        when(content.oralTask("INITIAL_TCF", 1))
                .thenReturn(Optional.of(task(EpreuveType.TCF_EO, "EO", null, null, 120, 180, null)));

        service.current();

        verify(content).activeCode();
        verify(content).activeVersion("INITIAL_TCF");
        verify(content).drawWrittenTask("INITIAL_TCF", 1);
        verify(content).oralTask("INITIAL_TCF", 1);
        verifyNoMoreInteractions(content);
    }

    private static ProductionTask task(
            EpreuveType epreuve, String titre, Integer motsMin, Integer motsMax,
            Integer dureeMin, Integer dureeMax, String audioUrl) {
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(epreuve);
        task.setTitre(titre);
        task.setConsigne("Consigne du sujet " + titre);
        task.setMotsMin(motsMin);
        task.setMotsMax(motsMax);
        task.setDureeMinSec(dureeMin);
        task.setDureeMaxSec(dureeMax);
        task.setInstructionAudioUrl(audioUrl);
        return task;
    }
}
