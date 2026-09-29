package com.sejourfr.app.service;

import com.sejourfr.app.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ImageUploadSupportTest {

    private static final byte[] BYTES = {1, 2, 3, 4};

    @Test
    void validJpeg_returnsValidatedImageWithExtension() {
        MockMultipartFile file = new MockMultipartFile("img", "p.jpg", "image/jpeg", BYTES);

        ImageUploadSupport.ValidatedImage v = ImageUploadSupport.validate(file);

        assertThat(v.contentType()).isEqualTo("image/jpeg");
        assertThat(v.extension()).isEqualTo("jpg");
        assertThat(v.bytes()).isEqualTo(BYTES);
    }

    @Test
    void validPng_returnsPngExtension() {
        MockMultipartFile file = new MockMultipartFile("img", "p.png", "image/png", BYTES);
        assertThat(ImageUploadSupport.validate(file).extension()).isEqualTo("png");
    }

    @Test
    void validWebp_returnsWebpExtension() {
        MockMultipartFile file = new MockMultipartFile("img", "p.webp", "image/webp", BYTES);
        assertThat(ImageUploadSupport.validate(file).extension()).isEqualTo("webp");
    }

    @Test
    void contentType_caseInsensitive() {
        MockMultipartFile file = new MockMultipartFile("img", "p.jpg", "IMAGE/JPEG", BYTES);
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
        big[0] = 1;
        MockMultipartFile file = new MockMultipartFile("img", "p.jpg", "image/jpeg", big);
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("volumineuse");
    }

    @Test
    void unsupportedContentType_rejected() {
        MockMultipartFile file = new MockMultipartFile("img", "f.gif", "image/gif", BYTES);
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Format non supporte");
    }

    @Test
    void nullContentType_rejected() {
        MockMultipartFile file = new MockMultipartFile("img", "f.bin", null, BYTES);
        assertThatThrownBy(() -> ImageUploadSupport.validate(file))
                .isInstanceOf(BusinessException.class);
    }
}
