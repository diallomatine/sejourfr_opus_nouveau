package com.sejourfr.app.service.questionimport;

import com.fasterxml.jackson.core.JacksonException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.exc.UnrecognizedPropertyException;
import com.sejourfr.app.config.QuestionImportProperties;
import com.sejourfr.app.dto.CoImageImportError;
import com.sejourfr.app.dto.CoImageImportManifest;
import com.sejourfr.app.dto.CoImageImportQuestion;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.CoImageImportErrorCode;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.ImageUploadSupport;
import com.sejourfr.app.service.ImageUploadSupport.Dimensions;
import com.sejourfr.app.service.ImageUploadSupport.FormatImage;
import com.sejourfr.app.util.PropositionsLuesCoImage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

import static com.sejourfr.app.enums.CoImageImportErrorCode.*;

/**
 * Validation PURE d'un lot CO image (§4.3 de l'audit) : aucune lecture en base,
 * aucun envoi. Le service lui passe ce qu'il a lu (themes, identifiants deja
 * importes) ; elle rend un verdict par question et par lot. Rejouee telle quelle
 * par l'import : l'analyse n'est jamais crue sur parole.
 */
@Component
@RequiredArgsConstructor
public class CoImageImportValidator {

    public static final String VERSION = "1";
    public static final String FORMAT = "CO_IMAGE";

    private static final Pattern EXTERNAL_ID = Pattern.compile("[a-z0-9-]{3,64}");
    private static final Set<Difficulty> NIVEAUX = Set.of(Difficulty.A2, Difficulty.B1, Difficulty.B2);
    private static final Pattern ESPACES = Pattern.compile("\\s+");

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);

    private final QuestionImportProperties props;
    private final CharteImagesCo charte;

    /** Le manifeste lu, ou l'erreur de lot qui empeche de le lire. */
    public record ManifesteLu(CoImageImportManifest manifeste, CoImageImportError erreur) {}

    public ManifesteLu lire(String json) {
        if (json == null || json.isBlank()) {
            return new ManifesteLu(null, err(MANIFESTE_ILLISIBLE, "manifest", "Manifeste absent."));
        }
        try {
            CoImageImportManifest m = MAPPER.readValue(json, CoImageImportManifest.class);
            if (m == null) {
                return new ManifesteLu(null, err(MANIFESTE_ILLISIBLE, "manifest", "Manifeste vide."));
            }
            return new ManifesteLu(m, null);
        } catch (UnrecognizedPropertyException e) {
            return new ManifesteLu(null, err(MANIFESTE_ILLISIBLE, e.getPropertyName(),
                    "Champ inconnu « " + e.getPropertyName() + " » dans le manifeste."));
        } catch (JacksonException e) {
            return new ManifesteLu(null, err(MANIFESTE_ILLISIBLE, "manifest",
                    "Manifeste illisible : JSON invalide ou valeur d'un mauvais type (ligne "
                            + (e.getLocation() != null ? e.getLocation().getLineNr() : "?") + ")."));
        }
    }

    /** Codes de theme a charger : ceux du manifeste, plus le theme par defaut. */
    public Set<String> codesDeTheme(CoImageImportManifest m) {
        Set<String> codes = new LinkedHashSet<>();
        codes.add(props.getDefaultThemeCode());
        for (CoImageImportQuestion q : questions(m)) {
            if (q != null && q.themeCode() != null && !q.themeCode().isBlank()) codes.add(q.themeCode().trim());
        }
        return codes;
    }

    /** Identifiants externes bien formes du manifeste, a confronter a la base. */
    public Set<String> externalIds(CoImageImportManifest m) {
        Set<String> ids = new LinkedHashSet<>();
        for (CoImageImportQuestion q : questions(m)) {
            if (q != null && q.externalId() != null && EXTERNAL_ID.matcher(q.externalId()).matches()) {
                ids.add(q.externalId());
            }
        }
        return ids;
    }

    public ResultatValidation valider(
            ManifesteLu lu,
            List<FichierImport> fichiers,
            Map<String, Theme> themesParCode,
            Set<String> externalIdsConnus) {
        List<CoImageImportError> lot = new ArrayList<>();
        Map<String, FichierImport> parNom = indexerFichiers(fichiers, lot);
        if (lu.erreur() != null) {
            lot.add(0, lu.erreur());
            return new ResultatValidation(lot, List.of());
        }
        CoImageImportManifest m = lu.manifeste();
        if (!VERSION.equals(m.version())) {
            lot.add(err(VERSION_INCONNUE, "version", "Version de manifeste inconnue : « "
                    + m.version() + " » (attendu « " + VERSION + " »)."));
        }
        if (!FORMAT.equals(m.format())) {
            lot.add(err(FORMAT_INCONNU, "format", "Format inconnu : « " + m.format()
                    + " » (attendu « " + FORMAT + " »)."));
        }
        List<CoImageImportQuestion> brutes = questions(m);
        if (brutes.isEmpty() || brutes.size() > props.getMaxQuestions()) {
            lot.add(err(NOMBRE_QUESTIONS, "questions", "Un lot compte de 1 à "
                    + props.getMaxQuestions() + " questions (reçu : " + brutes.size() + ")."));
        }

        Map<String, Integer> occurrencesId = new HashMap<>();
        Map<String, Integer> occurrencesImage = new HashMap<>();
        for (CoImageImportQuestion q : brutes) {
            if (q == null) continue;
            if (q.externalId() != null) occurrencesId.merge(q.externalId(), 1, Integer::sum);
            if (q.image() != null && !q.image().isBlank()) occurrencesImage.merge(q.image(), 1, Integer::sum);
        }

        List<QuestionAnalysee> analysees = new ArrayList<>();
        for (int i = 0; i < brutes.size(); i++) {
            analysees.add(analyser(i, brutes.get(i), parNom, themesParCode, externalIdsConnus,
                    occurrencesId, occurrencesImage));
        }

        for (String nom : parNom.keySet()) {
            if (!occurrencesImage.containsKey(nom)) {
                lot.add(err(FICHIER_EN_TROP, nom,
                        "Le fichier « " + nom + " » n'est référencé par aucune question."));
            }
        }
        return new ResultatValidation(lot, analysees);
    }

    private QuestionAnalysee analyser(
            int index,
            CoImageImportQuestion q,
            Map<String, FichierImport> fichiers,
            Map<String, Theme> themesParCode,
            Set<String> externalIdsConnus,
            Map<String, Integer> occurrencesId,
            Map<String, Integer> occurrencesImage) {
        List<CoImageImportError> erreurs = new ArrayList<>();
        if (q == null) {
            erreurs.add(err(QUESTION_ABSENTE, null, "Question vide (null) dans le manifeste."));
            return new QuestionAnalysee(index, null, null, null, null, null, null, null, null,
                    null, null, null, erreurs);
        }

        String externalId = verifierExternalId(q.externalId(), externalIdsConnus, occurrencesId, erreurs);
        Difficulty niveau = verifierNiveau(q.level(), erreurs);
        Theme theme = verifierTheme(q.themeCode(), themesParCode, erreurs);
        List<String> propositions = verifierPropositions(q.choices(), erreurs);
        Integer bonne = verifierBonneReponse(q.correctAnswer(), erreurs);
        String description = verifierTexte(q.sceneDescription(), "sceneDescription", true,
                props.getSceneDescriptionMaxLength(), DESCRIPTION_SCENE_VIDE, DESCRIPTION_SCENE_TROP_LONGUE,
                "La description de la scène", erreurs);
        String explication = verifierTexte(q.explanation(), "explanation", false,
                props.getExplanationMaxLength(), null, EXPLICATION_TROP_LONGUE, "L'explication", erreurs);

        FichierImport image = null;
        FormatImage format = null;
        Dimensions dims = null;
        if (q.image() == null || q.image().isBlank()) {
            erreurs.add(err(IMAGE_NON_RENSEIGNEE, "image", "Nom du fichier image manquant."));
        } else if (occurrencesImage.getOrDefault(q.image(), 0) > 1) {
            erreurs.add(err(IMAGE_REFERENCEE_PLUSIEURS_FOIS, "image",
                    "L'image « " + q.image() + " » est référencée par plusieurs questions."));
        } else if (!fichiers.containsKey(q.image())) {
            erreurs.add(err(IMAGE_ABSENTE, "image", "Fichier « " + q.image() + " » absent du dépôt."));
        } else {
            image = fichiers.get(q.image());
            format = verifierImage(image, erreurs);
            dims = format == null ? null : verifierDimensions(image, format, erreurs);
        }

        return new QuestionAnalysee(index, q, externalId, niveau, theme, propositions, bonne,
                description, explication, image, format, dims, List.copyOf(erreurs));
    }

    private String verifierExternalId(String id, Set<String> connus, Map<String, Integer> occurrences,
                                      List<CoImageImportError> erreurs) {
        if (id == null || !EXTERNAL_ID.matcher(id).matches()) {
            erreurs.add(err(EXTERNAL_ID_INVALIDE, "externalId",
                    "Identifiant attendu : 3 à 64 caractères parmi a-z, 0-9 et « - »."));
            return null;
        }
        if (occurrences.getOrDefault(id, 0) > 1) {
            erreurs.add(err(EXTERNAL_ID_EN_DOUBLE, "externalId",
                    "L'identifiant « " + id + " » apparaît plusieurs fois dans le lot."));
        }
        if (connus.contains(id)) {
            erreurs.add(err(EXTERNAL_ID_DEJA_IMPORTE, "externalId",
                    "L'identifiant « " + id + " » a déjà été importé (brouillon existant, tous statuts)."));
        }
        return id;
    }

    private Difficulty verifierNiveau(String level, List<CoImageImportError> erreurs) {
        Difficulty d = null;
        if (level != null) {
            try {
                d = Difficulty.valueOf(level.trim());
            } catch (IllegalArgumentException ignored) {
                d = null;
            }
        }
        if (d == null || !NIVEAUX.contains(d)) {
            erreurs.add(err(NIVEAU_INVALIDE, "level", "Niveau attendu : A2, B1 ou B2."));
            return null;
        }
        return d;
    }

    private Theme verifierTheme(String themeCode, Map<String, Theme> themes, List<CoImageImportError> erreurs) {
        String code = themeCode == null || themeCode.isBlank() ? props.getDefaultThemeCode() : themeCode.trim();
        Theme theme = themes.get(code);
        if (theme == null) {
            erreurs.add(err(THEME_INCONNU, "themeCode", "Thème inconnu : « " + code + " »."));
            return null;
        }
        if (theme.getModule() != Module.TCF) {
            erreurs.add(err(THEME_HORS_TCF, "themeCode",
                    "Le thème « " + code + " » n'appartient pas au module TCF."));
            return null;
        }
        return theme;
    }

    private List<String> verifierPropositions(List<String> choix, List<CoImageImportError> erreurs) {
        int attendu = PropositionsLuesCoImage.LETTRES.size();
        if (choix == null || choix.size() != attendu) {
            erreurs.add(err(CHOIX_NOMBRE, "choices", "Exactement " + attendu + " propositions attendues (reçu : "
                    + (choix == null ? 0 : choix.size()) + ")."));
            return null;
        }
        List<String> normalisees = new ArrayList<>(attendu);
        Map<String, Integer> vues = new HashMap<>();
        boolean valides = true;
        for (int i = 0; i < attendu; i++) {
            String champ = "choices[" + i + "]";
            String texte = choix.get(i) == null ? "" : ESPACES.matcher(choix.get(i).strip()).replaceAll(" ");
            if (texte.isEmpty()) {
                erreurs.add(err(CHOIX_VIDE, champ, "Proposition " + PropositionsLuesCoImage.LETTRES.get(i) + " vide."));
                valides = false;
            } else if (texte.length() > props.getChoiceMaxLength()) {
                erreurs.add(err(CHOIX_TROP_LONG, champ, "Proposition " + PropositionsLuesCoImage.LETTRES.get(i)
                        + " trop longue (" + texte.length() + " > " + props.getChoiceMaxLength() + " caractères)."));
                valides = false;
            } else {
                Integer premiere = vues.putIfAbsent(texte.toLowerCase(Locale.FRENCH), i);
                if (premiere != null) {
                    erreurs.add(err(CHOIX_EN_DOUBLE, champ, "Proposition " + PropositionsLuesCoImage.LETTRES.get(i)
                            + " identique à la proposition " + PropositionsLuesCoImage.LETTRES.get(premiere) + "."));
                    valides = false;
                }
            }
            normalisees.add(texte);
        }
        return valides ? List.copyOf(normalisees) : null;
    }

    private Integer verifierBonneReponse(String lettre, List<CoImageImportError> erreurs) {
        int i = lettre == null ? -1 : PropositionsLuesCoImage.LETTRES.indexOf(lettre.strip());
        if (i < 0) {
            erreurs.add(err(BONNE_REPONSE_INVALIDE, "correctAnswer", "Bonne réponse attendue : A, B, C ou D."));
            return null;
        }
        return i;
    }

    private String verifierTexte(String brut, String champ, boolean requis, int max,
                                 CoImageImportErrorCode codeVide, CoImageImportErrorCode codeLong,
                                 String libelle, List<CoImageImportError> erreurs) {
        String texte = brut == null ? "" : brut.strip();
        if (texte.isEmpty()) {
            if (requis) erreurs.add(err(codeVide, champ, libelle + " est requise."));
            return null;
        }
        if (texte.length() > max) {
            erreurs.add(err(codeLong, champ, libelle + " est trop longue ("
                    + texte.length() + " > " + max + " caractères)."));
            return null;
        }
        return texte;
    }

    private FormatImage verifierImage(FichierImport image, List<CoImageImportError> erreurs) {
        if (image.octets().length > ImageUploadSupport.MAX_BYTES) {
            erreurs.add(err(IMAGE_TROP_LOURDE, "image", "Image trop lourde (max "
                    + ImageUploadSupport.MAX_BYTES / (1024 * 1024) + " Mo)."));
            return null;
        }
        Optional<FormatImage> format = ImageUploadSupport.detecterFormat(image.octets());
        if (format.isEmpty()) {
            erreurs.add(err(IMAGE_FORMAT_INVALIDE, "image",
                    "Le contenu du fichier n'est pas une image PNG, WEBP ou JPEG."));
            return null;
        }
        if (!charte.formats().contains(format.get())) {
            erreurs.add(err(IMAGE_FORMAT_HORS_CHARTE, "image", "Format " + format.get().extension()
                    + " hors charte (attendu : " + extensions() + ")."));
            return null;
        }
        return format.get();
    }

    private Dimensions verifierDimensions(FichierImport image, FormatImage format, List<CoImageImportError> erreurs) {
        Optional<Dimensions> lues = ImageUploadSupport.lireDimensions(image.octets(), format);
        if (lues.isEmpty()) {
            erreurs.add(err(IMAGE_ILLISIBLE, "image", "Dimensions de l'image illisibles (fichier corrompu ?)."));
            return null;
        }
        Dimensions d = lues.get();
        if (d.largeur() < charte.largeurMinPx()) {
            erreurs.add(err(IMAGE_TROP_PETITE, "image", "Image trop petite : " + d.largeur()
                    + " px de large (minimum " + charte.largeurMinPx() + " px)."));
        }
        if (!charte.ratioConforme(d.largeur(), d.hauteur())) {
            erreurs.add(err(IMAGE_RATIO, "image", "Ratio " + d.largeur() + "×" + d.hauteur()
                    + " hors charte (attendu " + charte.ratioLargeur() + ":" + charte.ratioHauteur() + ")."));
        }
        if (charte.fondOpaque()) {
            switch (ImageUploadSupport.transparence(image.octets(), format)) {
                case PRESENTE -> erreurs.add(err(IMAGE_TRANSPARENTE, "image",
                        "Au moins un pixel de l'image est transparent : la charte exige un fond blanc"
                                + " opaque (aplatir l'image sur du blanc avant export)."));
                case INVERIFIABLE -> erreurs.add(err(IMAGE_ILLISIBLE, "image",
                        "Opacité de l'image invérifiable (fichier corrompu, image animée ou de plus de "
                                + ImageUploadSupport.MAX_PIXELS_OPACITE / 1_000_000 + " Mpx)."));
                case AUCUNE -> { }
            }
        }
        return d;
    }

    private Map<String, FichierImport> indexerFichiers(List<FichierImport> fichiers, List<CoImageImportError> lot) {
        Map<String, FichierImport> parNom = new LinkedHashMap<>();
        Set<String> doublons = new HashSet<>();
        for (FichierImport f : fichiers == null ? List.<FichierImport>of() : fichiers) {
            if (f == null || f.nom() == null) continue;
            if (parNom.putIfAbsent(f.nom(), f) != null && doublons.add(f.nom())) {
                lot.add(err(FICHIER_EN_DOUBLE, f.nom(), "Deux fichiers portent le nom « " + f.nom() + " »."));
            }
        }
        return parNom;
    }

    private String extensions() {
        return String.join(", ", charte.formats().stream().map(FormatImage::extension).sorted().toList());
    }

    private static List<CoImageImportQuestion> questions(CoImageImportManifest m) {
        return m == null || m.questions() == null ? List.of() : m.questions();
    }

    private static CoImageImportError err(CoImageImportErrorCode code, String champ, String message) {
        return new CoImageImportError(code, champ, message);
    }
}
