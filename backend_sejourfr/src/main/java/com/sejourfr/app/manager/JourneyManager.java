package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.JourneyAssessmentEventRepository;
import com.sejourfr.app.repository.JourneyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Le parcours et son <b>journal d'evaluations</b>.
 *
 * <p>Les deux vivent dans le meme manager parce qu'ils sont le meme agregat :
 * le journal ne se lit jamais sans son parcours, et personne d'autre ne le lit.
 */
@Component
@RequiredArgsConstructor
public class JourneyManager {

    private final JourneyRepository repository;
    private final JourneyAssessmentEventRepository eventRepository;

    /** Le cycle du candidat sur ce module, dans cet etat (D-13). */
    public Optional<Journey> find(UUID userId, Module module, JourneyStatus status) {
        return repository.findByUserIdAndModuleAndStatus(userId, module, status);
    }

    /**
     * Un cycle <b>de ce candidat</b>, ou rien. 🛑 L'identifiant d'un cycle d'un
     * tiers rend {@code empty} — l'appelant repond 404, jamais 403 (confirmer
     * l'existence d'un cycle serait deja une fuite).
     */
    public Optional<Journey> findDuCandidat(UUID journeyId, UUID userId) {
        return repository.findByIdAndUserId(journeyId, userId);
    }

    /**
     * <b>Serialise la creation du cycle</b> de ce candidat sur ce module,
     * jusqu'a la fin de la transaction courante (D-69). Le second appelant
     * attend, puis relit le cycle que le premier vient de creer.
     */
    public void verrouillerLaCreation(UUID userId, Module module) {
        repository.verrouillerLaCreation("journey:" + userId + ":" + module.name());
    }

    /** Le parcours <b>verrouille</b> pour ecriture : toute modification passe par la (R14). */
    public Optional<Journey> findForUpdate(UUID journeyId) {
        return repository.findByIdForUpdate(journeyId);
    }

    /**
     * Combien de cycles ce candidat a <b>derriere</b> lui sur ce module — le
     * rang du cycle courant vaut ce nombre plus un.
     *
     * <p>🛑 <b>Compte, jamais persiste</b> : un compteur sur {@code journey}
     * aurait pu diverger de l'historique reel, et c'est l'historique que la page
     * Progression lira.
     */
    public int compterHistorises(UUID userId, Module module) {
        return (int) repository.countByUserIdAndModuleAndStatus(
                userId, module, JourneyStatus.HISTORISE);
    }

    /**
     * Les cycles du module qui se <b>racontent</b> — l'historique et le cycle en
     * cours —, par ordre chronologique de creation. Le cycle {@code EN_ATTENTE}
     * est exclu <b>en base</b> : il est invisible du candidat (D-13).
     */
    public List<Journey> racontables(UUID userId, Module module) {
        return repository.findRacontables(userId, module);
    }

    /**
     * Les cycles <b>historises</b> du module, par ordre de creation, chacun avec
     * son nombre d'etapes d'entrainement non obsoletes. Une requete (D-68).
     */
    public List<CycleClos> cyclesClos(UUID userId, Module module) {
        return repository.findCyclesClos(userId, module).stream()
                .map(ligne -> new CycleClos(
                        ligne.getId(), ligne.getFinDeCycle(), ligne.getCompetences()))
                .toList();
    }

    /**
     * Un cycle clos, vu par le jalon d'examen complet : son geste de cloture et
     * son nombre d'etapes d'entrainement (obsoletes exclues).
     */
    public record CycleClos(UUID id, JourneyFinDeCycle finDeCycle, long competences) {}

    public Journey save(Journey journey) {
        return repository.save(journey);
    }

    /**
     * 🛑 <b>{@code saveAndFlush}, et ce n'est pas une precaution de style</b> —
     * meme piege que {@code JourneyLotManager.save}. L'ordre d'execution
     * d'Hibernate range <b>tous les INSERT avant tous les UPDATE</b> :
     * historiser un cycle puis promouvoir le suivant dans la meme transaction
     * envoyait l'UPDATE du promu <b>avant</b> celui qui libere la place, et
     * l'index unique partiel {@code uq_journey_en_cours} refusait la ligne. Le
     * flush retablit l'ordre reel des decisions.
     *
     * <p>Reserve aux <b>transitions de cycle</b> : une ecriture ordinaire n'a
     * pas besoin de ce cout.
     */
    public Journey saveEtFlush(Journey journey) {
        return repository.saveAndFlush(journey);
    }

    /**
     * Les parcours de {@code ids} qui existent (ingestion d'analytics : un
     * {@code journeyId} cite par un evenement doit exister). Une requete.
     */
    public Set<UUID> existingIds(Collection<UUID> ids) {
        if (ids == null || ids.isEmpty()) return Set.of();
        return new HashSet<>(repository.findExistingIds(ids));
    }

    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserId(userId);
    }

    /**
     * « Ce candidat a-t-il deja fait traiter cette evaluation ? » — R14, pose au
     * <b>candidat</b> et non au cycle (cf. le javadoc du repository : depuis
     * D-13 il en porte plusieurs).
     */
    /**
     * Le score du dernier examen civique complet de ce cycle, ou {@code null}.
     * 🛑 <b>Inconnu, jamais zero</b> : un cycle de travail n'a pas de score.
     */
    public Short dernierScoreDExamenComplet(UUID journeyId) {
        Integer score = eventRepository.dernierScoreDExamenComplet(journeyId);
        return score == null ? null : score.shortValue();
    }

    /**
     * Ce cycle a-t-il ete amorce par le diagnostic rapide ? — cf.
     * {@code JourneyAssessmentEventRepository.amorceParLeDiagnosticRapide}.
     */
    public boolean amorceParLeDiagnosticRapide(UUID journeyId) {
        return eventRepository.amorceParLeDiagnosticRapide(journeyId);
    }

    /** Ce cycle a-t-il journalise un diagnostic rapide ? (rattrapage D-69) */
    public boolean journaliseUnDiagnosticRapide(UUID journeyId) {
        return eventRepository.journaliseUnDiagnosticRapide(journeyId);
    }

    public boolean dejaTraitee(UUID userId, Module module, UUID sourceAssessmentId) {
        return eventRepository.dejaTraiteeParUnCycle(userId, module, sourceAssessmentId);
    }

    /** La derniere evaluation deja traitee de cette epreuve, s'il y en a une (R14). */
    public Optional<Instant> derniereMesure(UUID userId, Module module, EpreuveType examType) {
        return eventRepository.findDerniereMesureDeLEpreuve(userId, module, examType);
    }

    public JourneyAssessmentEvent enregistrer(JourneyAssessmentEvent event) {
        return eventRepository.save(event);
    }
}
