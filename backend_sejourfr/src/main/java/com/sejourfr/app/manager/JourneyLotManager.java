package com.sejourfr.app.manager;

import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.repository.JourneyLotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class JourneyLotManager {

    private final JourneyLotRepository repository;

    /** Le lot ouvert d'une epreuve. R5 garantit qu'il n'y en a jamais deux. */
    public Optional<JourneyLot> findOuvert(UUID journeyId, EpreuveType examType) {
        return repository.findByJourneyIdAndExamTypeAndStatus(
                journeyId, examType, JourneyLotStatus.OPEN);
    }

    public List<JourneyLot> findOuverts(UUID journeyId) {
        return repository.findByJourneyIdAndStatus(journeyId, JourneyLotStatus.OPEN);
    }

    public JourneyLot save(JourneyLot lot) {
        return repository.save(lot);
    }
}
