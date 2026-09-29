package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.service.plan.PlanConfig;
import com.sejourfr.app.service.plan.PlanConfigLoader;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>L'ordre du pool, et la composition de la journee.</b>
 *
 * <p>Les poids viennent de la configuration livree — aucun nombre n'est ecrit
 * dans ce test non plus : ce qui est verrouille, ce sont les <b>relations</b>
 * (reparer avant apprendre, domaine urgent avant domaine secondaire), pas des
 * valeurs.
 */
class PlanActionRankerTest {

    private static final PlanConfig CONFIG = PlanConfigLoader.load(1);

    private final PlanActionRanker ranker = new PlanActionRanker(CONFIG);

    /** 🛑 On repare ce qui bloque avant d'apprendre ce qui vient. */
    @Test
    @DisplayName("Une fragilite passe devant une acquisition du meme domaine")
    void uneFragilitePasseDevantUneAcquisition() {
        PlanActionRanker.Action acquisition = acquisition("EE2-C1", SkillSection.EE);
        PlanActionRanker.Action fragilite = fragilite("EE1-C1", SkillSection.EE);

        assertThat(codes(ranker.classer(List.of(acquisition, fragilite),
                domaines(NiveauCecrl.A2, NiveauCecrl.A2), TargetLevel.B2, null)))
                .containsExactly("EE1-C1", "EE2-C1");
    }

    /**
     * A nature egale, l'urgence du domaine tranche — et c'est celle que le
     * serveur a <b>deja</b> decidee, jamais un classement invente ici.
     */
    @Test
    @DisplayName("A nature egale, le domaine le plus urgent passe devant")
    void aNatureEgaleLeDomaineLePlusUrgentPasseDevant() {
        List<PlanActionRanker.Action> pool = List.of(
                acquisition("EO3-C1", SkillSection.EO),
                acquisition("EE2-C1", SkillSection.EE));
        Map<SkillSection, PlanDomainDto> domaines = new LinkedHashMap<>();
        domaines.put(SkillSection.EE, domaine(EpreuveType.TCF_EE, NiveauCecrl.A2,
                PlanDomainPriority.FORTE));
        domaines.put(SkillSection.EO, domaine(EpreuveType.TCF_EO, NiveauCecrl.B1,
                PlanDomainPriority.PAS_ENCORE_PRIORITAIRE));

        assertThat(codes(ranker.classer(pool, domaines, TargetLevel.B2, null)))
                .containsExactly("EE2-C1", "EO3-C1");
    }

    /**
     * 🛑 <b>REGLE DURE DE COMPOSITION</b> : au plus une action de domaine
     * secondaire dans la fenetre d'« Aujourd'hui ». Sans elle, un pool de vingt
     * actions ferait de la seance une liste de courses a quatre epreuves.
     */
    @Test
    @DisplayName("Aujourd'hui ne prend qu'une action de domaine secondaire")
    void aujourdHuiNePrendQuUneActionDeDomaineSecondaire() {
        List<PlanActionRanker.Action> pool = List.of(
                fragilite("EE1-C1", SkillSection.EE),
                acquisition("EO2-C1", SkillSection.EO),
                acquisition("EO2-C2", SkillSection.EO),
                acquisition("EE2-C1", SkillSection.EE));
        Map<SkillSection, PlanDomainDto> domaines = new LinkedHashMap<>();
        domaines.put(SkillSection.EE, domaine(EpreuveType.TCF_EE, NiveauCecrl.A2,
                PlanDomainPriority.FORTE));
        domaines.put(SkillSection.EO, domaine(EpreuveType.TCF_EO, NiveauCecrl.A2,
                PlanDomainPriority.A_TRAVAILLER));

        List<String> classe = codes(ranker.classer(pool, domaines, TargetLevel.B2, null));

        assertThat(classe.subList(0, CONFIG.display().todayMaxActions()))
                .as("une seule ligne d'oral dans la fenetre du jour")
                .filteredOn(code -> code.startsWith("EO"))
                .hasSize(CONFIG.display().todayMaxSecondaryDomainActions());
        assertThat(classe)
                .as("rien n'est perdu : le repousse revient juste apres la fenetre")
                .hasSize(4)
                .contains("EO2-C2");
    }

    /**
     * 🛑 Le plafond de domaines secondaires est un <b>maximum</b>, pas un
     * minimum : si tout le haut du classement est primaire, la seance reste sur
     * un seul domaine. On ne force pas de la diversite pour faire joli.
     */
    @Test
    @DisplayName("La composition ne FORCE aucune diversite")
    void laCompositionNeForceAucuneDiversite() {
        List<PlanActionRanker.Action> pool = List.of(
                fragilite("EE1-C1", SkillSection.EE),
                fragilite("EE1-C2", SkillSection.EE),
                fragilite("EE1-C3", SkillSection.EE),
                acquisition("EO2-C1", SkillSection.EO));
        Map<SkillSection, PlanDomainDto> domaines = new LinkedHashMap<>();
        domaines.put(SkillSection.EE, domaine(EpreuveType.TCF_EE, NiveauCecrl.A2,
                PlanDomainPriority.FORTE));
        domaines.put(SkillSection.EO, domaine(EpreuveType.TCF_EO, NiveauCecrl.B1,
                PlanDomainPriority.PAS_ENCORE_PRIORITAIRE));

        assertThat(codes(ranker.classer(pool, domaines, TargetLevel.B2, null))
                .subList(0, CONFIG.display().todayMaxActions()))
                .containsExactly("EE1-C1", "EE1-C2", "EE1-C3");
    }

    /**
     * 🛑 <b>La premiere place est epinglee.</b> C'est celle que le freemium
     * ouvre : un classement qui la deplacerait cadenasserait l'etape n&deg;1 du
     * candidat — exactement ce que cette ouverture existe pour eviter.
     */
    @Test
    @DisplayName("La premiere place designee reste en tete, quel que soit son score")
    void laPremierePlaceDesigneeResteEnTete() {
        PlanActionRanker.Action faible = acquisition("EO3-C1", SkillSection.EO);
        List<PlanActionRanker.Action> pool = List.of(
                fragilite("EE1-C1", SkillSection.EE), faible);
        Map<SkillSection, PlanDomainDto> domaines = new LinkedHashMap<>();
        domaines.put(SkillSection.EE, domaine(EpreuveType.TCF_EE, NiveauCecrl.A2,
                PlanDomainPriority.FORTE));
        domaines.put(SkillSection.EO, domaine(EpreuveType.TCF_EO, NiveauCecrl.B1,
                PlanDomainPriority.PAS_ENCORE_PRIORITAIRE));

        assertThat(codes(ranker.classer(pool, domaines, TargetLevel.B2, faible.skillId())))
                .containsExactly("EO3-C1", "EE1-C1");
    }

    /**
     * 🛑 <b>Aucune horloge.</b> Deux lectures du meme etat, sans action du
     * candidat, rendent exactement le meme ordre — c'est ce qui rend la
     * stickiness de la seance gratuite.
     */
    @Test
    @DisplayName("Le classement est deterministe")
    void leClassementEstDeterministe() {
        List<PlanActionRanker.Action> pool = List.of(
                acquisition("EE2-C1", SkillSection.EE),
                acquisition("EE2-C2", SkillSection.EE),
                fragilite("EO1-C1", SkillSection.EO));
        Map<SkillSection, PlanDomainDto> domaines = domaines(NiveauCecrl.A2, NiveauCecrl.A2);

        assertThat(ranker.classer(pool, domaines, TargetLevel.B2, null))
                .isEqualTo(ranker.classer(pool, domaines, TargetLevel.B2, null));
    }

    /** Un pool vide reste vide : rien n'est fabrique pour remplir une fenetre. */
    @Test
    @DisplayName("Un pool vide ne produit aucune action")
    void unPoolVideNeProduitAucuneAction() {
        assertThat(ranker.classer(List.of(), Map.of(), TargetLevel.B2, null)).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private static List<String> codes(List<PlanActionRanker.Action> actions) {
        return actions.stream().map(PlanActionRanker.Action::skillCode).toList();
    }

    private static PlanActionRanker.Action fragilite(String code, SkillSection section) {
        return new PlanActionRanker.Action(UUID.randomUUID(), code, section,
                PlanActionNature.A_RENFORCER, ObservationConfidence.HIGH,
                Instant.parse("2026-08-20T10:00:00Z"));
    }

    private static PlanActionRanker.Action acquisition(String code, SkillSection section) {
        return new PlanActionRanker.Action(UUID.randomUUID(), code, section,
                PlanActionNature.A_ACQUERIR, null, null);
    }

    private static Map<SkillSection, PlanDomainDto> domaines(
            NiveauCecrl ecrit, NiveauCecrl oral) {
        Map<SkillSection, PlanDomainDto> domaines = new LinkedHashMap<>();
        domaines.put(SkillSection.EE, domaine(EpreuveType.TCF_EE, ecrit,
                PlanDomainPriority.A_TRAVAILLER));
        domaines.put(SkillSection.EO, domaine(EpreuveType.TCF_EO, oral,
                PlanDomainPriority.A_TRAVAILLER));
        return domaines;
    }

    private static PlanDomainDto domaine(
            EpreuveType epreuve, NiveauCecrl niveau, PlanDomainPriority priority) {
        return PlanDomainDto.sansCompetences(epreuve, true, niveau, priority,
                null, null, List.of(), List.of());
    }
}
