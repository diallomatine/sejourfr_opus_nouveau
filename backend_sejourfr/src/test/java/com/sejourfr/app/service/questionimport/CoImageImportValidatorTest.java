package com.sejourfr.app.service.questionimport;

import com.sejourfr.app.config.QuestionImportProperties;
import com.sejourfr.app.dto.CoImageImportError;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.CoImageImportErrorCode;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.questionimport.CoImageImportValidator.ManifesteLu;
import com.sejourfr.app.support.ImagesDeTest;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static com.sejourfr.app.enums.CoImageImportErrorCode.*;
import static org.assertj.core.api.Assertions.assertThat;

class CoImageImportValidatorTest {

    private final QuestionImportProperties props = new QuestionImportProperties();
    private final CoImageImportValidator validator = new CoImageImportValidator(props, new CharteImagesCo(props));

    private final Theme tcfCo = theme("TCF_CO", Module.TCF);
    private final Theme tcfCe = theme("TCF_CE", Module.TCF);
    private final Theme civique = theme("CIV_PRINCIPES", Module.CIVIQUE);
    private final Map<String, Theme> themes = Map.of("TCF_CO", tcfCo, "TCF_CE", tcfCe, "CIV_PRINCIPES", civique);

    private static final byte[] PNG_OK = ImagesDeTest.png(800, 600);

    // --- manifeste ----------------------------------------------------------

    @Test
    void lot_valide_toutes_les_questions_ok() {
        ResultatValidation r = valider(manifeste(question("co-a2-001", "a.png"), question("co-a2-002", "b.png")),
                fichier("a.png", PNG_OK), fichier("b.png", ImagesDeTest.webpVp8x(1200, 900, false)));

        assertThat(r.ok()).isTrue();
        assertThat(r.erreursLot()).isEmpty();
        QuestionAnalysee q = r.questions().get(0);
        assertThat(q.externalId()).isEqualTo("co-a2-001");
        assertThat(q.niveau()).isEqualTo(Difficulty.A2);
        assertThat(q.theme()).isSameAs(tcfCo);
        assertThat(q.propositions()).containsExactly("Venez manger.", "Allez dormir.", "Regardez la télé.", "Lisez un livre.");
        assertThat(q.indexBonneReponse()).isZero();
        assertThat(q.dimensions().largeur()).isEqualTo(800);
    }

    @Test
    void manifeste_absent_ou_illisible() {
        assertThat(codesLot(validator.valider(validator.lire(null), List.of(), themes, Set.of())))
                .containsExactly(MANIFESTE_ILLISIBLE);
        assertThat(codesLot(validator.valider(validator.lire("{pas du json"), List.of(), themes, Set.of())))
                .containsExactly(MANIFESTE_ILLISIBLE);
    }

    @Test
    void champ_inconnu_refuse_pour_ne_pas_ignorer_une_faute_de_frappe() {
        ManifesteLu lu = validator.lire("{\"version\":\"1\",\"format\":\"CO_IMAGE\",\"questions\":[{\"theme\":\"TCF_CO\"}]}");

        assertThat(lu.erreur().code()).isEqualTo(MANIFESTE_ILLISIBLE);
        assertThat(lu.erreur().field()).isEqualTo("theme");
    }

    @Test
    void version_format_et_nombre_de_questions() {
        String json = "{\"version\":\"2\",\"format\":\"CO\",\"questions\":[]}";
        assertThat(codesLot(validator.valider(validator.lire(json), List.of(), themes, Set.of())))
                .containsExactly(VERSION_INCONNUE, FORMAT_INCONNU, NOMBRE_QUESTIONS);

        List<String> trop = new ArrayList<>();
        List<FichierImport> fichiers = new ArrayList<>();
        IntStream.range(0, props.getMaxQuestions() + 1).forEach(i -> {
            trop.add(question("co-" + i + "-x", i + ".png"));
            fichiers.add(new FichierImport(i + ".png", PNG_OK));
        });
        ResultatValidation r = validator.valider(validator.lire(manifeste(trop.toArray(String[]::new))),
                fichiers, themes, Set.of());
        assertThat(codesLot(r)).containsExactly(NOMBRE_QUESTIONS);
        assertThat(r.ok()).isFalse();
    }

    @Test
    void fichier_en_trop_et_fichier_en_double() {
        ResultatValidation r = valider(manifeste(question("co-a2-001", "a.png")),
                fichier("a.png", PNG_OK), fichier("a.png", PNG_OK), fichier("intrus.png", PNG_OK));

        assertThat(r.erreursLot()).extracting(CoImageImportError::code, CoImageImportError::field)
                .containsExactlyInAnyOrder(
                        org.assertj.core.groups.Tuple.tuple(FICHIER_EN_DOUBLE, "a.png"),
                        org.assertj.core.groups.Tuple.tuple(FICHIER_EN_TROP, "intrus.png"));
        assertThat(r.ok()).isFalse();
    }

    // --- question -----------------------------------------------------------

    @Test
    void external_id_motif_doublon_et_deja_importe() {
        ResultatValidation r = validator.valider(validator.lire(manifeste(
                        question("CO_A2", "a.png"), question("co-dup", "b.png"),
                        question("co-dup", "c.png"), question("co-vieux", "d.png"))),
                List.of(fichier("a.png", PNG_OK), fichier("b.png", PNG_OK),
                        fichier("c.png", PNG_OK), fichier("d.png", PNG_OK)),
                themes, Set.of("co-vieux"));

        assertThat(codes(r, 0)).containsExactly(EXTERNAL_ID_INVALIDE);
        assertThat(codes(r, 1)).containsExactly(EXTERNAL_ID_EN_DOUBLE);
        assertThat(codes(r, 2)).containsExactly(EXTERNAL_ID_EN_DOUBLE);
        assertThat(codes(r, 3)).containsExactly(EXTERNAL_ID_DEJA_IMPORTE);
    }

    @Test
    void niveau_hors_A2_B1_B2() {
        assertThat(codes(valider1(q -> q.replace("\"A2\"", "\"CSP\"")), 0)).containsExactly(NIVEAU_INVALIDE);
        assertThat(codes(valider1(q -> q.replace("\"A2\"", "\"a2\"")), 0)).containsExactly(NIVEAU_INVALIDE);
    }

    @Test
    void theme_par_defaut_explicite_inconnu_ou_hors_tcf() {
        assertThat(valider1(q -> q).questions().get(0).theme()).isSameAs(tcfCo);
        assertThat(valider1(q -> q.replace("\"level\"", "\"themeCode\":\"TCF_CE\",\"level\"")).questions().get(0).theme())
                .isSameAs(tcfCe);
        assertThat(codes(valider1(q -> q.replace("\"level\"", "\"themeCode\":\"NOPE\",\"level\"")), 0))
                .containsExactly(THEME_INCONNU);
        assertThat(codes(valider1(q -> q.replace("\"level\"", "\"themeCode\":\"CIV_PRINCIPES\",\"level\"")), 0))
                .containsExactly(THEME_HORS_TCF);
    }

    @Test
    void propositions_nombre_vide_longueur_et_doublon_insensible_a_la_casse() {
        assertThat(codes(valider1(q -> q.replace("\"Lisez un livre.\"", "")
                .replace("\"Regardez la télé.\",", "\"Regardez la télé.\"")), 0)).containsExactly(CHOIX_NOMBRE);

        ResultatValidation vide = valider1(q -> q.replace("\"Allez dormir.\"", "\"   \""));
        assertThat(vide.questions().get(0).erreurs()).extracting(CoImageImportError::code, CoImageImportError::field)
                .containsExactly(org.assertj.core.groups.Tuple.tuple(CHOIX_VIDE, "choices[1]"));

        String long_ = "x".repeat(props.getChoiceMaxLength() + 1);
        assertThat(codes(valider1(q -> q.replace("Allez dormir.", long_)), 0)).containsExactly(CHOIX_TROP_LONG);

        ResultatValidation doublon = valider1(q -> q.replace("\"Lisez un livre.\"", "\"  VENEZ   manger. \""));
        assertThat(doublon.questions().get(0).erreurs()).extracting(CoImageImportError::code, CoImageImportError::field)
                .containsExactly(org.assertj.core.groups.Tuple.tuple(CHOIX_EN_DOUBLE, "choices[3]"));
    }

    @Test
    void propositions_normalisees_espaces() {
        ResultatValidation r = valider1(q -> q.replace("\"Allez dormir.\"", "\"  Allez \\n  dormir.  \""));
        assertThat(r.questions().get(0).propositions().get(1)).isEqualTo("Allez dormir.");
    }

    @Test
    void bonne_reponse_hors_A_D() {
        assertThat(codes(valider1(q -> q.replace("\"correctAnswer\":\"A\"", "\"correctAnswer\":\"E\"")), 0))
                .containsExactly(BONNE_REPONSE_INVALIDE);
        assertThat(codes(valider1(q -> q.replace("\"correctAnswer\":\"A\"", "\"correctAnswer\":\"c\"")), 0))
                .containsExactly(BONNE_REPONSE_INVALIDE);
        assertThat(valider1(q -> q.replace("\"correctAnswer\":\"A\"", "\"correctAnswer\":\"D\""))
                .questions().get(0).indexBonneReponse()).isEqualTo(3);
    }

    @Test
    void description_requise_et_bornee_explication_facultative_et_bornee() {
        assertThat(codes(valider1(q -> q.replace("Une femme appelle sa famille.", " ")), 0))
                .containsExactly(DESCRIPTION_SCENE_VIDE);
        assertThat(codes(valider1(q -> q.replace("Une femme appelle sa famille.",
                "d".repeat(props.getSceneDescriptionMaxLength() + 1))), 0))
                .containsExactly(DESCRIPTION_SCENE_TROP_LONGUE);
        assertThat(codes(valider1(q -> q.replace("Seule A.", "e".repeat(props.getExplanationMaxLength() + 1))), 0))
                .containsExactly(EXPLICATION_TROP_LONGUE);
        QuestionAnalysee sans = valider1(q -> q.replace(",\"explanation\":\"Seule A.\"", "")).questions().get(0);
        assertThat(sans.ok()).isTrue();
        assertThat(sans.explication()).isNull();
    }

    // --- images -------------------------------------------------------------

    @Test
    void image_non_renseignee_absente_ou_referencee_deux_fois() {
        assertThat(codes(valider(manifeste(question("co-a", ""))), 0)).containsExactly(IMAGE_NON_RENSEIGNEE);
        assertThat(codes(valider(manifeste(question("co-a", "a.png"))), 0)).containsExactly(IMAGE_ABSENTE);
        ResultatValidation deux = valider(manifeste(question("co-a", "a.png"), question("co-b", "a.png")),
                fichier("a.png", PNG_OK));
        assertThat(codes(deux, 0)).containsExactly(IMAGE_REFERENCEE_PLUSIEURS_FOIS);
        assertThat(codes(deux, 1)).containsExactly(IMAGE_REFERENCEE_PLUSIEURS_FOIS);
    }

    @Test
    void image_signature_format_charte_et_poids() {
        assertThat(codesImage(new byte[]{1, 2, 3})).containsExactly(IMAGE_FORMAT_INVALIDE);
        assertThat(codesImage(ImagesDeTest.jpeg(800, 600))).containsExactly(IMAGE_FORMAT_HORS_CHARTE);
        byte[] lourde = java.util.Arrays.copyOf(PNG_OK, (int) com.sejourfr.app.service.ImageUploadSupport.MAX_BYTES + 1);
        assertThat(codesImage(lourde)).containsExactly(IMAGE_TROP_LOURDE);
    }

    @Test
    void image_dimensions_largeur_ratio_et_opacite_selon_la_charte() {
        assertThat(codesImage(ImagesDeTest.png(640, 480))).containsExactly(IMAGE_TROP_PETITE);
        assertThat(codesImage(ImagesDeTest.png(1600, 900))).containsExactly(IMAGE_RATIO);
        assertThat(codesImage(ImagesDeTest.png(808, 600))).as("4:3 a 1 % pres").isEmpty();
        assertThat(codesImage(ImagesDeTest.pngRgba(800, 600, true))).containsExactly(IMAGE_TRANSPARENTE);
        assertThat(codesImage(ImagesDeTest.pngRgba(800, 600, false))).isEmpty();
        assertThat(codesImage(ImagesDeTest.webpVp8x(1200, 900, true))).containsExactly(IMAGE_TRANSPARENTE);
        byte[] tronque = java.util.Arrays.copyOf(ImagesDeTest.webpVp8x(1200, 900, false), 24);
        assertThat(codesImage(tronque)).containsExactly(IMAGE_ILLISIBLE);
    }

    @Test
    void codes_de_theme_et_external_ids_a_charger() {
        var m = validator.lire(manifeste(question("co-a", "a.png"),
                question("CO_INVALIDE", "b.png").replace("\"level\"", "\"themeCode\":\"TCF_CE\",\"level\""))).manifeste();

        assertThat(validator.codesDeTheme(m)).containsExactly("TCF_CO", "TCF_CE");
        assertThat(validator.externalIds(m)).containsExactly("co-a");
    }

    // --- outillage ----------------------------------------------------------

    private List<CoImageImportErrorCode> codesImage(byte[] octets) {
        return codes(valider(manifeste(question("co-img", "i.png")), fichier("i.png", octets)), 0);
    }

    private ResultatValidation valider1(java.util.function.UnaryOperator<String> retouche) {
        return valider(manifeste(retouche.apply(question("co-a2-001", "a.png"))), fichier("a.png", PNG_OK));
    }

    private ResultatValidation valider(String json, FichierImport... fichiers) {
        return validator.valider(validator.lire(json), List.of(fichiers), themes, Set.of());
    }

    private static List<CoImageImportErrorCode> codes(ResultatValidation r, int index) {
        return r.questions().get(index).erreurs().stream().map(CoImageImportError::code).toList();
    }

    private static List<CoImageImportErrorCode> codesLot(ResultatValidation r) {
        return r.erreursLot().stream().map(CoImageImportError::code).toList();
    }

    private static FichierImport fichier(String nom, byte[] octets) {
        return new FichierImport(nom, octets);
    }

    static String question(String externalId, String image) {
        return "{\"externalId\":\"" + externalId + "\",\"level\":\"A2\",\"image\":\"" + image + "\","
                + "\"sceneDescription\":\"Une femme appelle sa famille.\","
                + "\"choices\":[\"Venez manger.\",\"Allez dormir.\",\"Regardez la télé.\",\"Lisez un livre.\"],"
                + "\"correctAnswer\":\"A\",\"explanation\":\"Seule A.\"}";
    }

    static String manifeste(String... questions) {
        return "{\"version\":\"1\",\"format\":\"CO_IMAGE\",\"questions\":["
                + java.util.Arrays.stream(questions).collect(Collectors.joining(",")) + "]}";
    }

    private static Theme theme(String code, Module module) {
        Theme t = new Theme();
        t.setCode(code);
        t.setModule(module);
        t.setName(code);
        return t;
    }
}
