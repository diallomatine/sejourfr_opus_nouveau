package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.PartialPractice;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateKey;
import com.sejourfr.app.progression.engine.ProgressionEngine;
import com.sejourfr.app.progression.entity.LearningEvidenceRecord;
import com.sejourfr.app.progression.manager.LearningEvidenceManager;
import com.sejourfr.app.progression.manager.ProgressionFamilyAggregateManager;
import com.sejourfr.app.progression.manager.ProgressionStateManager;
import com.sejourfr.app.progression.mapper.LearningEvidenceMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Le chemin d'écriture du moteur</b> : une preuve arrive, l'état se recalcule
 * (V4.2 §28).
 *
 * <p>🛑 <b>Aucune preuve n'est refusée à cause de son point d'entrée.</b> Une
 * activité lancée depuis « Réviser », depuis un lien profond ou depuis le Plan
 * produit exactement la même preuve (§1, invariant I1, T24). Le champ
 * {@code entryPoint} n'existe que pour l'observabilité.
 *
 * <h2>Sur le coût de recalcul</h2>
 *
 * <p>§28 décrit une mise à jour O(1). Les accumulateurs le sont bien : ils
 * s'additionnent sans relire quoi que ce soit. Mais trois sorties dépendent
 * réellement de l'historique — les hystérésis, le passage {@code SOLID → WATCH}
 * et la monotonie de {@code visibleProgress}. On relit donc l'historique
 * <b>de la seule clé touchée</b> et on rejoue le moteur dessus.
 *
 * <p>C'est un écart assumé à la lettre de §28, pour tenir une règle qui compte
 * davantage : <i>une règle, une autorité</i>. Dupliquer la machine à états dans
 * un chemin incrémental garantirait qu'un jour les deux divergent — et c'est le
 * défaut le plus cher du dépôt. La lecture est bornée (quelques dizaines de
 * lignes, indexées par {@code user + section + level}) et le chemin n'est pas
 * chaud : une preuve par activité terminée.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProgressionIngestionService {

    private final ProgressionEngine engine;
    private final LearningEvidenceManager evidenceManager;
    private final ProgressionStateManager stateManager;
    private final ProgressionFamilyAggregateManager familyAggregateManager;
    private final LearningEvidenceMapper mapper;
    private final ProgressionProperties properties;
    private final ProgressionShadowService shadowService;
    private final ProgressionExplanationService explanationService;

    /**
     * Enregistre une preuve et reprojette son état.
     *
     * @return l'état recalculé, ou vide si la preuve était un doublon (§42)
     */
    @Transactional
    public Optional<ProgressionSnapshot> ingerer(LearningEvidence evidence) {
        Instant occurredAt = evidence.occurredAt();
        if (occurredAt.isAfter(Instant.now().plusSeconds(300))) {
            // §5 : un occurredAt impossible dans le futur ne doit jamais être
            // accepté en silence. Cinq minutes de tolérance pour les horloges
            // de téléphone mal réglées, pas davantage.
            throw new IllegalArgumentException(
                    "occurredAt dans le futur : " + occurredAt);
        }

        LearningEvidenceRecord record = mapper.toEntity(evidence);
        Optional<LearningEvidenceRecord> enregistree =
                evidenceManager.enregistrerSiNouvelle(record);
        if (enregistree.isEmpty()) {
            return Optional.empty();
        }

        ProgressionSnapshot etat = reprojeter(evidence.userId(), evidence.stateKey(), Instant.now());
        shadowService.consignerSiTransitionNotable(evidence.userId(), etat, evidence.section());
        return Optional.of(etat);
    }

    /**
     * §23.1 — une activité laissée en cours : des points de parcours au prorata,
     * <b>aucune preuve de maîtrise</b>.
     *
     * <p>Abandonner une série n'est pas se tromper. Le candidat a travaillé
     * douze questions ; les compter comme douze échecs serait faux, et ne rien
     * compter du tout serait décourageant.
     */
    @Transactional
    public ProgressionSnapshot ingererPratiquePartielle(UUID userId, PartialPractice partielle) {
        return reprojeterAvecPartielles(userId, partielle.stateKey(),
                List.of(partielle), Instant.now());
    }

    /** Reprojette un état depuis son historique complet. */
    @Transactional
    public ProgressionSnapshot reprojeter(UUID userId, ProgressionStateKey stateKey, Instant now) {
        return reprojeterAvecPartielles(userId, stateKey, List.of(), now);
    }

    private ProgressionSnapshot reprojeterAvecPartielles(UUID userId, ProgressionStateKey stateKey,
                                                         List<PartialPractice> partielles,
                                                         Instant now) {
        List<LearningEvidence> historique = historiqueDe(userId, stateKey);
        ProgressionSnapshot etat = engine.project(stateKey, historique, partielles, now);

        Instant derniere = historique.stream()
                .map(LearningEvidence::occurredAt)
                .max(Instant::compareTo)
                .orElse(null);
        stateManager.enregistrer(userId, properties.getEngineVersion(), etat, derniere);
        // §27.3 — la ventilation MICRO / NON_MICRO, écrite en même temps que
        // l'état. C'est elle qui rend le cap micro (§11.1) auditable après coup :
        // sans elle on lit une masse totale sans savoir ce qui l'a remplie.
        familyAggregateManager.enregistrer(userId, properties.getEngineVersion(), etat);
        // §46 — « pourquoi cette recommandation ? » doit avoir une réponse sans
        // rejouer le moteur à la main : la confiance aura bougé entre-temps, et
        // on ne retrouverait jamais l'état qui a produit la décision.
        explanationService.tracer(userId, etat,
                explanationService.raisonIsolee(etat), properties.getEngineVersion());
        return etat;
    }

    /**
     * L'historique de la clé — et pour un palier réceptif, celui de tout le
     * domaine.
     *
     * <p>Le moteur filtre lui-même sur la clé exacte. On lui donne le domaine
     * entier parce que c'est un seul index à parcourir, et parce que c'est ce
     * dont la projection de domaine a besoin juste après.
     */
    private List<LearningEvidence> historiqueDe(UUID userId, ProgressionStateKey stateKey) {
        List<LearningEvidenceRecord> lignes = stateKey.skillId() == null
                ? evidenceManager.historiqueDomaine(userId, stateKey.section())
                : evidenceManager.historiqueCompetence(
                        userId, stateKey.section(), stateKey.skillId());
        return mapper.toDomain(lignes);
    }

    /**
     * §29 — le replay complet d'un candidat sur la version courante du moteur.
     *
     * <p>Réservé aux changements d'{@code engineVersion}, aux corrections de
     * données et aux audits. Il repart d'une projection vide : c'est la seule
     * façon de garantir qu'aucun reste d'un calcul précédent ne survit.
     */
    @Transactional
    public int rejouer(UUID userId, Instant now) {
        int engineVersion = properties.getEngineVersion();
        stateManager.purgerVersion(userId, engineVersion);
        familyAggregateManager.purgerVersion(userId, engineVersion);

        List<LearningEvidence> tout = mapper.toDomain(evidenceManager.historiqueComplet(userId));
        List<ProgressionStateKey> cles = tout.stream()
                .map(LearningEvidence::stateKey)
                .distinct()
                .toList();
        for (ProgressionStateKey cle : cles) {
            ProgressionSnapshot etat = engine.project(cle, tout, List.of(), now);
            Instant derniere = tout.stream()
                    .filter(e -> e.stateKey().equals(cle))
                    .map(LearningEvidence::occurredAt)
                    .max(Instant::compareTo)
                    .orElse(null);
            stateManager.enregistrer(userId, engineVersion, etat, derniere);
            familyAggregateManager.enregistrer(userId, engineVersion, etat);
        }
        log.info("Progression : replay user={} version={} — {} clés reconstruites",
                userId, engineVersion, cles.size());
        return cles.size();
    }

    /** Les deux domaines réceptifs, pour les recalculs de projection. */
    static List<SkillSection> domainesReceptifs() {
        return List.of(SkillSection.CO, SkillSection.CE);
    }
}
