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
import java.util.LinkedHashMap;
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

    private final ObjectMapper objectMapper;
    private final ProductionEvaluationProperties props;
    private final Map<String, String> templateCache = new ConcurrentHashMap<>();

    public EvaluationPromptBuilder(ObjectMapper objectMapper, ProductionEvaluationProperties props) {
        this.objectMapper = objectMapper;
        this.props = props;
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

        Map<String, Object> grille = task.getCriteresEvaluation() != null
            ? task.getCriteresEvaluation()
            : Map.of();

        // Pour la grille passee au LLM on n'envoie que les criteres + niveau_attendu
        // afin d'eviter de dupliquer consignes_correcteur / marqueurs_niveau_superieur
        // qui sont injectes en sections dediees ci-dessous.
        Map<String, Object> criteresPourPrompt = new LinkedHashMap<>();
        Object criteres = grille.get("criteres");
        if (criteres != null) criteresPourPrompt.put("criteres", criteres);
        Object niveauAttendu = grille.get("niveau_attendu");
        if (niveauAttendu != null) criteresPourPrompt.put("niveau_attendu", niveauAttendu);
        String criteresJson;
        try {
            criteresJson = objectMapper.writeValueAsString(criteresPourPrompt);
        } catch (Exception e) {
            criteresJson = "{}";
        }

        String consignesCorrecteur = asString(grille.get("consignes_correcteur"));
        String marqueursNiveauSup = asString(grille.get("marqueurs_niveau_superieur"));
        if (marqueursNiveauSup.isBlank()) {
            marqueursNiveauSup = "(non renseigne pour cette tache — utilise les descripteurs CECRL standards)";
        }

        String litteralNotice = transcriptionLitterale
            ? "Note : la transcription provient d'un systeme automatique configure en mode litteral. "
              + "Elle peut contenir des erreurs grammaticales refletant la production orale reelle du "
              + "candidat (ex: \"j'habites\", \"les voitures rouge\"). Tiens compte de ces erreurs dans "
              + "ton evaluation."
            : "";

        // EO : débit (mots/min) en tête du bloc, puis l'éventuel rappel de durée
        // sous-objectif. Injectés ensemble dans {DUREE_BLOCK} pour ne pas
        // toucher au gabarit .md (pas de bump de prompt-version : contexte
        // runtime, comme la durée).
        String dureeBlock = buildDebitBlock(task, production, dureeProductionSec)
                + buildDureeBlock(task, dureeProductionSec);

        return loadTemplate(userPath(currentVersion()))
            .replace("{MODALITE}", modalite(task.getEpreuve()))
            .replace("{TACHE_NUMERO}", String.valueOf(task.getTacheNumero()))
            .replace("{NIVEAU}", nullSafe(task.getNiveauCible()))
            .replace("{CONSIGNE}", nullSafe(task.getConsigne()))
            .replace("{CONTEXTE_BLOCK}", contexteBlock)
            .replace("{CRITERES}", criteresJson)
            .replace("{CONSIGNES_CORRECTEUR}", consignesCorrecteur.isBlank() ? "(aucune)" : consignesCorrecteur)
            .replace("{MARQUEURS_NIVEAU_SUPERIEUR}", marqueursNiveauSup)
            .replace("{PRODUCTION}", nullSafe(production))
            .replace("{LITTERAL_NOTICE}", litteralNotice)
            .replace("{DUREE_BLOCK}", dureeBlock);
    }

    /**
     * Bloc EO « débit de parole » (mots/minute). PUREMENT INFORMATIF depuis le
     * prompt v1.3 : on évalue la transcription comme un texte écrit, donc le
     * débit ne doit influencer ni la note ni le niveau (le modèle n'entend pas
     * l'oral réel). Vide pour l'EE ou sans durée.
     */
    private static String buildDebitBlock(ProductionTask task, String production, Integer dureeProductionSec) {
        if (task.getEpreuve() != EpreuveType.TCF_EO
                || dureeProductionSec == null || dureeProductionSec <= 0
                || production == null || production.isBlank()) {
            return "";
        }
        int mots = production.trim().split("\\s+").length;
        int wpm = (int) Math.round(mots * 60.0 / dureeProductionSec);
        return "DÉBIT DE PAROLE (indicatif) : ~" + mots + " mots en " + dureeProductionSec
            + " s, soit ~" + wpm + " mots/minute. Donnée fournie à titre PUREMENT INFORMATIF : "
            + "n'en tiens PAS compte dans la note_globale ni dans le niveau_cecrl (tu évalues le "
            + "texte transcrit, pas la fluidité orale que tu n'entends pas).\n";
    }

    /**
     * Bloc EO « durée parlée vs objectif ». PUREMENT INFORMATIF depuis v1.3 :
     * une transcription se note comme un texte écrit, la durée ne doit pas
     * minorer la note (le candidat peut être coupé par le temps, et on ne
     * récompense/pénalise pas l'oral non entendu). Vide pour l'EE ou si la durée
     * atteint l'objectif.
     */
    private static String buildDureeBlock(ProductionTask task, Integer dureeProductionSec) {
        if (task.getEpreuve() != EpreuveType.TCF_EO
                || dureeProductionSec == null
                || task.getDureeMaxSec() == null
                || dureeProductionSec >= task.getDureeMaxSec()) {
            return "";
        }
        StringBuilder sb = new StringBuilder("DURÉE DE LA PRODUCTION (indicatif) : ")
            .append(dureeProductionSec)
            .append(" s pour un objectif de ")
            .append(task.getDureeMaxSec())
            .append(" s");
        if (task.getDureeMinSec() != null) {
            sb.append(" (minimum ").append(task.getDureeMinSec()).append(" s)");
        }
        sb.append(". Donnée fournie à titre PUREMENT INFORMATIF : n'en tiens PAS compte dans la "
            + "note_globale ni dans le niveau_cecrl. Évalue la qualité linguistique du texte "
            + "transcrit, pas la complétude orale.\n");
        return sb.toString();
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
