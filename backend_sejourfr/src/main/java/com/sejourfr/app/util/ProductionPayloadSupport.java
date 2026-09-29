package com.sejourfr.app.util;

import com.sejourfr.app.exception.BusinessException;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.text.Normalizer;
import java.util.regex.Pattern;

/**
 * Traitement des productions rendues par un candidat — audio uploade et texte
 * saisi — commun aux deux voies qui en recoivent : les epreuves completes
 * ({@code ProductionEvaluationService}) et les micro-exercices du module
 * competences ({@code SkillAttemptService}).
 *
 * <p>Extrait ici a la deuxieme occurrence, avant que les deux copies ne
 * divergent : un garde-fou de content-type ou un comptage de mots qui ne dirait
 * pas la meme chose des deux cotes produirait des refus incoherents pour le
 * meme fichier.
 *
 * <p>Ces methodes ne portent aucune regle metier — ni plafond de taille, ni
 * bornes de longueur : ces seuils appartiennent a chaque voie (elles n'ont ni
 * les memes valeurs, ni les memes consequences) et restent chez elle.
 */
public final class ProductionPayloadSupport {

    /**
     * Extension acceptee telle quelle. La valeur est user-controlled (nom de
     * fichier, content-type) et sert de suffixe a une cle R2 : elle est donc
     * strictement mise en liste blanche, sinon on retombe sur {@code bin}.
     *
     * <p>Sans cette garde, un {@code originalFilename = "foo.x/../audio/<id>.mp3"}
     * produirait une cle R2 contenant des slashes et {@code ..} (R2 stocke les
     * cles en chaines opaques, mais des proxies/CDN peuvent les canoniser).
     */
    private static final Pattern SAFE_EXTENSION = Pattern.compile("^[a-z0-9]{1,8}$");

    private ProductionPayloadSupport() {
    }

    /**
     * Garde-fou content-type avant stockage R2 / transcription : on rejette un
     * type manifestement non-audio ({@code text/html}, {@code image/svg+xml}…),
     * tout en tolerant l'absence de type ou {@code application/octet-stream}
     * (certains clients mobiles n'etiquettent pas leur upload binaire). La cle
     * R2 est un UUID genere serveur — aucun path-traversal possible via le nom
     * de fichier.
     */
    public static void validateAudioContentType(MultipartFile audio) {
        String contentType = audio.getContentType();
        if (contentType == null || contentType.isBlank()) {
            return;
        }
        String lower = contentType.toLowerCase();
        boolean ok = lower.startsWith("audio/") || lower.equals("application/octet-stream");
        if (!ok) {
            throw new BusinessException(
                    "Type de fichier audio invalide (" + contentType + "). Formats acceptes : audio/*.");
        }
    }

    public static byte[] readBytes(MultipartFile audio) {
        try {
            return audio.getBytes();
        } catch (IOException e) {
            throw new BusinessException("Lecture du fichier audio impossible : " + e.getMessage());
        }
    }

    /**
     * Extension de stockage sure, deduite du nom d'origine puis, a defaut, du
     * content-type. {@code bin} en dernier recours : Whisper devine le format
     * au contenu, une extension inconnue ne doit pas faire echouer l'upload.
     */
    public static String extractExtension(MultipartFile file) {
        String name = file.getOriginalFilename();
        if (name != null) {
            int dot = name.lastIndexOf('.');
            if (dot >= 0 && dot < name.length() - 1) {
                String candidate = name.substring(dot + 1).toLowerCase();
                if (SAFE_EXTENSION.matcher(candidate).matches()) {
                    return candidate;
                }
            }
        }
        String ct = file.getContentType();
        if (ct != null) {
            return switch (ct) {
                case "audio/webm" -> "webm";
                case "audio/mpeg", "audio/mp3" -> "mp3";
                case "audio/mp4", "audio/m4a", "audio/x-m4a" -> "m4a";
                case "audio/ogg" -> "ogg";
                case "audio/wav", "audio/x-wav" -> "wav";
                default -> "bin";
            };
        }
        return "bin";
    }

    /**
     * Normalisation NFC + suppression des blancs de bord. La normalisation
     * evite que « é » saisi en deux points de code et « é » en un seul soient
     * traites comme deux textes differents — ce qui casserait toute recherche
     * de citation dans la production.
     */
    public static String sanitizeText(String texte) {
        String nfc = Normalizer.normalize(texte, Normalizer.Form.NFC);
        return nfc.strip();
    }

    public static int countWords(String texte) {
        if (texte == null || texte.isBlank()) return 0;
        return texte.trim().split("\\s+").length;
    }
}
