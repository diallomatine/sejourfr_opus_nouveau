package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Construit les prompts system / user passes a un {@link EvaluationLlmClient}.
 *
 * <p>Les gabarits sont charges depuis classpath:prompts/ a la demande et
 * mis en cache. Le suffixe de fichier est derive de la prompt-version active
 * (ex: {@code v1.0}, {@code v1.1}) : a chaque version ses propres fichiers
 * {@code production-evaluation-system-vX.Y.md},
 * {@code production-evaluation-user-template-vX.Y.md}. La version effective
 * est lue depuis la config du provider courant via
 * {@link ProductionEvaluationProperties#getProvider()}.
 *
 * <p>Pour les templates >= v1.1 on extrait aussi {@code consignes_correcteur}
 * et {@code marqueurs_niveau_superieur} de la grille pour les passer en
 * sections dediees (avant on les laissait fondus dans {@code criteres_evaluation}).
 * Les templates v1.0 ignorent ces placeholders sans broncher.
 */
@Component
public class EvaluationPromptBuilder {

    private static final String SYSTEM_PATH_FORMAT = "prompts/production-evaluation-system-%s.md";
    private static final String USER_PATH_FORMAT = "prompts/production-evaluation-user-template-%s.md";
    private static final List<String> NIVEAUX = List.of("A1", "A2", "B1", "B2", "C1", "C2");

    private final ObjectMapper objectMapper;
    private final ProductionEvaluationProperties props;
    private final ProductionRubricsProvider rubrics;
    private final Map<String, String> templateCache = new ConcurrentHashMap<>();

    public EvaluationPromptBuilder(ObjectMapper objectMapper, ProductionEvaluationProperties props,
                                   ProductionRubricsProvider rubrics) {
        this.objectMapper = objectMapper;
        this.props = props;
        this.rubrics = rubrics;
    }

    public String buildSystemPrompt(EpreuveType epreuve) {
        return loadTemplate(systemPath(currentVersion()))
            .replace("{MODALITE}", modalite(epreuve));
    }

    /**
     * @param production texte EE rendu ou transcription Whisper (EO).
     * @param transcriptionLitterale true si la production vient d'une transcription
     *        Whisper en mode litteral (pour informer le LLM que les fautes peuvent
     *        avoir ete partiellement lissees).
     * @param dureeProductionSec duree parlee reelle (EO uniquement, sinon null).
     *        Si elle est sous l'objectif {@code dureeMaxSec}, on injecte un bloc
     *        invitant le LLM a minorer la note pour production insuffisante.
     */
    public String buildUserPrompt(ProductionTask task, String production,
                                  boolean transcriptionLitterale, Integer dureeProductionSec) {
        String contexteBlock = (task.getContexte() == null || task.getContexte().isBlank())
            ? ""
            : "CONTEXTE :\n\"" + task.getContexte() + "\"\n";

        // Source UNIQUE et exclusive du "comment noter" par tache : la rubrique
        // fixe (fichier). Plus aucun fallback DB. Le system prompt porte le
        // global ; ce builder n'injecte que des donnees, pas d'instruction. La
        // couverture des taches actives est garantie au boot par
        // ProductionRubricsValidator. Le niveau cible est porte par {NIVEAU}, pas
        // dupplique dans la grille.
        Map<String, Object> rubric = rubrics.find(task.getEpreuve(), task.getTacheNumero()).orElse(Map.of());

        Object criteres = rubric.get("criteres");
        String criteresJson;
        try {
            criteresJson = objectMapper.writeValueAsString(criteres != null ? criteres : List.of());
        } catch (Exception e) {
            criteresJson = "[]";
        }

        String bareme = asString(rubric.get("bareme_note"));
        if (bareme.isBlank()) {
            bareme = "0-9 : tache insuffisamment remplie · 10-13 : tache remplie · "
                + "14-16 : bonne maitrise · 17-20 : excellente maitrise.";
        }

        String descripteurs = formatDescripteurs(rubric.get("descripteurs"));
        if (descripteurs.isBlank()) {
            descripteurs = "(non renseignes pour cette tache — applique les descripteurs CECRL standards.)";
        }

        String consignes = asString(rubric.get("consignes_correcteur"));
        if (consignes.isBlank()) consignes = "(aucune)";

        // Donnee factuelle uniquement (l'ordre d'ignorer la duree vit dans le
        // system prompt, section oral). `transcriptionLitterale` n'est plus
        // exploite ici : la notice de transcription est portee par le system prompt.
        String dureeBlock = buildDureeBlock(task, dureeProductionSec);

        return loadTemplate(userPath(currentVersion()))
            .replace("{MODALITE}", modalite(task.getEpreuve()))
            .replace("{TACHE_NUMERO}", String.valueOf(task.getTacheNumero()))
            .replace("{NIVEAU}", nullSafe(task.getNiveauCible()))
            .replace("{CONSIGNE}", nullSafe(task.getConsigne()))
            .replace("{CONTEXTE_BLOCK}", contexteBlock)
            .replace("{CRITERES}", criteresJson)
            .replace("{BAREME_NOTE}", bareme)
            .replace("{DESCRIPTEURS}", descripteurs)
            .replace("{CONSIGNES_CORRECTEUR}", consignes)
            .replace("{PRODUCTION}", nullSafe(production))
            .replace("{DUREE_BLOCK}", dureeBlock);
    }

    /** Formate la map descripteurs {A1..C2} en lignes "- B2 : ...", dans l'ordre. */
    private static String formatDescripteurs(Object o) {
        if (!(o instanceof Map<?, ?> m)) return "";
        StringBuilder sb = new StringBuilder();
        for (String niv : NIVEAUX) {
            Object v = m.get(niv);
            if (v != null && !v.toString().isBlank()) {
                sb.append("- ").append(niv).append(" : ").append(v).append("\n");
            }
        }
        return sb.toString().trim();
    }

    /**
     * Bloc EO « durée parlée vs objectif » — donnée FACTUELLE uniquement. La
     * consigne de ne pas la prendre en compte vit une seule fois dans le system
     * prompt (section oral). Vide pour l'EE ou si la durée atteint l'objectif.
     */
    private static String buildDureeBlock(ProductionTask task, Integer dureeProductionSec) {
        if (task.getEpreuve() != EpreuveType.TCF_EO
                || dureeProductionSec == null
                || task.getDureeMaxSec() == null
                || dureeProductionSec >= task.getDureeMaxSec()) {
            return "";
        }
        return "DURÉE (indicative) : " + dureeProductionSec + " s (objectif "
            + task.getDureeMaxSec() + " s).\n";
    }

    /**
     * Version active = celle du provider courant. On ne mélange pas les
     * versions entre providers : si tu actives OpenAI tu utilises la version
     * configurée pour OpenAI, idem Anthropic.
     */
    private String currentVersion() {
        String provider = props.getProvider() == null ? "" : props.getProvider().trim().toLowerCase();
        return switch (provider) {
            case "openai" -> props.getOpenai().getPromptVersion();
            case "anthropic" -> props.getAnthropic().getPromptVersion();
            default -> props.getOpenai().getPromptVersion();
        };
    }

    private String loadTemplate(String path) {
        return templateCache.computeIfAbsent(path, this::loadResource);
    }

    private String loadResource(String path) {
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            return StreamUtils.copyToString(is, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException(
                "Template prompt introuvable : " + path
                    + " (verifier sejourfr.production-evaluation.{openai,anthropic}.prompt-version)", e
            );
        }
    }

    private static String systemPath(String version) {
        return String.format(SYSTEM_PATH_FORMAT, version);
    }

    private static String userPath(String version) {
        return String.format(USER_PATH_FORMAT, version);
    }

    private static String modalite(EpreuveType epreuve) {
        return epreuve == EpreuveType.TCF_EO ? "orale" : "ecrite";
    }

    @SuppressWarnings("unused")
    private static List<?> asList(Object o) {
        return (o instanceof List<?> l) ? l : List.of();
    }

    private static String asString(Object o) {
        return o == null ? "" : o.toString();
    }

    private static String nullSafe(String s) {
        return s == null ? "" : s;
    }
}
