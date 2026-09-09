package com.sejourfr.app.progression;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateKey;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.domain.RecommendationReasonCode;
import com.sejourfr.app.progression.service.ProgressionExplanationService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.EnumMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * §46 — pourquoi le Plan a dit ça. L'<b>ordre</b> des cas est la règle, pas un
 * détail d'implémentation.
 */
class ProgressionExplanationServiceTest {

    private final ProgressionExplanationService service = new ProgressionExplanationService();

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>Un palier en {@code WATCH} est <b>aussi</b> satisfait par prérequis
     * dans ce cas de figure. Si l'ordre s'inversait, le Plan expliquerait
     * « validé via B1 » à un candidat à qui il demande justement de vérifier B1 —
     * et personne ne comprendrait l'écran.
     */
    @Test
    @DisplayName("Une vérification en attente passe avant toute autre explication")
    void watchPasseDevant() {
        DomainProjection projection = projection(
                Map.of(TargetLevel.A2, ProgressionStatus.WATCH),
                Map.of(TargetLevel.A2, true));

        assertThat(service.raison(projection, TargetLevel.A2))
                .isEqualTo(RecommendationReasonCode.WATCH_RECHECK);
    }

    @Test
    @DisplayName("Un palier satisfait par le dessus ne se retravaille pas")
    void satisfaitParLeDessus() {
        DomainProjection projection = projection(
                Map.of(TargetLevel.A2, ProgressionStatus.NOT_EVALUATED),
                Map.of(TargetLevel.A2, true));

        assertThat(service.raison(projection, TargetLevel.A2))
                .isEqualTo(RecommendationReasonCode.VALIDATED_VIA_HIGHER_LEVEL);
    }

    /** Jamais mesuré appelle une mesure, pas un entraînement à l'aveugle. */
    @Test
    @DisplayName("Un palier jamais mesuré demande une évaluation")
    void jamaisMesureDemandeUneMesure() {
        DomainProjection projection = projection(
                Map.of(TargetLevel.A2, ProgressionStatus.NOT_EVALUATED),
                Map.of(TargetLevel.A2, false));

        assertThat(service.raison(projection, TargetLevel.A2))
                .isEqualTo(RecommendationReasonCode.MISSING_ASSESSMENT);
    }

    @Test
    @DisplayName("Un palier en cours reste le palier à franchir")
    void palierEnCours() {
        DomainProjection projection = projection(
                Map.of(TargetLevel.A2, ProgressionStatus.PROGRESSING),
                Map.of(TargetLevel.A2, false));

        assertThat(service.raison(projection, TargetLevel.A2))
                .isEqualTo(RecommendationReasonCode.ACTIVE_LEVEL_NOT_CLEARED);
    }

    @Test
    @DisplayName("Une compétence prête à vérifier le dit, et ne se confond pas avec fragile")
    void competencePreteAVerifier() {
        assertThat(service.raison(competence(ProgressionStatus.READY_FOR_REASSESSMENT)))
                .isEqualTo(RecommendationReasonCode.READY_FOR_REASSESSMENT);
        assertThat(service.raison(competence(ProgressionStatus.FRAGILE)))
                .isEqualTo(RecommendationReasonCode.SKILL_FRAGILE);
        assertThat(service.raison(competence(ProgressionStatus.WATCH)))
                .isEqualTo(RecommendationReasonCode.WATCH_RECHECK);
    }

    private static DomainProjection projection(Map<TargetLevel, ProgressionStatus> statuts,
                                               Map<TargetLevel, Boolean> prerequis) {
        Map<TargetLevel, ProgressionSnapshot> paliers = new EnumMap<>(TargetLevel.class);
        Map<TargetLevel, Boolean> satisfaits = new EnumMap<>(TargetLevel.class);
        for (TargetLevel niveau : TargetLevel.values()) {
            paliers.put(niveau, palier(niveau,
                    statuts.getOrDefault(niveau, ProgressionStatus.NOT_EVALUATED)));
            satisfaits.put(niveau, prerequis.getOrDefault(niveau, false));
        }
        return new DomainProjection(SkillSection.CO, TargetLevel.B2, paliers, satisfaits,
                Map.of(), TargetLevel.A2, TargetLevel.A2);
    }

    private static ProgressionSnapshot palier(TargetLevel niveau, ProgressionStatus statut) {
        return new ProgressionSnapshot(
                ProgressionStateKey.receptive(SkillSection.CO, niveau),
                null, 0.0d, statut, false, false, false, null, 0.0d,
                0.0d, 0.0d, 0.0d, 0.0d, 0.0d, 0.0d, 0, 0, "CO:" + niveau + "#1");
    }

    private static ProgressionSnapshot competence(ProgressionStatus statut) {
        return new ProgressionSnapshot(
                ProgressionStateKey.productive(SkillSection.EE, "EE_CONNECTEURS"),
                null, 0.0d, statut, false, false, false, null, 0.0d,
                0.0d, 0.0d, 0.0d, 0.0d, 0.0d, 0.0d, 0, 0, "EE:EE_CONNECTEURS#1");
    }
}
