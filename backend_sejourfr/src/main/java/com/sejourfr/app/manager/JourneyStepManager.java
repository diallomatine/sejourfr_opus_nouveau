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
     * Les competences des etapes d'entrainement encore ouvertes, <b>dans l'ordre
     * de la file</b> — la « premiere place » que le freemium ouvre d'office.
     * <b>Une requete.</b>
     *
     * <p>{@link #COMPETENCES_OUVERTES_LUES} lignes au plus : l'appelant garde la
     * premiere qui est dans son pool, et un parcours n'a jamais des dizaines
     * d'etapes d'entrainement ouvertes d'affilee sans contenu.
     */
    public List<Skill> findCompetencesOuvertes(UUID userId, TargetLevel targetLevel) {
        return repository.findCompetencesOuvertes(
                userId, targetLevel, PageRequest.of(0, COMPETENCES_OUVERTES_LUES));
    }

    /**
     * Combien d'etapes d'entrainement ouvertes on lit pour trouver la premiere
     * place. Un plafond, pas un budget : la <b>premiere</b> dans le pool gagne,
     * et depasser ce plafond voudrait dire que le pool du Plan a ecarte douze
     * competences d'affilee — un catalogue vide, pas un parcours.
     */
    static final int COMPETENCES_OUVERTES_LUES = 12;
}
