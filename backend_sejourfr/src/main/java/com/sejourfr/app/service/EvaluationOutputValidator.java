package com.sejourfr.app.service;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

/** Validation metier d'une sortie LLM brute, avant toute normalisation. */
final class EvaluationOutputValidator {

    private static final Set<String> NIVEAUX_TCF_IRN = Set.of(
        "A1_NON_ATTEINT", "A1", "A2", "B1", "B2");

    private static final String UNMATCHED_PROOF_PREFIX = "preuve[";
    private static final String UNMATCHED_PROOF_SUFFIX =
        "] doit citer un passage reel de la production";

    private static final List<String> CHAMPS_V4 = List.of(
        "note_globale", "niveau_cecrl", "justification_niveau", "scores_criteres",
        "points_forts", "points_a_ameliorer", "suggestions", "exemples_corriges",
        "confiance", "confiance_raisons", "accomplissement");

    /**
     * Champ v5 : la production ECRITE reecrite en entier au palier au-dessus.
     * Obligatoire en EE, interdit d'usage en EO (une tache orale ne se reecrit
     * pas en dialogue modele) — cf. {@code AiEvaluationService}, qui le retire
     * defensivement des sorties orales.
     */
    private static final String CHAMP_VERSION_AMELIOREE = "version_amelioree";

    /** Versions de tool-schema dont la STRUCTURE est verifiee champ par champ. */
    private static final Set<String> SCHEMAS_STRICTS = Set.of("v4", "v5");

    private static final Set<String> OBJECTIFS =
        Set.of("ATTEINT", "PARTIELLEMENT_ATTEINT", "NON_ATTEINT");

    private static final Pattern MOTIFS_ORAUX_INTERDITS = Pattern.compile(
        "\\b(hesitation(?:s)?|repetition(?:s)?|faux[ -]?depart(?:s)?|hache(?:e|es|s)?|"
            + "(?:vous |tu )?(?:hesitez|repetez)|(?:vous |tu )?parl(?:ez|es) (?:trop )?"
            + "(?:vite|lentement)|(?:longues? )?pauses? (?:dans|pendant) (?:la |votre )?"
            + "(?:reponse|prise de parole|parole|discours)|"
            + "(?:debit|rythme) (?:de (?:parole|voix|discours|l['’]elocution)|oral|"
            + "(?:trop )?(?:lent|rapide|saccade|irregulier))|"
            + "fluidite|aisance|prononciation|accent|intonation|orthographe|"
            + "ponctuation|temps de parole|duree (?:de l['’]|de la |du |d['’])?"
            + "(?:enregistrement|audio|production|reponse|prise de parole|parole)|"
            + "(?:enregistrement|audio) (?:trop )?court)\\b");

    private EvaluationOutputValidator() {
    }

    static List<String> violations(Map<String, Object> feedback, ProductionTask task,
                                   ProductionRubricsProvider rubrics, String promptVersion) {
        return violations(feedback, task, rubrics, promptVersion, null);
    }

    static List<String> violations(Map<String, Object> feedback, ProductionTask task,
                                   ProductionRubricsProvider rubrics, String promptVersion,
                                   String production) {
        List<String> errors = new ArrayList<>();
        if (feedback == null) {
            return List.of("feedback absent");
        }

        validateNumber(feedback.get("note_globale"), "note_globale", errors);
        Object niveau = feedback.get("niveau_cecrl");
        if (niveau == null || !NIVEAUX_TCF_IRN.contains(niveau.toString())) {
            errors.add("niveau_cecrl doit appartenir au profil TCF IRN et ne jamais depasser B2");
        }
        // La structure n'est verifiee champ par champ que sur les contrats
        // stricts (v4, v5). Les schemas anterieurs restent volontairement
        // tolerants : un rollback ne doit rien casser.
        boolean strict = SCHEMAS_STRICTS.contains(promptVersion);
        boolean v5 = "v5".equals(promptVersion);
        if (strict) {
            requireText(feedback.get("justification_niveau"), "justification_niveau", errors);
        }

        Set<String> expected = expectedCodes(task, rubrics, errors);
        validateScores(feedback.get("scores_criteres"), expected, strict, production,
            task == null ? null : task.getEpreuve(), errors);

        if (strict) {
            validateStructure(feedback, v5, task, errors);
        }
        if (task != null && task.getEpreuve() == EpreuveType.TCF_EO) {
            validateOralFeedback(feedback, errors);
        }
        return List.copyOf(errors);
    }

    private static Set<String> expectedCodes(ProductionTask task, ProductionRubricsProvider rubrics,
                                             List<String> errors) {
        if (task == null || rubrics == null) {
            errors.add("rubrique de la tache absente");
            return Set.of();
        }
        Object raw = rubrics.find(task.getEpreuve(), task.getTacheNumero())
            .map(r -> r.get("criteres")).orElse(null);
        if (!(raw instanceof List<?> criteres)) {
            errors.add("criteres de rubrique absents");
            return Set.of();
        }
        Set<String> out = new LinkedHashSet<>();
        for (Object item : criteres) {
            if (item instanceof Map<?, ?> m && m.get("code") != null) {
                out.add(m.get("code").toString());
            }
        }
        if (out.isEmpty()) errors.add("aucun code de critere attendu");
        return out;
    }

    private static void validateScores(Object raw, Set<String> expected, boolean strict,
                                       String production, EpreuveType epreuve,
                                       List<String> errors) {
        if (!(raw instanceof List<?> scores)) {
            errors.add("scores_criteres doit etre une liste");
            return;
        }
        if (scores.size() != expected.size()) {
            errors.add("scores_criteres doit contenir exactement " + expected.size() + " criteres");
        }
        Set<String> seen = new HashSet<>();
        for (int i = 0; i < scores.size(); i++) {
            Object item = scores.get(i);
            if (!(item instanceof Map<?, ?> score)) {
                errors.add("scores_criteres[" + i + "] doit etre un objet");
                continue;
            }
            if (strict) {
                validateKeys(score, Set.of("code", "note_sur_20", "commentaire", "preuve"),
                    "scores_criteres[" + i + "]", errors);
            }
            Object codeRaw = score.get("code");
            String code = codeRaw == null ? null : codeRaw.toString();
            if (code == null || !expected.contains(code)) {
                errors.add("code de critere inattendu : " + code);
            } else if (!seen.add(code)) {
                errors.add("code de critere duplique : " + code);
            }
            validateNumber(score.get("note_sur_20"), "note_sur_20[" + code + "]", errors);
            requireText(score.get("commentaire"), "commentaire[" + code + "]", errors);
            if (strict) {
                Object preuve = score.get("preuve");
                requireText(preuve, "preuve[" + code + "]", errors);
                if (preuve instanceof String citation && !citation.isBlank() && production != null) {
                    if (EvaluationProofMatcher.canonicalPassage(production, citation, epreuve).isEmpty()) {
                        errors.add(unmatchedProofViolation(code));
                    }
                }
            }
        }
        if (!seen.equals(expected)) {
            Set<String> missing = new LinkedHashSet<>(expected);
            missing.removeAll(seen);
            if (!missing.isEmpty()) errors.add("criteres manquants : " + missing);
        }
    }

    /**
     * Identifie le seul cas degradable apres retry : une unique citation non
     * rattachable. Toute autre violation, y compris une preuve vide, reste
     * bloquante.
     */
    static Optional<String> singleUnmatchedProofCode(List<String> violations) {
        if (violations == null || violations.size() != 1) return Optional.empty();
        String violation = violations.get(0);
        if (violation == null || !violation.startsWith(UNMATCHED_PROOF_PREFIX)
                || !violation.endsWith(UNMATCHED_PROOF_SUFFIX)) {
            return Optional.empty();
        }
        String code = violation.substring(
            UNMATCHED_PROOF_PREFIX.length(),
            violation.length() - UNMATCHED_PROOF_SUFFIX.length());
        return code.isBlank() ? Optional.empty() : Optional.of(code);
    }

    /**
     * Codes de critere dont la citation n'a pas pu etre rattachee, dans l'ordre
     * des violations. Sert a construire un message de reessai qui rappelle au
     * correcteur LA citation refusee, critere par critere : la liste brute des
     * violations ne lui dit ni laquelle, ni pourquoi.
     */
    static List<String> unmatchedProofCodes(List<String> violations) {
        if (violations == null) return List.of();
        List<String> out = new ArrayList<>();
        for (String violation : violations) {
            if (violation == null || !violation.startsWith(UNMATCHED_PROOF_PREFIX)
                    || !violation.endsWith(UNMATCHED_PROOF_SUFFIX)) {
                continue;
            }
            String code = violation.substring(
                UNMATCHED_PROOF_PREFIX.length(),
                violation.length() - UNMATCHED_PROOF_SUFFIX.length());
            if (!code.isBlank()) out.add(code);
        }
        return List.copyOf(out);
    }

    private static String unmatchedProofViolation(String code) {
        return UNMATCHED_PROOF_PREFIX + code + UNMATCHED_PROOF_SUFFIX;
    }

    /**
     * Structure d'une sortie sur contrat strict. {@code v5} ajoute — et exige —
     * ce que v4 ne connait pas : le verdict {@code accomplissement.objectif} et
     * son resume, {@code version_amelioree} sur les taches ECRITES, et les
     * plafonds de restitution (2 points forts, 3 exemples corriges). Un
     * rollback vers v4 ne doit voir aucune de ces regles s'appliquer, d'ou le
     * drapeau plutot qu'une validation aveugle.
     */
    private static void validateStructure(Map<String, Object> feedback, boolean v5,
                                          ProductionTask task, List<String> errors) {
        Set<String> autorises = new LinkedHashSet<>(CHAMPS_V4);
        if (v5) autorises.add(CHAMP_VERSION_AMELIOREE);
        validateKeys(feedback, autorises, "racine", errors);
        for (String field : CHAMPS_V4) {
            if (!feedback.containsKey(field) || feedback.get(field) == null) {
                errors.add("champ obligatoire absent : " + field);
            }
        }
        validateStringList(feedback.get("points_forts"), "points_forts", errors);
        validateStringList(feedback.get("suggestions"), "suggestions", errors);
        validateStringList(feedback.get("confiance_raisons"), "confiance_raisons", errors);

        Object confiance = feedback.get("confiance");
        if (confiance == null || !Set.of("HAUTE", "MOYENNE", "FAIBLE").contains(confiance.toString())) {
            errors.add("confiance invalide");
        }
        validateAccomplissement(feedback.get("accomplissement"), v5, errors);
        validatePointsAAmeliorer(feedback.get("points_a_ameliorer"), errors);
        validateExemples(feedback.get("exemples_corriges"), v5, errors);
        if (v5) {
            validatePointsForts(feedback.get("points_forts"), errors);
            validateVersionAmelioree(feedback.get(CHAMP_VERSION_AMELIOREE), task, errors);
        }
    }

    /**
     * « Deux points forts, pas un inventaire » : meme regle produit que les deux
     * priorites, meme garantie. Une liste de cinq reussites dilue les deux qui
     * comptent.
     */
    private static void validatePointsForts(Object raw, List<String> errors) {
        if (raw instanceof List<?> points && points.size() > AiEvaluationService.MAX_POINTS_FORTS) {
            errors.add("points_forts contient plus de "
                + AiEvaluationService.MAX_POINTS_FORTS + " entrees");
        }
    }

    /**
     * {@code version_amelioree} : obligatoire et non vide sur une tache ECRITE
     * (c'est le dernier bloc de l'ecran du candidat), jamais exigee ailleurs.
     * Sur une tache ORALE, sa presence n'est pas une violation — elle est
     * simplement retiree par le serveur : reecrire un dialogue n'a aucun sens
     * pedagogique, mais cela ne vaut pas de perdre une evaluation entiere.
     */
    private static void validateVersionAmelioree(Object raw, ProductionTask task,
                                                 List<String> errors) {
        if (task == null || task.getEpreuve() != EpreuveType.TCF_EE) return;
        requireText(raw, CHAMP_VERSION_AMELIOREE, errors);
    }

    private static void validateAccomplissement(Object raw, boolean v5, List<String> errors) {
        if (!(raw instanceof Map<?, ?> map)) {
            errors.add("accomplissement doit etre un objet");
            return;
        }
        Set<String> autorises = new LinkedHashSet<>(List.of("points_traites", "points_oublies"));
        if (v5) {
            autorises.add("objectif");
            autorises.add("objectif_resume");
            Object objectif = map.get("objectif");
            if (objectif == null || !OBJECTIFS.contains(objectif.toString())) {
                errors.add("accomplissement.objectif doit valoir " + String.join(" | ",
                    "ATTEINT", "PARTIELLEMENT_ATTEINT", "NON_ATTEINT"));
            }
            requireText(map.get("objectif_resume"), "accomplissement.objectif_resume", errors);
        }
        validateKeys(map, autorises, "accomplissement", errors);
        for (String key : List.of("points_traites", "points_oublies")) {
            Object value = map.get(key);
            if (!(value instanceof List<?> points)) {
                errors.add("accomplissement." + key + " doit etre une liste");
                continue;
            }
            for (Object point : points) {
                if (!(point instanceof Map<?, ?> p)
                    || !(p.get("libelle") instanceof String libelle) || libelle.isBlank()
                    || !(p.get("obligatoire") instanceof Boolean)) {
                    errors.add("chaque entree de accomplissement." + key
                        + " doit porter libelle et obligatoire");
                } else {
                    validateKeys(p, Set.of("libelle", "obligatoire"),
                        "accomplissement." + key, errors);
                }
            }
        }
    }

    private static void validatePointsAAmeliorer(Object raw, List<String> errors) {
        if (!(raw instanceof List<?> points)) {
            errors.add("points_a_ameliorer doit etre une liste");
            return;
        }
        if (points.size() > AiEvaluationService.MAX_POINTS_A_AMELIORER) {
            errors.add("points_a_ameliorer contient plus de deux entrees");
        }
        for (Object point : points) {
            if (!(point instanceof Map<?, ?> p)) {
                errors.add("chaque point_a_ameliorer doit etre un objet");
                continue;
            }
            validateKeys(p, Set.of("constat", "comment", "exemple"),
                "points_a_ameliorer", errors);
            requireText(p.get("constat"), "points_a_ameliorer.constat", errors);
            requireText(p.get("comment"), "points_a_ameliorer.comment", errors);
            Object exemple = p.get("exemple");
            if (exemple != null && (!(exemple instanceof Map<?, ?> e)
                || !(e.get("avant") instanceof String) || !(e.get("apres") instanceof String))) {
                errors.add("points_a_ameliorer.exemple doit porter avant et apres");
            } else if (exemple instanceof Map<?, ?> e) {
                validateKeys(e, Set.of("avant", "apres"), "points_a_ameliorer.exemple", errors);
            }
        }
    }

    private static void validateExemples(Object raw, boolean v5, List<String> errors) {
        if (!(raw instanceof List<?> exemples)) {
            errors.add("exemples_corriges doit etre une liste");
            return;
        }
        if (v5 && exemples.size() > AiEvaluationService.MAX_EXEMPLES_CORRIGES) {
            errors.add("exemples_corriges contient plus de "
                + AiEvaluationService.MAX_EXEMPLES_CORRIGES + " entrees");
        }
        for (Object exemple : exemples) {
            if (!(exemple instanceof Map<?, ?> e)) {
                errors.add("chaque exemple_corrige doit etre un objet");
                continue;
            }
            validateKeys(e, Set.of("original", "corrige", "explication", "gain"),
                "exemples_corriges", errors);
            for (String field : List.of("original", "corrige", "explication", "gain")) {
                requireText(e.get(field), "exemples_corriges." + field, errors);
            }
        }
    }

    private static void validateOralFeedback(Map<String, Object> feedback, List<String> errors) {
        scanText(feedback.get("justification_niveau"), "justification_niveau", errors);
        scanTextList(feedback.get("points_forts"), "points_forts", errors);
        scanTextList(feedback.get("suggestions"), "suggestions", errors);
        scanTextList(feedback.get("avertissements"), "avertissements", errors);

        if (feedback.get("scores_criteres") instanceof List<?> scores) {
            for (Object item : scores) {
                if (item instanceof Map<?, ?> score) {
                    scanText(score.get("commentaire"), "scores_criteres.commentaire", errors);
                    // `preuve` est une citation litterale du candidat, pas un
                    // commentaire evaluatif : la scanner rejetterait a tort une
                    // production qui parle elle-meme d'un debit bancaire.
                }
            }
        }
        if (feedback.get("points_a_ameliorer") instanceof List<?> points) {
            for (Object item : points) {
                if (item instanceof Map<?, ?> p) {
                    scanText(p.get("constat"), "points_a_ameliorer.constat", errors);
                    scanText(p.get("comment"), "points_a_ameliorer.comment", errors);
                } else {
                    scanText(item, "points_a_ameliorer", errors);
                }
            }
        }
        if (feedback.get("exemples_corriges") instanceof List<?> exemples) {
            for (Object item : exemples) {
                if (item instanceof Map<?, ?> e) {
                    scanText(e.get("explication"), "exemples_corriges.explication", errors);
                    scanText(e.get("gain"), "exemples_corriges.gain", errors);
                }
            }
        }
        if (feedback.get("accomplissement") instanceof Map<?, ?> accomplissement) {
            scanAccomplissement(accomplissement.get("points_traites"), errors);
            scanAccomplissement(accomplissement.get("points_oublies"), errors);
        }
        // confiance_raisons est volontairement exclu : les limites de la
        // transcription peuvent y expliquer une certitude moindre, sans note.
    }

    private static void scanAccomplissement(Object raw, List<String> errors) {
        if (!(raw instanceof List<?> points)) return;
        for (Object item : points) {
            if (item instanceof Map<?, ?> p) {
                scanText(p.get("libelle"), "accomplissement.libelle", errors);
            }
        }
    }

    private static void scanTextList(Object raw, String path, List<String> errors) {
        if (!(raw instanceof List<?> list)) return;
        for (Object value : list) scanText(value, path, errors);
    }

    private static void scanText(Object raw, String path, List<String> errors) {
        if (!(raw instanceof String text) || text.isBlank()) return;
        String normalized = Normalizer.normalize(text, Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "")
            .toLowerCase(Locale.FRENCH);
        if (MOTIFS_ORAUX_INTERDITS.matcher(normalized).find()) {
            errors.add(path + " fonde le feedback oral sur un element non evaluable");
        }
    }

    private static void validateStringList(Object raw, String path, List<String> errors) {
        if (!(raw instanceof List<?> list)) {
            errors.add(path + " doit etre une liste");
            return;
        }
        for (Object item : list) {
            if (!(item instanceof String)) errors.add(path + " doit contenir des chaines");
        }
    }

    private static void validateKeys(Map<?, ?> map, Set<String> allowed, String path,
                                     List<String> errors) {
        for (Object key : map.keySet()) {
            if (key == null || !allowed.contains(key.toString())) {
                errors.add(path + " contient un champ inattendu : " + key);
            }
        }
    }

    private static void requireText(Object raw, String path, List<String> errors) {
        if (!(raw instanceof String text) || text.isBlank()) {
            errors.add(path + " doit etre une chaine non vide");
        }
    }

    private static void validateNumber(Object raw, String path, List<String> errors) {
        if (!(raw instanceof Number number)) {
            errors.add(path + " doit etre numerique");
            return;
        }
        double value = number.doubleValue();
        if (!Double.isFinite(value) || value < 0 || value > 20) {
            errors.add(path + " doit etre fini et compris entre 0 et 20");
        }
    }
}
