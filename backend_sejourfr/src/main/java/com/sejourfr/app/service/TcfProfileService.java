package com.sejourfr.app.service;

import com.sejourfr.app.dto.DiagnosticEpreuveLevel;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.EnumMap;
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
 *       {@code answers}) : un tel attempt n'est jamais chargé ici.
 *       <p>🛑 <b>La provenance de l'épreuve n'entre pas dans le calcul</b>
 *       (2026-09-16) : une CO/CE passée seule, dans un examen blanc complet ou
 *       comme sous-épreuve du <b>diagnostic complet</b> alimente exactement le
 *       même profil — depuis le 2026-09-13 ce sont les mêmes 25 items, le même
 *       tirage et la même durée. L'exclusion des diagnostics (V049) est
 *       révoquée ; {@link #bestQcm} retenant un <b>maximum</b>, rien n'est
 *       compté deux fois.</li>
 *   <li><b>EE / EO</b> : épreuve sans <b>aucun examen complet évalué</b> ni
 *       analyse de diagnostic ⇒ aucun niveau ⇒ épreuve à null. Une production
 *       rendue mais <b>inexploitable</b> (vide, quasi vide, langue non
 *       française, recopiage de la consigne) est du même ordre : sa ligne
 *       {@code ai_evaluations} existe mais ne porte aucun niveau
 *       ({@code evaluabilite = NON_EVALUABLE}), donc elle ne pèse pas dans le
 *       bilan de son épreuve — le domaine peut rester non évalué et le profil
 *       partiel.</li>
 * </ul>
 *
 * <h2>🛑 EE / EO : un ENTRAÎNEMENT ne définit jamais le niveau global</h2>
 * <p>Règle du propriétaire, <b>2026-09-16</b>. Le niveau global d'une épreuve de
 * production ne bouge que sur un <b>examen complet de l'épreuve</b> : celle du
 * diagnostic complet, un examen blanc isolé, ou la sous-épreuve d'un examen
 * blanc TCF complet. L'entraînement libre — même corrigé par l'IA, même situé
 * sur un palier, examinateur vocal temps réel compris — pratique, alimente les
 * compétences et garde son <b>niveau observé sur la tâche</b> sur son propre
 * écran de résultat ; il ne mesure pas l'épreuve.
 *
 * <p>Ce que ça a corrigé : un compte dont la seule trace EO était un
 * entraînement de trois minutes noté A2 affichait « expression orale : A2 » à
 * l'Accueil, sans avoir jamais passé d'épreuve d'EO. La liste des sessions qui
 * qualifient, et le niveau agrégé de chacune, vivent une seule fois, dans
 * {@link EpreuvesProductionQualifiantesResolver}.
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
    private final EpreuvesProductionQualifiantesResolver qualifiantesResolver;
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
            // 🛑 Le niveau d'UNE épreuve passée se demande à l'estimateur, il ne
            // se redérive pas ici : c'est la même valeur que l'écran
            // « Voir mes résultats » affiche pour justifier ce profil.
            best = levelEstimator.max(best, levelEstimator.niveauEpreuveQcm(a));
        }
        return best;
    }

    /**
     * Meilleur niveau d'une épreuve de production (EE/EO) : le plus haut
     * <b>niveau d'épreuve complète</b> jamais obtenu.
     *
     * <p>🛑 <b>L'unité est l'ÉPREUVE, jamais la tâche</b>, et la liste des
     * sessions qui y donnent droit n'est pas décidée ici : c'est
     * {@link EpreuvesProductionQualifiantesResolver}, la même autorité que la
     * page « Voir mes résultats » ({@code EpreuveHistoriqueService}). Les deux
     * écrans parlent donc désormais des mêmes mesures — l'un en prend le
     * maximum, l'autre la chronologie.
     *
     * <p><b>Ce que ça exclut, et c'est le but</b> (règle du propriétaire,
     * 2026-09-16) : l'entraînement libre, y compris évalué par l'IA et y compris
     * l'examinateur vocal temps réel. Un compte de test n'avait qu'un
     * entraînement EO de trois minutes, noté A2 : ce A2 s'affichait comme
     * « niveau global d'expression orale » alors qu'aucune épreuve d'EO n'avait
     * jamais été passée. Sans examen complet, l'épreuve reste <b>à évaluer</b>.
     *
     * <p><b>Toujours un maximum monotone</b> : la mauvaise journée ne fait pas
     * redescendre, et l'ordre des sessions n'influence rien. C'est ce qui tient
     * l'anti-yoyo sans règle de séquence.
     */
    private NiveauCecrl bestProduction(UUID userId, EpreuveType epreuve) {
        NiveauCecrl best = null;
        for (final EpreuvesProductionQualifiantesResolver.EpreuveQualifiante q
                : qualifiantesResolver.qualifiantes(userId, epreuve, SCAN_LIMIT)) {
            best = levelEstimator.max(best, levelEstimator.capB2(q.niveau()));
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
}
