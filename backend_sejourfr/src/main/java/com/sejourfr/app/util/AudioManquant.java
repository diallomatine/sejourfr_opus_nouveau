package com.sejourfr.app.util;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.QuestionType;

/**
 * « Cette question de comprehension orale n'a pas de bande audio » — indicateur
 * de la console admin ({@code QuestionDto.audioMissing}) et filtre
 * {@code media=AUDIO_MISSING}.
 * <ul>
 *   <li>{@code CO_IMAGE} : pas d'{@code audio_media_id} (l'image est le média
 *       principal, l'audio des propositions le second) ;</li>
 *   <li>{@code CO} : pas de média principal AUDIO.</li>
 * </ul>
 * Deux formes de la MEME regle, cote a cote ici et dans
 * {@code QuestionSpecifications.audioManquant} : un test d'integration verifie
 * qu'elles designent les memes lignes. Une {@code CO_IMAGE} sans audio n'est
 * jamais tiree ({@code QuestionRepository.SERVABLE_JPQL}).
 */
public final class AudioManquant {

    private AudioManquant() {}

    public static boolean de(Question q) {
        if (q.getQuestionType() == QuestionType.CO_IMAGE) {
            return q.getAudioMedia() == null;
        }
        if (q.getQuestionType() == QuestionType.CO) {
            return q.getMedia() == null || q.getMedia().getType() != MediaType.AUDIO;
        }
        return false;
    }
}
