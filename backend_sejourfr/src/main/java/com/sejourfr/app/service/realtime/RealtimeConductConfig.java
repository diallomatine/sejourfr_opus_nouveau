package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Source UNIQUE des paramètres de CONDUITE côté client de l'examinateur temps
 * réel : amorce d'accueil, délais, tenue micro, détection locale de voix,
 * relance sur silence, fin de temps douce, reprise — et les messages entre
 * crochets que la persona sait lire ({@code [SILENCE]}, {@code [FIN]},
 * {@code [REPRISE]}). Charge {@code prompts/realtime-conduct-<version>.json},
 * servi tel quel aux deux fronts dans le descripteur de session : aucune de ces
 * valeurs n'est recopiée en dur côté client (un repli local identique n'existe
 * que pour un serveur qui ne servirait pas le bloc).
 *
 * <p>Chaque fichier déclare les versions de persona qu'il sait piloter
 * ({@code personas}) : une persona qui n'y figure pas fait échouer le BOOT. Les
 * messages entre crochets n'ont de sens que pour la persona qui les définit —
 * envoyer {@code [FIN]} à la v3 la laisserait improviser. Fichier absent,
 * illisible ou incomplet = erreur de configuration bloquante, comme les
 * rubriques : jamais de repli muet.
 */
@Slf4j
@Component
public class RealtimeConductConfig {

    private static final String PATH_FORMAT = "prompts/realtime-conduct-%s.json";

    /** Clés obligatoires, en notation pointée. */
    private static final List<String> CLES = List.of(
            "version", "welcomePrimer", "welcomeGuardMs", "halfDuplexHoldMs",
            "voiceActivity.energyThreshold", "voiceActivity.minSpeechMs", "voiceActivity.hangoverMs",
            "silenceRelance.afterMs", "silenceRelance.maxConsecutive", "silenceRelance.disabledLastSec",
            "silenceRelance.message",
            "timeUp.graceMaxMs", "timeUp.message", "timeUp.closeIdleMs", "timeUp.closeMaxMs",
            "resume.message", "resume.contextTurns");

    private final RealtimeProperties props;
    private final ObjectMapper objectMapper;

    private JsonNode client;
    private String version;

    public RealtimeConductConfig(RealtimeProperties props, ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void load() {
        String path = String.format(PATH_FORMAT, props.getConductVersion());
        JsonNode root;
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            root = objectMapper.readTree(StreamUtils.copyToString(is, StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("JSON de conduite introuvable/illisible (" + path
                    + ") — vérifier sejourfr.realtime.conduct-version", e);
        }
        for (String cle : CLES) {
            if (lire(root, cle) == null) {
                throw new IllegalStateException("JSON de conduite " + path + " : clé « " + cle + " » absente.");
            }
        }
        List<String> personas = new ArrayList<>();
        JsonNode p = root.get("personas");
        if (p != null && p.isArray()) p.forEach(v -> personas.add(v.asString()));
        if (!personas.contains(props.getPersonaVersion())) {
            throw new IllegalStateException("JSON de conduite " + path + " incompatible avec la persona "
                    + props.getPersonaVersion() + " (personas pilotées : " + personas
                    + "). Retour arrière : persona v3 + conduite v0, persona v4 + conduite v1.");
        }
        this.version = root.get("version").asString();
        this.client = root;
        log.info("Conduite realtime chargée ({}) pour la persona {}.", version, props.getPersonaVersion());
    }

    /** Le bloc servi aux clients, tel que versionné. */
    public JsonNode client() {
        return client;
    }

    /** Version chargée, tracée sur chaque session ({@code conduct_config_version}). */
    public String version() {
        return version;
    }

    private static JsonNode lire(JsonNode root, String cle) {
        JsonNode n = root;
        for (String part : cle.split("\\.")) {
            if (n == null) return null;
            n = n.get(part);
        }
        return n == null || n.isNull() ? null : n;
    }
}
