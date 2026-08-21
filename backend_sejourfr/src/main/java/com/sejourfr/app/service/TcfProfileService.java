package com.sejourfr.app.service;

import com.sejourfr.app.dto.DiagnosticEpreuveLevel;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Niveau TCF d'un candidat <b>dans le temps</b> (à ne pas confondre avec le
 * résultat d'un examen donné) : <b>plancher des 4 épreuves, chaque épreuve
 * retenant son MEILLEUR résultat, une épreuve abandonnée sans rien rendre étant
 * EXCLUE du calcul</b>.
 *
 * <h2>« Abandonnée sans rien rendre »</h2>
 * <ul>
 *   <li><b>CO / CE</b> : examen blanc fini sans <b>aucune réponse</b>
 *       enregistrée. Le filtre vit dans la requête
 *       {@code AttemptRepository.findQcmEpreuvesPassees} ({@code EXISTS} sur
 *       {@code answers}) : un tel attempt n'est jamais chargé ici.</li>
 *   <li><b>EE / EO</b> : épreuve sans <b>aucune soumission évaluée</b> ni
 *       analyse de diagnostic ⇒ aucun niveau ⇒ épreuve à null.</li>
 * </ul>
 *
 * <h2>Le diagnostic est une BASELINE, pas un résultat</h2>
 * <p><b>Règle d'arbitrage</b> : le niveau estimé par le diagnostic ne renseigne
 * une épreuve de production que si elle n'a <b>aucune</b> production évaluée —
 * une évaluation réelle prime <b>toujours</b>, quelle que soit sa date, et la
 * règle du « meilleur résultat » ne joue qu'<b>entre</b> productions réelles.
 *
 * <p>Pourquoi le lire du tout : la bifurcation
 * {@code production_submissions.is_diagnostic} envoie les deux productions du
 * diagnostic dans {@code diagnostic_production_analyses} et <b>jamais</b> dans
 * {@code ai_evaluations}. Sans cette lecture, un candidat qui vient d'être
 * évalué sur son écrit ET son oral lisait « 0 domaine évalué sur 4 ».
 *
 * <p>Pourquoi seulement en repli : une baseline de 100 mots et de deux minutes
 * n'a pas l'autorité d'une tâche de production complète — même hiérarchie que
 * les poids du moteur de maîtrise (diagnostic 0,80 · production 1,00) et que
 * {@code SOLID}, qui refuse au diagnostic la valeur de preuve en situation. En
 * repli plutôt qu'en concurrent, il ne peut ni gonfler ni écraser un domaine
 * dont on a de vraies traces. Entre plusieurs analyses diagnostiques (versions
 * successives du diagnostic), on retient le meilleur, par cohérence.
 *
 * <p>Principe directeur, déjà celui du dépôt pour le niveau final d'un examen
 * complet : <b>« aucune preuve » n'est pas « mauvaise preuve »</b> — null =
 * inconnu, jamais mauvais. Une épreuve qu'on n'a jamais réellement passée ne
 * doit pas écraser l'indicateur affiché au candidat.
 *
 * <p>⚠️ Ceci ne change rien au calcul du résultat d'<b>un</b> examen : là, une
 * épreuve abandonnée sans verrou reste comptée {@code A1_NON_ATTEINT}
 * ({@code FullTcfExamResponseBuilder}) — elle a été passée et ratée. Ni au
 * bilan d'une épreuve de production, qui garde sa moyenne
 * ({@code ProductionBilanService}).
 *
 * <p>Toute la math CECRL (plancher, meilleur, plafond B2, niveau dérivé d'un
 * score pondéré) est déléguée à {@link TcfLevelEstimatorService} — ce service
 * ne fait que sélectionner les résultats opposables.
 */
@Service
@RequiredArgsConstructor
public class TcfProfileService {

    /**
     * Attempts d'examen QCM balayés par épreuve. On cherche le meilleur, donc
     * on balaie tout l'historique utile ; la requête filtre déjà les épreuves
     * non passées, ce qui borne le volume réel.
     */
    private static final int SCAN_LIMIT = 200;

    private final AttemptManager attemptManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final DiagnosticProductionAnalysisManager diagnosticAnalysisManager;
    private final TcfLevelEstimatorService levelEstimator;

    /**
     * Meilleur niveau par épreuve + niveau global (plancher des épreuves
     * renseignées). Tout à null si le candidat n'a jamais rien rendu en TCF.
     */
    @Transactional(readOnly = true)
    public TcfLevelProfile levelProfile(UUID userId) {
        final NiveauCecrl co = bestQcm(userId, EpreuveType.TCF_CO);
        final NiveauCecrl ce = bestQcm(userId, EpreuveType.TCF_CE);

        NiveauCecrl ee = bestProduction(userId, EpreuveType.TCF_EE);
        NiveauCecrl eo = bestProduction(userId, EpreuveType.TCF_EO);

        // Repli baseline : une seule requête, et seulement si au moins un des
        // deux domaines de production est vide — un candidat qui travaille
        // vraiment ne la paie jamais.
        if (ee == null || eo == null) {
            final Map<EpreuveType, NiveauCecrl> baseline = diagnosticLevels(userId);
            if (ee == null) ee = baseline.get(EpreuveType.TCF_EE);
            if (eo == null) eo = baseline.get(EpreuveType.TCF_EO);
        }

        // Arrays.asList (et non List.of) : une épreuve non passée vaut null, et
        // c'est précisément ce que le plancher doit ignorer.
        return new TcfLevelProfile(co, ce, ee, eo,
                levelEstimator.floor(Arrays.asList(co, ce, ee, eo)));
    }

    /**
     * Meilleur niveau d'une épreuve QCM (CO/CE) : le plus haut
     * {@code cecrl_level} des examens réellement passés (fallback dérivé du
     * score pondéré pour les attempts pré-V416). Les examens sans aucune
     * réponse sont déjà écartés par la requête.
     */
    private NiveauCecrl bestQcm(UUID userId, EpreuveType epreuve) {
        NiveauCecrl best = null;
        for (final Attempt a : attemptManager.findQcmEpreuvesPassees(userId, epreuve, SCAN_LIMIT)) {
            final NiveauCecrl level = a.getCecrlLevel() != null
                    ? levelEstimator.capB2(a.getCecrlLevel())
                    : levelEstimator.levelFromWeighted(a.getWeightedScore(), a.getMaxWeightedScore());
            best = levelEstimator.max(best, level);
        }
        return best;
    }

    /**
     * Meilleur niveau d'une épreuve de production (EE/EO) : le plus haut niveau
     * obtenu sur une tâche évaluée. L'unité retenue est la <b>tâche</b>, parce
     * que c'est l'unité que le candidat travaille (une session d'entraînement
     * EE/EO = une tâche).
     *
     * <p>Une soumission ré-évaluée porte plusieurs {@code ai_evaluations} :
     * seule la plus récente fait foi, sinon un verdict périmé pourrait
     * l'emporter.
     */
    private NiveauCecrl bestProduction(UUID userId, EpreuveType epreuve) {
        final Map<UUID, AiEvaluation> latestBySubmission = new HashMap<>();
        for (final AiEvaluation e : aiEvaluationManager.findByUserAndEpreuve(userId, epreuve)) {
            if (e.getNiveauCecrl() == null || e.getSubmission() == null) continue;
            latestBySubmission.merge(e.getSubmission().getId(), e, TcfProfileService::mostRecent);
        }

        NiveauCecrl best = null;
        for (final AiEvaluation e : latestBySubmission.values()) {
            best = levelEstimator.max(best, levelEstimator.capB2(e.getNiveauCecrl()));
        }
        return best;
    }

    /**
     * Niveaux du diagnostic <b>terminé</b>, par épreuve de production. Meilleur
     * niveau retenu si le candidat a plusieurs sessions terminées (versions
     * successives du diagnostic) ; plafonné B2 comme partout ailleurs.
     */
    private Map<EpreuveType, NiveauCecrl> diagnosticLevels(UUID userId) {
        final Map<EpreuveType, NiveauCecrl> out = new EnumMap<>(EpreuveType.class);
        for (final DiagnosticEpreuveLevel row : diagnosticAnalysisManager.findCompletedLevelsByUser(userId)) {
            if (row.epreuve() == null || row.niveau() == null) continue;
            out.merge(row.epreuve(), levelEstimator.capB2(row.niveau()), levelEstimator::max);
        }
        return out;
    }

    /** Plus récente des deux évaluations ; une date absente ne l'emporte jamais. */
    private static AiEvaluation mostRecent(AiEvaluation a, AiEvaluation b) {
        final Instant da = a.getEvaluatedAt();
        final Instant db = b.getEvaluatedAt();
        if (db == null) return a;
        if (da == null) return b;
        return db.isAfter(da) ? b : a;
    }
}
