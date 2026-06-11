package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
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
 *       des critères porteurs (lexique + morphosyntaxe) → seuils config.
 *       Calculé et persisté par {@code AiEvaluationService} à chaque évaluation
 *       (calibration admin), mais <b>jamais exposé par tâche</b> aux fronts.</li>
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
        BigDecimal acc = BigDecimal.ZERO;
        BigDecimal sumPoids = BigDecimal.ZERO;
        NiveauCecrl floorFallback = null;
        for (Map.Entry<Integer, AiEvaluation> e : evalsByTache.entrySet()) {
            AiEvaluation eval = e.getValue();
            BigDecimal comp = competenceOf(eval);
            if (comp == null) {
                // Éval inexploitable (scores absents et note nulle) : elle ne
                // pèse pas dans la moyenne, mais son niveau persisté reste un
                // garde-fou si TOUTES les évals sont dans ce cas.
                floorFallback = levelEstimator.min(floorFallback, eval.getNiveauCecrl());
                continue;
            }
            BigDecimal poids = poidsTache(e.getKey());
            acc = acc.add(comp.multiply(poids));
            sumPoids = sumPoids.add(poids);
        }
        if (sumPoids.signum() == 0) {
            return levelEstimator.capB2(floorFallback);
        }
        BigDecimal competence = acc.divide(sumPoids, 4, RoundingMode.HALF_UP);
        return niveauFromCompetence(competence, props.getNiveauCecrl());
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
     */
    private BigDecimal competenceOf(AiEvaluation eval) {
        BigDecimal note = eval.getNoteSur20();
        if (note != null && note.signum() == 0) {
            return BigDecimal.ZERO;
        }
        Object scores = eval.getFeedbackJson() != null
                ? eval.getFeedbackJson().get("scores_criteres")
                : null;
        return competence(scores, props.getNiveauCecrl().getSourceCriteres(), note);
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
