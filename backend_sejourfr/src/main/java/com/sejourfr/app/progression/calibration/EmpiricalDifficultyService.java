package com.sejourfr.app.progression.calibration;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.DifficultyBand;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.progression.repository.QuestionEmpiricalDifficultyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * La difficulté <b>observée</b> du catalogue (V4.2 §7).
 *
 * <p>🛑 <b>Ce service ne modifie jamais une question.</b> Il lit, il propose, et
 * c'est tout. Un job qui reposerait les bandes tout seul ferait bouger la
 * calibration des séries, donc le poids des preuves, donc des paliers déjà
 * acquis — un candidat verrait un acquis disparaître sans avoir rien fait, et
 * personne ne saurait pourquoi.
 *
 * <p>Le chemin prévu est celui du dépôt partout ailleurs : la console propose,
 * un humain tranche, et si la donnée montre qu'un seuil doit changer, cela
 * devient un {@code progression-config-v2.json} et un replay (§29, §50).
 */
@Service
@RequiredArgsConstructor
public class EmpiricalDifficultyService {

    private final QuestionEmpiricalDifficultyRepository repository;

    /** Le taux de réussite réel des questions d'un périmètre. */
    @Transactional(readOnly = true)
    public List<EmpiricalDifficulty> mesurer(Module module, QuestionType questionType,
                                             Difficulty difficulty) {
        return repository.lireDifficulteEmpirique(
                        module.name(),
                        questionType == null ? null : questionType.name(),
                        difficulty == null ? null : difficulty.name())
                .stream()
                .map(EmpiricalDifficultyService::toMesure)
                .toList();
    }

    /**
     * Les questions dont la bande déclarée contredit ce que les candidats
     * montrent — la seule liste réellement actionnable.
     *
     * <p>Une question taguée HARD que 90 % des candidats réussissent n'est pas
     * un détail : elle fausse la comparabilité de toutes les séries qui la
     * contiennent.
     */
    @Transactional(readOnly = true)
    public List<EmpiricalDifficulty> desaccords(Module module, QuestionType questionType,
                                                Difficulty difficulty) {
        return mesurer(module, questionType, difficulty).stream()
                .filter(EmpiricalDifficulty::enDesaccord)
                .toList();
    }

    /** Les questions non taguées pour lesquelles les données suffisent à proposer. */
    @Transactional(readOnly = true)
    public List<EmpiricalDifficulty> propositions(Module module, QuestionType questionType,
                                                  Difficulty difficulty) {
        return mesurer(module, questionType, difficulty).stream()
                .filter(mesure -> mesure.bandeDeclaree() == null)
                .filter(mesure -> mesure.bandeSuggeree() != null)
                .toList();
    }

    private static EmpiricalDifficulty toMesure(Object[] ligne) {
        return new EmpiricalDifficulty(
                (UUID) ligne[0],
                ((Number) ligne[1]).longValue(),
                ligne[2] == null ? null : ((Number) ligne[2]).doubleValue(),
                ligne[3] == null ? null : DifficultyBand.valueOf((String) ligne[3]));
    }
}
