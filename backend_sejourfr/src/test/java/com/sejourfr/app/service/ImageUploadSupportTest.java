package com.sejourfr.app.service;

import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.service.ImageUploadSupport.Dimensions;
import com.sejourfr.app.service.ImageUploadSupport.FormatImage;
import com.sejourfr.app.support.ImagesDeTest;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ImageUploadSupportTest {

    private static final byte[] PNG = ImagesDeTest.png(40, 30);
    private static final byte[] JPEG = ImagesDeTest.jpeg(40, 30);
    private static final byte[] WEBP = ImagesDeTest.webpVp8x(40, 30, false);

    @Test
    void validJpeg_returnsValidatedImageWithExtension() {
        MockMultipartFile file = new MockMultipartFile("img", "p.jpg", "image/jpeg", JPEG);

        ImageUploadSupport.ValidatedImage v = ImageUploadSupport.validate(file);

        assertThat(v.contentType()).isEqualTo("image/jpeg");
        assertThat(v.extension()).isEqualTo("jpg");
        assertThat(v.bytes()).isEqualTo(JPEG);
    }

    @Test
    void validPng_returnsPngExtension() {
        MockMultipartFile file = new MockMultipartFile("img", "p.png", "image/png", PNG);
        assertThat(ImageUploadSupport.validate(file).extension()).isEqualTo("png");
    }

    @Test
    void validWebp_returnsWebpExtension() {
        MockMultipartFile file = new MockMultipartFile("img", "p.webp", "image/webp", WEBP);
        assertThat(ImageUploadSupport.validate(file).extension()).isEqualTo("webp");
    }

    @Test
    void contentType_caseInsensitive() {
        MockMultipartFile file = new MockMultipartFile("img", "p.jpg", "IMAGE/JPEG", JPEG);
        assertThat(ImageUploadSupport.validate(file).extension()).isEqualTo("jpg");
    }

    @Test
    void nullFile_rejected() {
        assertThatThrownBy(() -> ImageUploadSupport.validate(null))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void emptyFile_rejected() {
        MockMultipartFile file = new MockMultipartFile("img", "p.jpg", "image/jpeg", new byte[0]);
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void oversizeFile_rejected() {
        byte[] big = new byte[(int) (ImageUploadSupport.MAX_BYTES + 1)];
        System.arraycopy(JPEG, 0, big, 0, JPEG.length);
        MockMultipartFile file = new MockMultipartFile("img", "p.jpg", "image/jpeg", big);
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("volumineuse");
    }

    @Test
    void unsupportedContentType_rejected() {
        MockMultipartFile file = new MockMultipartFile("img", "f.gif", "image/gif", PNG);
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Format non supporte");
    }

    @Test
    void nullContentType_rejected() {
        MockMultipartFile file = new MockMultipartFile("img", "f.bin", null, PNG);
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class);
    }

    // --- signature lue sur les octets -------------------------------------

    @Test
    void contenuQuiNEstPasUneImage_refuse_meme_avec_un_type_declare_valide() {
        MockMultipartFile file = new MockMultipartFile("img", "p.png", "image/png", new byte[]{1, 2, 3, 4});
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("n'est pas une image");
    }

    @Test
    void typeDeclareMenteur_refuse() {
        MockMultipartFile file = new MockMultipartFile("img", "p.png", "image/png", JPEG);
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("ne correspond pas");
    }

    @Test
    void detecterFormat_lit_les_trois_signatures() {
        assertThat(ImageUploadSupport.detecterFormat(PNG)).contains(FormatImage.PNG);
        assertThat(ImageUploadSupport.detecterFormat(JPEG)).contains(FormatImage.JPEG);
        assertThat(ImageUploadSupport.detecterFormat(WEBP)).contains(FormatImage.WEBP);
        assertThat(ImageUploadSupport.detecterFormat("GIF89a......".getBytes())).isEmpty();
        assertThat(ImageUploadSupport.detecterFormat(new byte[0])).isEmpty();
        assertThat(ImageUploadSupport.detecterFormat(null)).isEmpty();
    }

    // --- dimensions -------------------------------------------------------

    @Test
    void dimensions_png_et_jpeg_par_imageio() {
        assertThat(ImageUploadSupport.lireDimensions(ImagesDeTest.png(800, 600), FormatImage.PNG))
                .contains(new Dimensions(800, 600));
        assertThat(ImageUploadSupport.lireDimensions(ImagesDeTest.jpeg(1024, 768), FormatImage.JPEG))
                .contains(new Dimensions(1024, 768));
    }

    @Test
    void dimensions_webp_lues_dans_les_trois_entetes() {
        assertThat(ImageUploadSupport.lireDimensions(ImagesDeTest.webpVp8x(1200, 900, false), FormatImage.WEBP))
                .contains(new Dimensions(1200, 900));
        assertThat(ImageUploadSupport.lireDimensions(ImagesDeTest.webpVp8l(1600, 1200, false), FormatImage.WEBP))
                .contains(new Dimensions(1600, 1200));
        assertThat(ImageUploadSupport.lireDimensions(ImagesDeTest.webpVp8(800, 600), FormatImage.WEBP))
                .contains(new Dimensions(800, 600));
    }

    @Test
    void dimensions_illisibles_rendent_vide() {
        assertThat(ImageUploadSupport.lireDimensions(new byte[]{(byte) 0x89, 'P', 'N', 'G'}, FormatImage.PNG)).isEmpty();
        byte[] tronque = java.util.Arrays.copyOf(ImagesDeTest.webpVp8x(800, 600, false), 22);
        assertThat(ImageUploadSupport.lireDimensions(tronque, FormatImage.WEBP)).isEmpty();
    }

    // --- transparence -----------------------------------------------------

    @Test
    void transparence_png_lue_sur_les_pixels() {
        assertThat(ImageUploadSupport.aDeLaTransparence(ImagesDeTest.png(40, 30), FormatImage.PNG)).isFalse();
        assertThat(ImageUploadSupport.aDeLaTransparence(ImagesDeTest.pngRgba(40, 30, false), FormatImage.PNG))
                .as("une PNG RGBA entierement opaque passe").isFalse();
        assertThat(ImageUploadSupport.aDeLaTransparence(ImagesDeTest.pngRgba(40, 30, true), FormatImage.PNG)).isTrue();
    }

    @Test
    void transparence_webp_lue_sur_l_entete() {
        assertThat(ImageUploadSupport.aDeLaTransparence(ImagesDeTest.webpVp8x(40, 30, true), FormatImage.WEBP)).isTrue();
        assertThat(ImageUploadSupport.aDeLaTransparence(ImagesDeTest.webpVp8x(40, 30, false), FormatImage.WEBP)).isFalse();
        assertThat(ImageUploadSupport.aDeLaTransparence(ImagesDeTest.webpVp8l(40, 30, true), FormatImage.WEBP)).isTrue();
        assertThat(ImageUploadSupport.aDeLaTransparence(ImagesDeTest.webpVp8(40, 30), FormatImage.WEBP)).isFalse();
        assertThat(ImageUploadSupport.aDeLaTransparence(JPEG, FormatImage.JPEG)).isFalse();
    }
}
