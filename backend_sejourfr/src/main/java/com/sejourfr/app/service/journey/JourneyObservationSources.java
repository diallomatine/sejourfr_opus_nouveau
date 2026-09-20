package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * <b>« Quelles observations cette evaluation a-t-elle produites ? »</b> — et la
 * question inverse. <b>Une seule autorite</b> pour les deux.
 *
 * <h2>🛑 Pourquoi cette classe existe : deux identifiants de natures
 * differentes</h2>
 * <p>Une <b>evaluation</b> et une <b>observation</b> ne sont pas clavetees sur
 * la meme chose, et c'est voulu :
 * <ul>
 *   <li>{@link JourneyEvaluation#sourceAssessmentId()} est un
 *       {@code attempts.id} (ou un {@code diagnostic_sessions.id} pour le
 *       diagnostic rapide) — c'est <b>A11</b> : une epreuve d'expression produit
 *       <b>trois</b> soumissions, et traiter chacune comme une evaluation ferait
 *       que la tache 2 <b>remplacerait</b> (R7) le lot de la tache 1 ;</li>
 *   <li>{@code learning_plan_observations.source_id} d'une observation de
 *       <b>production</b> est un {@code production_submissions.id} — c'est le
 *       grain auquel le correcteur observe, et c'est la seule cle qui rend
 *       l'ecriture idempotente tache par tache
 *       ({@code LearningPlanObservationService.recordProduction}).</li>
 * </ul>
 *
 * <p>🛑 <b>Comparer les deux par egalite ne matche JAMAIS.</b> C'etait le defaut
 * corrige ici : un diagnostic rapide termine avec quatre fragilites EE ne creait
 * aucun lot, parce que {@code JourneyLotBuilder} cherchait des observations dont
 * le {@code source_id} valait l'id de la <b>session</b>. Mesure sur la base de
 * dev : 240 observations {@code DIAGNOSTIC_EE}/{@code DIAGNOSTIC_EO} clavetees
 * sur une soumission, <b>zero</b> sur une session.
 *
 * <p>🛑 <b>Et la correction n'est PAS de changer l'identite.</b> Passer
 * {@code submission.id} au parcours rouvrirait A11 / A16 mot pour mot. C'est la
 * <b>jointure</b> qui etait fausse, pas l'identite : elle vit desormais ici, et
 * nulle part ailleurs.
 *
 * <h2>La correspondance, nature par nature</h2>
 * <table>
 *   <tr><th>Evaluation</th><th>Ses observations</th></tr>
 *   <tr><td>{@code QUICK_DIAGNOSTIC}</td>
 *       <td>les soumissions des attempts de la session (l'ecrit, et l'oral
 *           quand il existe)</td></tr>
 *   <tr><td>{@code SECTION_EXAM} / {@code MOCK_EXAM} / {@code FULL_DIAGNOSTIC}
 *           sur {@code TCF_EE} / {@code TCF_EO}</td>
 *       <td>les soumissions de cet attempt</td></tr>
 *   <tr><td>les memes sur {@code TCF_CO} / {@code TCF_CE}</td>
 *       <td>l'attempt lui-meme</td></tr>
 *   <tr><td>{@code CIVIC_*}</td><td>inchange : l'identite elle-meme</td></tr>
 * </table>
 *
 * <p><b>L'identite fait toujours partie de l'ensemble</b>, et ce n'est pas une
 * precaution : en comprehension c'est <b>exactement</b> la cle des observations
 * ({@code LearningPlanObservationService} pose {@code source_id = attempt.id}).
 * Une seule regle couvre donc les quatre epreuves — « l'identite, plus les
 * soumissions de production qu'elle couvre » — au lieu d'un aiguillage par
 * epreuve recopie a chaque appelant.
 *
 * <h2>Cout borne, jamais un N+1</h2>
 * <p>{@code onAssessmentCompleted} tourne sur un chemin candidat :
 * {@link #pour} coute <b>au plus deux requetes</b> (les attempts de la session,
 * puis leurs soumissions), {@link #identitesParObservation} <b>au plus deux</b>
 * pour tout l'historique — jamais une par observation.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JourneyObservationSources {

    /** Combien d'observations non rattachees le garde nomme avant d'abreger. */
    private static final int ECHANTILLON = 5;

    private final ProductionSubmissionManager submissionManager;
    private final DiagnosticSessionManager sessionManager;

    /**
     * Une evaluation et les {@code source_id} de ses observations.
     *
     * @param evaluation   l'identite de l'evaluation — {@code attempts.id} ou
     *                     {@code diagnostic_sessions.id}. 🛑 <b>Jamais une
     *                     soumission</b> (A11).
     * @param observations les {@code learning_plan_observations.source_id} que
     *                     cette evaluation a produits. Elle contient toujours
     *                     {@code evaluation}.
     */
    public record Sources(UUID evaluation, Set<UUID> observations) {

        public boolean contient(UUID sourceId) {
            return sourceId != null && observations.contains(sourceId);
        }
    }

    /** Les observations que <b>cette</b> evaluation a produites. */
    public Sources pour(JourneyEvaluation evaluation) {
        UUID identite = evaluation.sourceAssessmentId();
        Set<UUID> sources = new LinkedHashSet<>();
        sources.add(identite);
        switch (evaluation.kind()) {
            // Le diagnostic rapide est une SESSION : ses observations sont
            // clavetees sur les soumissions de ses attempts — l'ecrit, et l'oral
            // quand il existe (cf. DiagnosticSessionCoordinator.submissions).
            case QUICK_DIAGNOSTIC -> sources.addAll(submissionManager.findIdsByAttemptIds(
                    sessionManager.findAttemptIdsBySessionId(identite)));
            case SECTION_EXAM, MOCK_EXAM, FULL_DIAGNOSTIC -> {
                if (estUneProduction(evaluation.examType())) {
                    sources.addAll(submissionManager.findIdsByAttemptIds(List.of(identite)));
                }
            }
            // 🛑 CIVIQUE : rien ne change. Ses observations portent une unite
            // officielle et sont clavetees sur l'attempt, comme la comprehension.
            case CIVIC_DIAGNOSTIC, CIVIC_EXAM, CIVIC_THEME_EXAM -> { }
        }
        return new Sources(identite, Set.copyOf(sources));
    }

    /**
     * Le chemin <b>inverse</b> : l'identite d'evaluation de chaque
     * {@code source_id} d'observation.
     *
     * <p>C'est ce dont le <b>bootstrap R19</b> a besoin. Il lit l'historique par
     * les observations, donc par des ids de <b>soumission</b> cote production ;
     * sans cette traduction il journalisait des ids de soumission dans
     * {@code journey_assessment_event.source_assessment_id}, la ou le chemin
     * live y ecrit des ids d'attempt ou de session. La colonne portait alors
     * <b>deux espaces d'identifiants</b>, et {@code dejaTraitee} ne reconnaissait
     * pas l'evaluation que l'amorce venait pourtant d'enregistrer : la meme
     * evaluation etait traitee <b>deux fois</b>.
     *
     * <p>🛑 <b>Repli sur l'identite elle-meme</b> quand la soumission est
     * introuvable ou sans attempt : une observation qu'on ne sait pas rattacher
     * reste son propre representant, plutot que de disparaitre du journal.
     * <b>{@code null} = inconnu, jamais mauvais.</b>
     *
     * @return {@code source_id} d'observation → identite d'evaluation. Seules
     *         les entrees qui <b>changent</b> y figurent : une observation de
     *         comprehension ou civique est deja sa propre identite.
     */
    public Map<UUID, UUID> identitesParObservation(
            Collection<LearningPlanObservation> observations) {
        Set<UUID> soumissions = new LinkedHashSet<>();
        for (LearningPlanObservation observation : observations) {
            if (observation.getSourceId() == null) continue;
            if (!estUneProduction(observation.getSourceType())) continue;
            soumissions.add(observation.getSourceId());
        }
        if (soumissions.isEmpty()) return Map.of();

        Map<UUID, UUID> attemptParSoumission =
                submissionManager.findAttemptIdBySubmissionIds(soumissions);
        Map<UUID, UUID> sessionParAttempt = sessionManager
                .findSessionIdByAttemptIds(new LinkedHashSet<>(attemptParSoumission.values()));

        Map<UUID, UUID> identites = new LinkedHashMap<>();
        attemptParSoumission.forEach((soumission, attempt) -> {
            // Une soumission de diagnostic rapide appartient a un attempt, qui
            // appartient a une session : c'est la SESSION qui est l'identite —
            // exactement ce que DiagnosticSessionCoordinator passe au parcours.
            UUID session = sessionParAttempt.get(attempt);
            identites.put(soumission, session != null ? session : attempt);
        });
        return Map.copyOf(identites);
    }

    // =====================================================================
    // Le garde — un join qui rend ZERO n'est jamais normal
    // =====================================================================

    /**
     * 🛑 <b>Une evaluation qui porte des observations mais dont le join n'en
     * retient AUCUNE est une panne, jamais un resultat.</b>
     *
     * <h2>Pourquoi ce garde existe, et pourquoi il a manque trois fois</h2>
     * <p>Le defaut corrige ici (A95) n'a leve <b>aucune</b> exception, viole
     * <b>aucune</b> contrainte et rendu <b>aucun</b> test rouge : le join a
     * simplement rendu zero ligne. Et zero ligne est un resultat
     * <b>parfaitement legitime</b> — R9 le dit mot pour mot, « zero fragilite
     * observee donne zero priorite ». C'est ce qui rend ces pannes invisibles :
     * le cycle ne se remplit jamais, et rien ne le signale.
     *
     * <p>🛑 <b>La distinction que ce garde fait, et c'est toute sa valeur</b> :
     * il ne regarde pas combien de <b>priorites</b> sont sorties — zero priorite
     * est normal —, il regarde combien d'<b>observations</b> le join a
     * rattachees. Zero observation rattachee alors que le candidat en a,
     * c'est <b>la jointure</b> qui a rate, pas le candidat qui n'a pas de
     * fragilite. Le branchement est appele <b>apres</b> l'ecriture des
     * observations : a ce moment-la, une evaluation en a.
     *
     * <p>Le message nomme <b>les deux identifiants et leur origine</b> — c'est
     * exactement ce qui manquait pour diagnostiquer : l'identite de l'evaluation
     * avec la table d'ou elle vient, et les {@code source_id} que le join a
     * laisses de cote avec leur {@code source_type}. Sans cette derniere moitie,
     * on lit « zero » sans savoir contre quoi la comparaison a echoue.
     *
     * <p>⚠️ <b>Chemin TCF</b> (exigence de lisibilite de D-48, transposee) : une
     * evaluation civique sort de {@code onAssessmentCompleted} avant ce point.
     *
     * <p>🛑 <b>Un {@code warn}, jamais une exception.</b> L'appelant est un
     * chemin candidat : refuser une soumission de reponse parce que le parcours
     * s'interroge serait pire que le defaut qu'on surveille.
     */
    public void verifierLeJoin(
            JourneyEvaluation evaluation, Sources sources,
            List<LearningPlanObservation> evaluations) {
        if (!joinVide(sources, evaluations)) return;
        log.warn("""
                🛑 Parcours : le join evaluation ⇄ observations a retenu ZERO ligne, \
                ce n'est jamais normal (A95). Evaluation {} — origine attendue : {} \
                ({}). Sources cherchees : {}. Le candidat a {} observation(s) \
                d'evaluation, dont : {}. Si l'origine d'un de ces source_id ne \
                correspond pas aux sources cherchees, c'est la JOINTURE qui est \
                fausse, pas le candidat qui n'a pas de fragilite.""",
                evaluation.sourceAssessmentId(), origineAttendue(evaluation.kind()),
                evaluation.kind(), sources.observations(), evaluations.size(),
                echantillon(evaluations));
    }

    /**
     * Le predicat du garde, isole pour etre verifiable sans lire un log.
     *
     * @return {@code true} quand le candidat a des observations d'evaluation et
     *         qu'<b>aucune</b> n'a ete rattachee a cette evaluation.
     */
    public static boolean joinVide(Sources sources, List<LearningPlanObservation> evaluations) {
        if (evaluations == null || evaluations.isEmpty()) return false;
        return evaluations.stream().noneMatch(o -> sources.contient(o.getSourceId()));
    }

    /**
     * De quelle table vient l'identifiant d'une evaluation — l'information que
     * {@code JourneyAssessmentKind} porte depuis A08, rendue lisible dans le
     * message.
     *
     * <p>⚠️ Cette correspondance est ecrite <b>ici seulement</b>, et pour un
     * message d'alerte. Le jour ou le depot decidera qu'une colonne portant un
     * identifiant doit <b>dire</b> de quelle table il vient, c'est cette
     * connaissance-la qui deviendra une colonne de nature ou une contrainte —
     * et ce garde n'aura plus a l'epeler.
     */
    private static String origineAttendue(com.sejourfr.app.enums.JourneyAssessmentKind kind) {
        return switch (kind) {
            case QUICK_DIAGNOSTIC -> "diagnostic_sessions.id";
            case FULL_DIAGNOSTIC -> "attempts.id (section de diagnostic complet)";
            case SECTION_EXAM, MOCK_EXAM -> "attempts.id (l'EPREUVE, jamais une soumission)";
            case CIVIC_DIAGNOSTIC -> "civic_diagnostic_sessions.id";
            case CIVIC_EXAM, CIVIC_THEME_EXAM -> "attempts.id";
        };
    }

    /** Les premieres observations non rattachees, avec leur origine reelle. */
    private static String echantillon(List<LearningPlanObservation> evaluations) {
        return evaluations.stream()
                .limit(ECHANTILLON)
                .map(o -> o.getSourceId() + " (" + o.getSourceType() + " ⇒ "
                        + (estUneProduction(o.getSourceType())
                                ? "production_submissions.id" : "attempts.id") + ")")
                .collect(Collectors.joining(", "));
    }

    /**
     * L'identite d'<b>une</b> observation, telle que
     * {@link #identitesParObservation} l'a resolue.
     */
    public static UUID identite(Map<UUID, UUID> identites, UUID sourceId) {
        UUID identite = identites.get(sourceId);
        return identite != null ? identite : sourceId;
    }

    /**
     * Une observation dont le {@code source_id} est une <b>soumission</b>, et
     * non l'evaluation elle-meme.
     *
     * <p>🛑 C'est la liste des sources de <b>production</b>, et elle est
     * exhaustive : tout le reste — comprehension, civique, petit sujet — est
     * claveté sur l'identite d'evaluation directement.
     */
    private static boolean estUneProduction(LearningPlanSourceType source) {
        if (source == null) return false;
        return switch (source) {
            case DIAGNOSTIC_EE, DIAGNOSTIC_EO, PRODUCTION_EE, PRODUCTION_EO,
                 MOCK_EXAM_EE, MOCK_EXAM_EO -> true;
            case SKILL_TRAINING, TCF_CO, TCF_CE, CIVIQUE_SERIE, CIVIQUE_EXAMEN -> false;
        };
    }

    /** Les deux epreuves dont les observations passent par une soumission. */
    private static boolean estUneProduction(EpreuveType epreuve) {
        return epreuve == EpreuveType.TCF_EE || epreuve == EpreuveType.TCF_EO;
    }
}
