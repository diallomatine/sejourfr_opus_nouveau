package com.sejourfr.app.service;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.ProductionTaskManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Garde-fou de demarrage : le fichier de rubriques etant l'UNIQUE source du
 * "comment noter", on refuse de demarrer si la couverture ou la coherence n'est
 * pas garantie. Verifie, sur {@link ApplicationReadyEvent} :
 * <ul>
 *   <li>les 6 cles {@code EE_T1..3} / {@code EO_T1..3} sont presentes ;</li>
 *   <li>chaque tache {@code is_active=TRUE} (epreuve EO/EE) a une rubrique ;</li>
 *   <li>par rubrique : Σ poids == 1.0 (±0.001) ;</li>
 *   <li>par rubrique : {@code criteres}, {@code bareme_note}, {@code descripteurs}
 *       et {@code consignes_correcteur} renseignes ;</li>
 *   <li>chaque {@code code} de critere ∈ set canonique ;</li>
 *   <li>presence obligatoire du SOCLE DE LANGUE ({@code lexique},
 *       {@code morphosyntaxe}) <b>et</b> des criteres dont le niveau CECRL est
 *       derive POUR CETTE GRILLE — {@code coherence} en v3/v4/v4.x, les quatre
 *       criteres du TCF en v5 (cf. {@link ProductionRubricsProvider#niveauCecrl()},
 *       qui lit {@code commun.niveau} du fichier puis la config). La protection
 *       suit donc ce que le calcul lit reellement, au lieu de figer une liste
 *       qui deviendrait fausse a chaque version. Les renommer ou les supprimer
 *       casserait silencieusement ce calcul.</li>
 * </ul>
 * Tout manquement → log ERROR + {@link IllegalStateException} (le contexte Spring
 * ne demarre pas).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ProductionRubricsValidator {

    /**
     * Codes critere canoniques. Le socle commun aux 6 taches (v2/v3) est complete
     * par les codes PROPRES A CHAQUE TACHE introduits en v4 (une grille par tache
     * plutot que 4 criteres universels). {@code pertinence} est conserve : il reste
     * le critere de tache des rubriques v3, qui doivent continuer a demarrer.
     */
    static final Set<String> CANONICAL_CODES = Set.of(
        // socle v2/v3
        "pertinence", "coherence", "lexique", "morphosyntaxe",
        // criteres de tache v4
        "realisation_consigne", "adequation_destinataire", "developpement_reponses",
        "conduite_echange", "chronologie_recit", "prise_position", "argumentation",
        // grille du TCF, v5 : 4 criteres equiponderes, identiques sur les 6 taches
        "communiquer", "interagir");

    /**
     * Socle de LANGUE, obligatoire quelle que soit la version de grille : ce sont
     * les deux criteres notes en absolu sur l'echelle CECRL, presents de v2 a v5.
     * Les supprimer ou les renommer casserait le garde-fou de couplage
     * ({@code AiEvaluationService#applyCouplage}) en plus du calcul du niveau.
     */
    static final Set<String> SOCLE_LANGUE = Set.of("lexique", "morphosyntaxe");

    /** Les 6 rubriques attendues, quelle que soit la version du fichier. */
    static final Set<String> CLES_ATTENDUES = Set.of(
        "EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3");

    /** Champs textuels/structures obligatoires de chaque rubrique (rendus dans le user prompt). */
    private static final List<String> CHAMPS_OBLIGATOIRES = List.of(
        "bareme_note", "descripteurs", "consignes_correcteur");

    private static final double POIDS_TOLERANCE = 0.001;

    private final ProductionRubricsProvider rubrics;
    private final ProductionTaskManager taskManager;

    @EventListener(ApplicationReadyEvent.class)
    public void validate() {
        List<String> errors = new ArrayList<>();

        // 0. Bloc commun (global rendu dans le system prompt) : sections + few-shot.
        Map<String, Object> commun = rubrics.getCommun();
        if (!(commun.get("sections") instanceof List<?> sections) || sections.isEmpty()) {
            errors.add("commun.sections absent ou vide (le system prompt serait vide).");
        }
        if (!(commun.get("few_shot") instanceof List<?> fewShot) || fewShot.isEmpty()) {
            errors.add("commun.few_shot absent ou vide.");
        }

        // 1. Coherence interne de chaque rubrique (poids = 1, codes canoniques).
        // Les codes OBLIGATOIRES sont le socle de langue + les criteres dont le
        // niveau CECRL est reellement derive pour CETTE grille (declares par le
        // fichier depuis v5, sinon la config) : la protection suit ce que le
        // calcul lit, au lieu de figer une liste qui devient fausse a chaque
        // version.
        Set<String> obligatoires = new java.util.LinkedHashSet<>(SOCLE_LANGUE);
        obligatoires.addAll(rubrics.niveauCecrl().getSourceCriteres());
        Map<String, Map<String, Object>> all = rubrics.all();
        for (Map.Entry<String, Map<String, Object>> e : all.entrySet()) {
            validateRubric(e.getKey(), e.getValue(), obligatoires, errors);
        }

        // 1b. Les 6 rubriques EE_T1..3 / EO_T1..3 doivent exister dans le fichier.
        for (String cle : CLES_ATTENDUES) {
            if (!all.containsKey(cle)) {
                errors.add("rubrique manquante dans le fichier : " + cle + ".");
            }
        }

        // 2. Couverture : chaque tache active a une rubrique.
        for (ProductionTask task : taskManager.findAllActive()) {
            EpreuveType epreuve = task.getEpreuve();
            if (epreuve != EpreuveType.TCF_EO && epreuve != EpreuveType.TCF_EE) {
                continue; // seules les productions EO/EE sont notees par rubrique
            }
            Integer tache = task.getTacheNumero() == null ? null : task.getTacheNumero().intValue();
            if (tache == null || rubrics.find(epreuve, tache).isEmpty()) {
                errors.add("Tache active sans rubrique : id=" + task.getId()
                    + " cle=" + ProductionRubricsProvider.key(epreuve, tache == null ? -1 : tache));
            }
            if (epreuve == EpreuveType.TCF_EE && tache != null) {
                validateEeTask(task, tache, errors);
            }
        }

        if (!errors.isEmpty()) {
            errors.forEach(msg -> log.error("[rubriques] {}", msg));
            throw new IllegalStateException("Rubriques de notation invalides ("
                + errors.size() + " erreur(s)) — cf. logs ERROR [rubriques]. "
                + "Corriger production-rubrics-<version>.json ou desactiver la tache.");
        }
        log.info("Rubriques de notation validees : {} rubriques, couverture des taches actives OK.",
            rubrics.all().size());
    }

    private static void validateEeTask(ProductionTask task, int tache, List<String> errors) {
        int expectedMin = tache == 1 ? 30 : 60;
        int expectedMax = tache == 1 ? 60 : 90;
        if (tache < 1 || tache > 3
                || task.getMotsMin() == null || task.getMotsMin() != expectedMin
                || task.getMotsMax() == null || task.getMotsMax() != expectedMax) {
            errors.add("Tache EE active hors bornes TCF IRN : id=" + task.getId()
                + " tache=" + tache + " bornes=" + task.getMotsMin() + "-" + task.getMotsMax()
                + " attendues=" + expectedMin + "-" + expectedMax + ".");
        }
        if (tache >= 2 && tache <= 3
                && (task.getContexte() == null || task.getContexte().isBlank())) {
            errors.add("Tache EE T" + tache + " sans contexte/destinataire : id=" + task.getId() + ".");
        }
    }

    private static void validateRubric(String cle, Map<String, Object> rubric,
                                       Set<String> obligatoires, List<String> errors) {
        validateChampsObligatoires(cle, rubric, errors);

        if (!(rubric.get("criteres") instanceof List<?> criteres) || criteres.isEmpty()) {
            errors.add(cle + " : aucun critere.");
            return;
        }
        double sommePoids = 0.0;
        Set<String> codes = new HashSet<>();
        for (Object c : criteres) {
            if (!(c instanceof Map<?, ?> m)) {
                errors.add(cle + " : critere malforme.");
                continue;
            }
            Object code = m.get("code");
            if (code == null || !CANONICAL_CODES.contains(code.toString())) {
                errors.add(cle + " : code non canonique '" + code + "' (attendus : " + CANONICAL_CODES + ").");
            } else if (!codes.add(code.toString())) {
                errors.add(cle + " : code '" + code + "' present en double.");
            }
            Object poids = m.get("poids");
            if (!(poids instanceof Number n)) {
                errors.add(cle + " : poids absent/non numerique pour '" + code + "'.");
            } else {
                sommePoids += n.doubleValue();
            }
        }
        if (Math.abs(sommePoids - 1.0) > POIDS_TOLERANCE) {
            errors.add(cle + " : Σ poids = " + sommePoids + " (attendu 1.0 ±" + POIDS_TOLERANCE + ").");
        }
        for (String obligatoire : obligatoires) {
            if (!codes.contains(obligatoire)) {
                errors.add(cle + " : critere obligatoire '" + obligatoire + "' absent — le niveau CECRL"
                    + " serveur derive de " + obligatoires + " pour cette grille, le supprimer ou le"
                    + " renommer casserait son calcul.");
            }
        }
    }

    /** {@code bareme_note} / {@code descripteurs} / {@code consignes_correcteur} : rendus dans le user prompt. */
    private static void validateChampsObligatoires(String cle, Map<String, Object> rubric, List<String> errors) {
        for (String champ : CHAMPS_OBLIGATOIRES) {
            Object valeur = rubric.get(champ);
            boolean vide = valeur == null
                || (valeur instanceof CharSequence cs && cs.toString().isBlank())
                || (valeur instanceof Map<?, ?> m && m.isEmpty())
                || (valeur instanceof List<?> l && l.isEmpty());
            if (vide) {
                errors.add(cle + " : champ '" + champ + "' absent ou vide.");
            }
        }
    }
}
