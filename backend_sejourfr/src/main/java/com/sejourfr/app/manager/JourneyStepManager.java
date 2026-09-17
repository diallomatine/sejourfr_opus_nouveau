package com.sejourfr.app.manager;

import com.sejourfr.app.entity.JourneyStep;
import java.util.Optional;
import org.springframework.data.domain.PageRequest;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.repository.JourneyStepRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class JourneyStepManager {

    private final JourneyStepRepository repository;

    /**
     * <b>Toutes</b> les etapes du parcours, dans l'ordre de la file, competence
     * et lot charges. Une requete, quelle que soit la taille du parcours.
     */
    public List<JourneyStep> findAll(UUID journeyId) {
        return repository.findAllByJourney(journeyId);
    }

    /** Les etapes encore ouvertes d'un lot (R7). */
    public List<JourneyStep> findOuvertesDuLot(UUID lotId) {
        return repository.findOuvertesByLot(lotId);
    }

    public JourneyStep save(JourneyStep step) {
        return repository.save(step);
    }

    public List<JourneyStep> saveAll(List<JourneyStep> steps) {
        return repository.saveAll(steps);
    }

    /**
     * La competence de la premiere etape d'entrainement encore ouverte — la
     * « premiere place » que le freemium ouvre d'office. <b>Une requete.</b>
     */
    public Optional<Skill> findPremiereCompetenceOuverte(UUID userId, TargetLevel targetLevel) {
        return repository
                .findPremiereCompetenceOuverte(userId, targetLevel, PageRequest.of(0, 1))
                .stream()
                .findFirst();
    }
}
