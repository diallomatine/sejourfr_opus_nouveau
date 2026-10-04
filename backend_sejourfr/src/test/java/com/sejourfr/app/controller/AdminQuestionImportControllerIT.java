package com.sejourfr.app.controller;

import com.sejourfr.app.audioquestion.service.AzureSpeechClient;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.ImagesDeTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockPart;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.charset.StandardCharsets;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Contrat HTTP de l'import CO image : parties multipart, statuts, forme du rapport. */
class AdminQuestionImportControllerIT extends AbstractIntegrationTest {

    private static final String BASE = "/api/admin/question-imports/co-image";

    @Autowired private MockMvc mockMvc;
    @Autowired private TestData testData;
    @Autowired private AuthTestSupport auth;

    @MockitoBean private AzureSpeechClient azureSpeechClient;
    @MockitoBean private CloudflareR2Client r2Client;

    @Test
    void analyze_rend_200_et_le_rapport_manifeste_en_partie_json() throws Exception {
        User admin = testData.admin();

        mockMvc.perform(multipart(BASE + "/analyze")
                        .file(manifeste(manifesteJson("co-ctl-a")))
                        .file(image("a.png"))
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ok").value(true))
                .andExpect(jsonPath("$.imported").value(false))
                .andExpect(jsonPath("$.format").value("CO_IMAGE"))
                .andExpect(jsonPath("$.charteVersion").value("charte-images-co-v1"))
                .andExpect(jsonPath("$.maxQuestions").value(20))
                .andExpect(jsonPath("$.questionCount").value(1))
                .andExpect(jsonPath("$.questions[0].themeCode").value("TCF_CO"))
                .andExpect(jsonPath("$.questions[0].imageWidth").value(800))
                .andExpect(jsonPath("$.questions[0].choices[1].letter").value("B"))
                .andExpect(jsonPath("$.questions[0].choices[0].correct").value(true))
                .andExpect(jsonPath("$.questions[0].transcriptText").exists());
    }

    /** {@code FormData.append("manifest", texte)} : une partie sans Content-Type, lue en UTF-8. */
    @Test
    void analyze_accepte_le_manifeste_en_champ_texte_utf8() throws Exception {
        mockMvc.perform(multipart(BASE + "/analyze")
                        .file(image("a.png"))
                        .part(new MockPart("manifest", manifesteJson("co-ctl-a").getBytes(StandardCharsets.UTF_8)))
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(testData.admin())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ok").value(true))
                .andExpect(jsonPath("$.questions[0].choices[2].text").value("Regardez la télé."));
    }

    @Test
    void analyze_sans_manifeste_rend_le_rapport_d_erreur_de_lot() throws Exception {
        mockMvc.perform(multipart(BASE + "/analyze")
                        .file(image("a.png"))
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(testData.admin())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ok").value(false))
                .andExpect(jsonPath("$.errors[0].code").value("MANIFESTE_ILLISIBLE"));
    }

    @Test
    void import_invalide_rend_422_et_le_rapport() throws Exception {
        mockMvc.perform(multipart(BASE + "/import")
                        .file(manifeste(manifesteJson("co-ctl-a")))
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(testData.admin())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.imported").value(false))
                .andExpect(jsonPath("$.questions[0].errors[0].code").value("IMAGE_ABSENTE"))
                .andExpect(jsonPath("$.questions[0].errors[0].field").value("image"));
    }

    @Test
    void import_valide_rend_201_et_les_brouillons() throws Exception {
        when(r2Client.uploadImage(anyString(), any(), anyString()))
                .thenAnswer(inv -> new R2UploadResult(inv.getArgument(0), "https://cdn.test/" + inv.getArgument(0)));

        mockMvc.perform(multipart(BASE + "/import")
                        .file(manifeste(manifesteJson("co-ctl-ok")))
                        .file(image("a.png"))
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(testData.admin())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.imported").value(true))
                .andExpect(jsonPath("$.questions[0].draftId").exists())
                .andExpect(jsonPath("$.questions[0].imageUrl").exists());
    }

    private static MockMultipartFile manifeste(String json) {
        return new MockMultipartFile("manifest", "", "application/json", json.getBytes(StandardCharsets.UTF_8));
    }

    private static MockMultipartFile image(String nom) {
        return new MockMultipartFile("images", nom, "image/png", ImagesDeTest.png(800, 600));
    }

    private static String manifesteJson(String externalId) {
        return "{\"version\":\"1\",\"format\":\"CO_IMAGE\",\"questions\":[{\"externalId\":\"" + externalId + "\","
                + "\"level\":\"A2\",\"image\":\"a.png\",\"sceneDescription\":\"Une femme appelle sa famille.\","
                + "\"choices\":[\"Venez manger.\",\"Allez dormir.\",\"Regardez la télé.\",\"Lisez un livre.\"],"
                + "\"correctAnswer\":\"A\"}]}";
    }
}
