package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.Test;

import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Prerequis de progression CO / CE : les reussites hautes ne rachetent pas une base fragile. */
class ComprehensionLevelResolverTest {

    private final ComprehensionLevelResolver resolver = new ComprehensionLevelResolver();

    @Test
    void a2SolideB1SolideB2FragileDonneB1() {
        assertThat(resolver.niveauConsolide(etats(
                SkillMasteryState.SOLID,
                SkillMasteryState.SOLID,
                SkillMasteryState.TO_REINFORCE)))
                .contains(TargetLevel.B1);
    }

    @Test
    void a2SolideB1FragileB2ReussiDonneA2() {
        // LE cas du brief §60 : quelques reussites B2 ne prouvent rien tant que
        // le B1 n'est pas tenu. Conclure « B2 » enverrait le candidat a l'examen
        // sur une base qui n'existe pas.
        assertThat(resolver.niveauConsolide(etats(
                SkillMasteryState.SOLID,
                SkillMasteryState.TO_REINFORCE,
                SkillMasteryState.SOLID)))
                .contains(TargetLevel.A2);
    }

    @Test
    void unA2FragileNeConsolideRienMemeAvecTouteLaSuiteSolide() {
        assertThat(resolver.niveauConsolide(etats(
                SkillMasteryState.CONSOLIDATING,
                SkillMasteryState.SOLID,
                SkillMasteryState.SOLID)))
                .isEmpty();
    }

    @Test
    void lesTroisSolidesDonnentB2() {
        assertThat(resolver.niveauConsolide(etats(
                SkillMasteryState.SOLID, SkillMasteryState.SOLID, SkillMasteryState.SOLID)))
                .contains(TargetLevel.B2);
    }

    @Test
    void unPalierJamaisObserveInterrompLaChaineSansRienInventer() {
        Map<TargetLevel, SkillMasteryState> etats = new EnumMap<>(TargetLevel.class);
        etats.put(TargetLevel.A2, SkillMasteryState.SOLID);
        // B1 absent : le serveur ne l'a jamais observe. Inconnu, jamais mauvais
        // — mais inconnu ne consolide rien au-dessus non plus.
        etats.put(TargetLevel.B2, SkillMasteryState.SOLID);

        assertThat(resolver.niveauConsolide(etats)).contains(TargetLevel.A2);
    }

    @Test
    void aucuneObservationNeConsolideRien() {
        assertThat(resolver.niveauConsolide(Map.of())).isEmpty();
        assertThat(resolver.niveauConsolide(null)).isEmpty();
    }

    // ------------------------------------------------------------------ par domaine

    @Test
    void chaqueDomaineEstResoluSeparement() {
        Skill coA2 = skill(SkillSection.CO, "A2");
        Skill coB1 = skill(SkillSection.CO, "B1");
        Skill coB2 = skill(SkillSection.CO, "B2");
        Skill ceA2 = skill(SkillSection.CE, "A2");
        Skill ceB1 = skill(SkillSection.CE, "B1");
        // Une competence d'EXPRESSION glissee dans le lot est ignoree.
        Skill ee = skill(SkillSection.EE, "B1");

        Map<UUID, SkillMasteryState> etats = new HashMap<>();
        etats.put(coA2.getId(), SkillMasteryState.SOLID);
        etats.put(coB1.getId(), SkillMasteryState.SOLID);
        etats.put(coB2.getId(), SkillMasteryState.PRIORITY);
        etats.put(ceA2.getId(), SkillMasteryState.PRIORITY);
        etats.put(ceB1.getId(), SkillMasteryState.SOLID);
        etats.put(ee.getId(), SkillMasteryState.SOLID);

        Map<SkillSection, TargetLevel> niveaux = resolver.niveauxConsolides(
                List.of(coA2, coB1, coB2, ceA2, ceB1, ee), etats);

        assertThat(niveaux).containsEntry(SkillSection.CO, TargetLevel.B1);
        // CE : rien de consolide, donc ABSENT — jamais present a null.
        assertThat(niveaux).doesNotContainKey(SkillSection.CE);
        assertThat(niveaux).doesNotContainKey(SkillSection.EE);
    }

    @Test
    void unPalierHorsBanqueEstIgnoreSansCasserLeDomaine() {
        // Le referentiel des competences descend jusqu'a A1, que TargetLevel ne
        // connait pas : la ligne est ignoree, pas une exception.
        Skill a1 = skill(SkillSection.CO, "A1");
        Skill a2 = skill(SkillSection.CO, "A2");

        Map<UUID, SkillMasteryState> etats =
                Map.of(a1.getId(), SkillMasteryState.SOLID, a2.getId(), SkillMasteryState.SOLID);

        assertThat(resolver.niveauxConsolides(List.of(a1, a2), etats))
                .containsEntry(SkillSection.CO, TargetLevel.A2);
    }

    // ------------------------------------------------------------------ fixtures

    private static Map<TargetLevel, SkillMasteryState> etats(
            SkillMasteryState a2, SkillMasteryState b1, SkillMasteryState b2) {
        Map<TargetLevel, SkillMasteryState> etats = new EnumMap<>(TargetLevel.class);
        etats.put(TargetLevel.A2, a2);
        etats.put(TargetLevel.B1, b1);
        etats.put(TargetLevel.B2, b2);
        return etats;
    }

    private static Skill skill(SkillSection section, String level) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        skill.setTargetLevel(level);
        skill.setCode(section.name() + "-" + level);
        return skill;
    }
}
