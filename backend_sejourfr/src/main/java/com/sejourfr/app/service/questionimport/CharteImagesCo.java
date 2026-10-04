package com.sejourfr.app.service.questionimport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.config.QuestionImportProperties;
import com.sejourfr.app.service.ImageUploadSupport.FormatImage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;

/**
 * Contraintes techniques de la charte des images CO
 * ({@code generation_questions/charte-images-co-vN.json}), chargees et
 * VERIFIEES au demarrage : une charte illisible ou incomplete fait echouer le
 * boot, jamais un import qui laisserait tout passer.
 *
 * <p>Seule autorite des formats, du ratio, de la largeur minimale et de
 * l'exigence d'opacite opposes par {@link CoImageImportValidator}.
 */
@Slf4j
@Component
public class CharteImagesCo {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final String version;
    private final Set<FormatImage> formats;
    private final int ratioLargeur;
    private final int ratioHauteur;
    private final double tolerance;
    private final int largeurMinPx;
    private final boolean fondOpaque;

    public CharteImagesCo(QuestionImportProperties props) {
        String chemin = props.getCharte();
        JsonNode racine;
        try (InputStream in = new ClassPathResource(chemin).getInputStream()) {
            racine = MAPPER.readTree(in);
        } catch (IOException e) {
            throw new IllegalStateException("Charte des images CO illisible : " + chemin, e);
        }
        JsonNode technique = exiger(racine, "technique", chemin);
        this.version = exiger(racine, "version", chemin).asText();
        EnumSet<FormatImage> lus = EnumSet.noneOf(FormatImage.class);
        for (JsonNode f : exiger(technique, "formats", chemin)) {
            lus.add(Arrays.stream(FormatImage.values())
                    .filter(fi -> fi.extension().equals(f.asText()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalStateException(
                            "Format inconnu « " + f.asText() + " » dans " + chemin)));
        }
        if (lus.isEmpty()) throw new IllegalStateException("Aucun format dans " + chemin);
        this.formats = Set.copyOf(lus);
        JsonNode ratio = exiger(technique, "ratio", chemin);
        this.ratioLargeur = positif(exiger(ratio, "largeur", chemin).asInt(), "ratio.largeur", chemin);
        this.ratioHauteur = positif(exiger(ratio, "hauteur", chemin).asInt(), "ratio.hauteur", chemin);
        this.tolerance = exiger(ratio, "tolerance", chemin).asDouble();
        if (tolerance < 0 || tolerance >= 1) {
            throw new IllegalStateException("ratio.tolerance hors [0, 1[ dans " + chemin);
        }
        this.largeurMinPx = positif(exiger(technique, "largeurMinPx", chemin).asInt(), "largeurMinPx", chemin);
        this.fondOpaque = exiger(technique, "fondOpaque", chemin).asBoolean();
        log.info("Charte des images CO chargee : {} (formats {}, ratio {}:{} ±{}, largeur >= {} px, opaque {})",
                version, formats, ratioLargeur, ratioHauteur, tolerance, largeurMinPx, fondOpaque);
    }

    public String version() { return version; }
    public Set<FormatImage> formats() { return formats; }
    public int ratioLargeur() { return ratioLargeur; }
    public int ratioHauteur() { return ratioHauteur; }
    public double tolerance() { return tolerance; }
    public int largeurMinPx() { return largeurMinPx; }
    public boolean fondOpaque() { return fondOpaque; }

    /** Le ratio largeur/hauteur est-il celui de la charte, a la tolerance relative pres ? */
    public boolean ratioConforme(int largeur, int hauteur) {
        if (largeur <= 0 || hauteur <= 0) return false;
        double attendu = (double) ratioLargeur / ratioHauteur;
        double reel = (double) largeur / hauteur;
        return Math.abs(reel - attendu) / attendu <= tolerance;
    }

    private static JsonNode exiger(JsonNode parent, String cle, String chemin) {
        JsonNode n = parent.get(cle);
        if (n == null || n.isNull()) {
            throw new IllegalStateException("Cle « " + cle + " » absente de " + chemin);
        }
        return n;
    }

    private static int positif(int v, String cle, String chemin) {
        if (v <= 0) throw new IllegalStateException(cle + " doit etre > 0 dans " + chemin);
        return v;
    }
}
