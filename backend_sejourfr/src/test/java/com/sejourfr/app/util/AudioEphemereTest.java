package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * La promesse « l'audio d'un candidat ne survit pas a son usage » n'est pas une
 * intention : elle est tenue par un {@code finally}. Ces tests la figent.
 */
class AudioEphemereTest {

    @Test
    void lesOctetsSontEffacesApresUnUsageReussi() {
        byte[] audio = {1, 2, 3, 4, 5};

        String resultat = AudioEphemere.avecOctets(audio, octets -> "transcrit:" + octets.length);

        assertThat(resultat).isEqualTo("transcrit:5");
        assertThat(audio).containsOnly((byte) 0);
    }

    /**
     * LE cas qui compte : Whisper indisponible, quota, exception inattendue —
     * les octets partent quand meme. Sans le {@code finally}, un echec etait
     * exactement le chemin ou l'enregistrement restait lisible en memoire.
     */
    @Test
    void lesOctetsSontEffacesMemeQuandLUsageEchoue() {
        byte[] audio = {9, 9, 9};

        assertThatThrownBy(() -> AudioEphemere.avecOctets(audio, octets -> {
            throw new IllegalStateException("Whisper indisponible");
        })).isInstanceOf(IllegalStateException.class);

        assertThat(audio).containsOnly((byte) 0);
    }

    /**
     * L'action voit les octets REELS : effacer avant l'usage rendrait la
     * garantie inutile en transcrivant du silence.
     */
    @Test
    void lActionVoitLesOctetsAvantEffacement() {
        byte[] audio = {7, 8};

        byte[] copie = AudioEphemere.avecOctets(audio, octets -> octets.clone());

        assertThat(copie).containsExactly((byte) 7, (byte) 8);
        assertThat(audio).containsOnly((byte) 0);
    }

    @Test
    void effacerTolereUnTableauAbsent() {
        AudioEphemere.effacer(null);
        AudioEphemere.effacer(new byte[0]);
    }
}
