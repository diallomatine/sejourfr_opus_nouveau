package com.sejourfr.app.manager;

import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.repository.CivicOfficialUnitRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Acces aux <b>16 unites du programme officiel</b> civique.
 *
 * <p>🛑 <b>Aucune ecriture, et c'est le garde-fou 1 de D-38</b> : la table est
 * seedee par migration (V115) et n'est editable par rien. Ce manager n'expose
 * donc ni {@code save} ni {@code delete}, contrairement a ses voisins.
 */
@Component
@RequiredArgsConstructor
public class CivicOfficialUnitManager {

    private final CivicOfficialUnitRepository repository;

    /** Les 16 unites dans l'ordre du programme (thematique, puis annexe I). */
    public List<CivicOfficialUnit> findAllDansLOrdreDuProgramme() {
        return repository.findAllDansLOrdreDuProgramme();
    }
}
