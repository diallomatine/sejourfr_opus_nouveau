package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.enums.EpreuveType;
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
