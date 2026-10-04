package com.sejourfr.app.service;

import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.service.ImageUploadSupport.Dimensions;
import com.sejourfr.app.service.ImageUploadSupport.FormatImage;
import com.sejourfr.app.support.ImagesDeTest;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static com.sejourfr.app.service.ImageUploadSupport.Transparence.AUCUNE;
import static com.sejourfr.app.service.ImageUploadSupport.Transparence.INVERIFIABLE;
import static com.sejourfr.app.service.ImageUploadSupport.Transparence.PRESENTE;
import static com.sejourfr.app.service.ImageUploadSupport.transparence;
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
    void svg_jamais_accepte_en_fichier_avant_comme_apres_la_signature() {
        byte[] svg = "<?xml version=\"1.0\"?><svg xmlns=\"http://www.w3.org/2000/svg\"/>"
                .getBytes(java.nio.charset.StandardCharsets.UTF_8);
        assertThatThrownBy(() -> ImageUploadSupport.validate(
                new MockMultipartFile("img", "f.svg", "image/svg+xml", svg)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Format non supporte");
        assertThatThrownBy(() -> ImageUploadSupport.validate(
                new MockMultipartFile("img", "f.png", "image/png", svg)))
                .as("un SVG deguise en PNG")
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("n'est pas une image");
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
    void transparence_png_lue_sur_les_pixels_pas_sur_le_canal() {
        assertThat(transparence(ImagesDeTest.png(40, 30), FormatImage.PNG))
                .as("PNG RGB sans canal alpha").isEqualTo(AUCUNE);
        assertThat(transparence(ImagesDeTest.pngRgba(40, 30, false), FormatImage.PNG))
                .as("une PNG RGBA entierement opaque passe").isEqualTo(AUCUNE);
        assertThat(transparence(ImagesDeTest.pngRgbaUnPixel(40, 30, 255), FormatImage.PNG))
                .as("canal alpha present, tous les pixels a 255").isEqualTo(AUCUNE);
        assertThat(transparence(ImagesDeTest.pngRgba(40, 30, true), FormatImage.PNG)).isEqualTo(PRESENTE);
        assertThat(transparence(ImagesDeTest.pngRgbaUnPixel(40, 30, 0), FormatImage.PNG))
                .as("un seul pixel totalement transparent").isEqualTo(PRESENTE);
        assertThat(transparence(ImagesDeTest.pngRgbaUnPixel(40, 30, 254), FormatImage.PNG))
                .as("seuil : un seul pixel d'alpha 254 suffit").isEqualTo(PRESENTE);
        assertThat(transparence(ImagesDeTest.pngPaletteAvecTrns(40, 30), FormatImage.PNG))
                .as("palette avec entree transparente (tRNS)").isEqualTo(PRESENTE);
    }

    @Test
    void transparence_png_illisible_ou_trop_grande_est_inverifiable() {
        byte[] tronque = java.util.Arrays.copyOf(ImagesDeTest.pngRgba(40, 30, false), 60);
        assertThat(transparence(tronque, FormatImage.PNG)).isEqualTo(INVERIFIABLE);
        // 4001 x 4000 > 16 Mpx : refuse avant tout decodage (bombe de decompression).
        assertThat(transparence(ImagesDeTest.pngNoirEtBlanc(4001, 4000), FormatImage.PNG)).isEqualTo(INVERIFIABLE);
    }

    @Test
    void transparence_webp_lue_sur_les_donnees_d_alpha_pas_sur_le_drapeau() {
        assertThat(transparence(ImagesDeTest.webpVp8(40, 30), FormatImage.WEBP)).isEqualTo(AUCUNE);
        assertThat(transparence(ImagesDeTest.webpVp8x(40, 30, false), FormatImage.WEBP)).isEqualTo(AUCUNE);
        assertThat(transparence(ImagesDeTest.webpVp8xDrapeauSansAlph(40, 30), FormatImage.WEBP))
                .as("drapeau alpha sans bloc ALPH : aucune donnee d'alpha").isEqualTo(AUCUNE);
        assertThat(transparence(ImagesDeTest.webpVp8x(40, 30, true), FormatImage.WEBP))
                .as("bloc ALPH compresse").isEqualTo(PRESENTE);
        assertThat(transparence(ImagesDeTest.webpVp8l(40, 30, true), FormatImage.WEBP)).isEqualTo(PRESENTE);
        assertThat(transparence(ImagesDeTest.webpVp8l(40, 30, false), FormatImage.WEBP)).isEqualTo(AUCUNE);
        assertThat(transparence(ImagesDeTest.webpVp8xVp8l(40, 30, true), FormatImage.WEBP)).isEqualTo(PRESENTE);
        assertThat(transparence(ImagesDeTest.webpVp8xVp8l(40, 30, false), FormatImage.WEBP)).isEqualTo(AUCUNE);
    }

    @Test
    void transparence_webp_alph_brut_lu_pixel_par_pixel() {
        byte[] plan = new byte[40 * 30];
        java.util.Arrays.fill(plan, (byte) 0xFF);
        assertThat(transparence(ImagesDeTest.webpVp8xAlphBrut(40, 30, plan), FormatImage.WEBP))
                .as("plan alpha brut entierement opaque").isEqualTo(AUCUNE);
        plan[123] = (byte) 0xFE;
        assertThat(transparence(ImagesDeTest.webpVp8xAlphBrut(40, 30, plan), FormatImage.WEBP)).isEqualTo(PRESENTE);
    }

    @Test
    void transparence_webp_tronque_et_jpeg() {
        byte[] tronque = java.util.Arrays.copyOf(ImagesDeTest.webpVp8x(40, 30, true), 34);
        assertThat(transparence(tronque, FormatImage.WEBP)).isEqualTo(INVERIFIABLE);
        assertThat(transparence(JPEG, FormatImage.JPEG)).isEqualTo(AUCUNE);
    }
}
