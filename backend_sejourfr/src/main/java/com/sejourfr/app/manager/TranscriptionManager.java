package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.repository.TranscriptionRepository;
import com.sejourfr.app.util.TranscriptTurnStitcher;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Transcription}.
 *
 * <p><b>Le texte d'une transcription ne sort d'ici que par
 * {@link #findLatestTexteBySubmissionId(UUID)}</b>, qui applique le recollage
 * des tours ({@link TranscriptTurnStitcher}). C'est volontaire : le manager est
 * la seule couche autorisee a toucher le repository, donc le seul passage
 * oblige vers {@code transcriptions.texte}. Il n'existe deliberement AUCUNE
 * methode rendant l'entite, pour qu'aucun appelant — correcteur, controle de
 * preuve ou DTO servi aux fronts — ne puisse lire un transcript non recolle et
 * rompre l'invariant « le texte cite est le texte affiche ».
 *
 * <p>La donnee en base, elle, n'est jamais modifiee : le recollage est une
 * transformation DE LECTURE.
 */
@Component
@RequiredArgsConstructor
public class TranscriptionManager {

    private final TranscriptionRepository repository;
    private final TranscriptTurnStitcher turnStitcher;

    /**
     * LE texte de production d'une submission orale : celui qui est envoye au
     * correcteur, celui sur lequel les preuves sont verifiees, celui que les
     * fronts affichent. En MVP, une seule transcription par submission ; on
     * prend la plus recente.
     */
    public Optional<String> findLatestTexteBySubmissionId(UUID submissionId) {
        return repository.findFirstBySubmissionIdOrderByCreatedAtDesc(submissionId)
            .map(Transcription::getTexte)
            .map(turnStitcher::stitch);
    }

    /** Une transcription existe-t-elle deja (pipeline : faut-il appeler Whisper ?). */
    public boolean existsBySubmissionId(UUID submissionId) {
        return repository.findFirstBySubmissionIdOrderByCreatedAtDesc(submissionId).isPresent();
    }

    public Transcription save(Transcription transcription) {
        return repository.save(transcription);
    }
}
