package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.manager.CivicOfficialUnitManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.util.StatutObservation;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Ce qu'une session civique terminee apprend, par UNITE OFFICIELLE</b> —
 * le pendant civique de {@link ComprehensionObservationService}, et le coeur de
 * <b>D-49</b>.
 *
 * <h2>🛑 Deux autorites, deux questions (D-49)</h2>
 * <p>L'<b>observation</b> ecrite ici dit « <b>cette unite a ete travaillee, et
 * voila ce que la mesure en dit</b> » : c'est elle qui <b>clot l'etape du
 * cycle</b>. {@code CivicLeitnerResolver} dit tout autre chose — « <b>ou en est
 * cette notion aujourd'hui</b> », avec l'oubli qui reprend. Les deux coexistent
 * <b>sans arbitrage entre elles</b> : elles ne repondent pas a la meme question,
 * et aucune ne corrige l'autre.
 *
 * <h2>🛑 Le grain est l'UNITE, jamais la notion (D-48)</h2>
 * <p>Une observation civique porte {@code official_unit_id} et <b>aucun</b>
 * {@code skill_id} — {@code chk_learning_plan_observation_unite} (V070) l'impose.
 * Le plan derive, lui, continue de travailler au grain de la <b>notion</b> :
 * c'est le meme corpus lu par deux axes, et ce n'est pas une contradiction.
 *
 * <h2>🛑 Le seuil est LU chez son autorite</h2>
 * <p>{@code learning-plan.comprehension.solid-ratio} (0,80) et
 * {@code min-questions} : les memes que la comprehension TCF, via
 * {@link StatutObservation}. <b>Aucun 9e seuil n'est declare ici</b> — c'est le
 * raisonnement de D-16 et de D-44.
 *
 * <h2>Best-effort</h2>
 * <p>{@link Propagation#REQUIRES_NEW}, comme le pendant TCF : l'ecriture vit
 * dans sa <b>propre</b> transaction, pour qu'une contrainte violee ne marque
 * jamais {@code rollback-only} la correction du QCM du candidat.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class CivicObservationService {

    private final LearningPlanProperties properties;
    private final LearningPlanObservationManager observationManager;
    private final CivicOfficialUnitManager unitManager;
    private final UserManager userManager;

    /**
     * Une reponse elementaire, reduite a ce qui decide de son rattachement.
     *
     * <p><b>Valeurs, pas entites</b> : l'appelant les extrait dans SA
     * transaction, et rien de detache ne traverse la frontiere
     * {@code REQUIRES_NEW}.
     *
     * @param uniteId  l'unite officielle dont releve la question, resolue par
     *                 {@code CivicExamCompositionService.uniteOfficielle} — son
     *                 <b>unique</b> autorite. {@code null} = <b>hors
     *                 programme</b> (connaissance non taguee, mise en situation
     *                 hors Principes / Droits) : la reponse n'apprend rien sur
     *                 aucune unite, et ne compte nulle part.
     * @param answered 🛑 <b>Une question laissee vide n'est pas une reponse
     *                 fausse</b> : ni au numerateur, ni au denominateur, ni dans
     *                 le plancher {@code min-questions}.
     */
    public record ReponseCivique(UUID uniteId, boolean answered, boolean correct) {}

    /**
     * Enregistre ce qu'une session civique terminee apprend, unite par unite.
     *
     * @param source {@code CIVIQUE_SERIE} ou {@code CIVIQUE_EXAMEN} — 🛑 la
     *               distinction est <b>opposable</b> : {@code JourneyEvaluationFilter}
     *               en deduit qu'une serie <b>n'evalue pas</b> (R3), donc
     *               qu'elle n'alimente jamais le cycle en attente.
     * @return les <b>unites que cette session concerne</b>, y compris celles
     *         dont l'observation existait deja : le rejeu d'une session ne doit
     *         pas faire <b>disparaitre</b> ce qu'elle a enseigne. C'est ce que
     *         le parcours lit pour faire avancer ses etapes.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Set<UUID> record(
            UUID userId,
            UUID attemptId,
            LearningPlanSourceType source,
            Instant observedAt,
            List<ReponseCivique> reponses) {

        if (userId == null || attemptId == null || reponses == null || reponses.isEmpty()) {
            return Set.of();
        }
        if (source == null || !source.isCivique()) {
            // 🛑 Un appel avec une source TCF n'est pas une donnee, c'est un
            // BRANCHEMENT FAUX : le laisser passer ecrirait une observation
            // civique sous une source de comprehension, et le filtre R3 dirait
            // n'importe quoi. Meme raison que `SkillMasteryEngine` qui leve (A50).
            throw new IllegalArgumentException(
                    "Une observation civique porte une source civique : " + source);
        }

        Map<UUID, Compte> parUnite = ventile(reponses);
        // Zero requete supplementaire quand rien n'est rattachable au programme.
        if (parUnite.isEmpty()) return Set.of();

        Optional<User> user = userManager.findById(userId);
        if (user.isEmpty()) return Set.of();

        Map<UUID, CivicOfficialUnit> unites = unitManager.findAllDansLOrdreDuProgramme().stream()
                .collect(LinkedHashMap::new,
                        (map, unite) -> map.put(unite.getId(), unite),
                        LinkedHashMap::putAll);

        Instant quand = observedAt == null ? Instant.now() : observedAt;
        Set<UUID> concernees = new LinkedHashSet<>();
        int ecrites = 0;
        for (Map.Entry<UUID, Compte> entree : parUnite.entrySet()) {
            CivicOfficialUnit unite = unites.get(entree.getKey());
            if (unite == null) continue;
            concernees.add(unite.getId());
            if (ecrire(user.get(), unite, entree.getValue(), source, attemptId, quand)) {
                ecrites++;
            }
        }
        log.debug("Session civique {} : {} observation(s) ecrite(s) sur {} unite(s).",
                attemptId, ecrites, concernees.size());
        return concernees;
    }

    // ------------------------------------------------------------------------
    // Interne
    // ------------------------------------------------------------------------

    private static Map<UUID, Compte> ventile(List<ReponseCivique> reponses) {
        Map<UUID, Compte> parUnite = new LinkedHashMap<>();
        for (ReponseCivique reponse : reponses) {
            // Une question JAMAIS REPONDUE n'apprend rien : ni bonne, ni
            // mauvaise, ni comptee. Une serie entierement vide ne produit donc
            // AUCUNE observation -- ni fausse fragilite, ni faux « insuffisant ».
            if (!reponse.answered() || reponse.uniteId() == null) continue;
            parUnite.computeIfAbsent(reponse.uniteId(), cle -> new Compte())
                    .ajouter(reponse.correct());
        }
        return parUnite;
    }

    private boolean ecrire(
            User user, CivicOfficialUnit unite, Compte compte,
            LearningPlanSourceType source, UUID attemptId, Instant quand) {

        if (observationManager.findBySourceEtUnite(
                user.getId(), unite.getId(), source, attemptId).isPresent()) {
            return false;
        }
        LearningPlanProperties.Comprehension config = properties.getComprehension();
        boolean fiable = compte.total >= config.getMinQuestions();

        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setUser(user);
        // 🛑 JAMAIS `setSkill` : `chk_learning_plan_observation_unite` (V070)
        // exige exactement un des deux, et une unite officielle n'est pas une
        // competence TCF.
        observation.setOfficialUnit(unite);
        observation.setSourceType(source);
        observation.setSourceId(attemptId);
        // Le SUJET d'une session civique, c'est la SESSION : deux series tirent
        // des questions differentes, ce sont deux preuves independantes. Une
        // meme session relue garde son identite -- c'est l'idempotence (R14).
        observation.setSubjectId(attemptId);
        observation.setObserved(fiable);
        // 🛑 Sous le plancher de questions : NOT_OBSERVED. Une serie trop courte
        // compte comme serie TERMINEE (R2), jamais comme serie REUSSIE -- c'est
        // la regle TCF, transposee sans ecart.
        observation.setStatus(fiable
                ? StatutObservation.selonRatio(compte.ratio(), config)
                : LearningPlanSkillStatus.NOT_OBSERVED);
        // `chk_learning_plan_observation_coherence` : pas de preuve sans mesure.
        observation.setEvidence(fiable
                ? compte.correctes + " / " + compte.total + " bonnes réponses" : null);
        observation.setConfidence(fiable
                ? (compte.total >= config.getHighConfidenceQuestions()
                        ? ObservationConfidence.HIGH : ObservationConfidence.MEDIUM)
                : ObservationConfidence.LOW);
        // La baseline, c'est le diagnostic initial et lui seul.
        observation.setBaseline(false);
        observation.setObservedAt(quand);
        try {
            observationManager.save(observation);
            return true;
        } catch (DataIntegrityViolationException doublonConcurrent) {
            // uq_learning_plan_observation_source_unite : deux clotures
            // concurrentes de la meme session aboutissent au meme signal.
            return false;
        }
    }

    /** Le compte d'une unite sur une session : rien d'autre n'est persiste. */
    private static final class Compte {
        private int total;
        private int correctes;

        void ajouter(boolean correcte) {
            total++;
            if (correcte) correctes++;
        }

        double ratio() {
            return total == 0 ? 0 : (double) correctes / total;
        }
    }
}
