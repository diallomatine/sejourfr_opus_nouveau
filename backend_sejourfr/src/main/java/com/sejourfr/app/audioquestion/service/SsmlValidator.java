package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse;
import com.sejourfr.app.audioquestion.exception.ContentValidationException;
import com.sejourfr.app.audioquestion.exception.SsmlValidationException;
import org.springframework.stereotype.Component;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.StringReader;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Valide le SSML produit par Claude et en extrait :
 *   - le texte effectif (pour cross-check avec le transcript)
 *   - le nombre de caracteres facturables Azure (texte des <voice>, sans balises)
 *
 * Verifie :
 *   - XML bien forme + securisation parser (FEATURE_SECURE_PROCESSING, pas de DOCTYPE)
 *   - tag racine <speak xml:lang="fr-FR">
 *   - au moins une <voice name="...">
 *   - toutes les voix utilisees sont dans la whitelist {@link AzureVoices}
 *   - voix utilisees = voix declarees dans {@code voices[]} (set egalite)
 *   - texte effectif extrait ~= champ {@code transcript} (tolerance whitespace)
 */
@Component
public class SsmlValidator {

    /**
     * Seuil de similarite Jaccard (par mots) entre le transcript Claude
     * et le texte effectif du SSML. Tolerance pour les prefixes locuteur
     * ("Patient :", "Receptionniste :") et la ponctuation residuelle.
     */
    private static final double TRANSCRIPT_SIMILARITY_THRESHOLD = 0.80;

    private final DocumentBuilderFactory factory;

    public SsmlValidator() {
        this.factory = DocumentBuilderFactory.newInstance();
        this.factory.setNamespaceAware(true);
        try {
            this.factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
            this.factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            this.factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            this.factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            this.factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
            this.factory.setXIncludeAware(false);
            this.factory.setExpandEntityReferences(false);
        } catch (Exception e) {
            throw new IllegalStateException("Impossible de durcir DocumentBuilderFactory", e);
        }
    }

    /**
     * Valide la coherence du SSML avec le DTO Claude. Lance une exception si rejet.
     * @return le texte effectif extrait (sans balises ni breaks)
     */
    public ValidationResult validate(AnthropicGenerationResponse.AudioSection audio) {
        // Azure rejette les <break/> enfants directs de <speak> (doivent etre dans <voice>).
        // Claude en produit parfois entre les repliques d'un dialogue : on les retire avant validation.
        String cleanedSsml = stripOrphanBreaks(audio.ssml());
        Document doc = parseDocument(cleanedSsml);

        Element root = doc.getDocumentElement();
        if (!"speak".equals(root.getLocalName())) {
            throw new SsmlValidationException("La racine SSML doit etre <speak>, trouvee : " + root.getLocalName());
        }
        String xmlLang = root.getAttribute("xml:lang");
        if (xmlLang.isBlank()) {
            xmlLang = root.getAttributeNS("http://www.w3.org/XML/1998/namespace", "lang");
        }
        if (!"fr-FR".equals(xmlLang)) {
            throw new SsmlValidationException("L'attribut xml:lang doit etre 'fr-FR', trouve : '" + xmlLang + "'");
        }

        Set<String> usedVoices = new LinkedHashSet<>();
        int speechChars = 0;
        StringBuilder spokenText = new StringBuilder();

        NodeList voiceNodes = doc.getElementsByTagName("voice");
        if (voiceNodes.getLength() == 0) {
            throw new SsmlValidationException("Au moins une balise <voice> est requise dans le SSML");
        }

        for (int i = 0; i < voiceNodes.getLength(); i++) {
            Element voice = (Element) voiceNodes.item(i);
            String name = voice.getAttribute("name");
            if (name.isBlank()) {
                throw new SsmlValidationException("Une balise <voice> n'a pas d'attribut name");
            }
            if (!AzureVoices.ALLOWED.contains(name)) {
                throw new SsmlValidationException("Voix Azure non autorisee : " + name);
            }
            usedVoices.add(name);

            String voiceText = extractTextContent(voice);
            speechChars += voiceText.length();
            if (!spokenText.isEmpty()) {
                spokenText.append(' ');
            }
            spokenText.append(voiceText);
        }

        Set<String> declaredVoices = audio.voices().stream()
            .map(AnthropicGenerationResponse.VoiceInfo::azureVoice)
            .collect(Collectors.toCollection(HashSet::new));

        if (!usedVoices.equals(declaredVoices)) {
            throw new ContentValidationException(
                "Voix declarees et voix utilisees dans le SSML different",
                Map.of(
                    "declared", List.copyOf(declaredVoices),
                    "used", List.copyOf(usedVoices)
                )
            );
        }

        if (audio.speakerCount() != audio.voices().size()) {
            throw new ContentValidationException(
                "speakerCount (" + audio.speakerCount() + ") != voices.size() (" + audio.voices().size() + ")"
            );
        }

        double similarity = jaccardWordSimilarity(spokenText.toString(), audio.transcript());
        if (similarity < TRANSCRIPT_SIMILARITY_THRESHOLD) {
            throw new ContentValidationException(
                "Le transcript ne correspond pas au texte effectif du SSML (similarite "
                    + String.format(Locale.ROOT, "%.0f%%", similarity * 100) + ")",
                Map.of(
                    "transcriptPreview", preview(audio.transcript()),
                    "spokenPreview", preview(spokenText.toString()),
                    "similarity", similarity
                )
            );
        }

        return new ValidationResult(cleanedSsml, spokenText.toString(), speechChars, List.copyOf(usedVoices));
    }

    /**
     * Retire les balises {@code <break/>} situees entre les blocs {@code <voice>}
     * (donc enfants directs de {@code <speak>}). Azure les refuse avec
     * "Node [speak] should not contain node [break]". Les breaks intra-voice sont conserves.
     */
    private static String stripOrphanBreaks(String ssml) {
        String s = ssml;
        // Cas 1 : <break .../> entre </voice> et <voice ...>
        s = s.replaceAll("(?i)(</voice>)\\s*<break[^>]*/>\\s*(?=<voice)", "$1");
        // Cas 2 : <break .../> juste apres <speak ...> et avant <voice ...>
        s = s.replaceAll("(?i)(<speak[^>]*>)\\s*<break[^>]*/>\\s*(?=<voice)", "$1");
        // Cas 3 : <break .../> juste avant </speak>
        s = s.replaceAll("(?i)<break[^>]*/>\\s*(?=</speak>)", "");
        return s;
    }

    private Document parseDocument(String ssml) {
        try {
            DocumentBuilder builder = factory.newDocumentBuilder();
            return builder.parse(new InputSource(new StringReader(ssml)));
        } catch (Exception e) {
            throw new SsmlValidationException("SSML non parseable comme XML : " + e.getMessage(), e);
        }
    }

    /** Concatene le texte brut d'un noeud en ignorant balises et attributs. <break/> est silencieux. */
    private String extractTextContent(Node node) {
        StringBuilder sb = new StringBuilder();
        collectText(node, sb);
        return sb.toString().trim();
    }

    private void collectText(Node node, StringBuilder sb) {
        switch (node.getNodeType()) {
            case Node.TEXT_NODE, Node.CDATA_SECTION_NODE -> sb.append(node.getNodeValue());
            case Node.ELEMENT_NODE -> {
                if ("break".equals(node.getLocalName())) {
                    return;
                }
                NodeList children = node.getChildNodes();
                for (int i = 0; i < children.getLength(); i++) {
                    collectText(children.item(i), sb);
                }
            }
            default -> { /* ignore */ }
        }
    }

    /**
     * Compare le transcript et le texte effectif du SSML via Jaccard sur l'ensemble
     * des mots normalises (lowercase, sans ponctuation). Tolere les prefixes locuteur
     * et la ponctuation differente sans regex fragile.
     */
    private static double jaccardWordSimilarity(String a, String b) {
        Set<String> wordsA = tokenize(a);
        Set<String> wordsB = tokenize(b);
        if (wordsA.isEmpty() && wordsB.isEmpty()) return 1.0;
        Set<String> union = new java.util.HashSet<>(wordsA);
        union.addAll(wordsB);
        Set<String> intersection = new java.util.HashSet<>(wordsA);
        intersection.retainAll(wordsB);
        return union.isEmpty() ? 1.0 : (double) intersection.size() / union.size();
    }

    private static Set<String> tokenize(String s) {
        if (s == null || s.isBlank()) return Set.of();
        String normalized = s.toLowerCase(Locale.FRENCH)
            .replaceAll("[\\p{Punct}«»“”…]", " ")
            .replaceAll("\\s+", " ")
            .trim();
        if (normalized.isEmpty()) return Set.of();
        return new java.util.HashSet<>(Arrays.asList(normalized.split(" ")));
    }

    private static String preview(String s) {
        if (s == null) return "";
        return s.length() > 120 ? s.substring(0, 120) + "..." : s;
    }

    public record ValidationResult(
        String cleanedSsml,
        String spokenText,
        int azureCharactersCount,
        List<String> usedVoices
    ) {}
}
