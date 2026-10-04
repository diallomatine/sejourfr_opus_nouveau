package com.sejourfr.app.service;

import com.sejourfr.app.exception.BusinessException;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import javax.imageio.stream.MemoryCacheImageInputStream;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.Iterator;
import java.util.Locale;
import java.util.Optional;

/**
 * Autorite unique de la validation des images uploadees (remplacement d'image
 * d'une question CO_IMAGE ou de son brouillon, import CO image).
 *
 * <ul>
 *   <li><b>Partout</b> : taille max, type declare en liste blanche, et type
 *       REEL lu sur les octets (signature) qui doit etre celui declare. Un
 *       fichier renomme ou un Content-Type menteur est refuse.</li>
 *   <li><b>Import seulement</b> : dimensions, ratio, largeur minimale et
 *       opacite, lus ici ({@link #lireDimensions}, {@link #transparence})
 *       mais opposes par le validateur d'import selon la charte
 *       {@code charte-images-co-v1.json}. Le remplacement d'image unitaire de
 *       la console reste libre de son cadrage.</li>
 * </ul>
 *
 * <p>Aucune dependance : JPEG et PNG passent par {@code ImageIO} du JDK, sans
 * cache disque (dimensions : en-tete seul ; opacite d'un PNG : decodage complet,
 * borne par {@link #MAX_PIXELS_OPACITE}). Le JDK ne sait pas lire le WEBP : ses
 * dimensions et son alpha sont lus dans les blocs RIFF (VP8, VP8L, VP8X, ALPH).
 */
public final class ImageUploadSupport {

    public static final long MAX_BYTES = 5L * 1024 * 1024; // 5 Mo

    /** Formats acceptes, avec leur Content-Type et leur extension de cle R2. */
    public enum FormatImage {
        JPEG("image/jpeg", "jpg"),
        PNG("image/png", "png"),
        WEBP("image/webp", "webp");

        private final String contentType;
        private final String extension;

        FormatImage(String contentType, String extension) {
            this.contentType = contentType;
            this.extension = extension;
        }

        public String contentType() { return contentType; }
        public String extension() { return extension; }

        static Optional<FormatImage> parContentType(String contentType) {
            if (contentType == null) return Optional.empty();
            String ct = contentType.toLowerCase(Locale.ROOT);
            return Arrays.stream(values()).filter(f -> f.contentType.equals(ct)).findFirst();
        }
    }

    /** Image validee : octets bruts + content-type normalise + extension. */
    public record ValidatedImage(byte[] bytes, String contentType, String extension) {}

    public record Dimensions(int largeur, int hauteur) {}

    private static final byte[] SIGNATURE_PNG = {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n'};

    public static ValidatedImage validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("Fichier image manquant");
        }
        if (file.getSize() > MAX_BYTES) {
            throw new BusinessException("Image trop volumineuse (max 5 Mo)");
        }
        FormatImage declare = FormatImage.parContentType(file.getContentType())
                .orElseThrow(() -> new BusinessException("Format non supporte (jpg, png ou webp attendu)"));
        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            throw new BusinessException("Lecture du fichier image impossible");
        }
        FormatImage reel = detecterFormat(bytes).orElseThrow(() -> new BusinessException(
                "Le contenu du fichier n'est pas une image jpg, png ou webp"));
        if (reel != declare) {
            throw new BusinessException("Le contenu du fichier (" + reel.extension()
                    + ") ne correspond pas au type declare (" + declare.extension() + ")");
        }
        return new ValidatedImage(bytes, reel.contentType(), reel.extension());
    }

    /** Format reel lu sur la signature des octets, vide si ce n'est ni JPEG, ni PNG, ni WEBP. */
    public static Optional<FormatImage> detecterFormat(byte[] b) {
        if (b == null) return Optional.empty();
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) {
            return Optional.of(FormatImage.JPEG);
        }
        if (b.length >= SIGNATURE_PNG.length
                && Arrays.equals(Arrays.copyOf(b, SIGNATURE_PNG.length), SIGNATURE_PNG)) {
            return Optional.of(FormatImage.PNG);
        }
        if (b.length >= 12 && ascii(b, 0, "RIFF") && ascii(b, 8, "WEBP")) {
            return Optional.of(FormatImage.WEBP);
        }
        return Optional.empty();
    }

    /** Dimensions lues dans l'en-tete, vide si l'en-tete est illisible. */
    public static Optional<Dimensions> lireDimensions(byte[] bytes, FormatImage format) {
        try {
            return format == FormatImage.WEBP ? dimensionsWebp(bytes) : dimensionsImageIo(bytes);
        } catch (IOException | RuntimeException e) {
            return Optional.empty();
        }
    }

    /** Verdict du controle d'opacite de la charte. */
    public enum Transparence {
        /** Tous les pixels sont pleinement opaques (alpha = 255), ou le format n'a pas d'alpha. */
        AUCUNE,
        /** Au moins un pixel a un alpha inferieur a 255. */
        PRESENTE,
        /** Les pixels n'ont pas pu etre lus (fichier corrompu, image trop grande, WEBP anime). */
        INVERIFIABLE
    }

    /**
     * Plafond de pixels decodes pour le controle d'opacite d'un PNG : le decodage
     * complet tient en memoire (4 octets par pixel, 64 Mo au plafond). Un PNG de
     * 5 Mo peut decrire une image bien plus grande (bombe de decompression).
     */
    public static final long MAX_PIXELS_OPACITE = 16_000_000L;

    /**
     * L'image porte-t-elle de la transparence REELLE ? Le critere est le pixel,
     * jamais la simple presence d'un canal alpha : une PNG RGBA entierement
     * opaque passe. Seuil : un seul pixel d'alpha inferieur a 255 suffit.
     *
     * <ul>
     *   <li><b>PNG</b> : decodage complet par {@code ImageIO}, chaque pixel lu
     *       (palette avec {@code tRNS} comprise).</li>
     *   <li><b>WEBP</b> : le JDK ne decode pas ses pixels. On lit les DONNEES
     *       d'alpha, pas le drapeau du VP8X : un bloc {@code ALPH} non compresse
     *       et non filtre est lu octet par octet ; un bloc {@code ALPH}
     *       compresse ou filtre vaut transparence ; un VP8L vaut ce que dit son
     *       indice {@code alpha_is_used}. libwebp n'ecrit l'un et l'autre que si
     *       un pixel est reellement transparent ({@code WebPPictureHasTransparency}).
     *       Un drapeau alpha sans bloc {@code ALPH} ne compte pas.</li>
     *   <li><b>JPEG</b> : jamais.</li>
     * </ul>
     */
    public static Transparence transparence(byte[] bytes, FormatImage format) {
        return switch (format) {
            case JPEG -> Transparence.AUCUNE;
            case WEBP -> transparenceWebp(bytes);
            case PNG -> transparencePng(bytes);
        };
    }

    private static Optional<Dimensions> dimensionsImageIo(byte[] bytes) throws IOException {
        try (ImageInputStream in = new MemoryCacheImageInputStream(new ByteArrayInputStream(bytes))) {
            Iterator<ImageReader> readers = ImageIO.getImageReaders(in);
            if (!readers.hasNext()) return Optional.empty();
            ImageReader reader = readers.next();
            try {
                reader.setInput(in, true, true);
                return Optional.of(new Dimensions(reader.getWidth(0), reader.getHeight(0)));
            } finally {
                reader.dispose();
            }
        }
    }

    private static Optional<Dimensions> dimensionsWebp(byte[] b) {
        if (b.length < 30) return Optional.empty();
        if (ascii(b, 12, "VP8 ")) {
            // Trame cle VP8 : code de demarrage 9D 01 2A, puis largeur/hauteur sur 14 bits.
            if ((b[23] & 0xFF) != 0x9D || (b[24] & 0xFF) != 0x01 || (b[25] & 0xFF) != 0x2A) {
                return Optional.empty();
            }
            return Optional.of(new Dimensions(le16(b, 26) & 0x3FFF, le16(b, 28) & 0x3FFF));
        }
        if (ascii(b, 12, "VP8L")) {
            if ((b[20] & 0xFF) != 0x2F) return Optional.empty();
            long bits = (b[21] & 0xFFL) | (b[22] & 0xFFL) << 8 | (b[23] & 0xFFL) << 16 | (b[24] & 0xFFL) << 24;
            int largeur = (int) (bits & 0x3FFF) + 1;
            int hauteur = (int) ((bits >> 14) & 0x3FFF) + 1;
            return Optional.of(new Dimensions(largeur, hauteur));
        }
        if (ascii(b, 12, "VP8X")) {
            return Optional.of(new Dimensions(le24(b, 24) + 1, le24(b, 27) + 1));
        }
        return Optional.empty();
    }

    private static Transparence transparenceWebp(byte[] b) {
        if (b == null || b.length < 20) return Transparence.INVERIFIABLE;
        int pos = 12;
        while (pos + 8 <= b.length) {
            long taille = le32(b, pos + 4);
            int debut = pos + 8;
            if (taille > b.length - debut) return Transparence.INVERIFIABLE;
            int n = (int) taille;
            if (ascii(b, pos, "ALPH")) return alphaWebpBrut(b, debut, n);
            if (ascii(b, pos, "VP8L")) {
                if (n < 5 || (b[debut] & 0xFF) != 0x2F) return Transparence.INVERIFIABLE;
                return (b[debut + 4] & 0x10) != 0 ? Transparence.PRESENTE : Transparence.AUCUNE;
            }
            // Le bloc ALPH precede toujours le VP8 : l'atteindre sans lui = opaque.
            if (ascii(b, pos, "VP8 ")) return Transparence.AUCUNE;
            if (ascii(b, pos, "ANMF")) return Transparence.INVERIFIABLE;
            pos = debut + n + (n & 1);
        }
        return Transparence.INVERIFIABLE;
    }

    /**
     * Bloc {@code ALPH} : un octet d'en-tete (compression sur les bits 0-1,
     * filtrage sur les bits 2-3), puis le plan alpha. Seul le plan brut non
     * filtre se lit sans decodeur.
     */
    private static Transparence alphaWebpBrut(byte[] b, int debut, int taille) {
        if (taille < 1) return Transparence.INVERIFIABLE;
        int entete = b[debut] & 0xFF;
        boolean brut = (entete & 0x03) == 0 && (entete & 0x0C) == 0;
        if (!brut) return Transparence.PRESENTE;
        if (taille == 1) return Transparence.INVERIFIABLE;
        for (int i = debut + 1; i < debut + taille; i++) {
            if ((b[i] & 0xFF) != 0xFF) return Transparence.PRESENTE;
        }
        return Transparence.AUCUNE;
    }

    private static Transparence transparencePng(byte[] bytes) {
        Optional<Dimensions> d = lireDimensions(bytes, FormatImage.PNG);
        if (d.isEmpty() || (long) d.get().largeur() * d.get().hauteur() > MAX_PIXELS_OPACITE) {
            return Transparence.INVERIFIABLE;
        }
        BufferedImage image;
        try {
            image = ImageIO.read(new MemoryCacheImageInputStream(new ByteArrayInputStream(bytes)));
        } catch (IOException | RuntimeException e) {
            return Transparence.INVERIFIABLE;
        }
        if (image == null) return Transparence.INVERIFIABLE;
        if (!image.getColorModel().hasAlpha()) return Transparence.AUCUNE;
        int largeur = image.getWidth();
        int[] ligne = new int[largeur];
        for (int y = 0; y < image.getHeight(); y++) {
            image.getRGB(0, y, largeur, 1, ligne, 0, largeur);
            for (int argb : ligne) {
                if ((argb >>> 24) != 0xFF) return Transparence.PRESENTE;
            }
        }
        return Transparence.AUCUNE;
    }

    private static boolean ascii(byte[] b, int offset, String attendu) {
        if (b.length < offset + attendu.length()) return false;
        for (int i = 0; i < attendu.length(); i++) {
            if (b[offset + i] != (byte) attendu.charAt(i)) return false;
        }
        return true;
    }

    private static int le16(byte[] b, int i) {
        return (b[i] & 0xFF) | (b[i + 1] & 0xFF) << 8;
    }

    private static long le32(byte[] b, int i) {
        return (b[i] & 0xFFL) | (b[i + 1] & 0xFFL) << 8 | (b[i + 2] & 0xFFL) << 16 | (b[i + 3] & 0xFFL) << 24;
    }

    private static int le24(byte[] b, int i) {
        return (b[i] & 0xFF) | (b[i + 1] & 0xFF) << 8 | (b[i + 2] & 0xFF) << 16;
    }

    private ImageUploadSupport() {}
}
