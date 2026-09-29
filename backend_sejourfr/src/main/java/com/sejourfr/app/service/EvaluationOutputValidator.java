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

    /**
     * CONTRAT v6 — la preuve n'est plus une chaine recopiee mais un NUMERO de
     * segment. Deux violations possibles, et deux seulement :
     * <ul>
     *   <li>{@link #MISSING_SEGMENT_SUFFIX} : champ absent, non numerique ou non
     *       entier. Bloquant, comme l'etait une preuve vide ;</li>
     *   <li>{@link #UNKNOWN_SEGMENT_SUFFIX} : entier hors de la liste servie.
     *       C'est l'equivalent exact d'une citation non rattachable, donc le seul
     *       cas degradable apres reessai.</li>
     * </ul>
     */
    private static final String SEGMENT_PROOF_PREFIX = "preuve_segment[";
    private static final String MISSING_SEGMENT_SUFFIX =
        "] doit etre un numero de segment entier";
    private static final String UNKNOWN_SEGMENT_SUFFIX =
        "] doit designer un segment numerote de la production";

    /**
     * SOCLE des champs exiges a la racine par TOUT contrat strict (v4 et
     * au-dela). Il ne bouge jamais : chacun est lu par un calcul de note ou de
     * niveau, par un controle serveur, ou par un bloc affiche au candidat.
     */
    private static final List<String> CHAMPS_STRICTS_SOCLE = List.of(
        "note_globale", "niveau_cecrl", "justification_niveau", "scores_criteres",
        "points_forts", "points_a_ameliorer",
        "confiance", "confiance_raisons", "accomplissement");

    /**
     * Les deux champs de la RESTITUTION LONGUE, exiges jusqu'au contrat v8 et
     * RETIRES en v9 (cf. {@link EvaluationToolSchema#exemplesEtSuggestions()}).
     *
     * <p>Cette liste ne peut pas etre fondue dans {@link #CHAMPS_STRICTS_SOCLE}
     * : la redeclarer en dur, toutes versions confondues, ferait rejeter
     * <b>100 %</b> des sorties des l'instant ou le tool-schema cesse de les
     * demander. Les champs obligatoires se derivent donc du RANG du contrat,
     * exactement comme {@link #CHAMP_VERSION_AMELIOREE}.
     *
     * <p>Ils restent TOLERES a la racine sous v9 : un correcteur qui les
     * produirait quand meme ne fait pas echouer la soumission, le serveur les
     * retire. Une evaluation perdue coute plus cher qu'un champ ignore.
     */
    private static final List<String> CHAMPS_RESTITUTION_LONGUE =
        List.of("suggestions", "exemples_corriges");

    /** Champs EXIGES a la racine sous ce contrat, dans l'ordre du schema. */
    private static List<String> champsObligatoires(EvaluationToolSchema schema) {
        if (!schema.exemplesEtSuggestions()) return CHAMPS_STRICTS_SOCLE;
        List<String> out = new ArrayList<>(CHAMPS_STRICTS_SOCLE);
        out.addAll(CHAMPS_RESTITUTION_LONGUE);
        return out;
    }

    /**
     * Champ v5 a v7 : la production ECRITE reecrite en entier au palier
     * au-dessus. Obligatoire en EE sous ces contrats, interdit d'usage en EO
     * (une tache orale ne se reecrit pas en dialogue modele) — cf.
     * {@code AiEvaluationService}, qui le retire defensivement des sorties
     * orales.
     *
     * <p>SOUS v8 IL N'EXISTE PLUS : il n'est plus dans le schema, plus exige, et
     * le serveur le retire de toute sortie. Il reste TOLERE a la racine (un
     * correcteur qui le produirait quand meme ne fait pas echouer la
     * soumission) : une evaluation perdue coute plus cher qu'un champ ignore.
     */
    private static final String CHAMP_VERSION_AMELIOREE = "version_amelioree";

    private static final Set<String> OBJECTIFS =
        Set.of("ATTEINT", "PARTIELLEMENT_ATTEINT", "NON_ATTEINT");

    /**
     * NOTIONS DE DICTION, interdites sans condition : les entendre reprocher,
     * c'est noter ce que nous n'avons pas entendu. {@code repetition} et
     * {@code accent} n'y figurent plus (cf. {@link #MOTIFS_ORAUX_CONTEXTUELS}) ;
     * tout le reste est inchange.
     */
    private static final Pattern MOTIFS_ORAUX_INTERDITS = Pattern.compile(
        "\\b(hesitation(?:s)?|faux[ -]?depart(?:s)?|hache(?:e|es|s)?|"
            + "(?:vous |tu )?(?:hesitez|repetez)|(?:vous |tu )?parl(?:ez|es) (?:trop )?"
            + "(?:vite|lentement)|(?:longues? )?pauses? (?:dans|pendant) (?:la |votre )?"
            + "(?:reponse|prise de parole|parole|discours)|"
            + "(?:debit|rythme) (?:de (?:parole|voix|discours|l['’]elocution)|oral|"
            + "(?:trop )?(?:lent|rapide|saccade|irregulier))|"
            + "fluidite|aisance|prononciation|intonation|orthographe|"
            + "ponctuation|temps de parole|duree (?:de l['’]|de la |du |d['’])?"
            + "(?:enregistrement|audio|production|reponse|prise de parole|parole)|"
            + "(?:enregistrement|audio) (?:trop )?court)\\b");

    /**
     * Mots qui designent le SUPPORT ORAL. Leur voisinage suffit a faire d'une
     * « repetition » un reproche de diction ; seuls, ils ne sont pas interdits
     * (« ton discours est clair » est un compliment legitime).
     */
    private static final String MARQUEURS_ORAUX =
        "oral|orale|oralement|discours|parole|elocution|articulation|voix|"
            + "enregistrement|audio|transcription|debit|fluidite|aisance|hesitation(?:s)?";

    /**
     * DEUX FAUX POSITIFS CORRIGES (2026-08-07) — une liste de MOTS ne sait pas
     * distinguer la diction de la syntaxe.
     *
     * <ol>
     *   <li><b>{@code repetition}</b> a detruit une evaluation reelle pour
     *       « cette <i>repetition</i> alourdit la phrase … supprime le pronom
     *       repete » : une remarque de MORPHOSYNTAXE. Pire, les rubriques
     *       ORDONNENT au correcteur de peser « a-t-il du faire repeter ? » dans
     *       {@code communiquer} — le prompt commandait une notion que le
     *       validateur interdisait d'ecrire. La notion reste refusee dans ses
     *       emplois de DICTION : consigne d'evitement portant sur « les
     *       repetitions » en bloc, ou voisinage d'un {@link #MARQUEURS_ORAUX
     *       marqueur oral}.</li>
     *   <li><b>{@code accent}</b> capturait « mettre l'accent sur », tournure
     *       parfaitement legitime. Il n'est refuse que hors de cet emploi
     *       (« votre accent », « un accent marque »).</li>
     * </ol>
     *
     * <p>Les autres jetons ({@code fluidite}, {@code prononciation},
     * {@code debit}, {@code intonation}, {@code pauses}) ne bougent pas : « on ne
     * note jamais sur la prononciation » reste entier.
     *
     * <p>Le groupe {@code noyau}, quand il existe, porte la notion a nommer dans
     * la violation — sans lui le message citerait la fenetre entiere au lieu du
     * mot rejete, et le reessai redeviendrait aveugle.
     */
    private static final List<Pattern> MOTIFS_ORAUX_CONTEXTUELS = List.of(
        // Consigne d'evitement portant sur « les repetitions » en bloc : c'est la
        // diction. « supprime le pronom repete » ne matche pas — l'objet y est un
        // element de langue nomme, pas le defaut oral lui-meme.
        Pattern.compile("\\b(?:evite|evitez|reduis|reduisez|supprime|supprimez|limite|limitez"
            + "|espace|espacez|diminue|diminuez|corrige|corrigez)\\s+(?:les|vos|tes|ces)\\s+"
            + "(?<noyau>repetitions)\\b"),
        // Voisinage d'un marqueur oral, dans la meme phrase, dans les deux sens.
        Pattern.compile("(?<noyau>repetition(?:s)?)\\b[^.!?]{0,80}?\\b(?:" + MARQUEURS_ORAUX + ")\\b"),
        Pattern.compile("\\b(?:" + MARQUEURS_ORAUX + ")\\b[^.!?]{0,80}?\\b(?<noyau>repetition(?:s)?)\\b"),
        // « accent » hors de l'idiome « mettre / porter l'accent SUR quelque
        // chose », reconnu par la presence de « sur » dans la meme proposition.
        // Un accent de DICTION n'est jamais mis « sur » quoi que ce soit.
        Pattern.compile("\\b(?<noyau>accents?)\\b(?![^.!?;:]{0,40}?\\bsur\\b)"));

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
        // Ce que le contrat ACTIF fait appliquer. Une version inconnue n'est pas
        // « pas de validation » : c'est une erreur de mise en service, et elle
        // echoue ici comme au boot (cf. EvaluationToolSchema). Les schemas
        // anterieurs a v4 restent volontairement tolerants : un rollback ne doit
        // rien casser.
        EvaluationToolSchema schema = EvaluationToolSchema.of(promptVersion);
        boolean strict = schema.strict();
        boolean restitution = schema.restitution();
        boolean preuveParNumero = schema.preuveParNumero();
        if (strict) {
            requireText(feedback.get("justification_niveau"), "justification_niveau", errors);
        }

        Set<String> expected = expectedCodes(task, rubrics, errors);
        EpreuveType epreuve = task == null ? null : task.getEpreuve();
        // Sous le contrat v6, la seule chose a verifier sur une preuve est qu'un
        // entier designe un segment servi. On recalcule donc la meme decoupe que
        // celle envoyee au correcteur : elle est deterministe.
        int nbSegments = preuveParNumero && production != null
            ? EvaluationProductionSegments.of(production, epreuve).taille()
            : 0;
        validateScores(feedback.get("scores_criteres"), expected, strict, preuveParNumero,
            nbSegments, production, epreuve, errors);

        if (strict) {
            validateStructure(feedback, schema, task, errors);
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
                                       boolean preuveParNumero, int nbSegments,
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
                validateKeys(score, preuveParNumero
                        ? Set.of("code", "note_sur_20", "commentaire", "preuve_segment")
                        : Set.of("code", "note_sur_20", "commentaire", "preuve"),
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
            if (strict && preuveParNumero) {
                validateSegmentProof(score.get("preuve_segment"), code, nbSegments, errors);
            } else if (strict) {
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
     * PREUVE PAR NUMERO (contrat v6). Le correcteur ne recopie rien : il ne peut
     * donc plus se tromper de graphie, seulement de numero. Deux cas, et deux
     * seulement — un entier attendu, et un entier qui existe.
     */
    private static void validateSegmentProof(Object raw, String code, int nbSegments,
                                             List<String> errors) {
        if (!(raw instanceof Number number) || !estEntier(number)) {
            errors.add(SEGMENT_PROOF_PREFIX + code + MISSING_SEGMENT_SUFFIX);
            return;
        }
        int numero = number.intValue();
        if (numero < 1 || numero > nbSegments) {
            errors.add(SEGMENT_PROOF_PREFIX + code + UNKNOWN_SEGMENT_SUFFIX);
        }
    }

    private static boolean estEntier(Number number) {
        double valeur = number.doubleValue();
        return Double.isFinite(valeur) && valeur == Math.rint(valeur)
            && Math.abs(valeur) <= Integer.MAX_VALUE;
    }

    /**
     * Identifie le seul cas degradable apres retry : une unique preuve non
     * rattachable — citation introuvable (contrats v4/v5) ou numero de segment
     * inexistant (contrat v6). Toute autre violation, y compris une preuve vide
     * ou un {@code preuve_segment} non entier, reste bloquante.
     */
    static Optional<String> singleUnmatchedProofCode(List<String> violations) {
        if (violations == null || violations.size() != 1) return Optional.empty();
        return unmatchedProofCode(violations.get(0));
    }

    private static Optional<String> unmatchedProofCode(String violation) {
        if (violation == null) return Optional.empty();
        Optional<String> citation = codeEntre(violation, UNMATCHED_PROOF_PREFIX, UNMATCHED_PROOF_SUFFIX);
        if (citation.isPresent()) return citation;
        return codeEntre(violation, SEGMENT_PROOF_PREFIX, UNKNOWN_SEGMENT_SUFFIX);
    }

    private static Optional<String> codeEntre(String violation, String prefix, String suffix) {
        if (!violation.startsWith(prefix) || !violation.endsWith(suffix)
                || violation.length() <= prefix.length() + suffix.length()) {
            return Optional.empty();
        }
        String code = violation.substring(prefix.length(), violation.length() - suffix.length());
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
            unmatchedProofCode(violation).ifPresent(out::add);
        }
        return List.copyOf(out);
    }

    /** Vrai si la violation porte sur un {@code preuve_segment} (contrat v6). */
    static boolean estViolationDeSegment(String violation) {
        return violation != null && violation.startsWith(SEGMENT_PROOF_PREFIX);
    }

    private static String unmatchedProofViolation(String code) {
        return UNMATCHED_PROOF_PREFIX + code + UNMATCHED_PROOF_SUFFIX;
    }

    /**
     * Structure d'une sortie sur contrat strict. {@code v5} ajoute — et exige —
     * ce que v4 ne connait pas : le verdict {@code accomplissement.objectif} et
     * son resume, {@code version_amelioree} sur les taches ECRITES, et les
     * plafonds de restitution (2 points forts, 3 exemples corriges). {@code v8}
     * retire la seule {@code version_amelioree} ; {@code v9} retire
     * {@code exemples_corriges} et {@code suggestions}, sans toucher au reste. Un
     * rollback vers v4 ne doit voir aucune de ces regles s'appliquer, et un
     * rollback vers v7 ou v8 doit les revoir : d'ou une lecture du CONTRAT
     * plutot qu'une validation aveugle.
     */
    private static void validateStructure(Map<String, Object> feedback, EvaluationToolSchema schema,
                                          ProductionTask task, List<String> errors) {
        boolean restitution = schema.restitution();
        List<String> obligatoires = champsObligatoires(schema);
        Set<String> autorises = new LinkedHashSet<>(CHAMPS_STRICTS_SOCLE);
        // TOLERES sous tous les contrats stricts, y compris v9 ou ils ne sont
        // plus demandes : le serveur les retire, il ne detruit pas le rapport.
        autorises.addAll(CHAMPS_RESTITUTION_LONGUE);
        // Meme tolerance pour version_amelioree, retiree du contrat en v8.
        if (restitution) autorises.add(CHAMP_VERSION_AMELIOREE);
        validateKeys(feedback, autorises, "racine", errors);
        for (String field : obligatoires) {
            if (!feedback.containsKey(field) || feedback.get(field) == null) {
                errors.add("champ obligatoire absent : " + field);
            }
        }
        validateStringList(feedback.get("points_forts"), "points_forts", errors);
        validateStringList(feedback.get("confiance_raisons"), "confiance_raisons", errors);

        Object confiance = feedback.get("confiance");
        if (confiance == null || !Set.of("HAUTE", "MOYENNE", "FAIBLE").contains(confiance.toString())) {
            errors.add("confiance invalide");
        }
        validateAccomplissement(feedback.get("accomplissement"), restitution, errors);
        validatePointsAAmeliorer(feedback.get("points_a_ameliorer"), errors);
        // Les deux champs de restitution longue ne sont controles QUE lorsque le
        // contrat les demande : sous v9 ils sont toleres puis retires, donc les
        // valider reviendrait a refuser une sortie pour un champ qu'on jette.
        if (schema.exemplesEtSuggestions()) {
            validateStringList(feedback.get("suggestions"), "suggestions", errors);
            validateExemples(feedback.get("exemples_corriges"), restitution, errors);
        }
        if (restitution) {
            validatePointsForts(feedback.get("points_forts"), errors);
        }
        if (schema.versionAmelioree()) {
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
     * SOUS LES CONTRATS v5 A v7 (elle y etait le dernier bloc de l'ecran du
     * candidat), jamais exigee ailleurs — ni en EO, ni sous v8, ou le champ a
     * quitte le schema.
     * Sur une tache ORALE, sa presence n'est pas une violation — elle est
     * simplement retiree par le serveur : reecrire un dialogue n'a aucun sens
     * pedagogique, mais cela ne vaut pas de perdre une evaluation entiere.
     */
    private static void validateVersionAmelioree(Object raw, ProductionTask task,
                                                 List<String> errors) {
        if (task == null || task.getEpreuve() != EpreuveType.TCF_EE) return;
        requireText(raw, CHAMP_VERSION_AMELIOREE, errors);
    }

    private static void validateAccomplissement(Object raw, boolean restitution, List<String> errors) {
        if (!(raw instanceof Map<?, ?> map)) {
            errors.add("accomplissement doit etre un objet");
            return;
        }
        Set<String> autorises = new LinkedHashSet<>(List.of("points_traites", "points_oublies"));
        if (restitution) {
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

    private static void validateExemples(Object raw, boolean restitution, List<String> errors) {
        if (!(raw instanceof List<?> exemples)) {
            errors.add("exemples_corriges doit etre une liste");
            return;
        }
        if (restitution && exemples.size() > AiEvaluationService.MAX_EXEMPLES_CORRIGES) {
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

    /**
     * GARDE-FOU ORAL — <b>la frontiere entre ce qui est FATAL et ce qui est
     * simplement PURGE</b>.
     *
     * <p>Sont scannes ici, et une violation y fait echouer l'evaluation apres
     * l'unique reessai, les champs qui portent le JUGEMENT : {@code
     * justification_niveau} (fondement de la note), {@code
     * scores_criteres[].commentaire} (caracterisation de chaque critere), {@code
     * points_forts}, {@code points_a_ameliorer}, {@code suggestions} et {@code
     * accomplissement}. Y laisser passer une remarque fondee sur la
     * prononciation ou le debit, c'est rendre au candidat une note batie sur ce
     * que nous n'avons pas entendu.
     *
     * <p><b>{@code exemples_corriges} en est volontairement SORTI</b> (2026-08-06).
     * Ce champ n'entre dans AUCUN calcul : la note est recalculee serveur depuis
     * {@code scores_criteres}, il est plafonne a trois entrees et peut etre vide.
     * Le rendre fatal detruisait des evaluations entieres — une tache d'examen
     * blanc EO a ete perdue pour deux {@code explication} rejetees, alors que le
     * serveur y jette deja des entrees (corrections orthographiques, mot isole).
     * Le meme traitement s'y applique donc : {@link EvaluationOralArtifactFilter}
     * SUPPRIME l'entree fautive, il ne detruit pas le rapport.
     */
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
        // `exemples_corriges` : PURGE, jamais fatal — cf. javadoc ci-dessus.
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

    /**
     * Vrai si le texte mentionne une NOTION non evaluable a l'oral. Meme
     * detection que {@link #scanText}, exposee sans construire de violation :
     * elle sert a la PURGE des champs non fatals ({@code exemples_corriges}),
     * pour que les deux traitements rejettent exactement les memes notions.
     */
    static boolean mentionneMotifOralInterdit(Object raw) {
        if (!(raw instanceof String text) || text.isBlank()) return false;
        return notionInterdite(normaliserPourScan(text)) != null;
    }

    /**
     * Notion non evaluable a l'oral trouvee le plus a GAUCHE dans {@code texte}
     * deja normalise, {@code null} sinon. Les motifs inconditionnels et les
     * motifs contextuels sont lus par la meme methode, pour que la PURGE et la
     * VIOLATION rejettent exactement les memes choses.
     */
    private static String notionInterdite(String texte) {
        int position = Integer.MAX_VALUE;
        String notion = null;
        var inconditionnel = MOTIFS_ORAUX_INTERDITS.matcher(texte);
        if (inconditionnel.find()) {
            position = inconditionnel.start();
            notion = inconditionnel.group();
        }
        for (Pattern motif : MOTIFS_ORAUX_CONTEXTUELS) {
            var matcher = motif.matcher(texte);
            if (!matcher.find()) continue;
            int debut = matcher.start("noyau");
            if (debut < position) {
                position = debut;
                notion = matcher.group("noyau");
            }
        }
        return notion;
    }

    private static String normaliserPourScan(String text) {
        return Normalizer.normalize(text, Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "")
            .toLowerCase(Locale.FRENCH);
    }

    private static void scanText(Object raw, String path, List<String> errors) {
        if (!(raw instanceof String text) || text.isBlank()) return;
        String notion = notionInterdite(normaliserPourScan(text));
        if (notion == null) return;
        // La NOTION rejetee et le passage exact sont dans le message : sans eux,
        // le reessai ne dit au correcteur ni quel champ ni quel mot revoir, et il
        // resoumet la meme phrase (meme pathologie que les preuves refusees, cf.
        // EvaluationRepairPrompt). C'est aussi ce qui rend le log exploitable.
        errors.add(path + ORAL_VIOLATION_MARKER
            + " — notion interdite « " + notion
            + " », dans : « " + extrait(text) + " »");
    }

    /** Marqueur stable des violations du garde-fou oral (lu par le reessai). */
    static final String ORAL_VIOLATION_MARKER = " fonde le feedback oral sur un element non evaluable";

    private static final int EXTRAIT_MAX = 200;

    private static String extrait(String text) {
        String clean = text.strip().replaceAll("\\s+", " ");
        return clean.length() <= EXTRAIT_MAX ? clean : clean.substring(0, EXTRAIT_MAX) + "…";
    }

    /** Violations du garde-fou oral, dans l'ordre, pour construire le reessai. */
    static List<String> oralViolations(List<String> violations) {
        return violations.stream().filter(v -> v.contains(ORAL_VIOLATION_MARKER)).toList();
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
