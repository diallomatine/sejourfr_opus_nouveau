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

    /** Le lot ouvert d'une <b>thematique</b> civique. R5, transposee. */
    public Optional<JourneyLot> findOuvertParTheme(UUID journeyId, UUID themeId) {
        return repository.findByJourneyIdAndThemeIdAndStatus(
                journeyId, themeId, JourneyLotStatus.OPEN);
    }

    public List<JourneyLot> findOuverts(UUID journeyId) {
        return repository.findByJourneyIdAndStatus(journeyId, JourneyLotStatus.OPEN);
    }

    /**
     * 🛑 <b>{@code saveAndFlush}, et ce n'est pas une precaution de style.</b>
     * L'ordre d'execution d'Hibernate range <b>tous les INSERT avant tous les
     * UPDATE</b> : fermer un lot puis en creer un autre sur la meme epreuve dans
     * la meme transaction envoyait donc l'INSERT du nouveau <b>avant</b> l'UPDATE
     * qui ferme l'ancien, et l'index unique partiel de R5 refusait la ligne. Le
     * flush retablit l'ordre reel des decisions.
     *
     * <p>Le cout est nul a l'echelle du parcours : un lot par epreuve et par
     * evaluation, jamais un par competence.
     */
    public JourneyLot save(JourneyLot lot) {
        return repository.saveAndFlush(lot);
    }
}
