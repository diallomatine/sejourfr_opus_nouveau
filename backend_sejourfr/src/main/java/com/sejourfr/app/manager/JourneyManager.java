package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.repository.JourneyAssessmentEventRepository;
import com.sejourfr.app.repository.JourneyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;
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

    public Optional<Journey> find(UUID userId, TargetLevel targetLevel) {
        return repository.findByUserIdAndTargetLevel(userId, targetLevel);
    }

    /** Le parcours <b>verrouille</b> pour ecriture : toute modification passe par la (R14). */
    public Optional<Journey> findForUpdate(UUID journeyId) {
        return repository.findByIdForUpdate(journeyId);
    }

    public Journey save(Journey journey) {
        return repository.save(journey);
    }

    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserId(userId);
    }

    public boolean dejaTraitee(UUID journeyId, UUID sourceAssessmentId) {
        return eventRepository.existsByJourneyIdAndSourceAssessmentId(journeyId, sourceAssessmentId);
    }

    /** La derniere evaluation deja traitee de cette epreuve, s'il y en a une (R14). */
    public Optional<Instant> derniereMesure(UUID journeyId, EpreuveType examType) {
        return eventRepository.findDerniereMesureDeLEpreuve(journeyId, examType);
    }

    public JourneyAssessmentEvent enregistrer(JourneyAssessmentEvent event) {
        return eventRepository.save(event);
    }
}
