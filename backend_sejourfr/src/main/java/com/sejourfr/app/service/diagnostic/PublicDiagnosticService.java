package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.dto.PublicDiagnosticExerciseDto;
import com.sejourfr.app.dto.PublicDiagnosticResponse;
import com.sejourfr.app.entity.ProductionTask;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Lecture publique des sujets du diagnostic, pour un visiteur sans compte.
 *
 * <p><strong>C'est le seul besoin serveur du parcours invité.</strong> Le
 * visiteur rédige ; tout reste côté client jusqu'à la création du compte
 * ({@code 50_} §3.1 : localStorage / secure storage, aucun {@code anon_id}).
 * Aucune {@code diagnostic_sessions}, aucun {@code attempts}, aucun objet R2
 * n'est créé ici, et rien d'un autre candidat n'est lisible : cette classe ne
 * rend que du contenu seedé.
 *
 * <p>🛑 <b>Le sujet écrit est TIRÉ ICI, une fois</b> (L3, {@code 10_} §3.3), et
 * le client le renvoie à la création de sa session. Retirer au sort plus tard
 * donnerait au candidat un énoncé différent de celui qu'il vient de traiter.
 *
 * <p>🛑 <b>{@code oral} peut être {@code null}</b> : le diagnostic rapide n'a
 * pas d'étape orale ({@code 50_} §3.2). C'est une forme, pas une panne.
 */
@Service
@RequiredArgsConstructor
public class PublicDiagnosticService {

    private final DiagnosticContentResolver content;

    /** Version active du diagnostic et ses sujets, dans l'ordre du parcours. */
    public PublicDiagnosticResponse current() {
        String code = content.activeCode();
        int version = content.activeVersion(code);
        return new PublicDiagnosticResponse(
                code, version,
                exercise(content.drawWrittenTask(code, version)),
                content.oralTask(code, version).map(this::exercise).orElse(null));
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
