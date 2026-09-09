package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.dto.ProgressionShadowReportDto;
import com.sejourfr.app.progression.dto.ProgressionStateDto;
import com.sejourfr.app.progression.entity.ProgressionPredictionRecord;
import com.sejourfr.app.progression.entity.ProgressionStateRecord;
import com.sejourfr.app.progression.manager.ProgressionPredictionManager;
import com.sejourfr.app.progression.manager.ProgressionStateManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Ce que la console admin a le droit de voir du moteur — <b>et ce qu'elle est la
 * seule à voir</b> (V4.2 §25 bis.2, §47.4).
 *
 * <p>Deux lectures très différentes vivent ici, volontairement côte à côte :
 *
 * <ul>
 *   <li>le <b>rapport shadow</b>, qui porte {@code masteryScore},
 *       {@code confidence} et les compteurs de prédictions. C'est le seul
 *       endroit du produit où ces valeurs sortent du moteur, et c'est ce qui
 *       permettra de décider de la bascule ;</li>
 *   <li>les <b>états servis</b>, qui n'en portent rien. C'est le contrat des
 *       fronts : un état, un libellé, un ton, un pourcentage éventuellement nul.
 *       De quoi afficher, jamais de quoi recalculer.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class ProgressionReportService {

    private final ProgressionConfig config;
    private final ProgressionProperties properties;
    private final ProgressionStateManager stateManager;
    private final ProgressionPredictionManager predictionManager;
    private final ProgressionShadowService shadowService;
    private final ProgressionReadService readService;

    /**
     * §47.4 — les chiffres du go/no-go, <b>avec leur base</b>.
     *
     * <p>Une précision servie sans le nombre de prédictions qui la fondent est
     * une invitation à décider trop tôt : 100 % sur deux cas ne dit rien.
     */
    @Transactional(readOnly = true)
    public ProgressionShadowReportDto rapportShadow() {
        int version = properties.getEngineVersion();
        List<ProgressionPredictionRecord> avecResultat =
                predictionManager.avecResultat(ProgressionStatus.SOLID, version);
        List<ProgressionPredictionRecord> enAttente =
                predictionManager.enAttenteDeResultat(version);
        Optional<Double> precision = shadowService.precisionSolid();
        double objectif = config.shadowValidation().minSolidPrecision();

        int minimum = config.shadowValidation().minOutcomeCount();
        ProgressionShadowReportDto.Verdict verdict =
                verdict(precision, avecResultat.size(), minimum, objectif);

        return new ProgressionShadowReportDto(
                properties.getMode(),
                version,
                precision.orElse(null),
                avecResultat.size(),
                enAttente.size(),
                avecResultat.size() + enAttente.size(),
                objectif,
                minimum,
                verdict,
                List.of(),
                recommandation(verdict, avecResultat.size(), minimum, objectif));
    }

    /**
     * La phrase que la console affiche à côté des chiffres.
     *
     * <p>🛑 Elle ne dit jamais « vous pouvez basculer ». La bascule est une
     * décision produit, et ce texte n'existe que pour empêcher la lecture
     * naïve d'un pourcentage — celle qui ferait passer un moteur en production
     * sur trois prédictions.
     */
    /**
     * Les trois refus et le seul feu vert, distingués.
     *
     * <p>« Aucune donnée » et « échantillon insuffisant » se ressemblent sur un
     * écran, mais n'appellent pas la même chose : l'un dit d'attendre que des
     * candidats passent des examens, l'autre combien il en manque.
     */
    private ProgressionShadowReportDto.Verdict verdict(Optional<Double> precision, int base,
                                                       int minimum, double objectif) {
        if (base == 0) {
            return ProgressionShadowReportDto.Verdict.AUCUNE_DONNEE;
        }
        if (base < minimum || precision.isEmpty()) {
            return ProgressionShadowReportDto.Verdict.ECHANTILLON_INSUFFISANT;
        }
        return precision.get() < objectif
                ? ProgressionShadowReportDto.Verdict.PRECISION_INSUFFISANTE
                : ProgressionShadowReportDto.Verdict.OBJECTIF_ATTEINT;
    }

    private String recommandation(ProgressionShadowReportDto.Verdict verdict, int base,
                                  int minimum, double objectif) {
        return switch (verdict) {
            case AUCUNE_DONNEE -> "Aucune prédiction n'a encore reçu de résultat. "
                    + "Absence de mesure, pas 0 % : rien ne peut être décidé.";
            case ECHANTILLON_INSUFFISANT -> "Échantillon insuffisant : " + base
                    + " issue(s) sur " + minimum + " requises. Aucune précision n'est servie "
                    + "tant que l'effectif n'est pas atteint — un pourcentage sur "
                    + base + " issue(s) serait lu comme une mesure.";
            case PRECISION_INSUFFISANTE -> "Précision sous l'objectif de "
                    + Math.round(objectif * 100) + " % sur " + base + " issues. "
                    + "Ne pas ajuster progression-config-v1.json : analyser les données, "
                    + "créer une v2, incrémenter engineVersion, rejouer.";
            case OBJECTIF_ATTEINT -> "Objectif atteint sur " + base + " issues. "
                    + "La bascule en ACTIVE reste une décision produit.";
        };
    }

    /**
     * Les états d'un candidat, dans la forme <b>servable à un front</b>.
     *
     * <p>Recalculés à la lecture plutôt que lus dans {@code progression_state} :
     * {@code prerequisiteSatisfied} est un dérivé révocable (§18.4), et la
     * projection matérialisée ne le porte pas — délibérément.
     */
    @Transactional(readOnly = true)
    public List<ProgressionStateDto> etatsServis(UUID userId, TargetLevel objectif) {
        Instant maintenant = Instant.now();
        List<ProgressionStateDto> etats = new ArrayList<>();
        for (SkillSection section : List.of(SkillSection.CO, SkillSection.CE)) {
            DomainProjection projection =
                    readService.domaine(userId, section, objectif, maintenant);
            for (TargetLevel niveau : TargetLevel.values()) {
                etats.add(toDto(projection.levels().get(niveau),
                        Boolean.TRUE.equals(projection.prerequisiteSatisfied().get(niveau)),
                        projection.prerequisiteSatisfiedByLevel().get(niveau)));
            }
        }
        return etats;
    }

    /**
     * Les lignes brutes de {@code progression_state} — <b>console admin
     * uniquement</b>. Elles portent {@code masteryScore} et {@code confidence},
     * qui ne sortent jamais vers un front (§25 bis.2).
     */
    @Transactional(readOnly = true)
    public List<ProgressionStateRecord> etatsInternes(UUID userId) {
        List<ProgressionStateRecord> etats =
                new ArrayList<>(stateManager.tousLesEtats(userId, properties.getEngineVersion()));
        etats.sort(Comparator.comparing(ProgressionStateRecord::getStateKey));
        return etats;
    }

    /** Le journal de prédictions d'un candidat, figé à son {@code predictedAt}. */
    @Transactional(readOnly = true)
    public List<ProgressionPredictionRecord> predictions(UUID userId) {
        return predictionManager.pourUtilisateur(userId);
    }

    private ProgressionStateDto toDto(ProgressionSnapshot etat, boolean prerequisSatisfait,
                                      TargetLevel parQui) {
        return new ProgressionStateDto(
                etat.stateKey().asText(),
                etat.stateKey().stateType(),
                etat.status(),
                etat.status().getLabel(),
                etat.status().getTone(),
                etat.visibleProgress(),
                etat.directQualification(),
                prerequisSatisfait,
                parQui == null ? null : parQui.name(),
                etat.levelCycleId());
    }

    /** Les statuts, comptés — pour un coup d'œil sur la population. */
    @Transactional(readOnly = true)
    public Map<ProgressionStatus, Long> repartition(UUID userId) {
        Map<ProgressionStatus, Long> compte = new EnumMap<>(ProgressionStatus.class);
        for (ProgressionStateRecord etat : etatsInternes(userId)) {
            compte.merge(etat.getStatus(), 1L, Long::sum);
        }
        return compte;
    }
}
