package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.dto.CorrespondanceTcfDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.BandeNoteTcf;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Source de vérité de la math CECRL des épreuves productives (EE / EO) —
 * pendant de {@link TcfLevelEstimatorService} pour les QCM.
 *
 * <p>Deux niveaux de calcul :
 * <ul>
 *   <li><b>Par soumission</b> ({@link #computeNiveau}) : compétence = moyenne
 *       des critères porteurs (lexique + morphosyntaxe + cohérence) → seuils
 *       config. Calculé et persisté par {@code AiEvaluationService} à chaque
 *       évaluation, puis exposé par tâche comme « performance observée »,
 *       <b>toujours avec sa confiance</b> (cf. {@code EvaluationResultDto}).
 *       Ce n'est PAS le niveau qui fait foi.</li>
 *   <li><b>Par épreuve en examen</b> ({@link #bilanEpreuve}) : moyenne
 *       <b>pondérée</b> des compétences des 3 tâches (poids croissants
 *       T1 &lt; T2 &lt; T3, cf. {@code poids-taches}) passée aux mêmes seuils.
 *       Remplace l'ancien plancher {@code min()} : l'IA note mal une tâche
 *       courte isolée (EE T1 = 30-60 mots), une seule éval basse ne doit pas
 *       plafonner toute l'épreuve.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionBilanService {

    /** Nombre de tâches d'une épreuve productive (3 comme le vrai TCF). */
    public static final int EXPECTED_TASKS_PER_EPREUVE = 3;

    private final AiEvaluationManager aiEvaluationManager;
    private final TcfLevelEstimatorService levelEstimator;
    private final ProductionEvaluationProperties props;

    /**
     * Dernière évaluation EVALUATED de chaque tâche d'un attempt, indexée par
     * {@code tacheNumero} (déduplique les soumissions multiples d'une même
     * tâche : seule la plus récente compte). Les callers doivent être
     * transactionnels (lazy-load submission → production_task).
     */
    public Map<Integer, AiEvaluation> latestEvalsByTache(List<ProductionSubmission> submissions) {
        Map<Integer, ProductionSubmission> latestSub = new HashMap<>();
        for (ProductionSubmission s : submissions) {
            if (s.getStatut() != SubmissionStatut.EVALUATED) continue;
            Short numero = s.getProductionTask() != null ? s.getProductionTask().getTacheNumero() : null;
            if (numero == null) continue;
            Integer tache = numero.intValue();
            ProductionSubmission prev = latestSub.get(tache);
            if (prev == null || (s.getSubmittedAt() != null && prev.getSubmittedAt() != null
                    && s.getSubmittedAt().isAfter(prev.getSubmittedAt()))) {
                latestSub.put(tache, s);
            }
        }
        Map<Integer, AiEvaluation> out = new LinkedHashMap<>();
        for (Map.Entry<Integer, ProductionSubmission> e : latestSub.entrySet()) {
            aiEvaluationManager.findLatestBySubmissionId(e.getValue().getId())
                    .filter(eval -> eval.getNiveauCecrl() != null || eval.getNoteSur20() != null)
                    .ifPresent(eval -> out.put(e.getKey(), eval));
        }
        return out;
    }

    /**
     * Niveau CECRL global d'une épreuve productive en examen blanc :
     * {@code competence_epreuve = Σ(competence_tache × poids) / Σ(poids)} →
     * seuils, plafonné B2. Une tâche hors-sujet (note 0) entre avec une
     * compétence 0 (pénalise sans annuler). Si aucune compétence n'est
     * exploitable, fallback sur le plancher des niveaux persistés.
     *
     * @param evalsByTache dernière évaluation par {@code tacheNumero}
     */
    public NiveauCecrl bilanEpreuve(Map<Integer, AiEvaluation> evalsByTache) {
        return compute(evalsByTache, false);
    }

    /**
     * Variante pour une épreuve d'examen <b>terminée</b> (fin de session,
     * chrono écoulé, abandon) : les tâches jamais rendues parmi
     * 1..{@value #EXPECTED_TASKS_PER_EPREUVE} comptent compétence 0 dans la
     * moyenne pondérée — le « reste noté 0 » d'un examen écourté. Aucune tâche
     * rendue → A1_NON_ATTEINT.
     */
    public NiveauCecrl bilanEpreuveTerminee(Map<Integer, AiEvaluation> evalsByTache) {
        return compute(evalsByTache, true);
    }

    private NiveauCecrl compute(Map<Integer, AiEvaluation> evalsByTache, boolean manquantesAZero) {
        java.util.Set<Integer> taches = new java.util.TreeSet<>(evalsByTache.keySet());
        if (manquantesAZero) {
            for (int t = 1; t <= EXPECTED_TASKS_PER_EPREUVE; t++) taches.add(t);
        }
        BigDecimal acc = BigDecimal.ZERO;
        BigDecimal sumPoids = BigDecimal.ZERO;
        NiveauCecrl floorFallback = null;
        for (Integer tache : taches) {
            AiEvaluation eval = evalsByTache.get(tache);
            BigDecimal comp = eval == null ? BigDecimal.ZERO : competenceOf(eval);
            if (comp == null) {
                // Éval inexploitable (scores absents et note nulle) : elle ne
                // pèse pas dans la moyenne, mais son niveau persisté reste un
                // garde-fou si TOUTES les évals sont dans ce cas.
                floorFallback = levelEstimator.min(floorFallback, eval.getNiveauCecrl());
                continue;
            }
            BigDecimal poids = poidsTache(tache);
            acc = acc.add(comp.multiply(poids));
            sumPoids = sumPoids.add(poids);
        }
        NiveauCecrl bilan;
        if (sumPoids.signum() == 0) {
            bilan = levelEstimator.capB2(floorFallback);
        } else {
            BigDecimal competence = acc.divide(sumPoids, 4, RoundingMode.HALF_UP);
            bilan = niveauFromCompetence(competence, props.getNiveauCecrl());
        }
        return appliquerCoherence(bilan, evalsByTache, manquantesAZero);
    }

    /**
     * Garde-fou de cohérence du bilan : la moyenne pondérée peut donner un B2 à
     * quelqu'un qui s'effondre sur la tâche 3 (argumentation / prise de
     * position), portée par deux bonnes premières tâches. Quand la T3 est sous
     * {@code tache3-niveau-min}, le bilan est plafonné à
     * {@code plafond-si-tache3-faible}.
     *
     * <p>Ne fait qu'ABAISSER, jamais relever. Piloté par
     * {@code sejourfr.production-evaluation.coherence-bilan.enabled}, <b>false
     * par défaut</b> : éteint, cette méthode rend le bilan inchangé, donc
     * exactement la math historique.
     *
     * <p>Épreuve <b>en cours</b> (T3 pas encore rendue) : aucun plafond, on ne
     * conclut pas d'une tâche absente. Épreuve <b>terminée</b> : une T3 jamais
     * rendue vaut 0, donc sous le plancher, donc plafond.
     */
    private NiveauCecrl appliquerCoherence(NiveauCecrl bilan, Map<Integer, AiEvaluation> evalsByTache,
                                           boolean manquantesAZero) {
        ProductionEvaluationProperties.CoherenceBilan cfg = props.getCoherenceBilan();
        if (!cfg.isEnabled() || bilan == null) return bilan;
        NiveauCecrl plafond = cfg.getPlafondSiTache3Faible();
        NiveauCecrl plancherT3 = cfg.getTache3NiveauMin();
        if (plafond == null || plancherT3 == null || bilan.ordinal() <= plafond.ordinal()) return bilan;

        NiveauCecrl niveauT3;
        AiEvaluation t3 = evalsByTache.get(EXPECTED_TASKS_PER_EPREUVE);
        if (t3 == null) {
            if (!manquantesAZero) return bilan;
            niveauT3 = NiveauCecrl.A1_NON_ATTEINT;
        } else {
            BigDecimal comp = competenceOf(t3);
            niveauT3 = comp == null
                ? t3.getNiveauCecrl()
                : niveauFromCompetence(comp, props.getNiveauCecrl());
            // T3 inexploitable : on ne plafonne pas a l'aveugle.
            if (niveauT3 == null) return bilan;
        }
        if (niveauT3.ordinal() >= plancherT3.ordinal()) return bilan;

        log.info("Coherence bilan : tache 3 a {} (< {}) — bilan {} plafonne a {}.",
            niveauT3, plancherT3, bilan, plafond);
        return plafond;
    }

    /**
     * Fourchette de note officielle du TCF IRN correspondant à un niveau
     * d'épreuve. Simple lecture de {@link BandeNoteTcf} — aucune conversion de
     * note : nos notes sont sur une échelle pédagogique plus fine, seul le
     * <b>niveau</b> est comparable à celui du TCF.
     *
     * <p>Null quand le niveau est inconnu (aucune tâche évaluée) ou hors
     * échelle TCF (C1/C2) : les fronts n'affichent alors rien de plus.
     */
    public CorrespondanceTcfDto correspondanceTcf(NiveauCecrl niveau) {
        BandeNoteTcf bande = BandeNoteTcf.of(niveau);
        if (bande == null) return null;
        return new CorrespondanceTcfDto(bande.getNiveau(), bande.getScoreMin(), bande.getScoreMax());
    }

    /** Moyenne simple /20 (1 décimale) des notes des évaluations, null si aucune. */
    public BigDecimal moyenneNotes(Map<Integer, AiEvaluation> evalsByTache) {
        List<BigDecimal> notes = new ArrayList<>();
        for (AiEvaluation eval : evalsByTache.values()) {
            if (eval.getNoteSur20() != null) notes.add(eval.getNoteSur20());
        }
        if (notes.isEmpty()) return null;
        return moyenne(notes).setScale(1, RoundingMode.HALF_UP);
    }

    /**
     * Compétence d'une évaluation : moyenne des critères porteurs depuis le
     * feedback persisté, fallback {@code note_sur_20}. Hors-sujet (note 0) →
     * 0. Null si rien d'exploitable.
     *
     * <p>La compétence est ensuite RAMENÉE sous le plafond de niveau éventuel
     * posé par {@code AiEvaluationService} (clé {@code plafond_niveau} du
     * feedback). Sans ça, le plafond n'abaissait que le niveau affiché par
     * tâche : le bilan d'épreuve — le seul niveau qui fait foi — repartait des
     * {@code scores_criteres} bruts et pouvait rendre B1/B2 une tâche plafonnée
     * A2. Aucun plafond posé (feature éteinte, évaluation antérieure) → la clé
     * est absente → math strictement identique à l'historique.
     */
    private BigDecimal competenceOf(AiEvaluation eval) {
        BigDecimal note = eval.getNoteSur20();
        if (note != null && note.signum() == 0) {
            return BigDecimal.ZERO;
        }
        Object scores = eval.getFeedbackJson() != null
                ? eval.getFeedbackJson().get("scores_criteres")
                : null;
        BigDecimal competence = competence(scores, props.getNiveauCecrl().getSourceCriteres(), note);
        return sousPlafond(competence, plafondNiveau(eval));
    }

    /** Plafond de niveau posé à l'évaluation, ou null (clé absente / valeur inconnue). */
    private static NiveauCecrl plafondNiveau(AiEvaluation eval) {
        Object raw = eval.getFeedbackJson() != null
                ? eval.getFeedbackJson().get(AiEvaluationService.PLAFOND_NIVEAU_KEY)
                : null;
        if (raw == null) return null;
        try {
            return NiveauCecrl.valueOf(raw.toString());
        } catch (IllegalArgumentException e) {
            log.warn("Plafond de niveau illisible dans le feedback : {}", raw);
            return null;
        }
    }

    /** Ramène la compétence sous la borne haute de la bande plafonnée. */
    private BigDecimal sousPlafond(BigDecimal competence, NiveauCecrl plafond) {
        if (competence == null || plafond == null) return competence;
        BigDecimal max = competenceMax(plafond, props.getNiveauCecrl());
        return (max != null && competence.compareTo(max) > 0) ? max : competence;
    }

    /**
     * Compétence maximale qui reste dans la bande {@code niveau} — la borne de
     * la bande supérieure, moins un epsilon (les compétences sont calculées à
     * l'échelle 4). Null quand la bande n'a pas de borne haute exploitable
     * (B2 est déjà le plafond du barème).
     */
    static BigDecimal competenceMax(NiveauCecrl niveau,
                                    ProductionEvaluationProperties.NiveauCecrl seuils) {
        return switch (niveau) {
            case A1_NON_ATTEINT -> BigDecimal.ZERO;
            case A1 -> justeSous(seuils.getSeuilA2());
            case A2 -> justeSous(seuils.getSeuilB1());
            case B1 -> justeSous(seuils.getSeuilB2());
            case B2, C1, C2 -> null;
        };
    }

    /** Plus grande valeur strictement sous {@code seuil} à l'échelle des compétences. */
    private static BigDecimal justeSous(double seuil) {
        return BigDecimal.valueOf(seuil).setScale(4, RoundingMode.HALF_UP)
                .subtract(new BigDecimal("0.0001"));
    }

    /** Poids d'une tâche (index {@code tacheNumero - 1} dans {@code poids-taches}, défaut 1). */
    private BigDecimal poidsTache(Integer tacheNumero) {
        List<Double> poids = props.getNiveauCecrl().getPoidsTaches();
        if (tacheNumero == null || poids == null
                || tacheNumero < 1 || tacheNumero > poids.size()) {
            return BigDecimal.ONE;
        }
        return BigDecimal.valueOf(poids.get(tacheNumero - 1));
    }

    // ------------------------------------------------------------------------
    // Math statique par soumission (utilisée aussi par AiEvaluationService)
    // ------------------------------------------------------------------------

    /**
     * {@code competence = moyenne(note_sur_20[source-criteres])} → bande CECRL
     * via les seuils config (plafond B2). Hors-sujet ({@code note_globale == 0})
     * → {@code A1_NON_ATTEINT}. Si un critere source manque, fallback sur la
     * moyenne ponderee deja calculee ({@code note_globale}). Retourne null si
     * rien d'exploitable. Package-private pour le test unitaire.
     */
    static NiveauCecrl computeNiveau(Object scoresCriteres, List<String> sourceCodes,
                                     BigDecimal noteGlobale, ProductionEvaluationProperties.NiveauCecrl seuils) {
        if (noteGlobale != null && noteGlobale.compareTo(BigDecimal.ZERO) == 0) {
            return NiveauCecrl.A1_NON_ATTEINT; // hors-sujet : coherent avec note_globale = 0
        }
        BigDecimal competence = competence(scoresCriteres, sourceCodes, noteGlobale);
        if (competence == null) return null;
        return niveauFromCompetence(competence, seuils);
    }

    /**
     * Moyenne des critères porteurs ({@code sourceCodes}) extraite de
     * {@code scores_criteres} ; si un critère source manque, fallback
     * {@code noteGlobale} ; null si rien d'exploitable.
     */
    static BigDecimal competence(Object scoresCriteres, List<String> sourceCodes, BigDecimal noteGlobale) {
        Map<String, BigDecimal> byCode = new HashMap<>();
        if (scoresCriteres instanceof List<?> scores) {
            for (Object s : scores) {
                if (s instanceof Map<?, ?> m && m.get("code") != null && m.get("note_sur_20") instanceof Number n) {
                    byCode.put(m.get("code").toString(), new BigDecimal(n.toString()));
                }
            }
        }
        List<BigDecimal> src = new ArrayList<>();
        for (String code : sourceCodes) {
            BigDecimal v = byCode.get(code);
            if (v != null) src.add(v);
        }

        if (!sourceCodes.isEmpty() && src.size() == sourceCodes.size()) {
            return moyenne(src);
        }
        if (noteGlobale != null) {
            return noteGlobale; // fallback : moyenne ponderee des criteres presents
        }
        if (!src.isEmpty()) {
            return moyenne(src);
        }
        return null;
    }

    /** Bande CECRL d'une compétence /20 selon les seuils config (plafond B2 inhérent). */
    static NiveauCecrl niveauFromCompetence(BigDecimal competence,
                                            ProductionEvaluationProperties.NiveauCecrl seuils) {
        double c = competence.doubleValue();
        if (c >= seuils.getSeuilB2()) return NiveauCecrl.B2; // plafond B2
        if (c >= seuils.getSeuilB1()) return NiveauCecrl.B1;
        if (c >= seuils.getSeuilA2()) return NiveauCecrl.A2;
        if (c > 0) return NiveauCecrl.A1;
        return NiveauCecrl.A1_NON_ATTEINT;
    }

    private static BigDecimal moyenne(Collection<BigDecimal> values) {
        BigDecimal sum = BigDecimal.ZERO;
        for (BigDecimal v : values) sum = sum.add(v);
        return sum.divide(BigDecimal.valueOf(values.size()), 4, RoundingMode.HALF_UP);
    }
}
