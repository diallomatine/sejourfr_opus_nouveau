package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyExamResultDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.service.EpreuvesProductionQualifiantesResolver;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * <b>Ce qu'ont donne les examens qui ont clos les etapes d'un cycle</b> — lu
 * par la consultation d'un cycle clos (« Mes cycles », 2026-09-27).
 *
 * <h2>🛑 Ce composant ne calcule aucun niveau</h2>
 * <p>Il retrouve l'examen qui a clos chaque etape
 * ({@code journey_step.resolved_by_assessment_id}, persiste a la cloture) et
 * demande son resultat a l'<b>autorite</b> de cet examen :
 * <ul>
 *   <li>comprehension (CO/CE) : {@code TcfLevelEstimatorService.niveauxQcm},
 *       la meme lecture que les ecrans de progression — une requete ;</li>
 *   <li>expression (EE/EO) :
 *       {@code EpreuvesProductionQualifiantesResolver.niveauxDesSessions}, la
 *       meme evaluation par session que le niveau actuel d'une epreuve ;</li>
 *   <li>theme civique : {@code attempts.score} / {@code max_score}, lus tels
 *       quels.</li>
 * </ul>
 *
 * <p>🛑 <b>{@code null} = inconnu, jamais mauvais.</b> Une etape close par un
 * diagnostic (son identifiant n'est pas une tentative), par l'examen d'un autre
 * axe (l'examen complet de 40 questions ferme les cinq thematiques d'un coup —
 * son score n'est celui d'aucune) ou par une evaluation sans rien d'exploitable
 * n'a <b>aucun</b> resultat : l'ecran dit « Passé », sans niveau.
 *
 * <p>🛑 <b>Isolation</b> : seules les tentatives <b>du candidat</b> sont lues
 * ({@code AttemptManager.findAllOwnedBy}).
 */
@Component
@RequiredArgsConstructor
public class JourneyExamResultReader {

    private final AttemptManager attemptManager;
    private final TcfLevelEstimatorService levelEstimator;
    private final EpreuvesProductionQualifiantesResolver qualifiantes;

    /** Les resultats par <b>etape</b>. Une etape sans resultat est absente. */
    public Map<UUID, JourneyExamResultDto> lire(UUID userId, List<JourneyStep> etapes) {
        List<JourneyStep> examens = etapes.stream()
                .filter(step -> step.getType() == JourneyStepType.SECTION_EXAM)
                .filter(step -> !step.estOuverte())
                .filter(step -> step.getResolvedByAssessmentId() != null)
                .toList();
        if (examens.isEmpty()) return Map.of();

        Set<UUID> ids = examens.stream()
                .map(JourneyStep::getResolvedByAssessmentId)
                .collect(Collectors.toCollection(java.util.LinkedHashSet::new));
        Map<UUID, Attempt> tentatives = attemptManager.findAllOwnedBy(userId, ids);
        if (tentatives.isEmpty()) return Map.of();

        List<UUID> qcm = tentatives.values().stream()
                .filter(a -> a.getEpreuve() == EpreuveType.TCF_CO
                        || a.getEpreuve() == EpreuveType.TCF_CE)
                .map(Attempt::getId)
                .toList();
        List<Attempt> productions = tentatives.values().stream()
                .filter(a -> a.getEpreuve() == EpreuveType.TCF_EE
                        || a.getEpreuve() == EpreuveType.TCF_EO)
                .toList();
        Map<UUID, NiveauCecrl> niveauxQcm =
                qcm.isEmpty() ? Map.of() : levelEstimator.niveauxQcm(qcm);
        Map<UUID, NiveauCecrl> niveauxProduction =
                qualifiantes.niveauxDesSessions(productions);

        Map<UUID, JourneyExamResultDto> out = new LinkedHashMap<>();
        for (JourneyStep step : examens) {
            Attempt tentative = tentatives.get(step.getResolvedByAssessmentId());
            if (tentative == null) continue;
            JourneyExamResultDto resultat =
                    resultat(step, tentative, niveauxQcm, niveauxProduction);
            if (resultat != null) out.put(step.getId(), resultat);
        }
        return out;
    }

    private JourneyExamResultDto resultat(
            JourneyStep step, Attempt tentative,
            Map<UUID, NiveauCecrl> niveauxQcm, Map<UUID, NiveauCecrl> niveauxProduction) {
        EpreuveType epreuve = step.getExamType();
        if (epreuve != null) {
            // 🛑 L'examen doit porter l'EPREUVE de l'etape : le parent d'un
            // examen complet (TCF_COMPLET) n'a pas le niveau d'une epreuve.
            if (tentative.getEpreuve() != epreuve) return null;
            NiveauCecrl niveau = switch (epreuve) {
                case TCF_CO, TCF_CE -> niveauxQcm.get(tentative.getId());
                case TCF_EE, TCF_EO -> niveauxProduction.get(tentative.getId());
                default -> null;
            };
            // Meme plafond d'affichage que tous les niveaux d'epreuve servis.
            return niveau == null
                    ? null
                    : new JourneyExamResultDto(levelEstimator.capB2(niveau), null, null);
        }
        if (step.getTheme() != null) {
            // 🛑 Seul un examen DE CE THEME dit quelque chose du theme : le score
            // d'un examen global de 40 questions n'est celui d'aucune thematique.
            if (tentative.getModule() != Module.CIVIQUE
                    || !step.getTheme().getId().equals(tentative.getLotThemeId())
                    || tentative.getScore() == null
                    || tentative.getMaxScore() == null) {
                return null;
            }
            return new JourneyExamResultDto(null, tentative.getScore(), tentative.getMaxScore());
        }
        return null;
    }
}
