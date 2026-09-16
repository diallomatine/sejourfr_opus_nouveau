package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.DiagnosticEpreuveLevel;
import com.sejourfr.app.dto.EpreuveHistoriqueDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SourceEvaluation;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.service.EpreuvesProductionQualifiantesResolver;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * <b>« D'où sort mon niveau ? »</b> — les dernières évaluations
 * <b>qualifiantes</b> d'une épreuve TCF.
 *
 * <h2>Ce service n'invente aucune mesure</h2>
 * <p>🛑 <b>CO/CE : mêmes lignes, même autorité de niveau</b> que
 * {@code TcfProfileService} — la même requête
 * ({@code findQcmEpreuvesPassees}) et le même
 * {@code TcfLevelEstimatorService.niveauEpreuveQcm}. Ce qui est servi ici
 * explique donc exactement le palier servi là-bas.
 *
 * <h2>🛑 EE/EO : mêmes sessions, même autorité de niveau — arbitrage clos</h2>
 * <p>Le propriétaire a tranché le <b>2026-09-16</b> : seul un <b>examen complet
 * de l'épreuve</b> définit le niveau global d'EE/EO. La contradiction décrite
 * ici auparavant — cette page ne montrait que les épreuves complètes pendant que
 * {@code TcfProfileService.bestProduction} servait un palier tiré de
 * <b>n'importe quelle tâche évaluée</b>, entraînement libre compris — est donc
 * fermée par le haut : le profil s'est restreint, pas cette page qui se serait
 * élargie. Les deux lisent maintenant
 * {@link EpreuvesProductionQualifiantesResolver}, à un usage près (un maximum
 * là-bas, une chronologie ici).
 * → {@code docs/regles/progression.md}, section « Écran ACCUEIL ».
 *
 * <table>
 *   <caption>Les sources, vues en chronologie plutôt qu'en maximum</caption>
 *   <tr><th>épreuve</th><th>lignes</th><th>niveau</th><th>date</th></tr>
 *   <tr>
 *     <td>CO / CE</td>
 *     <td>{@code AttemptManager.findQcmEpreuvesPassees}</td>
 *     <td>{@code TcfLevelEstimatorService.niveauEpreuveQcm}</td>
 *     <td>{@code finishedAt}</td>
 *   </tr>
 *   <tr>
 *     <td>EE / EO</td>
 *     <td>{@code EpreuvesProductionQualifiantesResolver.qualifiantes}</td>
 *     <td>{@code ProductionBilanService.niveauEpreuve}</td>
 *     <td>{@code finishedAt}</td>
 *   </tr>
 *   <tr>
 *     <td>EE / EO (baseline)</td>
 *     <td>{@code DiagnosticProductionAnalysisManager.findCompletedLevelsByUser}</td>
 *     <td>{@code levelEstimate}</td>
 *     <td>{@code analyzedAt}</td>
 *   </tr>
 * </table>
 *
 * <h2>Ce qui n'y entre pas, et pourquoi</h2>
 * <ul>
 *   <li>🛑 <b>Les petits sujets de compétence</b> ({@code user_skill_attempts}).
 *       Ils ne portent aucun niveau CECRL, n'alimentent pas le profil, et les
 *       montrer ici laisserait croire qu'un micro-entraînement mesure une
 *       épreuve. Décision du propriétaire.</li>
 *   <li>🛑 <b>L'entraînement libre de production.</b> Le produit n'y calcule
 *       aucun palier ({@code ProductionBilanService} : « jamais de niveau en
 *       entraînement libre ») — une ligne sans niveau n'est pas une évaluation
 *       qualifiante.</li>
 *   <li>🛑 <b>Une session sans verdict</b> : évaluation IA encore en vol, tâche
 *       en échec, production inexploitable. {@code null} = inconnu, jamais
 *       {@code A1_NON_ATTEINT} — c'est l'incident V040/V041/V042.</li>
 * </ul>
 *
 * <h2>Le plafond est un plafond d'AFFICHAGE</h2>
 * <p>🛑 {@value #MAX_EVALUATIONS} lignes servies, jamais un budget de lecture :
 * les requêtes balaient plus large que ça et le tri décide, sinon une baseline
 * de diagnostic ancienne pourrait évincer une épreuve d'hier par le simple
 * hasard de l'ordre de lecture.
 */
@Service
@RequiredArgsConstructor
public class EpreuveHistoriqueService {

    /** Ce que l'écran montre. Demande du propriétaire : les trois dernières. */
    public static final int MAX_EVALUATIONS = 3;

    /**
     * Ce qu'on balaie avant de trier. Volontairement plus large que
     * {@link #MAX_EVALUATIONS} : le tri chronologique doit pouvoir arbitrer
     * entre des sources lues séparément.
     */
    private static final int SCAN_LIMIT = 20;

    /** 🛑 Les quatre épreuves du TCF IRN. {@code TCF_STRUCTURE} n'en est pas une. */
    private static final List<EpreuveType> EPREUVES = List.of(
            EpreuveType.TCF_CO, EpreuveType.TCF_CE,
            EpreuveType.TCF_EE, EpreuveType.TCF_EO);

    private final AttemptManager attemptManager;
    private final EpreuvesProductionQualifiantesResolver qualifiantesResolver;
    private final DiagnosticProductionAnalysisManager diagnosticAnalysisManager;
    private final TcfLevelEstimatorService levelEstimator;

    /**
     * Les {@value #MAX_EVALUATIONS} dernières évaluations qualifiantes d'une
     * épreuve, de la plus récente à la plus ancienne.
     *
     * <p>🛑 <b>Liste vide plutôt qu'erreur</b> quand rien n'a été mesuré :
     * l'écran doit pouvoir le dire au candidat, pas planter.
     *
     * @throws BusinessException si l'épreuve demandée n'est pas l'une des
     *                           quatre du TCF IRN — là c'est bien une erreur de
     *                           client, pas une absence de mesure
     */
    @Transactional(readOnly = true)
    public EpreuveHistoriqueDto historique(UUID userId, EpreuveType epreuve) {
        if (epreuve == null || !EPREUVES.contains(epreuve)) {
            throw new BusinessException(
                    "epreuve doit etre l'une des quatre du TCF IRN : "
                            + "TCF_CO, TCF_CE, TCF_EE ou TCF_EO.");
        }
        final List<EpreuveHistoriqueDto.Evaluation> evaluations =
                switch (epreuve) {
                    case TCF_CO, TCF_CE -> qcm(userId, epreuve);
                    default -> production(userId, epreuve);
                };
        return new EpreuveHistoriqueDto(epreuve, evaluations.stream()
                .sorted(Comparator.comparing(
                        EpreuveHistoriqueDto.Evaluation::mesureA).reversed())
                .limit(MAX_EVALUATIONS)
                .toList());
    }

    /* ------------------------------------------------------------ CO / CE -- */

    private List<EpreuveHistoriqueDto.Evaluation> qcm(UUID userId, EpreuveType epreuve) {
        final List<EpreuveHistoriqueDto.Evaluation> out = new ArrayList<>();
        for (final Attempt a : attemptManager.findQcmEpreuvesPassees(userId, epreuve, SCAN_LIMIT)) {
            final NiveauCecrl niveau = levelEstimator.niveauEpreuveQcm(a);
            // Un examen dont rien n'est exploitable n'est pas une mauvaise
            // mesure : il n'en est pas une.
            if (niveau == null || a.getFinishedAt() == null) continue;
            out.add(new EpreuveHistoriqueDto.Evaluation(
                    a.getFinishedAt(), source(a), niveau));
        }
        return out;
    }

    /* ------------------------------------------------------------ EE / EO -- */

    private List<EpreuveHistoriqueDto.Evaluation> production(UUID userId, EpreuveType epreuve) {
        final List<EpreuveHistoriqueDto.Evaluation> out = new ArrayList<>();
        for (final EpreuvesProductionQualifiantesResolver.EpreuveQualifiante q
                : qualifiantesResolver.qualifiantes(userId, epreuve, SCAN_LIMIT)) {
            out.add(new EpreuveHistoriqueDto.Evaluation(
                    q.mesureA(), source(q.attempt()), q.niveau()));
        }
        for (final DiagnosticEpreuveLevel row
                : diagnosticAnalysisManager.findCompletedLevelsByUser(userId)) {
            if (row.epreuve() != epreuve || row.niveau() == null || row.mesureA() == null) continue;
            out.add(new EpreuveHistoriqueDto.Evaluation(
                    row.mesureA(),
                    SourceEvaluation.DIAGNOSTIC_RAPIDE,
                    levelEstimator.capB2(row.niveau())));
        }
        return out;
    }

    /* -------------------------------------------------------------- source -- */

    /**
     * D'où vient une épreuve passée. 🛑 <b>L'ordre des tests compte</b> : les
     * sous-épreuves d'un diagnostic TCF complet portent <b>aussi</b> un
     * {@code parentAttempt} (celui de leur session), et les lire dans l'autre
     * sens les annoncerait toutes comme des examens blancs.
     */
    private static SourceEvaluation source(Attempt attempt) {
        if (attempt.getTcfDiagnostic() != null) return SourceEvaluation.DIAGNOSTIC_COMPLET;
        if (attempt.getParentAttempt() != null) return SourceEvaluation.EXAMEN_BLANC;
        return SourceEvaluation.EPREUVE_SEULE;
    }
}
