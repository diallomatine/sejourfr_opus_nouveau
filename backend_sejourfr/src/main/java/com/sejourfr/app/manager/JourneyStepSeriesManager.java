package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.JourneyStepSeries;
import com.sejourfr.app.repository.JourneyStepSeriesRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * L'agregat « essais de serie d'une etape » (V072). Seule couche autorisee a
 * toucher {@link JourneyStepSeriesRepository}.
 */
@Component
@RequiredArgsConstructor
public class JourneyStepSeriesManager {

    private final JourneyStepSeriesRepository repository;

    /**
     * Les essais de ces etapes, attempt charge, ordonnes par carte puis par
     * date. <b>Une requete</b>, quel que soit le nombre d'etapes.
     *
     * <p>Une liste vide ne coute <b>aucune</b> requete : {@code IN ()} n'est pas
     * du SQL valide partout, et un parcours sans etape de serie n'a rien a lire.
     */
    public List<JourneyStepSeries> findDesEtapes(Collection<UUID> stepIds) {
        if (stepIds == null || stepIds.isEmpty()) return List.of();
        return repository.findDesEtapes(stepIds);
    }

    /** Rattache un attempt a une carte. Une ligne par ESSAI : rien n'est ecrase. */
    public JourneyStepSeries lier(JourneyStep step, int index, Attempt attempt) {
        JourneyStepSeries lien = new JourneyStepSeries();
        lien.setStep(step);
        lien.setSeriesIndex((short) index);
        lien.setAttempt(attempt);
        return repository.save(lien);
    }

    /** Cette session a-t-elle ete lancee depuis une carte d'etape ? */
    public boolean lieAUneEtape(UUID attemptId) {
        return repository.existsByAttemptId(attemptId);
    }
}
