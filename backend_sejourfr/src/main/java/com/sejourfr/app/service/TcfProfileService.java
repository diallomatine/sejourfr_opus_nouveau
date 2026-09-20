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
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.BiFunction;

/**
 * Niveau TCF d'un candidat <b>dans le temps</b> (à ne pas confondre avec le
 * résultat d'un examen donné) : <b>plancher des 4 épreuves, une épreuve
 * abandonnée sans rien rendre étant EXCLUE du calcul</b>.
 *
 * <p>🛑 <b>Ce que vaut « une épreuve » n'est PAS la même chose dans les deux
 * lectures</b> (cf. la section « DEUX lectures » plus bas) : la lecture du
 * <b>Plan</b> retient le <b>meilleur</b> résultat de tout l'historique, la
 * lecture d'<b>affichage</b> la <b>moyenne des 3 derniers examens
 * qualifiants</b> ({@link NiveauActuelEpreuveResolver}) — donc un niveau qui
 * peut redescendre.
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
 *       révoquée : une CE de diagnostic complet est une mesure de CE, elle
 *       entre dans le meilleur du Plan comme dans la moyenne d'affichage.</li>
 *   <li><b>EE / EO</b> : épreuve sans <b>aucune soumission évaluée</b> ni
 *       analyse de diagnostic ⇒ aucun niveau ⇒ épreuve à null. Une production
 *       rendue mais <b>inexploitable</b> (vide, quasi vide, langue non
 *       française, recopiage de la consigne) est du même ordre : sa ligne
 *       {@code ai_evaluations} existe mais ne porte aucun niveau
 *       ({@code evaluabilite = NON_EVALUABLE}), donc elle n'entre pas dans le
 *       calcul — le domaine reste non évalué et le profil partiel.</li>
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
 *
 * <h2>🛑 DEUX lectures, et elles ne servent pas le même écran</h2>
 * <p>Arbitrage du propriétaire, <b>2026-09-16</b>, après une première passe dont
 * le périmètre était trop large. Les deux méthodes publiques assemblent le
 * <b>même</b> profil — même baseline de diagnostic, même plancher global — et
 * ne diffèrent que sur <b>ce que vaut une épreuve</b> :
 * <ul>
 *   <li>{@link #levelProfile} — le <b>MEILLEUR</b> résultat de tout
 *       l'historique, et <b>toute évaluation IA valide</b> en EE/EO,
 *       entraînement compris. C'est la lecture du <b>Plan</b>
 *       ({@code PlanCycleResolver}, priorités, compétences) : un entraînement
 *       EE/EO est une observation, et le Plan doit continuer de la voir.</li>
 *   <li>{@link #levelProfileAccueil} — la <b>MOYENNE des 3 derniers examens
 *       qualifiants</b> ({@link NiveauActuelEpreuveResolver}), donc un niveau
 *       <b>actuel</b> qui monte comme il descend. C'est la lecture
 *       d'<b>affichage</b> : l'Accueil, le Profil et tout ce que sert
 *       {@code DashboardSummaryResponse.estimatedTcfLevel}.</li>
 * </ul>
 *
 * <p><b>Les deux peuvent donc diverger, et c'est voulu</b> : l'affichage dit
 * « à évaluer » ou annonce un palier en baisse pendant que le Plan travaille
 * déjà le domaine sur son meilleur niveau connu. Ce qui serait un défaut, c'est
 * qu'un écran <b>recalcule</b> l'un des deux — ils s'appellent.
 */
@Service
@RequiredArgsConstructor
public class TcfProfileService {

    /**
     * Attempts balayés par épreuve. 🛑 <b>Lu chez son autorité</b> depuis le
     * 2026-09-17 : cette constante vivait ici en copie privée, avec sa jumelle
     * dans {@code TcfDiagnosticReadService}, et le parcours TCF en aurait fait
     * une troisième.
     */
    private static final int SCAN_LIMIT = NiveauActuelEpreuveResolver.SCAN_LIMIT;

    private final AttemptManager attemptManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final NiveauActuelEpreuveResolver niveauActuelResolver;
    private final DiagnosticProductionAnalysisManager diagnosticAnalysisManager;
    private final TcfLevelEstimatorService levelEstimator;

    /**
     * <b>Lecture du PLAN</b> — meilleur niveau par épreuve + niveau global
     * (plancher des épreuves renseignées). Tout à null si le candidat n'a jamais
     * rien rendu en TCF.
     *
     * <p>EE/EO : <b>toute évaluation IA valide</b>, entraînement compris. Le
     * niveau retenu est le <b>meilleur</b> de tout l'historique, donc il ne
     * redescend pas : c'est voulu ici, un Plan n'a pas à désapprendre ce qu'un
     * candidat a déjà démontré. Cf. l'en-tête de classe, « DEUX lectures » ; ce
     * que voient l'Accueil et le Profil, c'est {@link #levelProfileAccueil}.
     */
    @Transactional(readOnly = true)
    public TcfLevelProfile levelProfile(UUID userId) {
        return profil(userId, this::bestQcm, this::bestProduction);
    }

    /**
     * <b>LECTURE D'AFFICHAGE — le niveau ACTUEL estimé.</b> Le même profil, mais
     * chaque épreuve vaut la <b>moyenne de ses {@value
     * NiveauActuelEpreuveResolver#EXAMENS_RETENUS} derniers examens
     * qualifiants</b>, scores d'abord, conversion en palier ensuite.
     *
     * <p>🛑 <b>Règle du propriétaire du 2026-09-16, qui RÉVOQUE le maximum
     * monotone de cette lecture</b>, posé le matin même : « <i>le niveau affiché
     * doit représenter le niveau actuel estimé, donc il peut monter comme
     * descendre</i> ». Un mauvais examen récent <b>fait</b> baisser le palier
     * affiché. Le meilleur niveau atteint reste lisible dans la chronologie de
     * « Voir mes résultats » ({@code EpreuveHistoriqueService}) — il ne se
     * confond plus avec le niveau actuel.
     *
     * <p>Ce qui <b>n'a pas</b> changé : un entraînement EE/EO n'entre jamais
     * dans cette moyenne (arbitrage du même jour) — la liste des examens
     * qualifiants reste celle de
     * {@link EpreuvesProductionQualifiantesResolver}, la même autorité que
     * « Voir mes résultats ». Sans examen qualifiant, l'épreuve reste
     * <b>{@code null}</b> (« À évaluer »), jamais un plancher fabriqué.
     *
     * <p>⚠️ <b>Ce n'est PAS la lecture du Plan.</b> Le premier jet de la règle
     * d'Accueil avait modifié {@link #levelProfile} lui-même : le Plan, les
     * priorités et les compétences perdaient alors les observations
     * d'entraînement, ce que le propriétaire a explicitement refusé. Le Plan
     * garde aussi son <b>maximum</b> : rien de cette révocation ne le touche.
     *
     * <p><b>Qui lit cette méthode</b> : {@code ProgressService.tcf} (l'Accueil
     * et l'écran Progrès) et {@code UserDashboardService} (le Profil, et les
     * autres surfaces qui affichent {@code estimatedTcfLevel}). Une seule
     * autorité d'affichage, pour que les deux écrans ne puissent pas annoncer
     * deux paliers différents le même jour.
     *
     * <p>Le <b>niveau global</b> rendu ici est, lui aussi, le plancher des
     * quatre paliers <b>affichés</b> : sans ça, l'écran annoncerait un niveau
     * global tiré d'une EO qu'il présente deux lignes plus bas comme non
     * évaluée.
     */
    @Transactional(readOnly = true)
    public TcfLevelProfile levelProfileAccueil(UUID userId) {
        return profil(userId,
                (u, e) -> niveauActuelResolver.qcm(u, e, SCAN_LIMIT),
                (u, e) -> niveauActuelResolver.production(u, e, SCAN_LIMIT));
    }

    /**
     * L'assemblage commun aux deux lectures. 🛑 Il n'existe qu'une fois : le
     * repli baseline et le plancher global sont la même règle pour l'affichage
     * et pour le Plan — seule la façon de valoriser une épreuve change, et
     * c'est le paramètre.
     */
    private TcfLevelProfile profil(
            UUID userId,
            BiFunction<UUID, EpreuveType, NiveauCecrl> comprehension,
            BiFunction<UUID, EpreuveType, NiveauCecrl> production) {
        final NiveauCecrl co = comprehension.apply(userId, EpreuveType.TCF_CO);
        final NiveauCecrl ce = comprehension.apply(userId, EpreuveType.TCF_CE);

        NiveauCecrl ee = production.apply(userId, EpreuveType.TCF_EE);
        NiveauCecrl eo = production.apply(userId, EpreuveType.TCF_EO);

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
     * <b>Lecture du PLAN</b> — meilleur niveau d'une épreuve QCM (CO/CE) : le
     * plus haut palier des examens réellement passés, chacun <b>dérivé de ses
     * réponses</b> (le niveau n'est plus persisté). Les examens sans aucune
     * réponse sont déjà écartés par la requête.
     *
     * <p>🛑 L'affichage, lui, ne passe plus par ici depuis le 2026-09-16 : il
     * <b>moyenne</b> les trois derniers examens ({@link
     * NiveauActuelEpreuveResolver#qcm}) au lieu d'en retenir le meilleur.
     */
    private NiveauCecrl bestQcm(UUID userId, EpreuveType epreuve) {
        final List<Attempt> passees =
                attemptManager.findQcmEpreuvesPassees(userId, epreuve, SCAN_LIMIT);
        // 🛑 Le niveau d'une épreuve passée se demande à l'estimateur, il ne se
        // redérive pas ici : c'est la même valeur que l'écran « Voir mes
        // résultats » affiche pour justifier ce profil. Et il se demande pour
        // TOUTE la fenêtre en une requête — le profil balaie jusqu'à
        // {@value #SCAN_LIMIT} sessions par épreuve, quatre fois.
        final Map<UUID, NiveauCecrl> niveaux = levelEstimator.niveauxQcm(
                passees.stream().map(Attempt::getId).toList());
        NiveauCecrl best = null;
        for (final Attempt a : passees) {
            best = levelEstimator.max(best, niveaux.get(a.getId()));
        }
        return best;
    }

    /**
     * <b>Lecture du PLAN</b> — meilleur niveau d'une épreuve de production
     * (EE/EO) : le plus haut niveau obtenu sur une tâche évaluée. L'unité
     * retenue est la <b>tâche</b>, parce que c'est l'unité que le candidat
     * travaille (une session d'entraînement EE/EO = une tâche).
     *
     * <p>🛑 <b>L'entraînement compte ici, et c'est voulu</b> (arbitrage du
     * 2026-09-16) : une production d'entraînement corrigée par l'IA est une
     * observation, et le Plan doit la voir. Ce qu'elle ne fait plus, c'est
     * <b>afficher</b> un niveau global sur l'Accueil — cf.
     * {@link NiveauActuelEpreuveResolver#production}.
     *
     * <p>Une soumission ré-évaluée porte plusieurs {@code ai_evaluations} :
     * seule la plus récente fait foi, sinon un verdict périmé pourrait
     * l'emporter.
     */
    private NiveauCecrl bestProduction(UUID userId, EpreuveType epreuve) {
        final Map<UUID, AiEvaluation> latestBySubmission = new HashMap<>();
        for (final AiEvaluation e : aiEvaluationManager.findByUserAndEpreuve(userId, epreuve)) {
            if (e.getSubmission() == null) continue;
            // Le tri « la plus recente fait foi » se fait sur TOUTES les lignes,
            // y compris celles sans niveau : filtrer avant reviendrait a laisser
            // un verdict perime l'emporter sur une re-evaluation qui n'a rien
            // pu observer.
            latestBySubmission.merge(e.getSubmission().getId(), e, TcfProfileService::mostRecent);
        }

        NiveauCecrl best = null;
        for (final AiEvaluation e : latestBySubmission.values()) {
            // Sans niveau, la ligne n'est pas une mauvaise preuve : elle n'est
            // pas une preuve. C'est le cas d'une production INEXPLOITABLE
            // (evaluabilite NON_EVALUABLE, aucun appel LLM emis) comme d'une
            // evaluation sans niveau situable.
            if (e.getNiveauCecrl() == null) continue;
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
