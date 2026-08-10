package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.dto.PublicDiagnosticExerciseDto;
import com.sejourfr.app.dto.PublicDiagnosticResponse;
import com.sejourfr.app.entity.ProductionTask;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Lecture publique des deux sujets du diagnostic, pour un visiteur sans compte.
 *
 * <p><strong>C'est le seul besoin serveur du parcours invité.</strong> Le
 * visiteur rédige son EE et s'enregistre en EO ; tout reste côté client jusqu'à
 * la création du compte. Aucune {@code diagnostic_sessions}, aucun
 * {@code attempts}, aucun objet R2 n'est créé ici, et rien d'un autre candidat
 * n'est lisible : cette classe ne rend que du contenu seedé, identique pour
 * tout le monde.
 */
@Service
@RequiredArgsConstructor
public class PublicDiagnosticService {

    private final DiagnosticContentResolver content;

    /** Version active du diagnostic et ses deux sujets, dans l'ordre du parcours. */
    public PublicDiagnosticResponse current() {
        String code = content.activeCode();
        int version = content.activeVersion(code);
        return new PublicDiagnosticResponse(
                code, version,
                exercise(content.writtenTask(code, version)),
                exercise(content.oralTask(code, version)));
    }

    private PublicDiagnosticExerciseDto exercise(ProductionTask task) {
        return new PublicDiagnosticExerciseDto(
                task.getId(), task.getEpreuve(), task.getTitre(), task.getConsigne(),
                DiagnosticContentResolver.helperText(task.getEpreuve()),
                task.getMotsMin(), task.getMotsMax(),
                task.getDureeMinSec(), task.getDureeMaxSec(),
                task.getInstructionAudioUrl());
    }
}
