package com.sejourfr.app.service;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Ce qui compte comme un EXAMEN COMPLET d'épreuve EE/EO</b> — une seule fois
 * pour tout le dépôt.
 *
 * <h2>La règle, tranchée par le propriétaire le 2026-09-16</h2>
 * <p>🛑 <b>Un entraînement ne définit JAMAIS le niveau global d'une épreuve de
 * production</b>, même corrigé par l'IA et même quand l'IA situe la tâche sur un
 * palier CECRL. Un entraînement sert à pratiquer autant qu'on veut, à alimenter
 * les compétences / priorités / feedbacks, et à porter son <b>niveau observé sur
 * la tâche</b> (son propre écran de résultat) — rien de plus.
 *
 * <p>Le niveau global d'une épreuve ne bouge que sur un <b>examen complet de
 * l'épreuve</b>. Trois provenances, et seulement trois :
 * <ol>
 *   <li>l'épreuve EO/EE du <b>diagnostic complet</b> (4 épreuves) ;</li>
 *   <li>un <b>examen blanc isolé</b> de l'épreuve ;</li>
 *   <li>l'épreuve EO/EE d'un <b>examen blanc TCF complet</b>.</li>
 * </ol>
 *
 * <h2>Comment les trois se reconnaissent en base</h2>
 * <p>🛑 <b>{@code attempts.type} ne distingue rien ici</b> :
 * {@code AttemptService.startProduction} pose {@code TRAINING} sur TOUTES les
 * sessions de production, examen blanc isolé compris — le drapeau d'examen y est
 * le {@code slot_number}. Filtrer sur {@code type = MOCK_EXAM} laisserait dehors
 * le cas 2 et ferait entrer... rien de plus.
 *
 * <p>Le prédicat réel est celui de
 * {@link ProductionAccessService#isExamSession(Attempt)}, porté en JPQL par
 * {@code AttemptRepository.findProductionEpreuvesPassees} :
 * <ul>
 *   <li>{@code slot_number IS NOT NULL} — cas 2, slot de la grille posé au
 *       démarrage d'un examen blanc d'épreuve ;</li>
 *   <li>{@code parent_attempt_id IS NOT NULL} — cas 3 (sous-épreuve d'un
 *       {@code TCF_COMPLET}) <b>et</b> cas 1 (le diagnostic complet accroche ses
 *       sections au même conteneur, cf.
 *       {@code TcfDiagnosticSectionStarter.creerProduction}) ;</li>
 *   <li>plus {@code finished_at IS NOT NULL} et au moins une soumission : une
 *       épreuve ouverte puis abandonnée sans rien rendre n'a rien mesuré.</li>
 * </ul>
 * L'entraînement libre — y compris les sessions temps réel de l'examinateur
 * vocal — n'a ni slot ni parent : il est dehors, quel que soit le nombre de
 * tâches soumises.
 *
 * <h2>Le niveau retenu est celui de l'ÉPREUVE, jamais d'une tâche</h2>
 * <p>Il est demandé à {@link ProductionBilanService#niveauEpreuve} — l'agrégat
 * pondéré des 3 tâches, avec son garde-fou de cohérence T3 et son « reste noté
 * 0 » sur une épreuve écourtée. Une session dont rien n'est encore exploitable
 * rend {@code null} et n'est pas servie : <b>{@code null} = inconnu, jamais
 * mauvais</b>.
 *
 * <h2>Qui lit ce resolver, et qui ne le lit PAS</h2>
 * <p>Extrait le 2026-09-16 à sa 2ᵉ occurrence. {@code EpreuveHistoriqueService}
 * listait déjà ces sessions <b>en chronologie</b> (« d'où sort mon niveau ? »)
 * pendant que la carte d'épreuve de l'Accueil annonçait un palier tiré de
 * <b>n'importe quelle tâche évaluée</b> : elle proposait « Voir mes résultats »
 * à un candidat à qui cette page répondait « aucune évaluation qualifiante ».
 * Les deux lisent maintenant cette liste — la <b>moyenne des 3 dernières</b>
 * pour l'affichage ({@code NiveauActuelEpreuveResolver.production}, appelé par
 * {@code TcfProfileService.levelProfileAccueil}), une <b>chronologie</b> pour
 * la page de résultats. ⚠️ C'était un <b>maximum</b> jusqu'au 2026-09-16 :
 * le propriétaire l'a révoqué le jour même, un niveau affiché devant pouvoir
 * redescendre.
 *
 * <p>🛑 <b>Le PLAN ne passe PAS par ici</b>, et c'est l'arbitrage du
 * propriétaire du 2026-09-16 : {@code TcfProfileService.levelProfile} — la
 * lecture de {@code PlanCycleResolver}, des priorités et des compétences —
 * continue de voir les entraînements EE/EO évalués, parce qu'un entraînement
 * est une observation. Un premier jet avait restreint le Plan lui aussi ; le
 * périmètre a été ramené à l'affichage.
 *
 * <h2>Le coût est CONSTANT, et c'est une contrainte, pas un détail</h2>
 * <p>🛑 <b>3 requêtes par épreuve</b>, que le candidat ait passé une session ou
 * dix : les sessions, puis leurs soumissions (tâche jointe), puis leurs
 * évaluations — chacune en <b>un lot</b>. Ce resolver tourne à chaque lecture
 * d'Accueil et de « Voir mes résultats » ; la version naïve (une requête par
 * session, une par soumission, plus un lazy-load de tâche par soumission)
 * coûtait <b>+14 requêtes</b> et grandissait avec l'historique.
 *
 * <p>⚠️ <b>Les appelants doivent être transactionnels</b> : le bilan traverse
 * {@code submission → production_task}, joint ici mais lazy ailleurs.
 */
@Service
@RequiredArgsConstructor
public class EpreuvesProductionQualifiantesResolver {

    private final AttemptManager attemptManager;
    private final ProductionSubmissionManager submissionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final ProductionBilanService bilanService;

    /**
     * Une épreuve complète réellement passée et réellement évaluée.
     *
     * @param attempt la session, pour sa provenance ({@code tcfDiagnostic} /
     *                {@code parentAttempt}) — l'appelant qui en a besoin la lit
     *                lui-même plutôt que de recevoir une provenance qu'il
     *                n'utilise pas
     * @param mesureA {@code finishedAt}, jamais null ici
     * @param niveau  l'agrégat d'épreuve, jamais null ici
     * @param competence le <b>nombre</b> dont {@code niveau} est la bande
     *                (échelle /20 des seuils, cf.
     *                {@code ProductionBilanService.niveauDepuisCompetence}).
     *                {@code null} quand le niveau vient du repli sur les
     *                niveaux persistés : une session peut donc porter un
     *                palier sans porter de score
     */
    public record EpreuveQualifiante(
            Attempt attempt, Instant mesureA, NiveauCecrl niveau, BigDecimal competence) {
    }

    /**
     * Les épreuves complètes d'un candidat pour une épreuve de production, de la
     * plus récente à la plus ancienne.
     *
     * <p>🛑 <b>Liste vide = aucun examen complet</b>, ce qui est le cas normal
     * d'un candidat qui n'a fait que s'entraîner — l'épreuve reste « À évaluer »,
     * elle ne devient pas basse.
     *
     * @param limit nombre de sessions balayées ; un plafond de lecture, pas un
     *              budget — l'appelant qui cherche un maximum balaie large, et
     *              celui qui n'en garde que trois n'en dépend pas
     */
    public List<EpreuveQualifiante> qualifiantes(UUID userId, EpreuveType epreuve, int limit) {
        final List<Attempt> sessions = attemptManager.findProductionEpreuvesPassees(userId, epreuve, limit);
        // 🛑 Retour anticipé ASSUMÉ : c'est le cas du candidat qui n'a jamais
        // passé d'épreuve, et il ne doit rien payer de plus qu'une requête. Le
        // budget de requêtes se mesure, lui, sur le candidat qui EN a.
        if (sessions.isEmpty()) return List.of();

        final List<UUID> attemptIds = sessions.stream().map(Attempt::getId).toList();
        final Map<UUID, List<ProductionSubmission>> submissionsByAttempt =
                submissionManager.findByAttemptIdsGrouped(attemptIds);
        final Map<UUID, AiEvaluation> latestBySubmission =
                aiEvaluationManager.findLatestBySubmissionIds(
                        submissionsByAttempt.values().stream()
                                .flatMap(List::stream)
                                .map(ProductionSubmission::getId)
                                .toList());

        final List<EpreuveQualifiante> out = new ArrayList<>();
        for (final Attempt a : sessions) {
            final List<ProductionSubmission> submissions =
                    submissionsByAttempt.getOrDefault(a.getId(), List.of());
            // La requête ne rend que des sessions d'examen terminées : les deux
            // drapeaux sont vrais par construction, et les passer explicitement
            // garde l'autorité du niveau au même endroit pour tout le monde.
            final ProductionBilanService.NiveauEpreuve bilan = bilanService.niveauEpreuve(
                    submissions,
                    bilanService.latestEvalsByTache(submissions,
                            id -> Optional.ofNullable(latestBySubmission.get(id))),
                    true, true);
            if (bilan.niveau() == null || a.getFinishedAt() == null) continue;
            out.add(new EpreuveQualifiante(
                    a, a.getFinishedAt(), bilan.niveau(), bilan.competence()));
        }
        return out;
    }
}
