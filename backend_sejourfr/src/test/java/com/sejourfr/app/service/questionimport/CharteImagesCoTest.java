package com.sejourfr.app.service.questionimport;

import com.sejourfr.app.config.QuestionImportProperties;
import com.sejourfr.app.service.ImageUploadSupport.FormatImage;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CharteImagesCoTest {

    @Test
    void charte_v1_chargee() {
        CharteImagesCo charte = new CharteImagesCo(new QuestionImportProperties());

        assertThat(charte.version()).isEqualTo("charte-images-co-v1");
        assertThat(charte.formats()).containsExactlyInAnyOrder(FormatImage.PNG, FormatImage.WEBP);
        assertThat(charte.largeurMinPx()).isEqualTo(800);
        assertThat(charte.fondOpaque()).isTrue();
        assertThat(charte.ratioConforme(1200, 900)).isTrue();
        assertThat(charte.ratioConforme(1024, 768)).isTrue();
        assertThat(charte.ratioConforme(1920, 1080)).isFalse();
        assertThat(charte.ratioConforme(0, 600)).isFalse();
    }

    @Test
    void charte_introuvable_echoue_au_demarrage() {
        QuestionImportProperties props = new QuestionImportProperties();
        props.setCharte("generation_questions/charte-inexistante.json");

        assertThatThrownBy(() -> new CharteImagesCo(props)).isInstanceOf(IllegalStateException.class);
    }
}
